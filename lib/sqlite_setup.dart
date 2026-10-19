import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';

/// Points SQLite at the DLL shipped with the Windows app.
void configureSqlite() {
  open.overrideFor(OperatingSystem.windows, () {
    final candidates = <String>[
      p.join(File(Platform.resolvedExecutable).parent.path, 'sqlite3.dll'),
      p.join(Directory.current.path, 'windows', 'runner', 'sqlite3.dll'),
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return DynamicLibrary.open(candidate);
      }
    }
    return DynamicLibrary.open('sqlite3.dll');
  });
}
