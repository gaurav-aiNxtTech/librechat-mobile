#!/usr/bin/env bash
# Full verification pass for the Flutter app: codegen, static analysis, tests, debug APK.
# Usage: scripts/ci.sh [--skip-build]
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
# A fixed seed keeps property tests reproducible; drop it locally for fresh cases.
flutter test --dart-define=PROPERTY_SEED=20260101

if [[ "${1:-}" != "--skip-build" ]]; then
  flutter build apk --debug
fi
