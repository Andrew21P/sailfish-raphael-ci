# SailfishOS 5.0.0.43 (Tampella) for Xiaomi Mi 9T Pro (raphael)

CI-based build system for porting SailfishOS to the Xiaomi Mi 9T Pro (codename: raphael).

Based on the [sailfish-on-davinci](https://github.com/sailfish-on-davinci/ci) approach.

## Device Info

- **Device**: Xiaomi Mi 9T Pro (also known as Redmi K20 Pro)
- **Codename**: raphael / raphaelin
- **SoC**: Qualcomm SM8150 (Snapdragon 855)
- **Android Base**: hybris-17.1 (Android 10)
- **SailfishOS Target**: 5.0.0.43 (Tampella)

## Setup Instructions

### 1. Fork Required Repositories

Before the CI can build, you need to fork and prepare these repos under your GitHub account or organization:

1. **Device Tree** - Fork from LineageOS and add hybris patches:
   ```
   https://github.com/LineageOS/android_device_xiaomi_raphael
   ```
   
2. **SM8150 Common** - Shared device tree for SM8150 devices:
   ```
   https://github.com/LineageOS/android_device_xiaomi_sm8150-common
   ```

3. **Kernel** - Fork from LineageOS:
   ```
   https://github.com/LineageOS/android_kernel_xiaomi_sm8150
   ```

4. **Vendor Blobs** - Extract from your device or use TheMuppets:
   ```
   https://github.com/TheMuppets/proprietary_vendor_xiaomi
   ```

5. **Hybris Boot** - Fork mer-hybris and add raphael to fixup-mountpoints:
   ```
   https://github.com/mer-hybris/hybris-boot
   ```
   
   **Note**: The complete `fixup-mountpoints` file with raphael is already included in this repo. Just copy it to your hybris-boot fork.

### 2. Add fixup-mountpoints for raphael

In your forked `hybris-boot` repo, edit `fixup-mountpoints` and add raphael:

```bash
"raphael")
    sed -i \
        -e 's block/platform/soc/1d84000.ufshc/by-name/system block/platform/soc/1d84000.ufshc/by-name/system g' \
        -e 's block/platform/soc/1d84000.ufshc/by-name/vendor block/platform/soc/1d84000.ufshc/by-name/vendor g' \
        -e 's block/platform/soc/1d84000.ufshc/by-name/userdata block/platform/soc/1d84000.ufshc/by-name/userdata g' \
        -e 's block/platform/soc/1d84000.ufshc/by-name/boot block/platform/soc/1d84000.ufshc/by-name/boot g' \
        "$@"
    ;;
```

### 3. Update Workflow URLs

Edit `.github/workflows/build.yml` and replace `nicknisi` placeholders with your GitHub username/org:

```yaml
# Change these URLs to your forked repos:
git clone https://github.com/YOUR_USERNAME/device_xiaomi_raphael.git
git clone https://github.com/YOUR_USERNAME/kernel_xiaomi_sm8150.git
git clone https://github.com/YOUR_USERNAME/vendor_xiaomi_raphael.git
git clone https://github.com/YOUR_USERNAME/hybris-boot.git
```

### 4. Push and Build

```bash
cd sailfish-raphael-ci
git init
git add .
git commit -m "Initial CI setup for raphael"
git remote add origin https://github.com/YOUR_USERNAME/sailfish-raphael-ci.git
git push -u origin main
```

Go to GitHub Actions tab and manually trigger the build, or push a commit.

## Build Outputs

After successful build, these artifacts will be available:
- `hybris-boot.img` - Boot image
- `hybris-recovery.img` - Recovery image  
- `system.img` - System partition
- `vendor.img` - Vendor partition

## Related Resources

- [Hadk Documentation](https://sailfishos.org/develop/hadk/)
- [mer-hybris](https://github.com/mer-hybris)
- [SailfishOS Porters Telegram](https://t.me/nicknisiorters)

## Credits

- sailfish-on-davinci CI for the build approach
- LineageOS for device trees
- mer-hybris for SailfishOS Android HAL
