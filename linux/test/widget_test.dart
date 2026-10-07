import 'package:flutter_test/flutter_test.dart';
import 'package:super_market/util/app_translation.dart';

void main() {
  test('AppTranslation fallback keys contain app_title', () {
    final translation = AppTranslation();
    expect(translation.keys.containsKey('en_US'), true);
    expect(translation.keys['en_US']?['app_title'], 'RH Supermarket');
  });
}
