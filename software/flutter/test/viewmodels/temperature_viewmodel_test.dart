import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bms/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TemperatureViewModel Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
