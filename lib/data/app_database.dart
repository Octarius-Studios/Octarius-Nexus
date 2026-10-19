import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'models.dart';
import 'passwords.dart';

class AppDatabase {
  AppDatabase({this.filePath});

  final String? filePath;
  Database? _db;

  static String defaultFilePath() {
    final root = Platform.environment['APPDATA'] ?? Directory.current.path;
    return p.join(root, 'Octarius Nexus', 'octarius_nexus.sqlite');
  }

  Database get db {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    final path = filePath ?? defaultFilePath();
    if (path != ':memory:') {
      File(path).parent.createSync(recursive: true);
    }
    final database = sqlite3.open(path);
    database.execute('PRAGMA foreign_keys = ON');
    _create(database);
    _db = database;
    return database;
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }

  void _create(Database database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        summary TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        details TEXT NOT NULL,
        column_id TEXT NOT NULL,
        assignee_id INTEGER,
        project_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    _migrate(database);
  }

  void _migrate(Database database) {
    _ensureColumn(
      database,
      'users',
      'status',
      "TEXT NOT NULL DEFAULT 'aktywny'",
    );
    _ensureColumn(
      database,
      'projects',
      'priority',
      "TEXT NOT NULL DEFAULT 'Normalny'",
    );
    _ensureColumn(database, 'projects', 'lead_id', 'INTEGER');
    _ensureColumn(database, 'projects', 'target_date', 'TEXT');
    _ensureColumn(
      database,
      'tasks',
      'priority',
      "TEXT NOT NULL DEFAULT 'normalny'",
    );
    _ensureColumn(database, 'tasks', 'kind', "TEXT NOT NULL DEFAULT 'kod'");
    _ensureColumn(database, 'tasks', 'due_date', 'TEXT');
    database.execute(
      "UPDATE projects SET status = 'Koncept' WHERE status = 'Plan'",
    );
    database.execute(
      "UPDATE projects SET status = 'Produkcja' WHERE status = 'W trakcie'",
    );
    database.execute(
      "UPDATE tasks SET column_id = 'backlog' WHERE column_id = 'todo'",
    );
    database.execute(
      "UPDATE users SET status = 'aktywny' WHERE status IS NULL OR status = ''",
    );
  }

