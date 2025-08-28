#!/bin/bash

# Universal installer for go-sol-sign
# Detects OS and architecture, downloads and installs appropriate binary

set -e

REPO="Aryamanraj/go-sol-sign"

# Function to get latest version from GitHub API
get_latest_version() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//'
}

# Get latest version dynamically
VERSION=$(get_latest_version)
if [[ -z "$VERSION" ]]; then
    echo "❌ Failed to fetch latest version. Using fallback version 1.2.0"
    VERSION="1.2.0"
fi

BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

# Parse command line arguments
FORCE_INSTALL=false
SHOW_HELP=false
for arg in "$@"; do
    case $arg in
        --force|-f)
            FORCE_INSTALL=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
    esac
done

# Show help if requested
if [[ "$SHOW_HELP" == "true" ]]; then
    echo "Universal installer for go-sol-sign"
    echo ""
    echo "Usage:"
    echo "  curl -fsSL https://raw.githubusercontent.com/Aryamanraj/go-sol-sign/main/install.sh | bash"
    echo "  curl -fsSL https://raw.githubusercontent.com/Aryamanraj/go-sol-sign/main/install.sh | bash -s -- --force"
    echo ""
    echo "Options:"
    echo "  --force, -f    Force installation without prompts"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "The installer automatically detects your OS and architecture,"
    echo "downloads the appropriate binary, and installs it to /usr/local/bin"
    exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS and architecture
detect_platform() {
    local os
    local arch
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)   os="linux" ;;
        Darwin*)  os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *) 
            echo -e "${RED}Error: Unsupported operating system$(uname -s)${NC}"
            exit 1
            ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo -e "${RED}Error: Unsupported architecture $(uname -m)${NC}"
            exit 1
            ;;
    esac
    
    echo "${os}_${arch}"
}

# Download and verify file
download_file() {
    local url="$1"
    local output="$2"
    
    echo -e "${BLUE}Downloading: $url${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        echo -e "${RED}Error: Neither curl nor wget found. Please install one of them.${NC}"
        exit 1
    fi
}

# Install function
install_sol_sign() {
    echo -e "${GREEN}🚀 Installing go-sol-sign v${VERSION}${NC}"
    echo ""
    
    # Create temporary directory
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    # Detect platform
    local platform=$(detect_platform)
    echo -e "${BLUE}Detected platform: $platform${NC}"
    
    # Determine file extension
    local extension="tar.gz"
    local binary_name="go-sol-sign"
    if [[ "$platform" == *"windows"* ]]; then
        extension="zip"
        binary_name="go-sol-sign.exe"
    fi
    
    # Download archive
    local archive_name="go-sol-sign_${VERSION}_${platform}.${extension}"
    local download_url="${BASE_URL}/${archive_name}"
    
    echo -e "${BLUE}Downloading $archive_name...${NC}"
    download_file "$download_url" "$archive_name"
    
    # Extract archive
    echo -e "${BLUE}Extracting archive...${NC}"
    if [[ "$extension" == "zip" ]]; then
        unzip -q "$archive_name"
    else
        tar -xzf "$archive_name"
    fi
    
    # Find the binary
    local binary_path=$(find . -name "$binary_name" -type f)
    if [[ -z "$binary_path" ]]; then
        echo -e "${RED}Error: Binary not found in archive${NC}"
        exit 1
    fi
    
    # Install the binary
    local install_dir="/usr/local/bin"
    local install_path="${install_dir}/go-sol-sign"
    
    echo -e "${BLUE}Installing to $install_path...${NC}"
    
    # Check if we need sudo
    if [[ -w "$install_dir" ]]; then
        cp "$binary_path" "$install_path"
        chmod +x "$install_path"
    else
        echo -e "${YELLOW}Installing to system directory requires sudo...${NC}"
        sudo cp "$binary_path" "$install_path"
        sudo chmod +x "$install_path"
    fi
    
    # Cleanup
    cd /
    rm -rf "$tmp_dir"
    
    echo ""
    echo -e "${GREEN}✅ go-sol-sign installed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Usage:${NC}"
    echo "  go-sol-sign -keypair <path> -message <message>"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  go-sol-sign -keypair ~/.config/solana/id.json -message \"Hello World\""
    echo "  go-sol-sign -version"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "  https://github.com/${REPO}"
}

# Check if go-sol-sign is already installed
if command -v go-sol-sign >/dev/null 2>&1; then
    current_version=$(go-sol-sign -version 2>&1 | head -n1 | cut -d' ' -f2 || echo "unknown")
    echo -e "${YELLOW}go-sol-sign is already installed (version: $current_version)${NC}"
    echo -e "${YELLOW}This will update it to version v${VERSION}${NC}"
    echo ""
    
    if [[ "$FORCE_INSTALL" == "true" ]]; then
        echo -e "${BLUE}Force install enabled, proceeding...${NC}"
    elif [[ ! -t 0 ]]; then
        echo -e "${BLUE}Non-interactive mode detected, proceeding with installation...${NC}"
    else
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
# Also check for old sol-sign installation and offer to remove it
elif command -v sol-sign >/dev/null 2>&1; then
    echo -e "${YELLOW}Found old 'sol-sign' installation${NC}"
    echo -e "${YELLOW}This installer will install the new 'go-sol-sign' binary${NC}"
    echo ""
    
    if [[ "$FORCE_INSTALL" == "true" ]]; then
        echo -e "${BLUE}Force install enabled, removing old sol-sign and installing go-sol-sign...${NC}"
        if [[ -w "/usr/local/bin" ]]; then
            rm -f /usr/local/bin/sol-sign
        else
            sudo rm -f /usr/local/bin/sol-sign
        fi
        echo -e "${GREEN}Old sol-sign removed${NC}"
    elif [[ ! -t 0 ]]; then
        echo -e "${BLUE}Non-interactive mode: automatically removing old sol-sign and installing go-sol-sign...${NC}"
        if [[ -w "/usr/local/bin" ]]; then
            rm -f /usr/local/bin/sol-sign
        else
            sudo rm -f /usr/local/bin/sol-sign
        fi
        echo -e "${GREEN}Old sol-sign removed${NC}"
    else
        read -p "Remove old 'sol-sign' and install 'go-sol-sign'? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Removing old sol-sign...${NC}"
            if [[ -w "/usr/local/bin" ]]; then
                rm -f /usr/local/bin/sol-sign
            else
                sudo rm -f /usr/local/bin/sol-sign
            fi
            echo -e "${GREEN}Old sol-sign removed${NC}"
        else
            echo "Installation cancelled."
            exit 0
        fi
    fi
fi

# Run installation
install_sol_sign
