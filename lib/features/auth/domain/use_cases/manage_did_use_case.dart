import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/did_entities.dart';
import '../repositories/did_repository.dart';

/// DID 관리 Use Case
class ManageDidUseCase {
  final DidRepository _didRepository;

  ManageDidUseCase(this._didRepository);

  /// DID 생성 및 등록 플로우 실행
  Future<Either<Failure, DidCreationResult>> createAndRegisterDid({
    required int userId,
  }) async {
    // 1. DID 생성
    final createResult = await _didRepository.createDid();
    if (createResult.isLeft()) {
      return createResult;
    }

    final didResult = createResult.getOrElse(() => throw Exception('Unexpected error'));

    // 2. 서버 등록
    final registerResult = await _didRepository.registerDid(
      userId: userId,
      didResult: didResult,
    );

    if (registerResult.isLeft()) {
      // 등록 실패 시 로컬 DID 삭제
      await _didRepository.deleteDid();
      return Left(registerResult.fold((l) => l, (r) => throw Exception('Unexpected error')));
    }

    return Right(didResult);
  }

  /// DID 생성 진행상태 스트림
  Stream<DidCreationProgress> getCreationProgressStream() {
    return _didRepository.getCreationProgressStream();
  }

  /// DID 삭제
  Future<Either<Failure, void>> deleteDid() {
    return _didRepository.deleteDid();
  }
}