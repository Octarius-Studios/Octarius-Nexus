import 'package:flutter_test/flutter_test.dart';
import 'package:octarius_nexus/data/app_database.dart';
import 'package:octarius_nexus/sqlite_setup.dart';
import 'package:octarius_nexus/state/app_state.dart';

void main() {
  setUpAll(configureSqlite);

  test('potwierdzenie konta, rangi i warsztat', () {
    final state = AppState(database: AppDatabase(filePath: ':memory:'));
    state.boot();

    expect(
      state.registerPresident(
        name: 'Jan Prezes',
        email: 'jan@octarius.test',
        password: 'haslo123',
        repeatedPassword: 'haslo123',
      ),
      isNull,
    );
    expect(state.projects.single.status, 'Produkcja');

    state.logout();
    expect(
      state.registerMember(
        name: 'Anna',
        email: 'anna@octarius.test',
        password: 'haslo123',
        repeatedPassword: 'haslo123',
      ),
      isNull,
    );
    expect(state.currentUser!.isPending, isTrue);
    expect(state.setRank(state.currentUser!.id, 'wspol'), isNotNull);

    state.logout();
    expect(
      state.login(email: 'jan@octarius.test', password: 'haslo123'),
      isNull,
    );
    final anna = state.users.firstWhere(
      (user) => user.email == 'anna@octarius.test',
    );
    expect(state.approveMember(anna.id), isNull);
    expect(
      state.users.firstWhere((user) => user.id == anna.id).isActive,
      isTrue,
    );
    expect(state.setRank(anna.id, 'wspol'), isNull);

    state.logout();
    expect(
      state.registerMember(
        name: 'Ola',
        email: 'ola@octarius.test',
        password: 'haslo123',
        repeatedPassword: 'haslo123',
      ),
      isNull,
    );
    state.logout();
    expect(
      state.login(email: 'anna@octarius.test', password: 'haslo123'),
      isNull,
    );
    expect(state.currentUser!.isPartner, isTrue);
    final ola = state.pendingUsers.single;
    expect(state.approveMember(ola.id), isNull);
    expect(state.setRank(ola.id, 'prezes'), isNotNull);

    state.logout();
    expect(
      state.login(email: 'jan@octarius.test', password: 'haslo123'),
      isNull,
    );
    expect(state.rejectMember(ola.id), isNotNull);
    expect(state.changeName('Janek'), isNull);
    expect(state.currentUser!.name, 'Janek');

    expect(
      state.saveTask(
        title: 'Przygotować build',
        details: '',
        columnId: 'backlog',
        priority: 'pilny',
        kind: 'kod',
        assigneeId: state.currentUser!.id,
        projectId: state.projects.single.id,
        dueDate: null,
      ),
      isNull,
    );
    expect(state.moveTask(state.tasks.single.id, 'review'), isNull);
    expect(state.urgentCount, 1);
    expect(state.progressFor(state.projects.single.id), 0);

    expect(state.setRank(state.currentUser!.id, 'pracownik'), isNotNull);
    expect(state.setRank(anna.id, 'pracownik'), isNull);
  });
}
