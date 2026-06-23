import '__generated__/models.dart';

enum v1UsageType {
  usage_type_signup,
  usage_type_login,
}

v1UsageType v1UsageTypeFromJson(dynamic value) {
  switch (value) {
    case 'USAGE_TYPE_SIGNUP':
      return v1UsageType.usage_type_signup;
    case 'USAGE_TYPE_LOGIN':
      return v1UsageType.usage_type_login;
    default:
      throw ArgumentError('Unknown v1UsageType: $value');
  }
}

dynamic v1UsageTypeToJson(v1UsageType value) {
  switch (value) {
    case v1UsageType.usage_type_signup:
      return 'USAGE_TYPE_SIGNUP';
    case v1UsageType.usage_type_login:
      return 'USAGE_TYPE_LOGIN';
  }
}

class v1LoginUsage {
  final String publicKey;

  const v1LoginUsage({required this.publicKey});

  factory v1LoginUsage.fromJson(Map<String, dynamic> json) {
    return v1LoginUsage(publicKey: json['publicKey'] as String);
  }

  Map<String, dynamic> toJson() => {'publicKey': publicKey};
}

class v1SignupUsageV2 {
  final String? email;
  final String? phoneNumber;
  final List<v1ApiKeyParamsV2>? apiKeys;
  final List<v1AuthenticatorParamsV2>? authenticators;
  final List<v1OauthProviderParamsV2>? oauthProviders;

  const v1SignupUsageV2({
    this.email,
    this.phoneNumber,
    this.apiKeys,
    this.authenticators,
    this.oauthProviders,
  });

  factory v1SignupUsageV2.fromJson(Map<String, dynamic> json) {
    return v1SignupUsageV2(
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      apiKeys: (json['apiKeys'] as List?)
          ?.map((e) => v1ApiKeyParamsV2.fromJson(e as Map<String, dynamic>))
          .toList(),
      authenticators: (json['authenticators'] as List?)
          ?.map(
            (e) => v1AuthenticatorParamsV2.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      oauthProviders: (json['oauthProviders'] as List?)
          ?.map(
            (e) => v1OauthProviderParamsV2.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (email != null) json['email'] = email;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (apiKeys != null) {
      json['apiKeys'] = apiKeys!.map((e) => e.toJson()).toList();
    }
    if (authenticators != null) {
      json['authenticators'] = authenticators!.map((e) => e.toJson()).toList();
    }
    if (oauthProviders != null) {
      json['oauthProviders'] = oauthProviders!.map((e) => e.toJson()).toList();
    }
    return json;
  }
}

class v1TokenUsage {
  final v1UsageType type;
  final String tokenId;
  final v1SignupUsageV2? signupV2;
  final v1LoginUsage? login;

  const v1TokenUsage({
    required this.type,
    required this.tokenId,
    this.signupV2,
    this.login,
  });

  factory v1TokenUsage.fromJson(Map<String, dynamic> json) {
    return v1TokenUsage(
      type: v1UsageTypeFromJson(json['type']),
      tokenId: json['tokenId'] as String,
      signupV2: json['signupV2'] == null
          ? null
          : v1SignupUsageV2.fromJson(json['signupV2'] as Map<String, dynamic>),
      login: json['login'] == null
          ? null
          : v1LoginUsage.fromJson(json['login'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': v1UsageTypeToJson(type),
      'tokenId': tokenId,
    };
    if (signupV2 != null) json['signupV2'] = signupV2!.toJson();
    if (login != null) json['login'] = login!.toJson();
    return json;
  }
}
