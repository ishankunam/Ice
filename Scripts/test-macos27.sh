#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

test_dir="${ICE_TEST_DIR:-build/tests}"
mkdir -p "$test_dir/module-cache"
export CLANG_MODULE_CACHE_PATH="$PWD/$test_dir/module-cache"

run_test() {
    local name="$1"
    shift
    xcrun swiftc -O -parse-as-library -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
        "$@" "Tests/$name.swift" -o "$test_dir/$name"
    "$test_dir/$name"
}

run_test NativeMenuBarBoundaryTests Ice/MenuBar/MenuBarItems/MacOS27NativeBoundary.swift
run_test MacOS27MenuBarGeometryTests Ice/MenuBar/MacOS27MenuBarGeometry.swift
run_test MacOS27VisibilityRequestTests Ice/MenuBar/MacOS27VisibilityRequest.swift
run_test MacOS27ScrollTests Ice/Events/MacOS27InteractionRules.swift Ice/MenuBar/MacOS27MenuBarGeometry.swift
run_test NativeDragVisibilityStateTests Ice/MenuBar/MenuBarItems/MacOS27NativeBoundary.swift
run_test MacOS27DynamicItemStateTests Ice/MenuBar/MenuBarItems/MacOS27DynamicItemState.swift
run_test MacOS27LayoutOwnerTests Ice/MenuBar/MenuBarItems/MacOS27DynamicItemState.swift
run_test MenuBarGlyphImageTests Ice/MenuBar/LayoutBar/MenuBarGlyphImage.swift
run_test AverageColorTests Ice/Utilities/CGImage+AverageColor.swift
run_test MenuBarOverlayGeometryTests Ice/MenuBar/Appearance/MenuBarOverlayGeometry.swift
xcrun clang -c Tests/SpaceTypeBridgeFixture.c -o "$test_dir/SpaceTypeBridgeFixture.o"
run_test SpaceTypeBridgeTests Shared/Bridging/Shims.swift "$test_dir/SpaceTypeBridgeFixture.o"
