/// Turns Supabase error codes into text a customer can act on.
///
/// Pure and side-effect free so it can be unit tested without an SDK or a
/// network connection — the widgets never show a raw server message.
class AuthErrorMapper {
  const AuthErrorMapper._();

  static String describe({
    String? code,
    String? message,
    String? pgCode,
    int? statusCode,
  }) {
    // Postgrest / Postgres constraint violations.
    switch (pgCode) {
      case '42501':
        return 'You do not have permission to do that.';
      case '23505':
        return 'That record already exists.';
      case '23514':
        return 'Some of those details did not pass validation.';
      case '23503':
        return 'That record refers to something that no longer exists.';
    }

    // GoTrue (auth) error codes.
    switch (code) {
      case 'invalid_credentials':
        return 'Email or password is incorrect.';
      case 'email_not_confirmed':
        return 'Confirm your email address before signing in.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists. Try signing in instead.';
      case 'weak_password':
        return 'Choose a stronger password: 8+ characters with a letter and a number.';
      case 'same_password':
        return 'Choose a password you have not used before.';
      case 'signup_disabled':
        return 'New sign-ups are closed right now. Please contact support.';
      case 'email_address_invalid':
      case 'validation_failed':
        return 'Enter a valid email address.';
      case 'email_address_not_authorized':
        return 'We could not send email to that address. Check it and try again.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
      case 'over_sms_send_rate_limit':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'session_not_found':
      case 'refresh_token_not_found':
      case 'session_expired':
        return 'Your session expired. Please sign in again.';
      case 'provider_disabled':
        return 'That sign-in method is not enabled yet.';
    }

    // Transport problems surface with no useful code.
    final String lower = (message ?? '').toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('connection') ||
        statusCode == 0) {
      return 'Check your internet connection and try again.';
    }

    final String cleaned = (message ?? '').trim();
    if (cleaned.isNotEmpty && cleaned.length <= 140) {
      return cleaned;
    }
    return 'Something went wrong. Please try again.';
  }
}
