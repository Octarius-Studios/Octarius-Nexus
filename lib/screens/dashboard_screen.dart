import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final focus = state.focusProject;
    final focusTasks = focus == null
        ? <StudioTask>[]
        : state.tasks
              .where((task) => task.projectId == focus.id && task.isOpen)
              .take(4)
              .toList();

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeader(
          title: '${greetingForNow()}, ${user.name}',
          subtitle:
              'Warsztat Octarius. ${state.activeUsers.length} z $maxTeamSize osób w zespole.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final tiles = [
              _Tile(
                icon: Icons.groups_outlined,
                label: 'Zespół',
                value: '${state.activeUsers.length} / $maxTeamSize',
                hint: state.pendingUsers.isEmpty
                    ? 'Wszyscy są w studiu'
                    : '${state.pendingUsers.length} czeka na potwierdzenie',
                onTap: () => state.openSection(1),
              ),
              _Tile(
                icon: Icons.assignment_ind_outlined,
                label: 'Moje zadania',
                value: '${state.myOpenTaskCount}',
                hint: 'Otwarte i przypisane do Ciebie',
                onTap: () => state.openSection(3),
              ),
              _Tile(
                icon: Icons.priority_high,
                label: 'Pilne',
                value: '${state.urgentCount}',
                hint: 'Otwarte zadania z priorytetem pilnym',
                onTap: () => state.openSection(3),
              ),
              _Tile(
                icon: Icons.folder_open_outlined,
                label: 'W produkcji',
                value: focus?.name ?? 'Brak',
                hint: focus == null
                    ? 'Dodaj pierwszy projekt'
                    : '${focus.status} · ${(state.progressFor(focus.id) * 100).round()}% gotowe',
                onTap: () {
                  if (focus != null) {
                    state.openProject(focus.id);
                  } else {
                    state.openSection(2);
                  }
                },
              ),
            ];
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  for (final tile in tiles) ...[
                    tile,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const Text(
          'Na warsztacie',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ice,
          ),
        ),
        const SizedBox(height: 12),
        if (focus == null)
          const SurfaceCard(
            child: Text(
              'Nie ma otwartego projektu.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        focus.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ice,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: focus.status,
                      tone: toneForStatus(focus.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  focus.summary,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: state.progressFor(focus.id),
                    minHeight: 8,
                    backgroundColor: AppColors.deep,
                    color: AppColors.azure,
                  ),
                ),
                const SizedBox(height: 14),
                if (focusTasks.isEmpty)
                  const Text(
                    'Brak otwartych zadań w tym projekcie.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  for (final task in focusTasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: task.priority == 'pilny'
                                ? const Color(0xFFFF8D8D)
                                : AppColors.azure,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(color: AppColors.ice),
                            ),
                          ),
                          Text(
                            labelOf(taskColumns, task.columnId),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.azure),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ice,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
