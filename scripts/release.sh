#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Safora Release Builder
# Usage:
#   ./scripts/release.sh patch    → 1.1.0+2  →  1.1.1+3
#   ./scripts/release.sh minor    → 1.1.0+2  →  1.2.0+3
#   ./scripts/release.sh major    → 1.1.0+2  →  2.0.0+3
#   ./scripts/release.sh build    → rebuild current version
# ─────────────────────────────────────────────────────────────
set -euo pipefail

PUBSPEC="pubspec.yaml"
OUTPUT_DIR="PlayStore"

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

log()   { echo -e "${GREEN}✔${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
err()   { echo -e "${RED}✘${NC} $1" >&2; exit 1; }
info()  { echo -e "${CYAN}ℹ${NC} $1"; }

# ── Parse current version from pubspec.yaml ─────────────────
parse_version() {
  local version_line
  version_line=$(grep -E '^version:' "$PUBSPEC") || err "No version found in $PUBSPEC"
  local full="${version_line#version: }"
  
  SEMVER="${full%%+*}"
  BUILD_NUMBER="${full##*+}"
  
  IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"
  
  log "Current version: ${CYAN}${SEMVER}+${BUILD_NUMBER}${NC}"
}

# ── Bump version ────────────────────────────────────────────
bump_version() {
  local bump_type="$1"
  
  case "$bump_type" in
    patch)
      PATCH=$((PATCH + 1))
      ;;
    minor)
      MINOR=$((MINOR + 1))
      PATCH=0
      ;;
    major)
      MAJOR=$((MAJOR + 1))
      MINOR=0
      PATCH=0
      ;;
    build)
      # Just increment build number, keep semver
      ;;
    *)
      err "Unknown bump type: $bump_type. Use: patch | minor | major | build"
      ;;
  esac
  
  # Always increment build number (Play Store requires unique, increasing)
  BUILD_NUMBER=$((BUILD_NUMBER + 1))
  
  NEW_SEMVER="${MAJOR}.${MINOR}.${PATCH}"
  NEW_VERSION="${NEW_SEMVER}+${BUILD_NUMBER}"
  
  log "New version:     ${CYAN}${NEW_VERSION}${NC}"
}

# ── Write version back to pubspec.yaml ──────────────────────
write_version() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
  else
    sed -i "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
  fi
  log "Updated $PUBSPEC"
}

# ── Build ───────────────────────────────────────────────────
build_release() {
  mkdir -p "$OUTPUT_DIR"
  
  echo ""
  info "Building App Bundle (AAB) for Play Store..."
  flutter build appbundle --release
  log "AAB built successfully"
  
  echo ""
  info "Building APK for direct distribution..."
  flutter build apk --release
  log "APK built successfully"
  
  # Copy to PlayStore directory with versioned names
  local aab_src="build/app/outputs/bundle/release/app-release.aab"
  local apk_src="build/app/outputs/flutter-apk/app-release.apk"
  local aab_dst="${OUTPUT_DIR}/safora-v${NEW_SEMVER}+${BUILD_NUMBER}.aab"
  local apk_dst="${OUTPUT_DIR}/safora-v${NEW_SEMVER}+${BUILD_NUMBER}.apk"
  
  cp "$aab_src" "$aab_dst"
  cp "$apk_src" "$apk_dst"
  
  echo ""
  log "Release files:"
  ls -lh "$aab_dst" "$apk_dst"
}

# ── Git commit ──────────────────────────────────────────────
git_commit() {
  echo ""
  read -p "$(echo -e "${YELLOW}?${NC} Git commit & tag this release? [y/N]: ")" confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    git add "$PUBSPEC"
    git commit -m "release: v${NEW_VERSION}"
    git tag "v${NEW_SEMVER}"
    log "Committed and tagged v${NEW_SEMVER}"
    
    read -p "$(echo -e "${YELLOW}?${NC} Push to remote? [y/N]: ")" push_confirm
    if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
      git push && git push --tags
      log "Pushed to remote"
    fi
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  local bump_type="${1:-}"
  
  if [[ -z "$bump_type" ]]; then
    echo ""
    echo "  Safora Release Builder"
    echo "  ─────────────────────"
    echo "  Usage: ./scripts/release.sh <bump_type>"
    echo ""
    echo "  Bump types:"
    echo "    patch   →  1.1.0 → 1.1.1  (bug fixes)"
    echo "    minor   →  1.1.0 → 1.2.0  (new features)"
    echo "    major   →  1.1.0 → 2.0.0  (breaking changes)"
    echo "    build   →  +2    → +3     (version code only)"
    echo ""
    exit 0
  fi
  
  echo ""
  echo "  🛡️  Safora Release Builder"
  echo "  ─────────────────────────"
  echo ""
  
  parse_version
  bump_version "$bump_type"
  write_version
  build_release
  git_commit
  
  echo ""
  echo "  ─────────────────────────"
  log "Release v${NEW_VERSION} complete! 🚀"
  echo ""
  info "Upload ${CYAN}${OUTPUT_DIR}/safora-v${NEW_SEMVER}+${BUILD_NUMBER}.aab${NC} to Play Store Console"
  echo ""
}

main "$@"
