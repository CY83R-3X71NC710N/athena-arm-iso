# GitHub Actions Workflows

This repository includes automated workflows to build and validate the Athena OS ARM64 ISO.

## Workflows

### 1. Build and Release ARM64 ISO (`build-arm64-iso.yml`)

**Purpose**: Builds the complete Athena OS ARM64 ISO and creates GitHub releases.

**Triggers**:
- Manual trigger via GitHub Actions UI
- Git tags matching `v*-arm64` or `v*-aarch64`

**Features**:
- **Native ARM64 build** using macOS runners (no emulation needed!)
- Uses Podman for containerized Fedora build environment
- Automatic checksum generation (SHA256, SHA512)
- GitHub release creation with detailed release notes
- Build artifacts with 30-day retention

**Technical Details**:
- Runs on `macos-latest` which provides native ARM64 hardware
- Uses Podman instead of Docker for better macOS performance
- Builds in Fedora container for proper package management

**Manual Trigger Parameters**:
- `release_tag`: Version tag for the release (e.g., `v1.0.0-arm64`)
- `fedora_version`: Base Fedora version (default: `42`)

### 2. Validation Workflow (`validate-arm64.yml`)

**Purpose**: Quick validation of kickstart file and ARM64 configurations.

**Triggers**:
- Manual trigger
- Push to main/master branch
- Changes to kickstart file or workflows

**Checks**:
- Kickstart file syntax validation
- ARM64-specific package verification
- EFI partition configuration check
- Ensures x86-specific packages are removed

### 3. Native Build Test (`build-native-test.yml`)

**Purpose**: Tests native macOS ARM64 build capabilities and validates environment.

**Triggers**:
- Manual trigger
- Push to main/master branch
- Changes to kickstart file

**Features**:
- Native ARM64 environment validation
- System information reporting
- Kickstart syntax checking
- Build environment testing

## Usage

### Building a Release

1. **Tag-based release** (recommended):
   ```bash
   git tag v1.0.0-arm64
   git push origin v1.0.0-arm64
   ```

2. **Manual trigger**:
   - Go to Actions → "Build and Release Athena OS ARM64 ISO"
   - Click "Run workflow"
   - Enter release tag and Fedora version
   - Click "Run workflow"

### Validation Only

The validation workflow runs automatically on pushes, or can be triggered manually for quick checks.

## Build Requirements

The workflows are designed to be self-contained and don't require special repository configuration beyond:

- GitHub Actions enabled
- `GITHUB_TOKEN` (automatically provided)

## Build Output

### Successful Build Produces:
- `athenaos-live-aarch64.iso` - Main ISO file
- `athenaos-live-aarch64.iso.sha256` - SHA256 checksum
- `athenaos-live-aarch64.iso.sha512` - SHA512 checksum

### Release Notes Include:
- Build information and compatibility matrix
- Installation instructions
- File checksums
- ARM64-specific changes and requirements

## Build Time

Typical build times on native ARM64 macOS runners:
- **Validation**: 1-2 minutes
- **Native test**: 2-3 minutes  
- **Full ISO build**: 20-40 minutes (much faster than emulation!)

**Performance Benefits**:
- ✅ Native ARM64 execution (no emulation overhead)
- ✅ Fast macOS SSD storage
- ✅ Dedicated GitHub Actions resources
- ✅ Parallel container operations

## Troubleshooting

### Common Issues:

1. **Build fails with package not found**:
   - Check if ARM64 packages are available in Fedora repositories
   - Verify kickstart syntax with validation workflow

2. **ISO too large**:
   - Adjust package list in `athena-iso.ks`
   - Consider removing unnecessary packages

3. **GRUB/boot issues**:
   - Ensure EFI partition is properly configured
   - Verify ARM64 GRUB packages are included

### Debug Build Issues:

1. Check workflow logs in GitHub Actions
2. Run validation workflow first to catch syntax errors
3. Use manual trigger with debug mode if needed

## ARM64 Compatibility

The built ISO supports:
- ✅ Apple Silicon Macs (M1/M2/M3/M4)
- ✅ ARM64 servers and workstations
- ✅ ARM64 development boards with UEFI
- ❌ x86/x64 systems (use standard Athena OS)

## Contributing

To modify the build process:

1. Test changes with validation workflow first
2. Update kickstart file (`athena-iso.ks`) for package changes
3. Modify workflows for build process changes
4. Document significant changes in `ARM64_CHANGES.md`
