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
    return DidCreationResult(
      did: response['did'] ?? '',
      keyId: response['keyId'] ?? '',
      publicKey: response['publicKey'] ?? '',
      keyAttestation: KeyAttestation.fromJson(response['keyAttestation'] ?? {}),
      didDocument: response['didDocument'] ?? {},
      success: response['success'] ?? false,
      error: response['error'],
    );
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
      keyId: json['keyId'] ?? '',
      algorithm: json['algorithm'] ?? '',
      storage: json['storage'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
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