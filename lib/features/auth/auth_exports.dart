/// 클린 아키텍처로 리팩토링된 인증 관련 exports
library;

// Domain Entities
export 'domain/entities/auth_level_entities.dart';
export 'domain/entities/did_entities.dart';
export 'domain/entities/auth_credentials.dart';
export 'domain/entities/user.dart';
export 'domain/entities/verification_result.dart';

// Domain Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/did_repository.dart';

// Domain Use Cases
export 'domain/use_cases/manage_auth_level_use_case.dart';
export 'domain/use_cases/manage_did_use_case.dart';

// Data Repositories
export 'data/repositories/auth_repository_impl.dart';
export 'data/repositories/did_repository_impl.dart';

// Presentation Providers
export 'presentation/providers/auth_level_provider.dart';
export 'presentation/providers/did_provider.dart';

// Presentation Widgets
export 'presentation/widgets/auth_status_card.dart';
export 'presentation/widgets/auth_upgrade_card.dart';
export 'presentation/widgets/did_creation_dialog.dart';
export 'presentation/widgets/auth_method_selection_dialog.dart';
export 'presentation/widgets/additional_auth_explanation_dialog.dart';

// Presentation Screens
export 'presentation/screens/auth_management_screen.dart';