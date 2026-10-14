#!/bin/zsh
# Compiles the preview tool into build/preview (see Tools/Preview/main.swift for how to use it).
set -euo pipefail
cd "${0:A:h}/../.."
mkdir -p build
swiftc -swift-version 5 -target "$(uname -m)-apple-macos13.0" \
    Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
    Sources/App/Universes/**/*.swift Sources/Shared/*.swift \
    Tools/Preview/main.swift -o build/preview
echo "✓ build/preview"
