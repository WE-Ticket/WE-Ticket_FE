/// Extension methods for String to provide convenient utility functions
extension StringExtensions on String {
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;
  
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
  
  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.capitalize)
        .join(' ');
  }
  
  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');
  
  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
  
  /// Check if string is a valid Korean phone number
  bool get isValidKoreanPhone {
    return RegExp(r'^01[016789]-?\d{3,4}-?\d{4}$').hasMatch(this);
  }
  
  /// Format Korean phone number (add hyphens)
  String get formatKoreanPhone {
    final digitsOnly = replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 11) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    } else if (digitsOnly.length == 10) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }
    return this;
  }
  
  /// Check if string contains only digits
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);
  
  /// Check if string is a valid Korean name (한글만)
  bool get isValidKoreanName {
    return RegExp(r'^[가-힣]{2,5}$').hasMatch(this);
  }
  
  /// Mask string (show first and last characters, hide middle)
  String mask({String maskChar = '*'}) {
    if (length <= 2) return this;
    final first = substring(0, 1);
    final last = substring(length - 1);
    final middle = maskChar * (length - 2);
    return '$first$middle$last';
  }
  
  /// Mask email (hide middle part)
  String get maskEmail {
    if (!isValidEmail) return this;
    final parts = split('@');
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) return this;
    
    final maskedUsername = '${username.substring(0, 2)}${'*' * (username.length - 2)}';
    return '$maskedUsername@$domain';
  }
  
  /// Mask phone number (hide middle digits)
  String get maskPhone {
    final formatted = formatKoreanPhone;
    if (formatted.length < 10) return this;
    
    final parts = formatted.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${'*' * parts[1].length}-${parts[2]}';
    }
    return this;
  }
  
  /// Convert to int safely
  int? get toIntOrNull => int.tryParse(this);
  
  /// Convert to double safely
  double? get toDoubleOrNull => double.tryParse(this);
  
  /// Check if string is a valid URL
  bool get isValidUrl {
    return Uri.tryParse(this)?.hasAbsolutePath ?? false;
  }
  
  /// Truncate string to specified length
  String truncate(int length, {String suffix = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length)}$suffix';
  }
  
  /// Format as Korean currency
  String get formatAsKoreanCurrency {
    final number = toIntOrNull;
    if (number == null) return this;
    
    return '${number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }
  
  /// Check if string is a valid login ID (alphanumeric and underscore)
  bool get isValidLoginId {
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(this);
  }
  
  /// Check if string is a valid password (8+ chars, letters and numbers)
  bool get isValidPassword {
    if (length < 8) return false;
    
    // Check for at least one letter (uppercase or lowercase)
    if (!RegExp(r'[a-zA-Z]').hasMatch(this)) return false;
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(this)) return false;
    
    // Only allow letters and digits
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this)) return false;
    
    return true;
  }
}