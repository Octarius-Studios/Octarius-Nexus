import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int? _projectId;
  String? _priority;
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = state.tasks.where((task) {
      if (_projectId != null && task.projectId != _projectId) {
        return false;
      }
      if (_priority != null && task.priority != _priority) {
        return false;
      }
      if (_onlyMine && task.assigneeId != state.currentUser?.id) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Zadania',
            subtitle: 'Backlog, produkcja, sprawdzenie i odbiór. Przeciągnij kartę albo użyj strzałek.',
            action: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => TaskDialog(projectId: _projectId),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nowe zadanie'),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('projekt-$_projectId'),
                  initialValue: _projectId,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Projekt'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final project in state.projects)
                      DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _projectId = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('priorytet-$_priority'),
                  initialValue: _priority,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Priorytet'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    for (final priority in taskPriorities)
                      DropdownMenuItem(
                        value: priority.id,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _priority = value),
                ),
              ),
              FilterChip(
                label: const Text('Tylko moje'),
                selected: _onlyMine,
                onSelected: (value) => setState(() => _onlyMine = value),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: _Board(tasks: visible)),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.tasks});

  final List<StudioTask> tasks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 1100;
        final columns = [
          for (final column in taskColumns)
            SizedBox(
              width: narrow ? 270 : null,
              child: _TaskColumn(
                columnId: column.id,
                label: column.label,
                tasks: tasks
                    .where((task) => task.columnId == column.id)
                    .toList(),
              ),
            ),
        ];
        if (narrow) {
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                columns[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: columns[i]),
            ],
          ],
        );
      },
    );
  }
}

class _TaskColumn extends StatelessWidget {
  const _TaskColumn({
    required this.columnId,
    required this.label,
    required this.tasks,
  });