  void _ensureColumn(
    Database database,
    String table,
    String column,
    String definition,
  ) {
    final info = database.select('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      database.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  List<StudioUser> listUsers() {
    final rows = db.select('''
      SELECT id, name, email, role, status, created_at FROM users
      ORDER BY CASE role WHEN 'prezes' THEN 0 WHEN 'wspol' THEN 1 ELSE 2 END, name COLLATE NOCASE
    ''');
    return rows.map(_userFromRow).toList();
  }

  List<Project> listProjects() {
    final rows = db.select('''
      SELECT id, name, summary, status, priority, lead_id, target_date, created_at
      FROM projects ORDER BY id
      ''');
    return rows.map(_projectFromRow).toList();
  }

  List<StudioTask> listTasks() {
    final rows = db.select('''
      SELECT id, title, details, column_id, priority, kind, assignee_id, project_id, due_date, created_at
      FROM tasks
      ORDER BY id DESC
    ''');
    return rows.map(_taskFromRow).toList();
  }

  StudioUser? authenticate(String email, String password) {
    final rows = db.select(
      '''
      SELECT id, name, email, role, status, created_at, password_hash, salt
      FROM users WHERE email = ?
      ''',
      [normalizeEmail(email)],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    final salt = row['salt'] as String;
    final hash = row['password_hash'] as String;
    if (hash != hashPassword(password, salt)) {
      return null;
    }
    return _userFromRow(row);
  }

  bool passwordMatches(int userId, String password) {
    final rows = db.select(
      'SELECT password_hash, salt FROM users WHERE id = ?',
      [userId],
    );
    if (rows.isEmpty) {
      return false;
    }
    final salt = rows.first['salt'] as String;
    final hash = rows.first['password_hash'] as String;
    return hash == hashPassword(password, salt);
  }

  void setPassword(int userId, String password) {
    final salt = createSalt();
    db.execute('UPDATE users SET password_hash = ?, salt = ? WHERE id = ?', [
      hashPassword(password, salt),
      salt,
      userId,
    ]);
  }

  StudioUser createPresident({
    required String name,
    required String email,
    required String password,
  }) {
    final salt = createSalt();
    final now = DateTime.now().toIso8601String();
    db.execute('BEGIN');
    try {
      db.execute(
        '''
        INSERT INTO users (name, email, password_hash, salt, role, status, created_at)
        VALUES (?, ?, ?, ?, 'prezes', 'aktywny', ?)
        ''',
        [
          name.trim(),
          normalizeEmail(email),
          hashPassword(password, salt),
          salt,
          now,
        ],
      );
      final userId = db.lastInsertRowId;
      db.execute(
        '''
        INSERT INTO projects (name, summary, status, priority, lead_id, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          'Nexora',
          'Przeglądarka łącząca graczy ze zwykłym przeglądaniem. Dopieszczamy szczegóły przed premierą.',
          'Produkcja',
          'Wysoki',
          userId,
          now,
        ],
      );
      db.execute('COMMIT');
      return StudioUser(
        id: userId,
        name: name.trim(),
        email: normalizeEmail(email),
        role: 'prezes',
        status: 'aktywny',
        createdAt: now,
      );
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  StudioUser insertEmployee({
    required String name,
    required String email,
    required String password,
  }) {
    final salt = createSalt();
    final now = DateTime.now().toIso8601String();
    db.execute(
      '''
      INSERT INTO users (name, email, password_hash, salt, role, status, created_at)
      VALUES (?, ?, ?, ?, 'pracownik', 'oczekuje', ?)
      ''',
      [
        name.trim(),
        normalizeEmail(email),
        hashPassword(password, salt),
        salt,
        now,
      ],
    );
    return StudioUser(
      id: db.lastInsertRowId,
      name: name.trim(),
      email: normalizeEmail(email),
      role: 'pracownik',
      status: 'oczekuje',
      createdAt: now,
    );
  }

  void setStatus(int id, String status) {
    db.execute('UPDATE users SET status = ? WHERE id = ?', [status, id]);
  }

  void setName(int id, String name) {
    db.execute('UPDATE users SET name = ? WHERE id = ?', [name.trim(), id]);
  }

  String? setting(String key) {
    final rows = db.select('SELECT value FROM settings WHERE key = ?', [key]);
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String;
  }

  void setSetting(String key, String value) {
    db.execute(
      'INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  void setRole(int id, String role) {
    db.execute('UPDATE users SET role = ? WHERE id = ?', [role, id]);
  }

  void deleteUser(int id) {
    db.execute('BEGIN');
    try {
      db.execute('UPDATE tasks SET assignee_id = NULL WHERE assignee_id = ?', [
        id,
      ]);
      db.execute('UPDATE projects SET lead_id = NULL WHERE lead_id = ?', [id]);
      db.execute('DELETE FROM users WHERE id = ?', [id]);
      db.execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void insertProject({
    required String name,
    required String summary,
    required String status,
    required String priority,
    required int? leadId,
    required String? targetDate,
  }) {
    db.execute(
      '''
      INSERT INTO projects (
        name, summary, status, priority, lead_id, target_date, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        name.trim(),
        summary.trim(),
        status,
        priority,
        leadId,
        targetDate,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  void updateProject({
    required int id,
    required String name,
    required String summary,
    required String status,
    required String priority,
    required int? leadId,
    required String? targetDate,
  }) {
    db.execute(
      '''
      UPDATE projects
      SET name = ?, summary = ?, status = ?, priority = ?, lead_id = ?, target_date = ?
      WHERE id = ?
      ''',
      [name.trim(), summary.trim(), status, priority, leadId, targetDate, id],
    );
  }

  void deleteProject(int id) {
    db.execute('BEGIN');
    try {
      db.execute('UPDATE tasks SET project_id = NULL WHERE project_id = ?', [
        id,
      ]);
      db.execute('DELETE FROM projects WHERE id = ?', [id]);
      db.execute('COMMIT');
    } catch (error) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void insertTask({
    required String title,
    required String details,
    required String columnId,
    required String priority,
    required String kind,
    required int? assigneeId,
    required int? projectId,
    required String? dueDate,
  }) {
    db.execute(
      '''
      INSERT INTO tasks (
        title, details, column_id, priority, kind, assignee_id, project_id, due_date, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        title.trim(),
        details.trim(),
        columnId,
        priority,
        kind,
        assigneeId,
        projectId,
        dueDate,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  void updateTask({
    required int id,
    required String title,
    required String details,
    required String columnId,
    required String priority,
    required String kind,
    required int? assigneeId,
    required int? projectId,
    required String? dueDate,
  }) {
    db.execute(
      '''
      UPDATE tasks
      SET title = ?, details = ?, column_id = ?, priority = ?, kind = ?,
          assignee_id = ?, project_id = ?, due_date = ?
      WHERE id = ?
      ''',
      [
        title.trim(),
        details.trim(),
        columnId,
        priority,
        kind,
        assigneeId,
        projectId,
        dueDate,
        id,
      ],
    );
  }

  void moveTask(int id, String columnId) {
    db.execute('UPDATE tasks SET column_id = ? WHERE id = ?', [columnId, id]);
  }

  void deleteTask(int id) {
    db.execute('DELETE FROM tasks WHERE id = ?', [id]);
  }

  bool emailTaken(String email) {
    final rows = db.select('SELECT id FROM users WHERE email = ?', [
      normalizeEmail(email),
    ]);
    return rows.isNotEmpty;
  }

  StudioUser _userFromRow(Row row) {
    return StudioUser(
      id: row['id'] as int,
      name: row['name'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
      status: (row['status'] as String?) ?? 'aktywny',
      createdAt: row['created_at'] as String,
    );
  }

  Project _projectFromRow(Row row) {
    return Project(
      id: row['id'] as int,
      name: row['name'] as String,
      summary: row['summary'] as String,
      status: row['status'] as String,
      priority: (row['priority'] as String?) ?? 'Normalny',
      leadId: row['lead_id'] as int?,
      targetDate: row['target_date'] as String?,
      createdAt: row['created_at'] as String,
    );
  }

  StudioTask _taskFromRow(Row row) {
    return StudioTask(
      id: row['id'] as int,
      title: row['title'] as String,
      details: row['details'] as String,
      columnId: row['column_id'] as String,
      priority: (row['priority'] as String?) ?? 'normalny',
      kind: (row['kind'] as String?) ?? 'kod',
      assigneeId: row['assignee_id'] as int?,
      projectId: row['project_id'] as int?,
      dueDate: row['due_date'] as String?,
      createdAt: row['created_at'] as String,
    );
  }
}
