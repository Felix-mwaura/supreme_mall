import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/utils/auth_errors.dart';

void main() {
  group('AuthErrorMapper maps auth codes to actionable text', () {
    test('wrong password does not reveal which half was wrong', () {
      expect(
        AuthErrorMapper.describe(code: 'invalid_credentials', message: 'Invalid login credentials'),
        'Email or password is incorrect.',
      );
    });

    test('existing account points the user to sign in', () {
      expect(
        AuthErrorMapper.describe(code: 'user_already_exists'),
        contains('already exists'),
      );
    });

    test('rate limiting tells the user to wait', () {
      expect(
        AuthErrorMapper.describe(code: 'over_email_send_rate_limit'),
        contains('Wait a few minutes'),
      );
    });

    test('weak password repeats the actual rule', () {
      expect(AuthErrorMapper.describe(code: 'weak_password'), contains('8+ characters'));
    });
  });

  group('AuthErrorMapper maps database errors', () {
    test('RLS rejection is a permission message, not a server dump', () {
      expect(
        AuthErrorMapper.describe(pgCode: '42501', message: 'new row violates row-level security policy'),
        'You do not have permission to do that.',
      );
    });

    test('unique violation is explained plainly', () {
      expect(
        AuthErrorMapper.describe(pgCode: '23505', message: 'duplicate key value'),
        'That record already exists.',
      );
    });
  });

  group('fallbacks', () {
    test('offline surfaces as a connection message', () {
      expect(
        AuthErrorMapper.describe(message: 'SocketException: Failed host lookup'),
        contains('internet connection'),
      );
    });

    test('unknown long messages are never shown raw', () {
      final String described = AuthErrorMapper.describe(
        message: 'x' * 400,
      );
      expect(described, 'Something went wrong. Please try again.');
    });

    test('empty input still returns something usable', () {
      expect(AuthErrorMapper.describe(), 'Something went wrong. Please try again.');
    });
  });
}
