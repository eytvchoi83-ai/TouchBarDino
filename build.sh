#!/bin/zsh
# TouchBarDino.app 빌드 스크립트
set -e
cd "$(dirname "$0")"

swift build -c release

APP=TouchBarDino.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/TouchBarDino "$APP/Contents/MacOS/"
cp -R Resources/Sounds "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleIdentifier</key><string>com.rainy.touchbardino</string>
    <key>CFBundleName</key><string>TouchBarDino</string>
    <key>CFBundleDisplayName</key><string>터치바 공룡</string>
    <key>CFBundleExecutable</key><string>TouchBarDino</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.1.0</string>
    <key>CFBundleVersion</key><string>2</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF

codesign --force --deep --sign - "$APP"
echo "OK: $(pwd)/$APP"
