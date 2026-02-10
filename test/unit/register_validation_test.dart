import 'package:flutter_test/flutter_test.dart';

bool isValidName(String name) => name.isNotEmpty;
bool isValidPhone(String phone) => phone.length >= 10;
bool isValidEducation(String edu) => edu.isNotEmpty;

void main() {
  test('First name required', () {
    expect(isValidName(''), false);
    expect(isValidName('John'), true);
  });

  test('Last name required', () {
    expect(isValidName(''), false);
    expect(isValidName('Doe'), true);
  });

  test('Phone number validation', () {
    expect(isValidPhone('123'), false);
    expect(isValidPhone('1234567890'), true);
  });

  test('Education required', () {
    expect(isValidEducation(''), false);
    expect(isValidEducation('BSc'), true);
  });

  test('Password validation', () {
    expect('123'.length >= 6, false);
    expect('123456'.length >= 6, true);
  });
}
