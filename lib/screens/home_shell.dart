import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account_screen.dart';
import 'dashboard_screen.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';
import 'team_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _sections = <({String label, IconData icon, IconData selected})>[
    (
      label: 'Panel',
      icon: Icons.space_dashboard_outlined,
      selected: Icons.space_dashboard,
    ),
    (label: 'Zespół', icon: Icons.groups_outlined, selected: Icons.groups),
    (
      label: 'Projekty',
      icon: Icons.folder_open_outlined,
      selected: Icons.folder_open,
    ),
    (
      label: 'Zadania',
      icon: Icons.view_kanban_outlined,
      selected: Icons.view_kanban,
    ),
    (label: 'Konto', icon: Icons.person_outline, selected: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pages = const [
      DashboardScreen(),
      TeamScreen(),
      ProjectsScreen(),
      TasksScreen(),
      AccountScreen(),
    ];
    final index = state.section.clamp(0, pages.length - 1);
    final page = pages[index];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Scaffold(
            body: SafeArea(child: page),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: state.openSection,
              destinations: [
                for (var i = 0; i < _sections.length; i++)
                  NavigationDestination(
                    icon: _badge(state, i, Icon(_sections[i].icon)),
                    selectedIcon: _badge(state, i, Icon(_sections[i].selected)),
                    label: _sections[i].label,
                  ),
              ],
            ),
          );
        }

        final collapsed = state.navCollapsed;
        final user = state.currentUser!;
        return Scaffold(
          backgroundColor: AppColors.abyss,
          body: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: collapsed ? 84 : 252,
                padding: EdgeInsets.fromLTRB(
                  collapsed ? 12 : 16,
                  16,
                  collapsed ? 12 : 16,
                  16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.deep,
                  border: Border(right: BorderSide(color: AppColors.line)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const LogoMark(size: 42),
                        if (!collapsed) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Octarius Nexus',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ice,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Align(
                      alignment: collapsed
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: IconButton(
                        tooltip: collapsed ? 'Rozsuń menu' : 'Schowaj menu',
                        onPressed: state.toggleNav,
                        icon: Icon(
                          collapsed ? Icons.chevron_right : Icons.chevron_left,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _sections.length; i++) ...[
                      _NavButton(
                        label: _sections[i].label,
                        icon: index == i
                            ? _sections[i].selected
                            : _sections[i].icon,
                        selected: index == i,
                        collapsed: collapsed,
                        count: _countFor(state, i),
                        onTap: () => state.openSection(i),
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Spacer(),
                    Tooltip(
                      message: collapsed
                          ? '${user.name} · ${user.roleLabel}'
                          : '',
                      child: Container(
                        padding: EdgeInsets.all(collapsed ? 8 : 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: collapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.azure,
                              child: Text(
                                initialsOf(user.name),
                                style: const TextStyle(
                                  color: AppColors.abyss,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (!collapsed) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ice,
                                      ),
                                    ),
                                    Text(
                                      user.roleLabel,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: page),
            ],
          ),
        );
      },
    );
  }

  int _countFor(AppState state, int index) {
    if (index == 1 && state.currentUser!.canReviewMembers) {
      return state.pendingUsers.length;
    }
    if (index == 3) {
      return state.myOpenTaskCount;
    }
    return 0;
  }

  Widget _badge(AppState state, int index, Widget icon) {
    final count = _countFor(state, index);
    if (count == 0) {
      return icon;
    }
    return Badge(label: Text('$count'), child: icon);
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    required this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 22,
      color: selected ? AppColors.azure : AppColors.muted,
    );
    return Tooltip(
      message: collapsed ? label : '',
      child: Material(
        color: selected ? AppColors.azureSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 11,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (count > 0)
                  Badge(label: Text('$count'), child: iconWidget)
                else
                  iconWidget,
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected ? AppColors.ice : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
