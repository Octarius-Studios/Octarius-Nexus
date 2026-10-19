import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/models.dart';
import '../data/passwords.dart';

class AppState extends ChangeNotifier {
  AppState({AppDatabase? database}) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  bool ready = false;
  String? bootError;
  StudioUser? currentUser;
  List<StudioUser> users = [];
  List<Project> projects = [];
  List<StudioTask> tasks = [];
  int section = 0;
  int? selectedProjectId;
  bool navCollapsed = false;

  bool get hasUsers => users.isNotEmpty;

  List<StudioUser> get activeUsers =>
      users.where((user) => user.isActive).toList();

  List<StudioUser> get pendingUsers =>
      users.where((user) => user.isPending).toList();

  int get openTaskCount => tasks.where((task) => task.isOpen).length;

  int get myOpenTaskCount => tasks
      .where((task) => task.isOpen && task.assigneeId == currentUser?.id)
      .length;

  int get urgentCount =>
      tasks.where((task) => task.isOpen && task.priority == 'pilny').length;

  Project? get focusProject {
    for (final project in projects) {
      if (project.status == 'Produkcja') {
        return project;
      }
    }
    for (final project in projects) {
      if (project.status != 'Wydane' && project.status != 'Wstrzymany') {
        return project;
      }
    }
    if (projects.isEmpty) {
      return null;
    }
    return projects.first;
  }

  Project? get selectedProject {
    for (final project in projects) {
      if (project.id == selectedProjectId) {
        return project;
      }
    }
    return focusProject;
  }

  double progressFor(int projectId) {
    final related = tasks.where((task) => task.projectId == projectId).toList();
    if (related.isEmpty) {
      return 0;
    }
    final done = related.where((task) => !task.isOpen).length;
    return done / related.length;
  }

  void boot() {
    if (ready) {
      return;
    }
    try {
      _database.db;
      _load();
    } catch (error) {
      bootError = 'Nie udało się otworzyć lokalnej bazy. $error';
    }
    ready = true;
    notifyListeners();
  }

  void openSection(int index) {
    section = index;
    notifyListeners();
  }

  void openProject(int id) {
    selectedProjectId = id;
    section = 2;
    notifyListeners();
  }

  void toggleNav() {
    navCollapsed = !navCollapsed;
    _database.setSetting('nav_collapsed', navCollapsed ? '1' : '0');
    notifyListeners();
  }

  String? registerPresident({
    required String name,
    required String email,
    required String password,
    required String repeatedPassword,
  }) {
    final error = _validateNewAccount(
      name: name,
      email: email,
      password: password,
      repeatedPassword: repeatedPassword,
    );
    if (error != null) {
      return error;
    }
    if (hasUsers) {
      return 'Konto prezesa już istnieje.';
    }
    currentUser = _database.createPresident(
      name: name,
      email: email,
      password: password,
    );
    _refresh();
    return null;
  }

  String? login({required String email, required String password}) {
    final user = _database.authenticate(email, password);
    if (user == null) {
      return 'Nieprawidłowy e-mail lub hasło.';
    }
    currentUser = user;
    section = 0;
    _refresh();
    return null;
  }

  void logout() {
    currentUser = null;
    section = 0;
    notifyListeners();
  }

  String? registerMember({
    required String name,
    required String email,
    required String password,
    required String repeatedPassword,
  }) {
    if (!hasUsers) {
      return 'Najpierw potrzebne jest konto prezesa.';
    }
    final error = _validateNewAccount(
      name: name,
      email: email,
      password: password,
      repeatedPassword: repeatedPassword,
    );
    if (error != null) {
      return error;
    }
    if (activeUsers.length >= maxTeamSize) {
      return 'Zespół jest pełny. Mieści się w nim 5 osób.';
    }
    if (_database.emailTaken(email)) {
      return 'Ten adres e-mail jest już używany.';
    }
    currentUser = _database.insertEmployee(
      name: name,
      email: email,
      password: password,
    );
    section = 0;
    _refresh();
    return null;
  }

  String? setRank(int id, String role) {
    final actor = currentUser;
    if (actor == null || !actor.canManageRanks) {
      return 'Tylko prezes nadaje rangi.';
    }
    if (!ranks.any((rank) => rank.id == role)) {
      return 'Nie ma takiej rangi.';
    }
    final target = _findUser(id);
    if (target == null || !target.isActive) {
      return 'Rangę można nadać tylko potwierdzonej osobie.';
    }
    if (target.role == role) {
      return null;
    }
    final presidents = activeUsers.where((user) => user.isPresident).length;
    if (target.isPresident && role != 'prezes' && presidents <= 1) {
      return 'W studiu musi zostać przynajmniej jeden prezes.';
    }
    _database.setRole(id, role);
    _refresh();
    return null;
  }

  String? deleteMember(int id) {
    final actor = currentUser;
    if (actor == null || !actor.canManageRanks) {
      return 'Tylko prezes usuwa osoby z zespołu.';
    }
    if (actor.id == id) {
      return 'Nie możesz usunąć własnego konta.';
    }
    final target = _findUser(id);
    if (target == null) {
      return 'Nie ma takiej osoby.';
    }
    final presidents = activeUsers.where((user) => user.isPresident).length;
    if (target.isPresident && presidents <= 1) {
      return 'W studiu musi zostać przynajmniej jeden prezes.';
    }
    _database.deleteUser(id);
    _refresh();
    return null;
  }

