#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build/artifacts
{
    git rev-parse HEAD
    sw_vers
    xcodebuild -version
    xcrun swift --version
    echo "Runner image: ${ImageOS:-local} ${ImageVersion:-unknown}"
} > build/artifacts/build-info.txt

bash Scripts/test-macos27.sh 2>&1 | tee build/artifacts/tests.log
xcodebuild -project Ice.xcodeproj -scheme Ice -configuration Release \
    -derivedDataPath build/DerivedData \
    -onlyUsePackageVersionsFromResolvedFile \
    ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
    ENABLE_HARDENED_RUNTIME=NO \
    build 2>&1 | tee build/artifacts/build.log

ice_app=build/DerivedData/Build/Products/Release/Ice.app
codesign --verify --deep --strict --verbose=2 "$ice_app" 2>&1 | tee build/artifacts/signature.log
test "$(lipo -archs "$ice_app/Contents/MacOS/Ice")" = arm64
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$ice_app/Contents/Info.plist")" = com.jordanbaird.Ice
test "$(/usr/libexec/PlistBuddy -c 'Print :IceDisableUpstreamUpdates' "$ice_app/Contents/Info.plist")" = true
git diff --exit-code -- Ice.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
ditto -c -k --sequesterRsrc --keepParent "$ice_app" build/artifacts/Ice-macos27-arm64.zip
(cd build/artifacts && shasum -a 256 Ice-macos27-arm64.zip > SHA256SUMS)
