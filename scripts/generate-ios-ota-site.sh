#!/bin/sh
set -eu

# Generate the small HTTPS site consumed by an iOS itms-services QR link.
# The caller supplies the public GitHub Pages URL and the already signed IPA.

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
IPA=${1:?Usage: generate-ios-ota-site.sh path/to/Foodcart.ipa https://owner.github.io/repo/}
BASE_URL=${2:?Usage: generate-ios-ota-site.sh path/to/Foodcart.ipa https://owner.github.io/repo/}
OUT=${3:-$ROOT/builds/distribution/site}
BUNDLE_ID=${BUNDLE_ID:-}
DISPLAY_NAME=${DISPLAY_NAME:-一口小精灵}
VERSION=${VERSION:-}
BUILD_NUMBER=${BUILD_NUMBER:-}

case "$BASE_URL" in */) ;; *) BASE_URL="$BASE_URL/" ;; esac
[ -f "$IPA" ] || { echo "IPA not found: $IPA" >&2; exit 2; }
mkdir -p "$OUT"

# Read metadata from the signed app unless the caller explicitly overrides it.
META_DIR=$(mktemp -d)
trap 'rm -rf "$META_DIR"' EXIT
unzip -q "$IPA" -d "$META_DIR"
APP_PLIST=$(find "$META_DIR/Payload" -maxdepth 2 -name Info.plist -print -quit)
[ -n "$APP_PLIST" ] || { echo "IPA has no app Info.plist: $IPA" >&2; exit 2; }
read_plist_key() {
  python3 - "$APP_PLIST" "$1" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as stream:
    print(plistlib.load(stream).get(sys.argv[2], ""))
PY
}
[ -n "$BUNDLE_ID" ] || BUNDLE_ID=$(read_plist_key CFBundleIdentifier)
[ -n "$VERSION" ] || VERSION=$(read_plist_key CFBundleShortVersionString)
[ -n "$BUILD_NUMBER" ] || BUILD_NUMBER=$(read_plist_key CFBundleVersion)
BUNDLE_ID=${BUNDLE_ID:-com.johnny.game.foodcart}
VERSION=${VERSION:-unknown}
BUILD_NUMBER=${BUILD_NUMBER:-unknown}
cp "$IPA" "$OUT/Foodcart.ipa"

cat > "$OUT/manifest.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>items</key><array><dict><key>assets</key><array>
<dict><key>kind</key><string>software-package</string><key>url</key><string>${BASE_URL}Foodcart.ipa</string></dict>
</array><key>metadata</key><dict>
<key>bundle-identifier</key><string>${BUNDLE_ID}</string>
<key>bundle-version</key><string>${BUILD_NUMBER}</string>
<key>kind</key><string>software</string>
<key>title</key><string>${DISPLAY_NAME}</string>
<key>version</key><string>${VERSION}</string>
</dict></dict></array></dict></plist>
EOF

SHA256=$(shasum -a 256 "$OUT/Foodcart.ipa" | awk '{print $1}')
cat > "$OUT/index.html" <<EOF
<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${DISPLAY_NAME} 测试包</title>
<h1>${DISPLAY_NAME} iOS 测试包</h1>
<p>版本 ${VERSION}（${BUILD_NUMBER}）</p>
<p><a href="itms-services://?action=download-manifest&amp;url=${BASE_URL}manifest.plist">在 iPhone 上安装</a></p>
<p>IPA SHA-256：<code>${SHA256}</code></p>
<p>仅限已加入 Ad Hoc provisioning profile 的测试设备。请使用 iPhone Safari 打开。</p>
EOF

echo "Generated OTA site: $OUT"
