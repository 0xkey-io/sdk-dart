# ZeroXKey Dart SDK

The ZeroXKey Dart SDK provides Flutter and Dart packages for integrating ZeroXKey Embedded Wallets into mobile applications.

## Packages

| Package | Description |
| --- | --- |
| `zeroxkey_sdk_flutter` | High-level Flutter SDK (`ZeroXKeyProvider`, Auth Proxy, OTP, Passkey, wallets) — thin presentation layer |
| `zeroxkey_core` | Pure-Dart core: domain/data/network/DI, unified errors, `Signer`/`KeyStore` ports |
| `zeroxkey_http` | Typed HTTP client generated from 0xkey OpenAPI specs |
| `zeroxkey_crypto` | Cryptographic utilities including 0xkey-native HPKE |
| `zeroxkey_api_key_stamper` | API key request stamping |
| `zeroxkey_passkey_stamper` | Passkey request stamping |
| `zeroxkey_encoding` | Encoding helpers |

## Installation

This repo is a [pub workspace](https://dart.dev/tools/pub/workspaces): the
packages depend on each other by version (`^x`). Two integration methods are
supported.

### 方案 1 — Git dependency + `dependency_overrides`

When you reference `zeroxkey_sdk_flutter` over Git, pub cannot resolve the
sibling packages from pub.dev, so you must add `dependency_overrides` for every
sibling. Generate the exact snippet (no hand-editing) with:

```bash
# from a clone of this repo; REF is any branch/tag/commit
make git-overrides REF=main
# or: dart run tool/gen_git_overrides.dart --ref main --url <your-fork-url>
```

Paste the output into your app's `pubspec.yaml`. It looks like:

```yaml
dependencies:
  zeroxkey_sdk_flutter:
    git:
      url: https://github.com/0xkey-io/sdk-dart.git
      path: packages/sdk-flutter
      ref: main

dependency_overrides:
  zeroxkey_core:
    git: { url: https://github.com/0xkey-io/sdk-dart.git, path: packages/core, ref: main }
  zeroxkey_http:
    git: { url: https://github.com/0xkey-io/sdk-dart.git, path: packages/http, ref: main }
  # ... one entry per sibling package (api-key/passkey stamper, crypto, encoding)
```

Pin `ref` to a release tag (e.g. `prod-20260624`) for reproducible builds rather
than tracking `main`.

### 方案 2 — pub.dev (public release)

Once the packages are published to [pub.dev](https://pub.dev), consumers depend
on them by version only — no overrides:

```yaml
dependencies:
  zeroxkey_sdk_flutter: ^0.1.0
```

Publishing is **guarded** (it is never an automatic tag-push side effect),
mirroring the JS SDK's protected release flow:

1. Bump versions via changesets: `make prepare-release`, commit, then
   `dart run tool/push_package_tags.dart` to push `{package_name}-{version}`
   tags and dispatch `publish.yml` per package.
2. `.github/workflows/publish.yml` runs per tag, publishes to pub.dev via
   **OIDC** (no long-lived token), and is gated by a manual approval on the
   `pub-dev` GitHub environment. Already-published versions are skipped.

**One-time setup** (see the workflow header for details):

- Create a Google account and a **verified publisher** for `0xkey.io` on
  pub.dev (DNS/Search Console domain verification).
- Manually publish each package's first version in dependency order
  (encoding → crypto → api_key/passkey stamper → http → core → sdk_flutter).
- On each package: enable Automated publishing → GitHub Actions, repository
  `0xkey-io/sdk-dart`, tag pattern `{{package}}-{{version}}`, require
  environment `pub-dev`.

Either way, also add `provider` and `flutter_inappwebview` to your Flutter app.

## Development

```bash
flutter pub get
make -C packages/http generate
dart format .
make test
dart analyze .
```

The OpenAPI specs that drive codegen are committed under
`packages/http/lib/swagger/`; regenerate the client with
`make -C packages/http generate` after updating them.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
