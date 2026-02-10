import 'package:flutter_test/flutter_test.dart';

bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

void main() {
  test('Empty email is invalid', () {
    expect(isValidEmail(''), false);
  });

  test('Invalid email format is invalid', () {
    expect(isValidEmail('invalidemail'), false);
    expect(isValidEmail('test@com'), false);
  });

  test('Valid email format is valid', () {
    expect(isValidEmail('test@example.com'), true);
  });

  test('Password too short is invalid', () {
    expect(isValidPassword('123'), false);
  });

  test('Password 6+ chars is valid', () {
    expect(isValidPassword('123456'), true);
  });
}
