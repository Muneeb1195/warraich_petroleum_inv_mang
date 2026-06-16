import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:warraich_petroleum/app.dart';
import 'package:warraich_petroleum/database/app_database.dart';
import 'package:warraich_petroleum/providers/backup_provider.dart';
import 'package:warraich_petroleum/providers/database_provider.dart';
import 'package:warraich_petroleum/providers/product_provider.dart';
import 'package:warraich_petroleum/providers/shift_provider.dart';
import 'package:warraich_petroleum/services/backup_service.dart';

class _NoOpBackupNotifier extends BackupNotifier {
  _NoOpBackupNotifier(BackupService service, Ref ref) : super(service, ref);

  @override
  Future<void> initializeAutoBackup() async {}
}

void main() {
  testWidgets('App renders dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final db = AppDatabase(executor: NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          backupNotifierProvider.overrideWith((ref) {
            return _NoOpBackupNotifier(BackupService(), ref);
          }),
          activeShiftProvider.overrideWith((ref) => const Stream.empty()),
          allInventoryProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const WarraichPetroleumApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsNWidgets(2));

    await db.close();
  });
}
