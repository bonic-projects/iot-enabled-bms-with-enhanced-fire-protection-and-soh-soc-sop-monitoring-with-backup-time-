import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../services/temperature_service.dart';

class TemperatureViewModel extends BaseViewModel {
  final _temperatureService = locator<TemperatureService>();
  static const String TEMPERATURE_DATA_KEY = 'stored_temperature_data';
  static const int MAX_POINTS = 500;

  List<FlSpot> tempSpots = [];
  double tempXValue = 0;
  double currentTemperature = 0;
  double previousTemperature = -1; // Store the previous temperature
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    setBusy(true);
    await _initSharedPreferences();
    await _loadStoredTemperatureData();
    _subscribeToTemperatureData(); // Listen to stream now
    setBusy(false);
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadStoredTemperatureData() async {
    final storedTempData = _prefs.getString(TEMPERATURE_DATA_KEY);
    if (storedTempData != null) {
      final List<dynamic> decodedTempData = json.decode(storedTempData);
      tempSpots = decodedTempData
          .map((point) => FlSpot(
        double.parse(point['x'].toString()),
        double.parse(point['y'].toString()),
      ))
          .toList();
      tempXValue = tempSpots.isNotEmpty ? tempSpots.last.x.toInt() + 1 : 0;
      currentTemperature = tempSpots.isNotEmpty ? tempSpots.last.y : 0; // Set current temp from stored data
      previousTemperature = currentTemperature; // Set the previous temperature from stored data
    }
  }

  void _subscribeToTemperatureData() {
    _temperatureService.getTemperatureStream().listen((temperatureData) {
      final temperature = temperatureData.value;

      print('Received temperature: $temperature'); // Debugging print

      // Check if the temperature value has changed
      if (temperature != previousTemperature) {
        if (tempSpots.length > MAX_POINTS) {
          tempSpots.removeAt(0); // Remove the oldest data point if exceeding MAX_POINTS
        }

        // Add the new data point to the graph
        tempSpots.add(FlSpot(tempXValue.toDouble(), temperature));
        tempXValue++;
        currentTemperature = temperature;  // Update the current temperature
        previousTemperature = temperature; // Update the previous temperature

        // Store updated temperature data in SharedPreferences
        _storeTemperatureData();

        // Push the new temperature to Firebase
        _temperatureService.updateTemperature(temperature);

        // Notify listeners to update the UI
        notifyListeners();
      }
    });
  }

  Future<void> _storeTemperatureData() async {
    final List<Map<String, double>> tempDataToStore = tempSpots
        .map((spot) => {
      'x': spot.x,
      'y': spot.y,
    })
        .toList();

    await _prefs.setString(TEMPERATURE_DATA_KEY, json.encode(tempDataToStore));
  }

  void resetTemperatureGraph() {
    tempSpots.clear();
    tempXValue = 0;
    previousTemperature = -1; // Reset the previous temperature when resetting the graph
    _storeTemperatureData();
    notifyListeners();
  }

  LineChartData getTemperatureChartData() {
    if (tempSpots.isEmpty) {
      tempSpots = [const FlSpot(0, 0)];
    }

    return LineChartData(
      backgroundColor: Colors.white,
      lineBarsData: [
        LineChartBarData(
          spots: tempSpots,
          color: Colors.orange,
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
          axisNameWidget: const Text('Temperature (°C)'),
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
      maxX: tempSpots.isNotEmpty ? tempSpots.last.x + 5 : 5,
    );
  }
}
