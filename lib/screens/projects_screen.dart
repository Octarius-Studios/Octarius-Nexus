import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'tasks_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selected = state.selectedProject;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Projekty',
            subtitle: 'Etapy studia: koncept, produkcja, polish i wydanie.',
            action: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _ProjectDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nowy projekt'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final list = _ProjectList(selectedId: selected?.id);
                if (selected == null) {
                  return list;
                }
                final detail = _ProjectDetail(
                  key: ValueKey(selected.id),
                  project: selected,
                );
                if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      SizedBox(height: 220, child: list),
                      const SizedBox(height: 12),
                      Expanded(child: detail),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 320, child: list),
                    const SizedBox(width: 16),
                    Expanded(child: detail),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.projects.isEmpty) {
      return const SurfaceCard(
        child: Text(
          'Nie ma jeszcze projektów.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    return ListView(
      children: [
        for (final project in state.projects) ...[
          Material(
            color: project.id == selectedId
                ? AppColors.azureSoft
                : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => state.openProject(project.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: project.id == selectedId
                        ? AppColors.azure
                        : AppColors.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ice,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusChip(
                          label: project.status,
                          tone: toneForStatus(project.status),
                        ),
                        StatusChip(
                          label: project.priority,
                          tone: ChipTone.sand,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: state.progressFor(project.id),
                        minHeight: 6,
                        backgroundColor: AppColors.deep,
                        color: AppColors.azure,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProjectDetail extends StatefulWidget {
  const _ProjectDetail({super.key, required this.project});

  final Project project;

  @override
  State<_ProjectDetail> createState() => _ProjectDetailState();
}

class _ProjectDetailState extends State<_ProjectDetail> {
  late final TextEditingController _name;
  late final TextEditingController _summary;
  late String _status;
  late String _priority;
  int? _leadId;
  DateTime? _target;
  String? _error;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _name = TextEditingController(text: project.name);
    _summary = TextEditingController(text: project.summary);
    _status = project.status;
    _priority = project.priority;
    _leadId = project.leadId;
    _target = DateTime.tryParse(project.targetDate ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _save() {
    final date = _target == null
        ? null
        : '${_target!.year.toString().padLeft(4, '0')}-${_target!.month.toString().padLeft(2, '0')}-${_target!.day.toString().padLeft(2, '0')}';
    final error = AppScope.of(context).saveProject(
      id: widget.project.id,
      name: _name.text,
      summary: _summary.text,
      status: _status,
      priority: _priority,
      leadId: _leadId,
      targetDate: date,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    showNotice(context, 'Projekt zapisany.');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final tasks = state.tasks
        .where((task) => task.projectId == widget.project.id)
        .toList();
    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nazwa'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summary,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Opis'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('status-$_status'),
                initialValue: _status,
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(labelText: 'Etap'),
                items: [
                  for (final status in projectStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('prio-$_priority'),
                initialValue: _priority,
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(labelText: 'Priorytet'),
                items: [
                  for (final priority in projectPriorities)
                    DropdownMenuItem(value: priority, child: Text(priority)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                key: ValueKey('lead-$_leadId'),
                initialValue: _leadId,
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(labelText: 'Prowadzący'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nieprzypisany'),
                  ),
                  for (final member in state.activeUsers)
                    DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                ],
                onChanged: (value) => setState(() => _leadId = value),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _target ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _target = picked);
                  }
                },
                child: Text(
                  _target == null
                      ? 'Cel wydania: brak'
                      : 'Cel wydania: ${formatDay(_target!.toIso8601String())}',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Zapisz projekt'),
                  ),
                  const SizedBox(width: 8),
                  if (user.canEditStudio)
                    TextButton(
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Usunąć ${widget.project.name}?',
                          message: 'Zadania zostaną, ale stracą przypisanie do projektu.',
                          confirmLabel: 'Usuń',
                        );
                        if (!ok || !context.mounted) {
                          return;
                        }
                        final error = AppScope.of(context)
                            .deleteProject(widget.project.id);
                        if (error != null && context.mounted) {
                          showNotice(context, error);
                        }
                      },
                      child: const Text('Usuń'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Zadania projektu',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ice,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => TaskDialog(projectId: widget.project.id),
                    ),
                    child: const Text('Dodaj'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                const Text(
                  'Ten projekt nie ma jeszcze zadań.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                for (final task in tasks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      task.title,
                      style: const TextStyle(color: AppColors.ice),
                    ),
                    subtitle: Text(
                      '${labelOf(taskKinds, task.kind)} · ${labelOf(taskColumns, task.columnId)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    trailing: Icon(
                      Icons.circle,
                      size: 10,
                      color: priorityColor(task.priority),
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => TaskDialog(task: task),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog();

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  final _name = TextEditingController();
  final _summary = TextEditingController();
  String _status = 'Koncept';
  String _priority = 'Normalny';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _submit() {
    final state = AppScope.of(context);
    final error = state.saveProject(
      name: _name.text,
      summary: _summary.text,
      status: _status,
      priority: _priority,
      leadId: state.currentUser?.id,
      targetDate: null,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nowy projekt',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ice,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nazwa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summary,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Opis'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(labelText: 'Etap'),
                items: [
                  for (final status in projectStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(labelText: 'Priorytet'),
                items: [
                  for (final priority in projectPriorities)
                    DropdownMenuItem(value: priority, child: Text(priority)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                  FilledButton(onPressed: _submit, child: const Text('Utwórz')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
