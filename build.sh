#!/bin/bash

# Simple build script for sol-sign
echo "Building sol-sign..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go first."
    echo ""
    echo "On Ubuntu/Debian:"
    echo "  sudo apt update && sudo apt install golang-go"
    echo ""
    echo "Or download from: https://golang.org/dl/"
    exit 1
fi

# Build the binary
go build -o sol-sign

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Binary created: ./sol-sign"
    echo ""
    echo "Usage: ./sol-sign -keypair <path> -message <message>"
    echo ""
    echo "To install globally, run:"
    echo "  sudo cp sol-sign /usr/local/bin/"
else
    echo "❌ Build failed!"
    exit 1
fi
