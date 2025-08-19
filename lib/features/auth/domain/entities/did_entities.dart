import 'dart:convert';

/// DID 관련 도메인 엔티티들
class DidCreationResult {
  final String did;
  final String keyId;
  final String publicKey;
  final KeyAttestation keyAttestation;
  final Map<String, dynamic> didDocument;
  final bool success;
  final String? error;

  const DidCreationResult({
    required this.did,
    required this.keyId,
    required this.publicKey,
    required this.keyAttestation,
    required this.didDocument,
    required this.success,
    this.error,
  });

  factory DidCreationResult.fromPlatformResponse(Map<String, dynamic> response) {
    try {
      // 여러 가능한 DID document 키 이름들 확인
      Map<String, dynamic> didDoc = _safeMapConversion(response['didDocument']);
      if (didDoc.isEmpty) {
        didDoc = _safeMapConversion(response['did_document']);
      }
      if (didDoc.isEmpty) {
        didDoc = _safeMapConversion(response['ownerDidDoc']);
      }
      if (didDoc.isEmpty) {
        didDoc = _safeMapConversion(response['owner_did_doc']);
      }
      
      return DidCreationResult(
        did: _safeStringConversion(response['did']),
        keyId: _safeStringConversion(response['keyId']),
        publicKey: _safeStringConversion(response['publicKey']),
        keyAttestation: KeyAttestation.fromJson(_safeMapConversion(response['keyAttestation'])),
        didDocument: didDoc,
        success: response['success'] ?? false,
        error: _safeStringConversion(response['error']),
      );
    } catch (e) {
      // 디버깅을 위한 상세 로그
      print('❌ DidCreationResult 파싱 오류: $e');
      print('📋 Response keys: ${response.keys.toList()}');
      print('📋 Response types: ${response.map((k, v) => MapEntry(k, v.runtimeType))}');
      print('📋 didDocument candidates:');
      print('   - didDocument: ${response['didDocument']}');
      print('   - did_document: ${response['did_document']}');
      print('   - ownerDidDoc: ${response['ownerDidDoc']}');
      print('   - owner_did_doc: ${response['owner_did_doc']}');
      
      return DidCreationResult.failure('DID 응답 파싱 오류: $e');
    }
  }

  /// 안전한 String 변환 헬퍼 함수
  static String _safeStringConversion(dynamic input) {
    if (input == null) return '';
    return input.toString();
  }

  /// 안전한 Map 변환 헬퍼 함수
  static Map<String, dynamic> _safeMapConversion(dynamic input) {
    if (input == null) return <String, dynamic>{};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return Map<String, dynamic>.from(
        input.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    if (input is String && input.isNotEmpty) {
      try {
        // JSON 문자열을 Map으로 파싱 시도
        final decoded = jsonDecode(input);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (e) {
        print('❌ JSON 파싱 실패: $e');
        print('📋 입력 문자열: ${input.length > 200 ? input.substring(0, 200) + "..." : input}');
      }
    }
    return <String, dynamic>{};
  }

  factory DidCreationResult.failure(String error) {
    return DidCreationResult(
      did: '',
      keyId: '',
      publicKey: '',
      keyAttestation: const KeyAttestation.empty(),
      didDocument: {},
      success: false,
      error: error,
    );
  }

  bool get isSuccess => success && error == null;
  
  String get displayPublicKey => publicKey.length > 32 
      ? '${publicKey.substring(0, 32)}...' 
      : publicKey;
}

class KeyAttestation {
  final String keyId;
  final String algorithm;
  final String storage;
  final String createdAt;

  const KeyAttestation({
    required this.keyId,
    required this.algorithm,
    required this.storage,
    required this.createdAt,
  });

  const KeyAttestation.empty()
      : keyId = '',
        algorithm = '',
        storage = '',
        createdAt = '';

  factory KeyAttestation.fromJson(Map<String, dynamic> json) {
    return KeyAttestation(
      keyId: _safeStringConversion(json['keyId']),
      algorithm: _safeStringConversion(json['algorithm']),
      storage: _safeStringConversion(json['storage']),
      createdAt: _safeStringConversion(json['createdAt']),
    );
  }

  /// 안전한 String 변환 헬퍼 함수
  static String _safeStringConversion(dynamic input) {
    if (input == null) return '';
    return input.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'algorithm': algorithm,
      'storage': storage,
      'createdAt': createdAt,
    };
  }
}

class DidRegistrationRequest {
  final int userId;
  final KeyAttestation keyAttestation;
  final Map<String, dynamic> ownerDidDoc;

  const DidRegistrationRequest({
    required this.userId,
    required this.keyAttestation,
    required this.ownerDidDoc,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'key_attestation': keyAttestation.toJson(),
      'owner_did_doc': ownerDidDoc,
    };
  }
}

/// DID 생성 진행 상태
enum DidCreationStatus {
  idle,
  creating,
  registering,
  completed,
  failed,
}

class DidCreationProgress {
  final DidCreationStatus status;
  final String message;
  final double progress;
  final String? error;

  const DidCreationProgress({
    required this.status,
    required this.message,
    required this.progress,
    this.error,
  });

  factory DidCreationProgress.idle() {
    return const DidCreationProgress(
      status: DidCreationStatus.idle,
      message: '대기 중',
      progress: 0.0,
    );
  }

  factory DidCreationProgress.creating() {
    return const DidCreationProgress(
      status: DidCreationStatus.creating,
      message: '보안 인증서 생성 중...',
      progress: 0.3,
    );
  }

  factory DidCreationProgress.registering() {
    return const DidCreationProgress(
      status: DidCreationStatus.registering,
      message: '서버에 등록 중...',
      progress: 0.7,
    );
  }

  factory DidCreationProgress.completed() {
    return const DidCreationProgress(
      status: DidCreationStatus.completed,
      message: '완료',
      progress: 1.0,
    );
  }

  factory DidCreationProgress.failed(String error) {
    return DidCreationProgress(
      status: DidCreationStatus.failed,
      message: '실패',
      progress: 0.0,
      error: error,
    );
  }

  bool get isCompleted => status == DidCreationStatus.completed;
  bool get isFailed => status == DidCreationStatus.failed;
  bool get isInProgress => status == DidCreationStatus.creating || 
                          status == DidCreationStatus.registering;
}