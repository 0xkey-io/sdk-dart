/// Platform-agnostic core for the ZeroXKey SDK.
///
/// Layers: errors, config/provider, network, signing/auth ports, domain
/// (entities/repositories/usecases), data (repository implementations), and the
/// dependency-injection composition root.
library;

// Errors & configuration
export 'src/errors/exceptions.dart';
export 'src/config/configuration.dart';
export 'src/config/resolved_runtime_config.dart';
export 'src/provider/backend_provider.dart';

// Network
export 'src/network/retry_policy.dart';
export 'src/network/middleware_http_transport.dart';
export 'src/network/api_error_mapper.dart';

// Signing/auth ports
export 'src/signing/signer.dart';
export 'src/ports/session_store.dart';
export 'src/ports/oauth_redirect_handler.dart';

// Auth
export 'src/auth/auth_result.dart';
export 'src/auth/auth_provider.dart';
export 'src/auth/otp_auth_provider.dart';
export 'src/auth/oauth_auth_provider.dart';
export 'src/auth/passkey_auth_provider.dart';
export 'src/data/mappers/entity_mappers.dart';

// Domain
export 'src/domain/entities/session_entity.dart';
export 'src/domain/entities/user_entity.dart';
export 'src/domain/entities/wallet_entity.dart';
export 'src/domain/entities/policy_entity.dart';
export 'src/domain/repositories/user_repository.dart';
export 'src/domain/repositories/wallet_repository.dart';
export 'src/domain/repositories/signing_repository.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/domain/repositories/passkey_repository.dart';
export 'src/domain/repositories/policy_repository.dart';
export 'src/domain/repositories/wallet_kit_config_repository.dart';
export 'src/domain/usecases/sign_message_usecase.dart';
export 'src/domain/usecases/otp_usecases.dart';
export 'src/domain/usecases/signup_usecases.dart';
export 'src/domain/usecases/oauth_usecases.dart';
export 'src/domain/usecases/passkey_usecases.dart';
export 'src/domain/usecases/policy_usecases.dart';
export 'src/domain/usecases/wallet_kit_config_usecase.dart';

// Data
export 'src/data/signing_codec.dart';
export 'src/data/client_signature_codec.dart';
export 'src/data/repositories/user_repository_impl.dart';
export 'src/data/repositories/wallet_repository_impl.dart';
export 'src/data/repositories/signing_repository_impl.dart';
export 'src/data/repositories/auth_repository_impl.dart';
export 'src/data/repositories/passkey_repository_impl.dart';
export 'src/data/repositories/policy_repository_impl.dart';
export 'src/data/repositories/wallet_kit_config_repository_impl.dart';

// Composition root
export 'src/di/zeroxkey_container.dart';
