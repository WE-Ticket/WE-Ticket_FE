import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/did_entities.dart';

/// DID 관리를 위한 Repository 인터페이스
abstract class DidRepository {
  /// DID 생성
  Future<Either<Failure, DidCreationResult>> createDid();
  
  /// DID 서버 등록
  Future<Either<Failure, void>> registerDid({
    required int userId,
    required DidCreationResult didResult,
  });
  
  /// DID Document 삭제
  Future<Either<Failure, void>> deleteDid();
  
  /// DID 생성 진행상태 스트림
  Stream<DidCreationProgress> getCreationProgressStream();
}