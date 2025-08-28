#!/bin/bash

# Legacy release script - now redirects to automated version-bump.sh
# This script is kept for backwards compatibility

echo "🔄 This script has been replaced by the automated version-bump.sh"
echo ""
echo "New usage:"
echo "  ./version-bump.sh patch   # Bug fixes (1.2.3 -> 1.2.4)"
echo "  ./version-bump.sh minor   # New features (1.2.3 -> 1.3.0)"
echo "  ./version-bump.sh major   # Breaking changes (1.2.3 -> 2.0.0)"
echo ""

# Check if version-bump.sh exists and is executable
if [[ -x "./version-bump.sh" ]]; then
    echo "🚀 Running automated version bump..."
    ./version-bump.sh patch  # Default to patch for backwards compatibility
else
    echo "❌ version-bump.sh not found or not executable"
    echo "Please run: chmod +x version-bump.sh"
    exit 1
fi
