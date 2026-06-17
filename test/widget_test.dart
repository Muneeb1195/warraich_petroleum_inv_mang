import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warraich_petroleum/app.dart';
import 'package:warraich_petroleum/database/app_database.dart';
import 'package:warraich_petroleum/providers/backup_provider.dart';
import 'package:warraich_petroleum/providers/database_provider.dart';
import 'package:warraich_petroleum/providers/firebase_auth_provider.dart';
import 'package:warraich_petroleum/providers/onboarding_provider.dart';
import 'package:warraich_petroleum/providers/product_provider.dart';
import 'package:warraich_petroleum/providers/shift_provider.dart';
import 'package:warraich_petroleum/services/auth_service.dart';
import 'package:warraich_petroleum/services/backup_service.dart';

class _NoAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoOpBackupNotifier extends BackupNotifier {
  _NoOpBackupNotifier(super.service, super.ref);

  @override
  Future<void> initializeAutoBackup() async {}
}

void main() {
  testWidgets('App shows sign-in screen when not authenticated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final db = AppDatabase(executor: NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          onboardingProvider.overrideWithValue(const AsyncValue.data(true)),
          authServiceProvider.overrideWithValue(_NoAuthService()),
          firebaseAuthUserProvider.overrideWithValue(const AsyncValue.data(null)),
          backupNotifierProvider.overrideWith((ref) {
            return _NoOpBackupNotifier(BackupService(_NoAuthService()), ref);
          }),
          activeShiftProvider.overrideWith((ref) => const Stream.empty()),
          allInventoryProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const WarraichPetroleumApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Sign in with Google'), findsOneWidget);

    await db.close();
  });
}
