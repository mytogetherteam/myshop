#!/bin/bash

# Vercel doesn't have Flutter installed by default. This script downloads the stable flutter SDK before building.
echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Building Flutter Web App with WebAssembly (--wasm)..."
flutter build web --wasm
