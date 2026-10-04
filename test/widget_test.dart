import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/core/utils/phone_input.dart';

void main() {
  test('PhoneInput validates Algerian local numbers', () {
    expect(PhoneInput.isValid('0550 00 00 01'), isTrue);
    expect(PhoneInput.toIdentifier('550000001'), '0550000001');
    expect(PhoneInput.isValid('123'), isFalse);
  });
}
