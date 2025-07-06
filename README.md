# athena-arm-iso

Athena OS Live ISO configuration for ARM64 (aarch64) architecture.

## Architecture Support

This Kickstart configuration is specifically designed for:
- **Target Architecture**: ARM64 (aarch64)
- **Boot Method**: UEFI
- **Target Platforms**: ARM64 devices including Apple Silicon Macs, ARM64 servers, and ARM64 development boards

## Key ARM64-Specific Changes

- **Bootloader**: Uses GRUB2 EFI for aarch64 with appropriate modules
- **Partitioning**: Includes EFI system partition for UEFI boot
- **Virtualization**: Removes x86-specific tools (VirtualBox, VMware tools)
- **Packages**: Excludes x86-only packages like syslinux

## Building the ISO

### Automated Build (Recommended)

This repository includes GitHub Actions workflows for automated building:

1. **Quick build via tag**:
   ```bash
   git tag v1.0.0-arm64
   git push origin v1.0.0-arm64
   ```

2. **Manual build**:
   - Go to GitHub Actions → "Build and Release Athena OS ARM64 ISO"
   - Click "Run workflow" and specify parameters

3. **Validation only**:
   - Push changes to trigger automatic validation
   - Or manually run the validation workflow

### Manual Build

For manual building, you'll need:
1. An ARM64 system or cross-compilation environment
2. Fedora's `livecd-tools` or `lorax` package
3. Access to Fedora ARM64 repositories

Example build command:
```bash
sudo livemedia-creator --make-iso --ks athena-iso.ks --no-virt --iso-only --iso-name athenaos-live-aarch64.iso --resultdir ./results --releasever 42 --arch aarch64
```

## Compatibility

This configuration targets modern ARM64 systems with UEFI firmware. Legacy BIOS boot is not supported as most ARM64 systems use UEFI.

## GitHub Actions Workflows

This repository includes automated CI/CD workflows:

- **Build and Release**: Complete ARM64 ISO build with automatic GitHub releases
- **Validation**: Quick syntax and configuration validation
- **Cross-platform**: Uses Docker and QEMU for ARM64 builds on x86 runners

See [`.github/workflows/README.md`](.github/workflows/README.md) for detailed workflow documentation.

## Repository Support

The configuration uses `$basearch` variables in repository URLs, which will automatically resolve to `aarch64` for ARM64 builds, ensuring the correct architecture packages are used.