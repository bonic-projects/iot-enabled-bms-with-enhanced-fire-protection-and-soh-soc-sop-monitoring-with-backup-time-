import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';

class HomeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  void navigateToLeadAcid() {
    _navigationService.navigateTo(Routes.leadacidView);
  }

  void navigateToLithium() {
    _navigationService.navigateTo(Routes.lithiumView);
  }

  void navigateToTemperature() {
    _navigationService.navigateTo(Routes.temperatureView);
  }
}
