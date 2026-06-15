import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final onboardingProvider = FutureProvider<bool>((ref) async {
  const storage = FlutterSecureStorage();
  final completed = await storage.read(key: 'onboarding_completed');
  return completed == 'true';
});

Future<void> completeOnboarding() async {
  const storage = FlutterSecureStorage();
  await storage.write(key: 'onboarding_completed', value: 'true');
}
