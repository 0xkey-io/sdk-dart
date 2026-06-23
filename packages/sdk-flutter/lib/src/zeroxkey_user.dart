part of 'zeroxkey.dart';

extension on ZeroXKeyProvider {
  /// Refreshes the current user data.
  ///
  /// Fetches the latest user details from the API using the current session's client.
  /// If the user data is successfully retrieved, updates the session with the new user details.
  /// Saves the updated session and updates the state.
  ///
  /// Throws an [Exception] if the session or client is not initialized.
  Future<void> refreshUser() async {
    if (runtimeConfig?.authConfig.autoRefreshManagedState == false) {
      return;
    }

    if (session == null) {
      throw Exception("Failed to refresh user. Sessions not initialized");
    }
    user = await _container.userRepository.fetchUser(
      organizationId: session!.organizationId,
      userId: session!.userId,
    );
  }
}
