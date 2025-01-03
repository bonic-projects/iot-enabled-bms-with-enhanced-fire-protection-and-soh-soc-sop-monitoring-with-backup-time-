import 'package:smart_bms/services/firebase_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';

class HomeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _firebaseService=locator<FirebaseService>();

  void navigateToLeadAcid() {
    _navigationService.navigateTo(Routes.leadacidView);
  }

  void navigateToLithium() {
    _navigationService.navigateTo(Routes.lithiumView);
  }

  void navigateToTemperature() {
    _navigationService.navigateTo(Routes.temperatureView);
  }
  void toggleReset() async {
    setBusy(true);
    try {
      await _firebaseService.toggleResetField();
    } catch (e) {
      // Handle errors if needed
      print('Error toggling reset field: $e');
    } finally {
      setBusy(false);
    }
  }
}
