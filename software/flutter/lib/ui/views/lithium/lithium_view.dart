import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_bms/ui/views/lithium/lithium_viewmodel.dart';
import 'package:stacked/stacked.dart';

class LithiumView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LithiumViewModel>.reactive(
      viewModelBuilder: () => LithiumViewModel(),
      onViewModelReady: (model) {
        // Initialize the view model to fetch the latest data from Firebase
        model.initialize();
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Lithium Battery'),
            backgroundColor: Colors.blue,
          ),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBatteryInfo(viewModel),
                SizedBox(height: 16),
                _buildChartLegend(),
                SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: viewModel.isBusy
                          ? Center(child: CircularProgressIndicator())
                          : LineChart(viewModel.getChartData()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Reset Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.resetGraph();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the battery info display (SOC, SOH, SOP, Time Remaining)
  Widget _buildBatteryInfo(LithiumViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _InfoRow('SOC', '${viewModel.currentSoc.toStringAsFixed(1)}%'),
            _InfoRow('SOH', '${viewModel.currentSoh.toStringAsFixed(1)}%'),
            _InfoRow('SOP', '${viewModel.currentSop.toStringAsFixed(1)}%'),
            _InfoRow('Time Remaining',
                '${viewModel.timeRemaining.toStringAsFixed(1)} hrs'),
          ],
        ),
      ),
    );
  }

  // Chart legend to represent SOC, SOH, and SOP with corresponding colors
  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(color: Colors.green, label: 'SOC'),
        _LegendItem(color: Colors.blue, label: 'SOH'),
        _LegendItem(color: Colors.red, label: 'SOP'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
