/// Field validation shared by the customer and business sign-up forms.
///
/// Kept as pure functions so they are trivial to unit test.
class Validators {
  const Validators._();

  /// Strips spaces, dashes and a leading +254 / 254 / 0 so the number can be
  /// stored in one canonical form.
  static String normaliseKenyanPhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('254')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Kenyan mobile numbers: 9 digits after +254, starting 7 or 1.
  static String? phone(String? value) {
    final String digits = normaliseKenyanPhone(value ?? '');
    if (digits.isEmpty) {
      return 'Enter your phone number';
    }
    if (!RegExp(r'^[71][0-9]{8}$').hasMatch(digits)) {
      return 'Use a valid Kenyan mobile number, e.g. 712 345 678';
    }
    return null;
  }

  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }

  static String? personName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Enter your full name';
    }
    if (text.length < 3) {
      return 'Enter your full name';
    }
    return null;
  }

  static String? businessName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Enter the business name';
    }
    if (text.length < 2) {
      return 'Enter the business name';
    }
    return null;
  }

  /// Email is optional for customers, mandatory for businesses.
  static String? email(String? value, {bool required = true}) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return required ? 'Enter your email address' : null;
    }
    final bool looksValid = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(text);
    if (!looksValid) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Minimum 8 characters with at least one letter and one number.
  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) {
      return 'Create a password';
    }
    if (text.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(text) || !RegExp(r'[0-9]').hasMatch(text)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }
}
