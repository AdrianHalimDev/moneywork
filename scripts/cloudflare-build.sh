#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if [[ -z "${FIREBASE_OPTIONS_DART_BASE64:-}" ]]; then
  echo 'Missing FIREBASE_OPTIONS_DART_BASE64. Set it in Cloudflare Pages Production build variables (and Preview if used).' >&2
  exit 1
fi

# Validate before replacing the file; never print Firebase configuration.
firebase_tmp="$(mktemp)"
trap 'rm -f -- "$firebase_tmp"' EXIT
if ! printf '%s' "$FIREBASE_OPTIONS_DART_BASE64" | base64 --decode > "$firebase_tmp"; then
  echo 'FIREBASE_OPTIONS_DART_BASE64 is not valid Base64. Encode the entire lib/firebase_options.dart file again.' >&2
  exit 1
fi
if ! grep -Eq 'class[[:space:]]+DefaultFirebaseOptions([[:space:]]|\{)' "$firebase_tmp"; then
  echo 'Decoded Firebase configuration is empty or missing class DefaultFirebaseOptions. Encode lib/firebase_options.dart, not google-services.json.' >&2
  exit 1
fi
cp -- "$firebase_tmp" lib/firebase_options.dart

# Use the same Flutter release that successfully builds this project locally.
flutter_sdk_dir="$(mktemp -d -t moneywork-flutter.XXXXXX)"
git clone --depth 1 --branch 3.44.9 https://github.com/flutter/flutter.git "$flutter_sdk_dir"
"$flutter_sdk_dir/bin/flutter" pub get
"$flutter_sdk_dir/bin/flutter" build web --release
