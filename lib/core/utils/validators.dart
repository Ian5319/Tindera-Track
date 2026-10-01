class Validators {
  static String? requiredField(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? phoneOrUsername(String? value) {
    final required = requiredField(value, 'Username / phone');
    if (required != null) return required;
    if (value!.trim().length < 4) return 'Enter a valid username or phone number.';
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, 'Password / PIN');
    if (required != null) return required;
    if (value!.trim().length < 4) return 'Use at least 4 characters.';
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
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return ok ? null : 'Enter a valid email address.';
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
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static String? integer(String? value, [String label = 'Quantity']) {
    final required = requiredField(value, label);
    if (required != null) return required;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < 0) return '$label must be a whole number.';
    return null;
  }
}
