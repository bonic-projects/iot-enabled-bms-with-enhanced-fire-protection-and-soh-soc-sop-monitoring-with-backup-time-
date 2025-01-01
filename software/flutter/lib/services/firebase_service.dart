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
}
