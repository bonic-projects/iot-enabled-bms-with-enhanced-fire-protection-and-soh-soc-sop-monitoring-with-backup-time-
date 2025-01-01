import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_bms/ui/views/temperature/temperature_viewmodel.dart';
import 'package:stacked/stacked.dart';

class TemperatureView extends StatelessWidget {
  const TemperatureView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TemperatureViewModel>.reactive(
      viewModelBuilder: () => TemperatureViewModel(),
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Temperature Graph'),
          ),
          body: viewModel.isBusy
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LineChart(viewModel.getTemperatureChartData()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Temperature: ${viewModel.currentTemperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.resetTemperatureGraph,
                      child: const Text('Reset Graph'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
