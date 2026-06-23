import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zeroxkey_core/zeroxkey_core.dart' show OAuthRedirectHandler;

/// Flutter implementation of the core [OAuthRedirectHandler] port for the
/// standard `id_token`-via-redirect OAuth flow (e.g. Google).
///
/// Opens an in-app browser at [originUri] and resolves with the `id_token`
/// query parameter delivered back through the app's deep-link scheme. Provider
/// flows requiring a server-side code exchange (X/Discord) or native SDKs
/// (Apple Sign-In) are handled separately by the presentation layer.
class FlutterOAuthRedirectHandler implements OAuthRedirectHandler {
  final String appScheme;
  final String nonce;
  final Duration timeout;

  FlutterOAuthRedirectHandler({
    required this.appScheme,
    required this.nonce,
    this.timeout = const Duration(minutes: 10),
  });

  @override
  Future<String> fetchOidcToken({
    required String providerName,
    required String primaryClientId,
    List<String>? secondaryClientIds,
    String? originUri,
    String? redirectUri,
  }) async {
    if (originUri == null || originUri.isEmpty) {
      throw ArgumentError('originUri is required for the redirect OAuth flow');
    }
    if (redirectUri == null || redirectUri.isEmpty) {
      throw ArgumentError(
          'redirectUri is required for the redirect OAuth flow');
    }

    final oauthUrl = originUri +
        '?provider=${Uri.encodeComponent(providerName)}' +
        '&clientId=${Uri.encodeComponent(primaryClientId)}' +
        '&redirectUri=${Uri.encodeComponent(redirectUri)}' +
        '&nonce=${Uri.encodeComponent(nonce)}';

    final appLinks = AppLinks();
    final completer = Completer<String>();
    StreamSubscription? subscription;

    subscription = appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri == null || !uri.toString().startsWith(appScheme)) return;
      final idToken = uri.queryParameters['id_token'];
      if (idToken != null && !completer.isCompleted) {
        completer.complete(idToken);
      }
    });

    final browser = _RedirectBrowser(onClosedCallback: () {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('OAuth browser closed before returning a token'),
        );
      }
    });

    try {
      await browser.open(
        url: WebUri(oauthUrl),
        settings: ChromeSafariBrowserSettings(
          showTitle: true,
          toolbarBackgroundColor: Colors.white,
        ),
      );
      return await completer.future.timeout(
        timeout,
        onTimeout: () =>
            throw TimeoutException('OAuth authentication timed out'),
      );
    } finally {
      await subscription.cancel();
      await browser.close();
    }
  }
}

class _RedirectBrowser extends ChromeSafariBrowser {
  final VoidCallback onClosedCallback;

  _RedirectBrowser({required this.onClosedCallback});

  @override
  void onClosed() {
    onClosedCallback();
    super.onClosed();
  }
}
