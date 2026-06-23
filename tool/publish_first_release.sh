#!/usr/bin/env bash
# Publish all workspace packages to pub.dev in dependency order (first release).
# Requires: dart pub login (Google account with 0xkey.io publisher access).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

is_pub_logged_in() {
  if dart pub token list 2>&1 | grep -q 'pub.dev'; then
    return 0
  fi
  # `dart pub login` stores OAuth credentials here (macOS/Linux).
  local creds="${PUB_CREDENTIALS:-${HOME}/Library/Application Support/dart/pub-credentials.json}"
  if [[ -f "$creds" ]]; then
    return 0
  fi
  creds="${HOME}/.config/dart/pub-credentials.json"
  [[ -f "$creds" ]]
}

if ! is_pub_logged_in; then
  echo "Not logged in to pub.dev. Run: dart pub login" >&2
  exit 1
fi

ORDER=(
  packages/encoding
  packages/crypto
  packages/api-key-stamper
  packages/http
  packages/passkey-stamper
  packages/core
  packages/sdk-flutter
)

package_exists_on_pub() {
  local pkg="$1"
  local ver="$2"
  local body
  body="$(curl -fsSL "https://pub.dev/api/packages/$pkg" 2>/dev/null || true)"
  [[ -n "$body" ]] && echo "$body" | grep -q "\"version\":\"$ver\""
}

for dir in "${ORDER[@]}"; do
  name="$(grep -E '^name:' "$dir/pubspec.yaml" | head -1 | sed 's/name: //')"
  version="$(grep -E '^version:' "$dir/pubspec.yaml" | head -1 | sed 's/version: //')"
  if package_exists_on_pub "$name" "$version"; then
    echo "==> Skipping $name@$version (already on pub.dev)"
    echo
    continue
  fi
  echo "==> Publishing $name@$version from $dir"
  (cd "$dir" && flutter pub publish --dry-run)
  if ! (cd "$dir" && flutter pub publish --force 2>&1 | tee /tmp/pub_publish.log); then
    if grep -q 'already exists' /tmp/pub_publish.log; then
      echo "    $name@$version already on pub.dev (skip)"
    else
      exit 1
    fi
  else
    echo "    Published $name@$version"
  fi
  echo
done

echo "All packages published. Next: enable OIDC on each package at pub.dev (Admin → Automated publishing)."
