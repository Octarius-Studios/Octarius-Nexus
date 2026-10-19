class StudioUser {
  const StudioUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String createdAt;

  bool get isPresident => role == 'prezes';

  bool get isPartner => role == 'wspol';

  bool get isActive => status == 'aktywny';

  bool get isPending => status == 'oczekuje';

  bool get canManageRanks => isPresident && isActive;

  bool get canReviewMembers => (isPresident || isPartner) && isActive;

  bool get canEditStudio => canReviewMembers;

  String get roleLabel => switch (role) {
    'prezes' => 'Prezes',
    'wspol' => 'Współwłaściciel',
    _ => 'Pracownik',
  };
}

const ranks = <({String id, String label})>[
  (id: 'prezes', label: 'Prezes'),
  (id: 'wspol', label: 'Współwłaściciel'),
  (id: 'pracownik', label: 'Pracownik'),
];

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.summary,
    required this.status,
    required this.priority,
    required this.leadId,
    required this.targetDate,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String summary;
  final String status;
  final String priority;
  final int? leadId;
  final String? targetDate;
  final String createdAt;
}

class StudioTask {
  const StudioTask({
    required this.id,
    required this.title,
    required this.details,
    required this.columnId,
    required this.priority,
    required this.kind,
    required this.assigneeId,
    required this.projectId,
    required this.dueDate,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String details;
  final String columnId;
  final String priority;
  final String kind;
  final int? assigneeId;
  final int? projectId;
  final String? dueDate;
  final String createdAt;

  bool get isOpen => columnId != 'done';
}

const maxTeamSize = 5;

const projectStatuses = [
  'Koncept',
  'Produkcja',
  'Polish',
  'Wydane',
  'Wstrzymany',
];

const projectPriorities = ['Niski', 'Normalny', 'Wysoki'];

const taskColumns = <({String id, String label})>[
  (id: 'backlog', label: 'Backlog'),
  (id: 'doing', label: 'W toku'),
  (id: 'review', label: 'Do sprawdzenia'),
  (id: 'done', label: 'Zrobione'),
];

const taskPriorities = <({String id, String label})>[
  (id: 'niski', label: 'Niski'),
  (id: 'normalny', label: 'Normalny'),
  (id: 'wysoki', label: 'Wysoki'),
  (id: 'pilny', label: 'Pilny'),
];

const taskKinds = <({String id, String label})>[
  (id: 'kod', label: 'Kod'),
  (id: 'grafika', label: 'Grafika'),
  (id: 'dzwiek', label: 'Dźwięk'),
  (id: 'design', label: 'Design'),
  (id: 'blad', label: 'Błąd'),
  (id: 'organizacja', label: 'Organizacja'),
];

String labelOf(List<({String id, String label})> items, String id) {
  for (final item in items) {
    if (item.id == id) {
      return item.label;
    }
  }
  return id;
}
