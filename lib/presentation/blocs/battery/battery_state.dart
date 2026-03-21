import 'package:equatable/equatable.dart';

/// States for battery monitoring cubit.
sealed class BatteryState extends Equatable {
  const BatteryState({required this.level});
  final int level;

  @override
  List<Object?> get props => [level];
}

/// Battery level unknown or not yet checked.
class BatteryUnknown extends BatteryState {
  const BatteryUnknown() : super(level: -1);
}

/// Battery level is normal (>15%).
class BatteryNormal extends BatteryState {
  const BatteryNormal({required super.level});
}

/// Battery level is low (≤15%).
class BatteryLow extends BatteryState {
  const BatteryLow({required super.level});
}

/// Battery level is critical (≤5%). Contacts should be alerted.
class BatteryCritical extends BatteryState {
  const BatteryCritical({required super.level});
}
