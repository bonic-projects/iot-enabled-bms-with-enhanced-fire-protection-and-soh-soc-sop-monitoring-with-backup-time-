import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Battery Monitor'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () => viewModel.navigateToLeadAcid(),
                  child: Text('Lead Acid Battery'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => viewModel.navigateToLithium(),
                  child: Text('Lithium Battery'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    backgroundColor: Colors.greenAccent,
                  ),
                  onPressed: () => viewModel.navigateToTemperature(),
                  child: Text('Temperature'),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () => viewModel.toggleReset(),
                  child: Text('Toggle Reset'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
