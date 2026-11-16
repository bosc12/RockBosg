#!/usr/bin/env bash
# Compila y publica una versión nueva de RockBosg en GitHub Releases.
# Uso: scripts/release.sh ["notas de la versión"]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep -E '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*([0-9.]+).*/\1/')
CODE_VERSION=$(grep -oE "'[0-9.]+'" lib/version.dart | tr -d "'")
TAG="v$VERSION"
NOTES="${1:-Versión $VERSION}"

[ "$VERSION" = "$CODE_VERSION" ] || { echo "❌ pubspec ($VERSION) y lib/version.dart ($CODE_VERSION) no coinciden"; exit 1; }
[ -f android/key.properties ] || { echo "❌ Falta android/key.properties (llave de firma)"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "❌ Hay cambios sin commitear"; exit 1; }
gh release view "$TAG" >/dev/null 2>&1 && { echo "❌ La release $TAG ya existe"; exit 1; }

flutter test
flutter build apk --release
APK="build/app/outputs/flutter-apk/RockBosg-$VERSION.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$APK"

git tag "$TAG"
git push origin "$TAG"
gh release create "$TAG" "$APK" --title "RockBosg $VERSION" --notes "$NOTES"
echo "✅ Publicada $TAG"
