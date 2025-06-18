class ValidationUtils {
  // Name field validation according to API requirements
  static String? validateEmployeeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee name is required';
    }
    if (value.trim().length > 255) {
      return 'Employee name cannot exceed 255 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'Employee name can only contain letters, spaces, and dots';
    }
    return null;
  }

  static String? validateContactPersonName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact person name is required';
    }
    if (value.trim().length > 255) {
      return 'Contact person name cannot exceed 255 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'Contact person name can only contain letters, spaces, and dots';
    }
    return null;
  }

  static String? validateFamilyMemberName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Family member name is required';
    }
    if (value.trim().length > 255) {
      return 'Family member name cannot exceed 255 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'Family member name can only contain letters, spaces, and dots';
    }
    return null;
  }

  static String? validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank name is required';
    }
    if (value.trim().length > 255) {
      return 'Bank name cannot exceed 255 characters';
    }
    // Allow bank names to contain letters, numbers, spaces, and common bank name characters
    if (!RegExp(r'^[a-zA-Z0-9\s\-&.()]+$').hasMatch(value.trim())) {
      return 'Invalid bank name format';
    }
    return null;
  }

  static String? validateCompanyName(String? value) {
    // This is nullable in API, so empty is allowed
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > 255) {
      return 'Company name cannot exceed 255 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-&.()]+$').hasMatch(value.trim())) {
      return 'Invalid company name format';
    }
    return null;
  }

  static String? validateDocumentName(String? value) {
    // This is nullable in API, so empty is allowed
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > 255) {
      return 'Document name cannot exceed 255 characters';
    }
    return null;
  }

  static String? validateEPFNomineeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'EPF nominee name is required';
    }
    if (value.trim().length > 255) {
      return 'EPF nominee name cannot exceed 255 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'EPF nominee name can only contain letters, spaces, and dots';
    }
    return null;
  }

  static String? validateEPSNomineeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'EPS nominee name is required';
    }
    if (value.trim().length > 255) {
      return 'EPS nominee name cannot exceed 255 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'EPS nominee name can only contain letters, spaces, and dots';
    }
    return null;
  }

  static String? validateWitnessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Witness name is required';
    }
    if (value.trim().length > 500) {
      return 'Witness name cannot exceed 500 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'Witness name can only contain letters, spaces, and dots';
    }
    return null;
  }

  static String? validateESIFamilyName(String? value) {
    // This is nullable in API, so empty is allowed
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > 100) {
      return 'ESI family member name cannot exceed 100 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'ESI family member name can only contain letters, spaces, and dots';
    }
    return null;
  }

  // Additional common validation methods
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMaxLength(
      String? value, int maxLength, String fieldName) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  static String? validateNameFormat(String? value, String fieldName) {
    if (value != null && value.trim().isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
        return '$fieldName can only contain letters, spaces, and dots';
      }
    }
    return null;
  }

  // Comprehensive name validation combining all rules
  static String? validateName({
    required String? value,
    required String fieldName,
    required bool isRequired,
    required int maxLength,
    bool allowNumbers = false,
    bool allowSpecialChars = false,
  }) {
    // Check if required
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '$fieldName is required';
    }

    // If empty and not required, it's valid
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Check length
    if (value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    // Check format based on allowed characters
    String pattern = r'^[a-zA-Z\s.';
    if (allowNumbers) pattern += r'0-9';
    if (allowSpecialChars) pattern += r'\-&()';
    pattern += r']+$';

    if (!RegExp(pattern).hasMatch(value.trim())) {
      String allowedChars = 'letters, spaces, and dots';
      if (allowNumbers) allowedChars += ', numbers';
      if (allowSpecialChars)
        allowedChars += ', hyphens, ampersands, and parentheses';
      return '$fieldName can only contain $allowedChars';
    }

    return null;
  }
}
