import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/did_entities.dart';
import '../../domain/repositories/did_repository.dart';

/// DID Repository 구현체
class DidRepositoryImpl implements DidRepository {
  static const platform = MethodChannel('did_sdk');

  final DioClient _dioClient;
  final StreamController<DidCreationProgress> _progressController;

  DidRepositoryImpl(this._dioClient)
    : _progressController = StreamController<DidCreationProgress>.broadcast();

  @override
  Stream<DidCreationProgress> getCreationProgressStream() {
    return _progressController.stream;
  }

  @override
  Future<Either<Failure, DidCreationResult>> createDid() async {
    try {
      AppLogger.info('DID 생성 시작', 'DID');
      _progressController.add(DidCreationProgress.creating());

      final response = await platform.invokeMethod('createDid');
      final result = _safeMapConversion(response);

      AppLogger.debug('플랫폼 응답: $result', 'DID');
      AppLogger.debug('응답 키들: ${result.keys.toList()}', 'DID');
      AppLogger.debug('didDocument 값: ${result['didDocument']}', 'DID');

      if (result['success'] == true) {
        AppLogger.success('DID 생성 성공', 'DID');
        final didResult = DidCreationResult.fromPlatformResponse(result);

        // DID document 검증
        if (didResult.didDocument.isEmpty) {
          AppLogger.error('DID document가 비어있습니다', null, null, 'DID');
          _progressController.add(
            DidCreationProgress.failed('DID document 생성 실패'),
          );
          return Left(TechnicalFailure(message: 'DID document가 생성되지 않았습니다'));
        }

        return Right(didResult);
      } else {
        final error = result['error'] ?? 'DID 생성 실패';
        AppLogger.error('DID 생성 실패: $error', null, null, 'DID');
        _progressController.add(DidCreationProgress.failed(error));
        return Left(TechnicalFailure(message: error));
      }
    } on PlatformException catch (e) {
      final error = '플랫폼 오류: ${e.message}';
      AppLogger.error(error, e, null, 'DID');
      _progressController.add(DidCreationProgress.failed(error));
      return Left(TechnicalFailure(message: error));
    } catch (e) {
      final error = 'DID 생성 중 예상치 못한 오류: $e';
      AppLogger.error(error, e, null, 'DID');
      _progressController.add(DidCreationProgress.failed(error));
      return Left(TechnicalFailure(message: error));
    }
  }

  @override
  Future<Either<Failure, void>> registerDid({
    required int userId,
    required DidCreationResult didResult,
  }) async {
    try {
      AppLogger.info('DID 서버 등록 시작', 'DID');
      _progressController.add(DidCreationProgress.registering());

      final request = DidRegistrationRequest(
        userId: userId,
        keyAttestation: didResult.keyAttestation,
        ownerDidDoc: didResult.didDocument,
      );

      final response = await _dioClient.post(
        '/users/did/register/',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.success('DID 서버 등록 성공', 'DID');
        _progressController.add(DidCreationProgress.completed());
        return const Right(null);
      } else {
        final error = 'DID 등록 실패: ${response.statusCode}';
        AppLogger.error(error, null, null, 'DID');
        _progressController.add(DidCreationProgress.failed(error));
        await deleteDid(); // 실패 시 로컬 DID 삭제
        return Left(NetworkFailure(message: error));
      }
    } catch (e) {
      final error = 'DID 등록 중 오류 발생: $e';
      AppLogger.error(error, e, null, 'DID');
      _progressController.add(DidCreationProgress.failed(error));
      await deleteDid(); // 실패 시 로컬 DID 삭제
      return Left(NetworkFailure(message: error));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDid() async {
    try {
      AppLogger.info('DID 삭제 시작', 'DID');

      final response = await platform.invokeMethod('delDidDoc');
      final result = _safeMapConversion(response);

      if (result['success'] == true) {
        AppLogger.success('DID 삭제 성공', 'DID');
        return const Right(null);
      } else {
        final error = result['error'] ?? 'DID 삭제 실패';
        AppLogger.error('DID 삭제 실패: $error', null, null, 'DID');
        return Left(TechnicalFailure(message: error));
      }
    } on PlatformException catch (e) {
      final error = '플랫폼 오류: ${e.message}';
      AppLogger.error(error, e, null, 'DID');
      return Left(TechnicalFailure(message: error));
    } catch (e) {
      final error = 'DID 삭제 중 예상치 못한 오류: $e';
      AppLogger.error(error, e, null, 'DID');
      return Left(TechnicalFailure(message: error));
    }
  }

  /// 안전한 Map 변환 헬퍼 함수
  Map<String, dynamic> _safeMapConversion(dynamic input) {
    if (input == null) return <String, dynamic>{};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return Map<String, dynamic>.from(
        input.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return <String, dynamic>{};
  }

  void dispose() {
    _progressController.close();
  }
}
