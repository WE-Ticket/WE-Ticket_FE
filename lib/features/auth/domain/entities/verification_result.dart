import 'package:equatable/equatable.dart';

import 'user.dart';

/// Domain entity representing identity verification result
class VerificationResult extends Equatable {
  final String? did;
  final VerificationProvider provider;
  final String name;
  final String phone;
  final String birthday;
  final Gender sex;

  const VerificationResult({
    this.did,
    required this.provider,
    required this.name,
    required this.phone,
    required this.birthday,
    required this.sex,
  });

  /// Get formatted phone number (010-1234-5678)
  String get formattedPhone {
    if (phone.startsWith('010') && phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  /// Get formatted birthday (YYYY-MM-DD)
  String get formattedBirthday {
    if (birthday.length == 8) {
      return '${birthday.substring(0, 4)}-${birthday.substring(4, 6)}-${birthday.substring(6, 8)}';
    }
    return birthday;
  }

  @override
  List<Object?> get props => [did, provider, name, phone, birthday, sex];

  @override
  String toString() => 'VerificationResult(name: $name, phone: $formattedPhone, provider: $provider)';
}

/// Enum representing verification providers
enum VerificationProvider {
  pass('PASS', 'PASS'),
  nice('NICE', 'NICE'),
  other('OTHER', '기타');

  const VerificationProvider(this.value, this.displayName);

  final String value;
  final String displayName;

  static VerificationProvider fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PASS':
        return VerificationProvider.pass;
      case 'NICE':
        return VerificationProvider.nice;
      default:
        return VerificationProvider.other;
    }
  }
}

/// Enum representing gender
enum Gender {
  male('M', '남성'),
  female('F', '여성');

  const Gender(this.value, this.displayName);

  final String value;
  final String displayName;

  static Gender fromString(String value) {
    switch (value.toUpperCase()) {
      case 'M':
        return Gender.male;
      case 'F':
        return Gender.female;
      default:
        return Gender.male;
    }
  }
}

/// Domain entity representing identity verification request
class IdentityVerificationRequest extends Equatable {
  final int userId;
  final UserAuthLevel nextVerificationLevel;
  final bool isSuccess;
  final VerificationResult? verificationResult;

  const IdentityVerificationRequest({
    required this.userId,
    required this.nextVerificationLevel,
    required this.isSuccess,
    this.verificationResult,
  });

  @override
  List<Object?> get props => [userId, nextVerificationLevel, isSuccess, verificationResult];

  @override
  String toString() => 'IdentityVerificationRequest(userId: $userId, nextLevel: $nextVerificationLevel, success: $isSuccess)';
}