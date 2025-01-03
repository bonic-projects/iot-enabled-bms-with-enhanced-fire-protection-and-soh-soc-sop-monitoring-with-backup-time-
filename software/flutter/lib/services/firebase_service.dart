import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import '../models/device_data.dart';

class FirebaseService {
  final _database = FirebaseDatabase.instance.ref();

  Stream<BatteryData> getBatteryDataStream(String batteryType) {
    return _database
        .child('batterydata')
        .child(batteryType)
        .onValue
        .map((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return BatteryData.fromMap(data);
    });
  }
  Future<void> toggleResetField() async {
    try {
      final resetRef = _database.child('batterydata/toggle');
      final snapshot = await resetRef.get();

      if (snapshot.exists) {
        final currentValue = snapshot.value as bool;
        await resetRef.set(!currentValue);
      } else {
        // If the field doesn't exist, initialize it as `true`
        await resetRef.set(true);
      }
    } catch (e) {
      throw Exception('Failed to toggle reset field: $e');
    }
  }
}
