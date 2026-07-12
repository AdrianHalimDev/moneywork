import 'package:moneywork/data/app_state.dart';
import 'package:moneywork/data/storage.dart';

/// Storage in-memory untuk menguji controller tanpa SharedPreferences/Firestore.
class InMemoryStorage implements StorageBackend {
  AppState _state;
  InMemoryStorage([this._state = const AppState()]);

  @override
  Future<AppState> load() async => _state;

  @override
  Future<void> save(AppState state) async => _state = state;

  @override
  Future<void> clear() async => _state = const AppState();
}
