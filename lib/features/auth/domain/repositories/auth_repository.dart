import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_credentials.dart';
import '../entities/user.dart';
import '../entities/verification_result.dart';

/// Repository interface for authentication operations
/// This defines the contract for auth data operations
abstract class AuthRepository {
  /// Login with credentials
  Future<Either<Failure, User>> login(AuthCredentials credentials);

  /// Sign up new user
  Future<Either<Failure, void>> signup(SignupData signupData);

  /// Logout current user
  Future<Either<Failure, void>> logout();

  /// Get current user information
  Future<Either<Failure, User?>> getCurrentUser();

  /// Check if user is currently logged in
  Future<Either<Failure, bool>> isLoggedIn();

  /// Refresh authentication tokens
  Future<Either<Failure, AuthTokens>> refreshTokens();

  /// Record identity verification result
  Future<Either<Failure, UserAuthLevel>> recordIdentityVerification(
    IdentityVerificationRequest request,
  );

  /// Check authentication status and restore session if valid
  Future<Either<Failure, User?>> checkAuthStatus();

  /// Clear all authentication data
  Future<Either<Failure, void>> clearAuthData();

  /// Load user authentication level
  Future<Either<Failure, Map<String, dynamic>>> loadUserAuthLevel(int userId);
}