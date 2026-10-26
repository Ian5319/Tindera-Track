class Validators {
  // Keep amounts within a practical Firestore/UI range and avoid accepting
  // values that lose precision when converted to a Dart double.
  static const maxMoney = 1000000000000.0;

  static String? requiredField(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? username(String? value) {
    final required = requiredField(value, 'Username');
    if (required != null) return required;
    final normalized = value!.trim();
    if (normalized.length < 3 || normalized.length > 32) {
      return 'Username must be 3 to 32 characters.';
    }
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(normalized)) {
      return 'Use only letters, numbers, dots, underscores, or hyphens.';
    }
    return null;
  }

  static String? loginUsername(String? value) {
    final required = requiredField(value, 'Username');
    if (required != null) return required;
    final normalized = value!.trim();
    if (normalized.length < 3 || normalized.length > 100) {
      return 'Enter your username.';
    }
    return null;
  }

  static String? phoneOrUsername(String? value) {
    final required = requiredField(value, 'Username / phone');
    if (required != null) return required;
    if (value!.trim().length < 4) {
      return 'Enter a valid username or phone number.';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, 'Password');
    if (required != null) return required;
    if (value!.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? strongPassword(String? value) {
    final required = requiredField(value, 'Password');
    if (required != null) return required;
    final pass = value!;
    if (pass.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(pass) ||
        !RegExp(r'\d').hasMatch(pass) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) {
      return 'Use 8+ characters with letters, numbers, and symbols.';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, 'Email');
    if (required != null) return required;
    final normalized = value!.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
    if (!ok || normalized.length > 320) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? passwordResetIdentifier(String? value) {
    return email(value);
  }

  static String? money(String? value) {
    final required = requiredField(value, 'Amount');
    if (required != null) return required;
    final amount = parseMoney(value);
    if (amount == null || !amount.isFinite || amount <= 0) {
      return 'Enter an amount greater than 0.';
    }
    return null;
  }

  static double? parseMoney(String? value) {
    if (value == null) return null;
    final input = value.trim();
    final validFormat = RegExp(
      r'^\+?(?:(?:\d+)(?:\.\d+)?|(?:\d{1,3}(?:,\d{3})+)(?:\.\d+)?)$',
    );
    if (!validFormat.hasMatch(input)) return null;

    final parsed = double.tryParse(input.replaceAll(',', ''));
    return parsed != null && parsed.isFinite && parsed <= maxMoney
        ? parsed
        : null;
  }

  static String? integer(String? value, [String label = 'Quantity']) {
    final required = requiredField(value, label);
    if (required != null) return required;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 0 || parsed > 1000000000) {
      return '$label must be a whole number within the allowed range.';
    }
    return null;
  }
}
