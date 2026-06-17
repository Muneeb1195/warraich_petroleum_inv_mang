import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

final abbreviateAmountsProvider =
    StateNotifierProvider<AbbreviateNotifier, bool>((ref) {
      return AbbreviateNotifier();
    });

class AbbreviateNotifier extends StateNotifier<bool> {
  static const _key = 'abbreviate_amounts';
  bool _loaded = false;

  AbbreviateNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    try {
      const storage = FlutterSecureStorage();
      final value = await storage.read(key: _key);
      if (!_loaded) {
        _loaded = true;
        if (value == 'false') state = false;
      }
    } catch (_) {}
  }

  Future<void> setAbbreviate(bool value) async {
    _loaded = true;
    state = value;
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: _key, value: value.toString());
    } catch (_) {}
  }
}

String fm(WidgetRef ref, double value) {
  final abbreviate = ref.watch(abbreviateAmountsProvider);
  return formatMoney(value, abbreviate: abbreviate);
}
