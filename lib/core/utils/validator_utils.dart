class ValidatorUtils {
  static String? validateRequired(
      String? value,
      String fieldName,
      ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? validateAmount(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);

    if (amount == null || amount <= 0) {
      return 'Enter valid amount';
    }

    return null;
  }
}