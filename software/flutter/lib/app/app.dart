import 'package:smart_bms/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:smart_bms/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:smart_bms/ui/views/home/home_view.dart';
import 'package:smart_bms/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_bms/services/firebase_service.dart';
import 'package:smart_bms/ui/views/lithium/lithium_view.dart';
import 'package:smart_bms/ui/views/leadacid/leadacid_view.dart';
import 'package:smart_bms/ui/views/temperature/temperature_view.dart';
import 'package:smart_bms/services/temperature_service.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LithiumView),
    MaterialRoute(page: LeadacidView),
    MaterialRoute(page: TemperatureView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: FirebaseService),
    LazySingleton(classType: TemperatureService),
// @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