  String? approveMember(int id) {
    final actor = currentUser;
    if (actor == null || !actor.canReviewMembers) {
      return 'Tylko prezes lub współwłaściciel potwierdza konta.';
    }
    final target = _findUser(id);
    if (target == null || !target.isPending) {
      return 'To konto nie czeka na potwierdzenie.';
    }
    if (activeUsers.length >= maxTeamSize) {
      return 'Zespół jest pełny. Mieści się w nim 5 osób.';
    }
    _database.setStatus(id, 'aktywny');
    _refresh();
    return null;
  }

  String? rejectMember(int id) {
    final actor = currentUser;
    if (actor == null || !actor.canReviewMembers) {
      return 'Tylko prezes lub współwłaściciel odrzuca konta.';
    }
    final target = _findUser(id);
    if (target == null || !target.isPending) {
      return 'Odrzucić można tylko konto oczekujące.';
    }
    _database.deleteUser(id);
    _refresh();
    return null;
  }

  String? changeName(String name) {
    final user = currentUser;
    if (user == null) {
      return 'Zaloguj się ponownie.';
    }
    final nameError = validateName(name);
    if (nameError != null) {
      return nameError;
    }
    _database.setName(user.id, name);
    _refresh();
    return null;
  }

  String? saveProject({
    int? id,
    required String name,
    required String summary,
    required String status,
    required String priority,
    required int? leadId,
    required String? targetDate,
  }) {
    if (currentUser == null || currentUser!.isPending) {
      return 'Zaloguj się ponownie.';
    }
    if (name.trim().length < 2) {
      return 'Podaj nazwę projektu.';
    }
    if (!projectStatuses.contains(status)) {
      return 'Wybierz etap projektu.';
    }
    if (!projectPriorities.contains(priority)) {
      return 'Wybierz priorytet projektu.';
    }
    final creating = id == null;
    if (creating) {
      _database.insertProject(
        name: name,
        summary: summary,
        status: status,
        priority: priority,
        leadId: leadId,
        targetDate: targetDate,
      );
    } else {
      _database.updateProject(
        id: id,
        name: name,
        summary: summary,
        status: status,
        priority: priority,
        leadId: leadId,
        targetDate: targetDate,
      );
    }
    _refresh();
    if (creating && projects.isNotEmpty) {
      selectedProjectId = projects.last.id;
      notifyListeners();
    }
    return null;
  }

  String? deleteProject(int id) {
    final actor = currentUser;
    if (actor == null || !actor.canEditStudio) {
      return 'Tylko prezes lub współwłaściciel usuwa projekty.';
    }
    _database.deleteProject(id);
    _refresh();
    return null;
  }

  String? saveTask({
    int? id,
    required String title,
    required String details,
    required String columnId,
    required String priority,
    required String kind,
    required int? assigneeId,
    required int? projectId,
    required String? dueDate,
  }) {
    if (currentUser == null || currentUser!.isPending) {
      return 'Zaloguj się ponownie.';
    }
    if (title.trim().isEmpty) {
      return 'Podaj tytuł zadania.';
    }
    if (!taskColumns.any((column) => column.id == columnId)) {
      return 'Wybierz kolumnę.';
    }
    if (!taskPriorities.any((item) => item.id == priority)) {
      return 'Wybierz priorytet.';
    }
    if (!taskKinds.any((item) => item.id == kind)) {
      return 'Wybierz rodzaj pracy.';
    }
    if (id == null) {
      _database.insertTask(
        title: title,
        details: details,
        columnId: columnId,
        priority: priority,
        kind: kind,
        assigneeId: assigneeId,
        projectId: projectId,
        dueDate: dueDate,
      );
    } else {
      _database.updateTask(
        id: id,
        title: title,
        details: details,
        columnId: columnId,
        priority: priority,
        kind: kind,
        assigneeId: assigneeId,
        projectId: projectId,
        dueDate: dueDate,
      );
    }
    _refresh();
    return null;
  }

  String? moveTask(int id, String columnId) {
    if (currentUser == null) {
      return 'Zaloguj się ponownie.';
    }
    if (!taskColumns.any((column) => column.id == columnId)) {
      return 'Wybierz kolumnę.';
    }
    _database.moveTask(id, columnId);
    _refresh();
    return null;
  }

  String? deleteTask(int id) {
    if (currentUser == null) {
      return 'Zaloguj się ponownie.';
    }
    _database.deleteTask(id);
    _refresh();
    return null;
  }

  String? changePassword({
    required String current,
    required String next,
    required String repeated,
  }) {
    final user = currentUser;
    if (user == null) {
      return 'Zaloguj się ponownie.';
    }
    if (next != repeated) {
      return 'Nowe hasła nie są takie same.';
    }
    final passwordError = validatePassword(next);
    if (passwordError != null) {
      return passwordError;
    }
    if (!_database.passwordMatches(user.id, current)) {
      return 'Obecne hasło jest nieprawidłowe.';
    }
    _database.setPassword(user.id, next);
    return null;
  }

  String? _validateNewAccount({
    required String name,
    required String email,
    required String password,
    required String repeatedPassword,
  }) {
    final nameError = validateName(name);
    if (nameError != null) {
      return nameError;
    }
    final emailError = validateEmail(email);
    if (emailError != null) {
      return emailError;
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      return passwordError;
    }
    if (password != repeatedPassword) {
      return 'Hasła nie są takie same.';
    }
    return null;
  }

  StudioUser? _findUser(int id) {
    for (final user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  void _load() {
    users = _database.listUsers();
    projects = _database.listProjects();
    tasks = _database.listTasks();
    navCollapsed = _database.setting('nav_collapsed') == '1';
  }

  void _refresh() {
    final currentId = currentUser?.id;
    _load();
    if (currentId != null) {
      currentUser = _findUser(currentId);
    }
    notifyListeners();
  }
}
