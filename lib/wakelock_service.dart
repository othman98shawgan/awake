import 'package:wakelock_plus/wakelock_plus.dart';

/// Lightweight abstraction over [WakelockPlus] for clean lifecycle management
/// and deterministic widget testing.
abstract interface class WakelockService {
  Future<void> enable();
  Future<void> disable();
  Future<bool> isEnabled();
}

/// Default implementation backed by the `wakelock_plus` plugin.
class WakelockPlusService implements WakelockService {
  const WakelockPlusService();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();

  @override
  Future<bool> isEnabled() => WakelockPlus.enabled;
}
