import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../services/firebase_service.dart';

class LithiumViewModel extends BaseViewModel {
  final _firebaseService = locator<FirebaseService>();
  static const String BATTERY_TYPE = 'lithium';
  static const int MAX_POINTS = 500;

  List<FlSpot> spots = []; // For SOC
  List<FlSpot> sohSpots = []; // For SOH
  List<FlSpot> sopSpots = []; // For SOP

  int xValue = 0; // Time (x-axis)
  double currentSoc = 0;
  double currentSoh = 0;
  double currentSop = 0;
  double timeRemaining = 0;
  late SharedPreferences _prefs;

  double previousSoc = -1; // Variable to track previous SOC value
  double previousSoh = -1; // Variable to track previous SOH value
  double previousSop = -1; // Variable to track previous SOP value

  StreamSubscription? _batteryDataSubscription;

  Future<void> initialize() async {
    setBusy(true);
    await _initSharedPreferences();
    await _loadStoredData(); // Load stored data from SharedPreferences
    await _subscribeToData(); // Start listening to Firebase
    setBusy(false);
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _storeData() async {
    final List<Map<String, double>> socDataToStore = spots
        .map((spot) => {
      'x': spot.x,
      'y': spot.y,
    })
        .toList();

    final List<Map<String, double>> sohDataToStore = sohSpots
        .map((spot) => {
      'x': spot.x,
      'y': spot.y,
    })
        .toList();

    final List<Map<String, double>> sopDataToStore = sopSpots
        .map((spot) => {
      'x': spot.x,
      'y': spot.y,
    })
        .toList();

    await _prefs.setString('${BATTERY_TYPE}_soc_data', json.encode(socDataToStore));
    await _prefs.setString('${BATTERY_TYPE}_soh_data', json.encode(sohDataToStore));
    await _prefs.setString('${BATTERY_TYPE}_sop_data', json.encode(sopDataToStore));
  }

  Future<void> _loadStoredData() async {
    final storedSocData = _prefs.getString('${BATTERY_TYPE}_soc_data');
    final storedSohData = _prefs.getString('${BATTERY_TYPE}_soh_data');
    final storedSopData = _prefs.getString('${BATTERY_TYPE}_sop_data');

    if (storedSocData != null) {
      final List<dynamic> decodedSocData = json.decode(storedSocData);
      spots = decodedSocData
          .map((point) => FlSpot(
        double.parse(point['x'].toString()),
        double.parse(point['y'].toString()),
      ))
          .toList();
      xValue = spots.isNotEmpty ? (spots.last.x.toInt() + 1) : 0;

      if (spots.isNotEmpty) {
        previousSoc = spots.last.y;
      }
    }

    if (storedSohData != null) {
      final List<dynamic> decodedSohData = json.decode(storedSohData);
      sohSpots = decodedSohData
          .map((point) => FlSpot(
        double.parse(point['x'].toString()),
        double.parse(point['y'].toString()),
      ))
          .toList();

      if (sohSpots.isNotEmpty) {
        previousSoh = sohSpots.last.y;
      }
    }

    if (storedSopData != null) {
      final List<dynamic> decodedSopData = json.decode(storedSopData);
      sopSpots = decodedSopData
          .map((point) => FlSpot(
        double.parse(point['x'].toString()),
        double.parse(point['y'].toString()),
      ))
          .toList();

      if (sopSpots.isNotEmpty) {
        previousSop = sopSpots.last.y;
      }
    }

    if (spots.isNotEmpty) {
      currentSoc = spots.last.y;
    }
    if (sohSpots.isNotEmpty) {
      currentSoh = sohSpots.last.y;
    }
    if (sopSpots.isNotEmpty) {
      currentSop = sopSpots.last.y;
    }
  }

  Future<void> _subscribeToData() async {
    _batteryDataSubscription =
        _firebaseService.getBatteryDataStream(BATTERY_TYPE).listen((data) {
          if (data.soc == previousSoc &&
              data.soh == previousSoh &&
              data.sop == previousSop) {
            return;
          }

          if (spots.length > MAX_POINTS) spots.removeAt(0);
          if (sohSpots.length > MAX_POINTS) sohSpots.removeAt(0);
          if (sopSpots.length > MAX_POINTS) sopSpots.removeAt(0);

          spots.add(FlSpot(xValue.toDouble(), data.soc));
          sohSpots.add(FlSpot(xValue.toDouble(), data.soh));
          sopSpots.add(FlSpot(xValue.toDouble(), data.sop));

          previousSoc = data.soc;
          previousSoh = data.soh;
          previousSop = data.sop;

          xValue++;
          currentSoc = data.soc;
          currentSoh = data.soh;
          currentSop = data.sop;
          timeRemaining = data.timeremaining;

          _storeData();
          notifyListeners();
        });
  }
  @override
  void dispose() {
    _batteryDataSubscription?.cancel();
    super.dispose();
  }

  LineChartData getChartData() {
    return LineChartData(
      backgroundColor: Colors.white,
      lineBarsData: [
        LineChartBarData(
          spots: spots.isNotEmpty ? spots : [FlSpot(0, 0)],
          color: Colors.green,
          isCurved: true,
          dotData: const FlDotData(show: false),
          barWidth: 2,
        ),
        LineChartBarData(
          spots: sohSpots.isNotEmpty ? sohSpots : [FlSpot(0, 0)],
          color: Colors.blue,
          isCurved: true,
          dotData: const FlDotData(show: false),
          barWidth: 2,
        ),
        LineChartBarData(
          spots: sopSpots.isNotEmpty ? sopSpots : [FlSpot(0, 0)],
          color: Colors.red,
          isCurved: true,
          dotData: const FlDotData(show: false),
          barWidth: 2,
        ),
      ],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.black12, strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.black12, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          axisNameWidget: const Text('Time (s)'),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 12),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text('Value (%)'),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black26),
          bottom: BorderSide(color: Colors.black26),
        ),
      ),
      minY: 0,
      maxY: 100,
      minX: 0,
      maxX: spots.isNotEmpty ? spots.last.x + 5 : 5,
    );
  }

  void resetGraph() {
    spots = [FlSpot(0, 0)];
    sohSpots = [FlSpot(0, 0)];
    sopSpots = [FlSpot(0, 0)];
    xValue = 0;
    _storeData();
    notifyListeners();
  }

}

