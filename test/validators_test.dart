import 'package:flutter_test/flutter_test.dart';

import 'package:tenderatrack/core/utils/validators.dart';

void main() {
  group('Validators.money', () {
    test('rejects empty, malformed, non-positive, and non-finite values', () {
      for (final value in <String?>[
        null,
        '',
        '   ',
        'abc',
        '0',
        '-1',
        'NaN',
        'Infinity',
        '-Infinity',
        '1,2,3',
      ]) {
        expect(Validators.money(value), isNotNull, reason: 'value: $value');
      }
    });

    test('accepts formatted positive finite amounts', () {
      for (final value in ['1', '0.01', '1,000', ' 25.50 ']) {
        expect(Validators.money(value), isNull, reason: 'value: $value');
      }
    });
  });

  group('Validators.integer', () {
    test('rejects negative, decimal, and malformed quantities', () {
      for (final value in <String?>[null, '', '-1', '1.5', 'one']) {
        expect(Validators.integer(value), isNotNull, reason: 'value: $value');
      }
    });

    test('accepts zero, positive quantities, and surrounding spaces', () {
      for (final value in ['0', '12', ' 7 ']) {
        expect(Validators.integer(value), isNull, reason: 'value: $value');
      }
    });
  });

  test('parseMoney returns null for null and preserves finite values', () {
    expect(Validators.parseMoney(null), isNull);
    expect(Validators.parseMoney('1,234.50'), 1234.5);
    expect(Validators.parseMoney('Infinity'), isNull);
    expect(
        Validators.parseMoney(
            '999999999999999999999999999999999999999999999999999999999999999999999999999999'),
        isNull);
  });

  group('text validators', () {
    test('username requires the account username format', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('ana santos'), isNotNull);
      expect(Validators.username('tindera_ana'), isNull);
    });

    test('login username accepts existing profile values', () {
      expect(Validators.loginUsername('Ana Santos'), isNull);
      expect(Validators.loginUsername(''), isNotNull);
    });

    test('login identifier accepts either email or username', () {
      expect(Validators.loginIdentifier('ate@example.com'), isNull);
      expect(Validators.loginIdentifier('tindera_ana'), isNull);
      expect(Validators.loginIdentifier('not an identifier'), isNotNull);
      expect(Validators.loginIdentifier(''), isNotNull);
    });

    test('legacy identifier and password enforce minimum lengths', () {
      expect(Validators.phoneOrUsername('abc'), isNotNull);
      expect(Validators.phoneOrUsername('user'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('strong password requires letters, numbers, and symbols', () {
      for (final value in ['short', 'password', 'password1', '12345678', '']) {
        expect(Validators.strongPassword(value), isNotNull,
            reason: 'value: $value');
      }
      expect(Validators.strongPassword('Pass123!'), isNull);
    });

    test('email accepts a normal address and rejects malformed input', () {
      expect(Validators.email('ate@example.com'), isNull);
      for (final value in <String?>[
        null,
        '',
        'ate@',
        '@example.com',
        'ate example.com'
      ]) {
        expect(Validators.email(value), isNotNull, reason: 'value: $value');
      }
    });
  });
}
