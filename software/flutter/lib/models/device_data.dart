class BatteryData {
  final double soc;
  final double soh;
  final double sop;
  final double timeremaining;
  final DateTime timestamp;

  BatteryData({
    required this.soc,
    required this.soh,
    required this.sop,
    required this.timeremaining,
    required this.timestamp,
  });

  factory BatteryData.fromMap(Map<String, dynamic> map) {
    return BatteryData(
      soc: (map['soc'] ?? 0).toDouble(),
      soh: (map['soh'] ?? 0).toDouble(),
      sop: (map['sop'] ?? 0).toDouble(),
      timeremaining: (map['timeremaining'] ?? 0).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}
