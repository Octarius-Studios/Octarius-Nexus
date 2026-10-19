import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;
    final seatsLeft = maxTeamSize - state.activeUsers.length;

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeader(
          title: 'Zespół',
          subtitle: user.canReviewMembers
              ? 'Potwierdzasz nowe konta. Prezes nadaje rangi. Aktywnych miejsc: $seatsLeft.'
              : 'Twoja ranga: ${user.roleLabel}. Nowe konto potwierdza prezes albo współwłaściciel.',
        ),
        const SizedBox(height: 20),
        if (user.canReviewMembers && state.pendingUsers.isNotEmpty) ...[
          const Text(
            'Do potwierdzenia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ice,
            ),
          ),
          const SizedBox(height: 10),
          for (final member in state.pendingUsers) ...[
            SurfaceCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.deep,
                    child: Text(
                      initialsOf(member.name),
                      style: const TextStyle(
                        color: AppColors.ice,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ice,
                          ),
                        ),
                        Text(
                          member.email,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final error = state.rejectMember(member.id);
                      if (error != null) {
                        showNotice(context, error);
                      }
                    },
                    child: const Text('Odrzuć'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final error = state.approveMember(member.id);
                      if (error != null) {
                        showNotice(context, error);
                      }
                    },
                    child: const Text('Potwierdź'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
        ],
        for (final member in state.activeUsers) ...[
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: switch (member.role) {
                    'prezes' => AppColors.azure,
                    'wspol' => AppColors.lilac,
                    _ => AppColors.deep,
                  },
                  child: Text(
                    initialsOf(member.name),
                    style: TextStyle(
                      color: member.role == 'pracownik'
                          ? AppColors.ice
                          : AppColors.abyss,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.ice,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      if (user.canManageRanks)
                        DropdownButtonFormField<String>(
                          key: ValueKey('${member.id}-${member.role}'),
                          initialValue: member.role,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          decoration: const InputDecoration(labelText: 'Ranga'),
                          items: [
                            for (final rank in ranks)
                              DropdownMenuItem(
                                value: rank.id,
                                child: Text(rank.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null || value == member.role) {
                              return;
                            }
                            final error = state.setRank(member.id, value);
                            if (error != null) {
                              showNotice(context, error);
                            }
                          },
                        )
                      else
                        StatusChip(
                          label: member.roleLabel,
                          tone: toneForRank(member.role),
                        ),
                    ],
                  ),
                ),
                if (user.canManageRanks && member.id != user.id)
                  IconButton(
                    tooltip: 'Usuń z zespołu',
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Usunąć ${member.name}?',
                        message:
                            'Ta osoba nie zaloguje się już na tym komputerze.',
                        confirmLabel: 'Usuń',
                      );
                      if (!ok || !context.mounted) {
                        return;
                      }
                      final error = AppScope.of(context)
                          .deleteMember(member.id);
                      if (error != null && context.mounted) {
                        showNotice(context, error);
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