  final String columnId;
  final String label;
  final List<StudioTask> tasks;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return DragTarget<int>(
      onAcceptWithDetails: (details) => state.moveTask(details.data, columnId),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? AppColors.azureSoft : AppColors.deep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? AppColors.azure : AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ice,
                      ),
                    ),
                  ),
                  Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    if (tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Pusto',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    for (final task in tasks) ...[
                      _TaskCard(task: task),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final StudioTask task;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final columnIndex = taskColumns.indexWhere(
      (column) => column.id == task.columnId,
    );
    final assignee = _person(state, task.assigneeId);
    final project = _projectName(state, task.projectId);
    return Draggable<int>(
      data: task.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 250,
          child: _body(assignee, project, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _body(assignee, project),
      ),
      child: _body(
        assignee,
        project,
        onOpen: () => showDialog<void>(
          context: context,
          builder: (_) => TaskDialog(task: task),
        ),
        onLeft: columnIndex > 0
            ? () => state.moveTask(task.id, taskColumns[columnIndex - 1].id)
            : null,
        onRight: columnIndex >= 0 && columnIndex < taskColumns.length - 1
            ? () => state.moveTask(task.id, taskColumns[columnIndex + 1].id)
            : null,
        onDelete: () async {
          final ok = await confirmAction(
            context,
            title: 'Usunąć zadanie?',
            message: task.title,
            confirmLabel: 'Usuń',
          );
          if (!ok || !context.mounted) {
            return;
          }
          AppScope.of(context).deleteTask(task.id);
        },
      ),
    );
  }

  Widget _body(
    String assignee,
    String? project, {
    bool dragging = false,
    VoidCallback? onOpen,
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onDelete,
  }) {
    final late = task.isOpen && isOverdue(task.dueDate);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 8, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 72,
                margin: const EdgeInsets.only(left: 8, right: 10, top: 2),
                decoration: BoxDecoration(
                  color: priorityColor(task.priority),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ice,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusChip(label: labelOf(taskKinds, task.kind)),
                        StatusChip(
                          label: labelOf(taskPriorities, task.priority),
                          tone: ChipTone.sand,
                        ),
                        if (project != null)
                          StatusChip(label: project, tone: ChipTone.lilac),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      late
                          ? '$assignee · po terminie ${formatDay(task.dueDate!)}'
                          : assignee,
                      style: TextStyle(
                        color: late ? const Color(0xFFFF8D8D) : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (!dragging)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'W lewo',
                            onPressed: onLeft,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            tooltip: 'W prawo',
                            onPressed: onRight,
                            icon: const Icon(Icons.chevron_right),
                          ),
                          IconButton(
                            tooltip: 'Usuń',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _person(AppState state, int? id) {
    if (id == null) {
      return 'Nieprzypisane';
    }
    for (final user in state.users) {
      if (user.id == id) {
        return user.name;
      }
    }
    return 'Była osoba';
  }

  String? _projectName(AppState state, int? id) {
    if (id == null) {
      return null;
    }
    for (final project in state.projects) {
      if (project.id == id) {
        return project.name;
      }
    }
    return null;
  }
}

Color priorityColor(String priority) {
  return switch (priority) {
    'pilny' => const Color(0xFFFF8D8D),
    'wysoki' => AppColors.azure,
    'niski' => AppColors.muted,
    _ => AppColors.ink,
  };
}

bool isOverdue(String? due) {
  if (due == null || due.isEmpty) {
    return false;
  }
  final date = DateTime.tryParse(due);
  if (date == null) {
    return false;
  }
  final today = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).isBefore(DateTime(today.year, today.month, today.day));
}

class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key, this.task, this.projectId});

  final StudioTask? task;
  final int? projectId;

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _details;
  late String _columnId;
  late String _priority;
  late String _kind;
  int? _assigneeId;
  int? _projectId;
  DateTime? _due;
  String? _error;
  var _defaultsApplied = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _details = TextEditingController(text: task?.details ?? '');
    _columnId = task?.columnId ?? 'backlog';
    _priority = task?.priority ?? 'normalny';
    _kind = task?.kind ?? 'kod';
    _assigneeId = task?.assigneeId;
    _projectId = task?.projectId ?? widget.projectId;
    _due = DateTime.tryParse(task?.dueDate ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.task != null || _defaultsApplied) {
      return;
    }
    _defaultsApplied = true;
    final state = AppScope.of(context);
    _assigneeId ??= state.currentUser?.id;
    _projectId ??= widget.projectId ?? state.focusProject?.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _due = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final due = _due == null
        ? null
        : '${_due!.year.toString().padLeft(4, '0')}-${_due!.month.toString().padLeft(2, '0')}-${_due!.day.toString().padLeft(2, '0')}';
    final error = AppScope.of(context).saveTask(
      id: widget.task?.id,
      title: _title.text,
      details: _details.text,
      columnId: _columnId,
      priority: _priority,
      kind: _kind,
      assigneeId: _assigneeId,
      projectId: _projectId,
      dueDate: due,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.task == null ? 'Nowe zadanie' : 'Karta zadania',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ice,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Tytuł'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Podaj tytuł zadania.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _details,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Opis'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('col-$_columnId'),
                    initialValue: _columnId,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Etap'),
                    items: [
                      for (final column in taskColumns)
                        DropdownMenuItem(
                          value: column.id,
                          child: Text(column.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _columnId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('pri-$_priority'),
                    initialValue: _priority,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Priorytet'),
                    items: [
                      for (final priority in taskPriorities)
                        DropdownMenuItem(
                          value: priority.id,
                          child: Text(priority.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('kind-$_kind'),
                    initialValue: _kind,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Rodzaj'),
                    items: [
                      for (final kind in taskKinds)
                        DropdownMenuItem(
                          value: kind.id,
                          child: Text(kind.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _kind = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: ValueKey('who-$_assigneeId'),
                    initialValue: _assigneeId,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Osoba'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Nieprzypisane'),
                      ),
                      for (final user in state.activeUsers)
                        DropdownMenuItem(
                          value: user.id,
                          child: Text(user.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _assigneeId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: ValueKey('proj-$_projectId'),
                    initialValue: _projectId,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Projekt'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Bez projektu'),
                      ),
                      for (final project in state.projects)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(
                      _due == null
                          ? 'Termin: brak'
                          : 'Termin: ${formatDay(_due!.toIso8601String())}',
                    ),
                  ),
                  if (_due != null)
                    TextButton(
                      onPressed: () => setState(() => _due = null),
                      child: const Text('Usuń termin'),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anuluj'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        child: const Text('Zapisz'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
