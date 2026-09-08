#!/bin/bash

echo "🚀 Fixing Flutter permissions for: $PWD"

# 1. Clear macOS quarantine attributes (Gatekeeper blocks stuff in Downloads)
echo "🧹 Clearing macOS quarantine flags..."
xattr -rc . 2>/dev/null

# 2. Fix read/write permissions for the current user
echo "🔓 Granting read/write permissions..."
chmod -R u+rwX .

# 3. Make gradlew executable
if [ -f "android/gradlew" ]; then
    echo "⚙️ Making gradlew executable..."
    chmod +x android/gradlew
else
    echo "⚠️ android/gradlew not found! Make sure you run this from the Flutter project root."
fi

# 4. Clean up the build cache
echo "🗑️ Running flutter clean..."
flutter clean

echo "📦 Fetching pub get..."
flutter pub get
