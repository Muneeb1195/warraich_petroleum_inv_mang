import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

final abbreviateAmountsProvider = StateNotifierProvider<AbbreviateNotifier, bool>((ref) {
  return AbbreviateNotifier();
});

class AbbreviateNotifier extends StateNotifier<bool> {
  static const _key = 'abbreviate_amounts';

  AbbreviateNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: _key);
    if (value == 'false') state = false;
  }

  Future<void> setAbbreviate(bool value) async {
    state = value;
    const storage = FlutterSecureStorage();
    await storage.write(key: _key, value: value.toString());
  }
}

String fm(WidgetRef ref, double value) {
  final abbreviate = ref.watch(abbreviateAmountsProvider);
  return formatMoney(value, abbreviate: abbreviate);
}
