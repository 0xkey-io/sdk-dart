import 'package:zeroxkey_http/zeroxkey_http.dart'
    show ZeroXKeyClient, HttpTransport, DefaultHttpTransport;

import '../auth/oauth_auth_provider.dart';
import '../auth/otp_auth_provider.dart';
import '../auth/passkey_auth_provider.dart';
import '../config/configuration.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/passkey_repository_impl.dart';
import '../data/repositories/policy_repository_impl.dart';
import '../data/repositories/signing_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/wallet_kit_config_repository_impl.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/passkey_repository.dart';
import '../domain/repositories/policy_repository.dart';
import '../domain/repositories/signing_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/wallet_kit_config_repository.dart';
import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/oauth_usecases.dart';
import '../domain/usecases/otp_usecases.dart';
import '../domain/usecases/passkey_usecases.dart';
import '../domain/usecases/policy_usecases.dart';
import '../domain/usecases/sign_message_usecase.dart';
import '../domain/usecases/signup_usecases.dart';
import '../domain/usecases/wallet_kit_config_usecase.dart';
import '../network/middleware_http_transport.dart';
import '../signing/signer.dart';

/// Hand-written composition root.
///
/// Wires the configured backend/network options into a decorated [HttpTransport]
/// and the repository + use-case graph. Kept dependency-free (no third-party DI)
/// to honor the SDK's minimal-dependency policy. The presentation layer supplies
/// [clientResolver] so repositories always target the session's active client.
class ZeroXKeyContainer {
  final ZeroXKeyConfiguration configuration;

  /// Decorated transport (tracing/retry/timeout) to inject into every client.
  final HttpTransport transport;

  final UserRepository userRepository;
  final WalletRepository walletRepository;
  final SigningRepository signingRepository;
  final AuthRepository authRepository;
  final PasskeyRepository passkeyRepository;
  final PolicyRepository policyRepository;
  final WalletKitConfigRepository walletKitConfigRepository;

  final OtpAuthProvider otpAuthProvider;
  final OAuthAuthProvider oauthAuthProvider;
  final PasskeyAuthProvider passkeyAuthProvider;

  final InitOtpUseCase initOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final LoginWithOtpUseCase loginWithOtpUseCase;
  final SignUpWithOtpUseCase signUpWithOtpUseCase;
  final LoginOrSignUpWithOtpUseCase loginOrSignUpWithOtpUseCase;
  final LoginWithOAuthUseCase loginWithOAuthUseCase;
  final LoginOrSignUpWithOAuthUseCase loginOrSignUpWithOAuthUseCase;
  final LoginWithPasskeyUseCase loginWithPasskeyUseCase;
  final SignMessageUseCase signMessageUseCase;
  final FetchPoliciesUseCase fetchPoliciesUseCase;
  final CreatePoliciesUseCase createPoliciesUseCase;
  final FetchWalletKitConfigUseCase fetchWalletKitConfigUseCase;

  ZeroXKeyContainer._({
    required this.configuration,
    required this.transport,
    required this.userRepository,
    required this.walletRepository,
    required this.signingRepository,
    required this.authRepository,
    required this.passkeyRepository,
    required this.policyRepository,
    required this.walletKitConfigRepository,
    required this.otpAuthProvider,
    required this.oauthAuthProvider,
    required this.passkeyAuthProvider,
    required this.initOtpUseCase,
    required this.verifyOtpUseCase,
    required this.loginWithOtpUseCase,
    required this.signUpWithOtpUseCase,
    required this.loginOrSignUpWithOtpUseCase,
    required this.loginWithOAuthUseCase,
    required this.loginOrSignUpWithOAuthUseCase,
    required this.loginWithPasskeyUseCase,
    required this.signMessageUseCase,
    required this.fetchPoliciesUseCase,
    required this.createPoliciesUseCase,
    required this.fetchWalletKitConfigUseCase,
  });

  factory ZeroXKeyContainer({
    required ZeroXKeyConfiguration configuration,
    required ZeroXKeyClient Function() clientResolver,
    required Signer signer,
    required KeyStore keyStore,
    HttpTransport? transport,
  }) {
    final decorated = transport ??
        MiddlewareHttpTransport(
          DefaultHttpTransport(defaultTimeout: configuration.network.timeout),
          retryPolicy: configuration.network.retryPolicy,
          timeout: configuration.network.timeout,
        );

    final auth = AuthRepositoryImpl(clientResolver);
    const passkey = PasskeyRepositoryImpl();
    final signing = SigningRepositoryImpl(clientResolver);
    final policies = PolicyRepositoryImpl(clientResolver);
    final walletKit = WalletKitConfigRepositoryImpl(clientResolver);

    final otpProvider = OtpAuthProvider(
      auth: auth,
      signer: signer,
      keyStore: keyStore,
    );
    final oauthProvider = OAuthAuthProvider(auth: auth);
    final passkeyProvider = PasskeyAuthProvider(passkey: passkey);

    return ZeroXKeyContainer._(
      configuration: configuration,
      transport: decorated,
      userRepository: UserRepositoryImpl(clientResolver),
      walletRepository: WalletRepositoryImpl(clientResolver),
      signingRepository: signing,
      authRepository: auth,
      passkeyRepository: passkey,
      policyRepository: policies,
      walletKitConfigRepository: walletKit,
      otpAuthProvider: otpProvider,
      oauthAuthProvider: oauthProvider,
      passkeyAuthProvider: passkeyProvider,
      initOtpUseCase: InitOtpUseCase(otpProvider),
      verifyOtpUseCase: VerifyOtpUseCase(otpProvider),
      loginWithOtpUseCase: LoginWithOtpUseCase(otpProvider),
      signUpWithOtpUseCase: SignUpWithOtpUseCase(otpProvider),
      loginOrSignUpWithOtpUseCase: LoginOrSignUpWithOtpUseCase(otpProvider),
      loginWithOAuthUseCase: LoginWithOAuthUseCase(oauthProvider),
      loginOrSignUpWithOAuthUseCase:
          LoginOrSignUpWithOAuthUseCase(oauthProvider),
      loginWithPasskeyUseCase: LoginWithPasskeyUseCase(passkeyProvider),
      signMessageUseCase: SignMessageUseCase(signing),
      fetchPoliciesUseCase: FetchPoliciesUseCase(policies),
      createPoliciesUseCase: CreatePoliciesUseCase(policies),
      fetchWalletKitConfigUseCase: FetchWalletKitConfigUseCase(walletKit),
    );
  }
}
