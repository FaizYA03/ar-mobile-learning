import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/ar_uco_service.dart';

void main() {
  test('scanner supports every ArUco dictionary accepted by the backend', () {
    expect(
      ArUcoService.supportedDictionaries.keys,
      containsAll(<String>[
        'DICT_4X4_50',
        'DICT_5X5_100',
        'DICT_6X6_250',
        'DICT_7X7_1000',
      ]),
    );
  });
}
