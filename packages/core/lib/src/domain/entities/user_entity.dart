import 'package:zeroxkey_http/zeroxkey_http.dart' show v1User;

/// Domain view of a ZeroXKey user. Preserves the wire [v1User] for protocol
/// compatibility while allowing future field evolution behind this type.
class UserEntity {
  final v1User user;

  const UserEntity(this.user);

  String get userId => user.userId;
  String? get userName => user.userName;
}
