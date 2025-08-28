#!/bin/bash

# Automated release script for go-sol-sign
# Usage: ./release.sh [version]
# Example: ./release.sh 1.2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse version argument
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.0"
    exit 1
fi

VERSION="$1"
TAG="v$VERSION"

echo -e "${GREEN}🚀 Preparing release $TAG${NC}"
echo ""

# Verify we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Warning: Not on main branch (current: $CURRENT_BRANCH)${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled."
        exit 0
    fi
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
    echo -e "${RED}Error: You have uncommitted changes${NC}"
    echo "Please commit or stash your changes before releasing."
    exit 1
fi

# Update version in files
echo -e "${BLUE}📝 Updating version to $VERSION in source files...${NC}"

# Update main.go
sed -i "s/Version = \".*\"/Version = \"$VERSION\"/" main.go

# Update build-release.sh  
sed -i "s/VERSION=\".*\"/VERSION=\"$VERSION\"/" build-release.sh

# Update install.sh
sed -i "s/VERSION=\".*\"/VERSION=\"$VERSION\"/" install.sh

# Update packaging files
sed -i "s/Version:        .*/Version:        $VERSION/" packaging/rpm/go-sol-sign.spec

echo -e "${GREEN}✅ Version updated in all files${NC}"

# Run tests
echo -e "${BLUE}🧪 Running tests...${NC}"
go test ./...
echo -e "${GREEN}✅ All tests passed${NC}"

# Build release locally to verify
echo -e "${BLUE}🔨 Building release locally...${NC}"
chmod +x build-release.sh
./build-release.sh
echo -e "${GREEN}✅ Build successful${NC}"

# Clean up build artifacts
rm -rf dist/

# Commit version changes
echo -e "${BLUE}📝 Committing version updates...${NC}"
git add main.go build-release.sh install.sh packaging/rpm/go-sol-sign.spec
git commit -m "chore: bump version to $VERSION

- Update version in main.go, build-release.sh, and install.sh
- Update RPM spec file version
- Prepare for $TAG release"

# Create and push tag
echo -e "${BLUE}🏷️  Creating and pushing tag $TAG...${NC}"
git tag -a "$TAG" -m "Release $TAG

Automated release of go-sol-sign version $VERSION

Changes:
- Updated binary name to go-sol-sign
- Improved install script with non-interactive support
- Enhanced CI/CD with automatic version management
- Updated packaging for all platforms"

git push origin main
git push origin "$TAG"

echo ""
echo -e "${GREEN}🎉 Release $TAG created successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. GitHub Actions will automatically build and publish the release"
echo "2. Monitor the progress at: https://github.com/Aryamanraj/go-sol-sign/actions"
echo "3. The release will be available at: https://github.com/Aryamanraj/go-sol-sign/releases/tag/$TAG"
echo ""
echo -e "${BLUE}Install command will be:${NC}"
echo "curl -fsSL https://raw.githubusercontent.com/Aryamanraj/go-sol-sign/main/install.sh | bash"
