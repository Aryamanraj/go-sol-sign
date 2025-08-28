# Development Workflow

This document outlines the automated development and release workflow for go-sol-sign.

## Quick Release Commands

### Automated Version Bumping (Recommended)

```bash
# For bug fixes (1.3.0 -> 1.3.1)
./version-bump.sh patch

# For new features (1.3.0 -> 1.4.0)
./version-bump.sh minor

# For breaking changes (1.3.0 -> 2.0.0)
./version-bump.sh major
```

### Legacy Commands (Still Works)

```bash
# Will automatically run patch version bump
./release.sh
```

## What Happens Automatically

The `version-bump.sh` script handles everything:

1. **🔍 Validation**
   - Checks if repository is clean
   - Verifies you're on main branch
   - Ensures tests pass

2. **📊 Version Management**
   - Automatically detects current version from git tags
   - Calculates new version based on bump type
   - Shows you the changes before proceeding

3. **🚀 Release Process**
   - Creates annotated git tag with changelog
   - Pushes tag to GitHub
   - Triggers GitHub Actions automatically
   - Builds multi-platform binaries
   - Creates GitHub release with assets

4. **⏱️ Timeline**
   - Immediate: Tag created and pushed
   - 3-5 minutes: GitHub Actions completes build
   - Ready: Release available for download

## Development Workflow

### Day-to-Day Development

```bash
# 1. Make your changes
git add .
git commit -m "feat: add new feature"

# 2. Push to main
git push

# 3. When ready to release
./version-bump.sh minor  # or patch/major
```

### Release Types

- **patch**: Bug fixes, documentation updates, small improvements
- **minor**: New features, enhancements (backwards compatible)
- **major**: Breaking changes, major rewrites

## Examples

```bash
# After fixing a bug
./version-bump.sh patch

# After adding base58 support
./version-bump.sh minor

# After changing CLI interface significantly
./version-bump.sh major
```

## Manual Override (Advanced)

If you need to create a specific version:

```bash
# Create tag manually
git tag v1.5.0
git push origin v1.5.0
```

## Monitoring Releases

- **GitHub Actions**: https://github.com/Aryamanraj/go-sol-sign/actions
- **Releases**: https://github.com/Aryamanraj/go-sol-sign/releases

## Troubleshooting

If a release fails:

1. Check GitHub Actions logs
2. Ensure all tests pass locally: `go test ./...`
3. Verify repository is clean: `git status`
4. Try running `./version-bump.sh` again

The automation handles all the complex parts - just focus on writing great code! 🚀
