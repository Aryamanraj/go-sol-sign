#!/bin/bash

# Production build script for sol-sign
# Builds for multiple architectures and operating systems

set -e

VERSION="1.2.0"
APP_NAME="go-sol-sign"
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
    "windows/arm64"
)

echo "🚀 Building $APP_NAME v$VERSION for production..."
echo ""

# Clean previous builds
rm -rf dist/
mkdir -p dist/

# Ensure go.mod is tidy
echo "📦 Tidying dependencies..."
go mod tidy

# Run tests
echo "🧪 Running tests..."
go test ./... || {
    echo "❌ Tests failed!"
    exit 1
}

# Build for each platform
echo "🔨 Building for multiple platforms..."
for platform in "${PLATFORMS[@]}"; do
    platform_split=(${platform//\// })
    GOOS=${platform_split[0]}
    GOARCH=${platform_split[1]}
    
    output_name=$APP_NAME
    if [ $GOOS = "windows" ]; then
        output_name+='.exe'
    fi
    
    echo "   Building for $GOOS/$GOARCH..."
    
    env GOOS=$GOOS GOARCH=$GOARCH go build \
        -ldflags="-w -s" \
        -o dist/${APP_NAME}_${GOOS}_${GOARCH}/${output_name} \
        .
    
    # Create compressed archives
    cd dist/${APP_NAME}_${GOOS}_${GOARCH}/
    
    if [ $GOOS = "windows" ]; then
        zip -q ../${APP_NAME}_${VERSION}_${GOOS}_${GOARCH}.zip ${output_name}
    else
        tar -czf ../${APP_NAME}_${VERSION}_${GOOS}_${GOARCH}.tar.gz ${output_name}
    fi
    
    cd ../..
    
    # Calculate file size
    size=$(du -h dist/${APP_NAME}_${VERSION}_${GOOS}_${GOARCH}.* | cut -f1)
    echo "   ✅ Built ${APP_NAME}_${VERSION}_${GOOS}_${GOARCH} (${size})"
done

# Generate checksums
echo ""
echo "🔐 Generating checksums..."
cd dist/
sha256sum *.{tar.gz,zip} > checksums.txt 2>/dev/null || true
cd ..

echo ""
echo "✅ Build complete! Artifacts in ./dist/"
echo ""
echo "📦 Generated packages:"
ls -la dist/*.{tar.gz,zip} 2>/dev/null || true
echo ""
echo "🔐 Checksums:"
cat dist/checksums.txt 2>/dev/null || echo "No checksums generated"
