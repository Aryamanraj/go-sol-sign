#!/bin/bash

# Automated version bumping and release script
# Usage: ./version-bump.sh [patch|minor|major]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to get current version from latest git tag
get_current_version() {
    git fetch --tags 2>/dev/null || true
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo ${latest_tag#v}  # Remove 'v' prefix
}

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -ra ADDR <<< "$version"
    local major=${ADDR[0]}
    local minor=${ADDR[1]}
    local patch=${ADDR[2]}
    
    case $type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch"|*)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to validate git repository state
validate_repo_state() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if working tree is clean
    if ! git diff-index --quiet HEAD --; then
        print_error "Working tree is not clean. Please commit or stash your changes."
        git status --short
        exit 1
    fi
    
    # Check if we're on main branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        print_warning "Not on main/master branch (currently on: $current_branch)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    if ! go test ./...; then
        print_error "Tests failed! Aborting release."
        exit 1
    fi
    print_success "All tests passed!"
}

# Function to create and push release
create_release() {
    local new_version=$1
    local tag="v$new_version"
    
    print_status "Creating release $tag..."
    
    # Create git tag
    git tag -a "$tag" -m "Release $tag

Features in this release:
- Base58 signature format (Solana standard)
- Escape sequence processing for messages
- Multi-platform builds
- Automated CI/CD pipeline

Changes:
$(git log $(git describe --tags --abbrev=0 2>/dev/null || echo)..HEAD --oneline || echo "Initial release")"
    
    # Push tag to trigger release
    git push origin "$tag"
    
    print_success "Tag $tag created and pushed!"
    print_status "GitHub Actions will now build and publish the release."
    print_status "Monitor progress at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
}

# Main function
main() {
    local bump_type=${1:-"patch"}
    
    print_status "🚀 Starting automated release process..."
    echo
    
    # Validate input
    if [[ ! "$bump_type" =~ ^(patch|minor|major)$ ]]; then
        print_error "Invalid bump type. Use: patch, minor, or major"
        echo "Usage: $0 [patch|minor|major]"
        exit 1
    fi
    
    # Validate repository state
    validate_repo_state
    
    # Get current version
    local current_version=$(get_current_version)
    print_status "Current version: v$current_version"
    
    # Calculate new version
    local new_version=$(increment_version "$current_version" "$bump_type")
    print_status "New version will be: v$new_version ($bump_type bump)"
    echo
    
    # Confirm with user
    read -p "Proceed with release v$new_version? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Release cancelled."
        exit 0
    fi
    
    # Run tests
    run_tests
    
    # Pull latest changes
    print_status "Pulling latest changes..."
    git pull origin $(git rev-parse --abbrev-ref HEAD)
    
    # Create and push release
    create_release "$new_version"
    
    echo
    print_success "🎉 Release v$new_version initiated successfully!"
    print_status "The release will be available in a few minutes at:"
    print_status "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases"
}

# Help function
show_help() {
    echo "Automated Version Bumping and Release Script"
    echo ""
    echo "Usage: $0 [BUMP_TYPE]"
    echo ""
    echo "BUMP_TYPE:"
    echo "  patch    Increment patch version (1.2.3 -> 1.2.4) [default]"
    echo "  minor    Increment minor version (1.2.3 -> 1.3.0)"
    echo "  major    Increment major version (1.2.3 -> 2.0.0)"
    echo ""
    echo "Examples:"
    echo "  $0 patch   # Bug fixes"
    echo "  $0 minor   # New features"
    echo "  $0 major   # Breaking changes"
    echo ""
    echo "The script will:"
    echo "  1. Validate repository state"
    echo "  2. Run tests"
    echo "  3. Calculate new version"
    echo "  4. Create annotated git tag"
    echo "  5. Push tag to trigger GitHub Actions release"
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
