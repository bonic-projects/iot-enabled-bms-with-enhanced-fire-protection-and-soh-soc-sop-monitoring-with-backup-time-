class Temperature {
  final double value;

  Temperature({required this.value});

  factory Temperature.fromMap(Map<String, dynamic> map) {
    return Temperature(value: map['value']?.toDouble() ?? 0.0);
  }
  double get temperature => value;
}
