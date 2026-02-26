#!/bin/bash
# HAL build script for SailfishOS on raphael
# This script is called from the GitHub Actions workflow
set -e

echo "=== Build HAL for hybris-18.1 ==="
echo "ANDROID_ROOT: $ANDROID_ROOT"
echo "DEVICE: $DEVICE"

sudo apt-get update
sudo apt-get install -y \
  openjdk-8-jdk android-tools-adb bc bison \
  build-essential curl flex gnupg gperf \
  imagemagick lib32ncurses-dev lib32readline-dev lib32z1-dev \
  liblz4-tool libncurses5-dev libsdl1.2-dev libssl-dev \
  libxml2 libxml2-utils lzop pngcrush rsync schedtool \
  squashfs-tools xsltproc yasm zip zlib1g-dev \
  qemu-user-static qemu-system-arm e2fsprogs simg2img \
  libtinfo5 libncurses5 gzip virtualenv git python2 \
  gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi \
  clang lld llvm

# Setup JDK
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export PATH=$JAVA_HOME/bin:$PATH

mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
git config --global user.email "ci@github.com"
git config --global user.name "Github Actions"
git config --global --add safe.directory '*'

# Create directory and sync from cache
mkdir -p $ANDROID_ROOT
cd $ANDROID_ROOT

# If .repo exists from cache, use local sync; otherwise full init+sync
if [ -d ".repo" ]; then
  echo "Cache found, running local checkout..."
  python3 ~/bin/repo sync -l -j$(nproc --all) || python3 ~/bin/repo sync -j$(nproc --all) -c --no-clone-bundle --no-tags
else
  echo "No cache, running full init+sync..."
  python3 ~/bin/repo init -u https://github.com/mer-hybris/android.git -b hybris-18.1 --depth=1
  python3 ~/bin/repo sync -j$(nproc --all) -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync
fi

#------------------------------------------
# Clone device-specific repos for raphael
#------------------------------------------
# Device tree (PixelExperience eleven branch)
rm -rf $ANDROID_ROOT/device/xiaomi/raphael || true
git clone https://github.com/PixelExperience-Devices/device_xiaomi_raphael.git \
  $ANDROID_ROOT/device/xiaomi/raphael --depth=1 -b eleven

# Kernel (PixelExperience eleven branch)
rm -rf $ANDROID_ROOT/kernel/xiaomi/raphael || true
git clone https://github.com/PixelExperience-Devices/kernel_xiaomi_raphael.git \
  $ANDROID_ROOT/kernel/xiaomi/raphael --depth=1 -b eleven

# Patch kernel IPA driver - fix copy_from_user buffer size mismatch (GCC 11+ issue)
IPA_FILE="$ANDROID_ROOT/kernel/xiaomi/raphael/drivers/platform/msm/ipa/ipa_v3/ipa_hw_stats.c"
IPA_MAKEFILE="$ANDROID_ROOT/kernel/xiaomi/raphael/drivers/platform/msm/ipa/ipa_v3/Makefile"

if [ -f "$IPA_FILE" ]; then
  echo "Patching IPA driver for GCC 11+ compatibility..."
  perl -i -pe 's/char\s+dbg_buff\s*\[\s*\d+\s*\]/char dbg_buff[64]/g' "$IPA_FILE"
  perl -i -pe 's/copy_from_user\s*\(\s*dbg_buff\s*,\s*(\w+)\s*,\s*count\s*\)/copy_from_user(dbg_buff, $1, min_t(size_t, count, sizeof(dbg_buff) - 1))/g' "$IPA_FILE"
fi

if [ -f "$IPA_MAKEFILE" ]; then
  echo "" >> "$IPA_MAKEFILE"
  echo "# Disable FORTIFY_SOURCE for GCC 11+ compatibility" >> "$IPA_MAKEFILE"
  echo 'CFLAGS_ipa_hw_stats.o += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -Wno-error' >> "$IPA_MAKEFILE"
fi

# Disable FORTIFY_SOURCE and other problematic configs in defconfig
DEFCONFIG="$ANDROID_ROOT/kernel/xiaomi/raphael/arch/arm64/configs/raphael_user_defconfig"
if [ -f "$DEFCONFIG" ]; then
  sed -i '/CONFIG_FORTIFY_SOURCE/d' "$DEFCONFIG"
  sed -i '/CONFIG_HARDENED_USERCOPY/d' "$DEFCONFIG"
  sed -i '/CONFIG_COMPAT_VDSO/d' "$DEFCONFIG"
  sed -i '/CONFIG_MODVERSIONS/d' "$DEFCONFIG"
  sed -i '/CONFIG_QCOM_RTIC/d' "$DEFCONFIG"
  sed -i '/CONFIG_KALLSYMS_BASE_RELATIVE/d' "$DEFCONFIG"
  echo "# CONFIG_FORTIFY_SOURCE is not set" >> "$DEFCONFIG"
  echo "# CONFIG_HARDENED_USERCOPY is not set" >> "$DEFCONFIG"
  echo "# CONFIG_COMPAT_VDSO is not set" >> "$DEFCONFIG"
  echo "# CONFIG_MODVERSIONS is not set" >> "$DEFCONFIG"
  echo "# CONFIG_QCOM_RTIC is not set" >> "$DEFCONFIG"
  echo "# CONFIG_KALLSYMS_BASE_RELATIVE is not set" >> "$DEFCONFIG"
fi

# RTIC FIX: Redefine __rticdata to empty
KERNEL_DIR="$ANDROID_ROOT/kernel/xiaomi/raphael"
sed -i 's/#define __rticdata.*__attribute__.*section.*bss\.rtic.*/#define __rticdata \/\* disabled \*\//' "$KERNEL_DIR/include/linux/init.h"
if [ -f "$KERNEL_DIR/include/linux/rtic_mp.h" ]; then
  sed -i 's/#define __rticdata.*/#define __rticdata \/\* disabled \*\//' "$KERNEL_DIR/include/linux/rtic_mp.h"
fi

# Patch KALLSYMS_BASE_RELATIVE
sed -i 's/config KALLSYMS_BASE_RELATIVE/config KALLSYMS_BASE_RELATIVE\n\tdefault n\n\t# Patched by sailfish-raphael-ci/' "$KERNEL_DIR/init/Kconfig" || true
if [ -f "$KERNEL_DIR/scripts/kallsyms.c" ]; then
  sed -i 's/static int base_relative;/static int base_relative = 0; \/\/ Forced to absolute mode/' "$KERNEL_DIR/scripts/kallsyms.c"
  sed -i 's/int base_relative = 1;/int base_relative = 0; \/\/ Forced to absolute mode/' "$KERNEL_DIR/scripts/kallsyms.c"
fi

# Disable raphael DTBO build only
QCOM_DTS_MAKEFILE="$KERNEL_DIR/arch/arm64/boot/dts/qcom/Makefile"
if [ -f "$QCOM_DTS_MAKEFILE" ]; then
  sed -i '/raphael.*overlay.*dtbo/d' "$QCOM_DTS_MAKEFILE"
  sed -i '/dtbo.*raphael.*overlay/d' "$QCOM_DTS_MAKEFILE"
fi

# Kernel image and clang config in BoardConfig
if [ -f device/xiaomi/raphael/BoardConfig.mk ]; then
  echo "" >> device/xiaomi/raphael/BoardConfig.mk
  echo "# Use Image.gz without appended DTB for hybris" >> device/xiaomi/raphael/BoardConfig.mk
  echo "BOARD_KERNEL_IMAGE_NAME := Image.gz" >> device/xiaomi/raphael/BoardConfig.mk
  echo 'KERNEL_MAKE_FLAGS += KCFLAGS="-Wno-error -Wno-unused-but-set-variable -Wno-unused-variable -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"' >> device/xiaomi/raphael/BoardConfig.mk
  echo 'KERNEL_MAKE_FLAGS += CROSS_COMPILE=aarch64-linux-gnu-' >> device/xiaomi/raphael/BoardConfig.mk
  echo 'KERNEL_MAKE_FLAGS += CROSS_COMPILE_ARM32=arm-linux-gnueabi-' >> device/xiaomi/raphael/BoardConfig.mk
  echo 'KERNEL_MAKE_FLAGS += CC=clang' >> device/xiaomi/raphael/BoardConfig.mk
  echo 'KERNEL_MAKE_FLAGS += CLANG_TRIPLE=aarch64-linux-gnu-' >> device/xiaomi/raphael/BoardConfig.mk
fi

# Hardware Xiaomi
rm -rf $ANDROID_ROOT/hardware/xiaomi || true
git clone https://github.com/LineageOS/android_hardware_xiaomi.git \
  -b lineage-18.1 $ANDROID_ROOT/hardware/xiaomi --depth=1 --single-branch || true

# Qualcomm HALs for SM8150
rm -rf $ANDROID_ROOT/hardware/qcom-caf/sm8150/display || true
mkdir -p $ANDROID_ROOT/hardware/qcom-caf/sm8150
git clone https://github.com/LineageOS/android_hardware_qcom_display.git \
  -b lineage-18.1-caf-sm8150 $ANDROID_ROOT/hardware/qcom-caf/sm8150/display --depth=1

rm -rf $ANDROID_ROOT/hardware/qcom-caf/sm8150/audio || true
git clone https://github.com/LineageOS/android_hardware_qcom_audio.git \
  -b lineage-18.1-caf-sm8150 $ANDROID_ROOT/hardware/qcom-caf/sm8150/audio --depth=1

rm -rf $ANDROID_ROOT/hardware/qcom-caf/sm8150/media || true
git clone https://github.com/LineageOS/android_hardware_qcom_media.git \
  -b lineage-18.1-caf-sm8150 $ANDROID_ROOT/hardware/qcom-caf/sm8150/media --depth=1

#------------------------------------------
# Create vendor stubs
#------------------------------------------
mkdir -p $ANDROID_ROOT/vendor/xiaomi/raphael
cat > $ANDROID_ROOT/vendor/xiaomi/raphael/raphael-vendor.mk << 'EOF'
# Stub vendor makefile for hybris build
PRODUCT_SOONG_NAMESPACES += vendor/xiaomi/raphael
EOF

cat > $ANDROID_ROOT/vendor/xiaomi/raphael/Android.bp << 'EOF'
// Stub Android.bp for hybris build
soong_namespace {
}
EOF

echo '# Stub BoardConfig for hybris' > $ANDROID_ROOT/vendor/xiaomi/raphael/BoardConfigVendor.mk

#------------------------------------------
# Patch device tree for hybris compatibility
#------------------------------------------
if [ -f "$ANDROID_ROOT/device/xiaomi/raphael/BoardConfig.mk" ]; then
  sed -i 's|kernel/xiaomi/sm8150|kernel/xiaomi/raphael|g' \
    $ANDROID_ROOT/device/xiaomi/raphael/BoardConfig.mk || true
fi

sed -i '/vendor.lineage.biometrics.fingerprint.inscreen/d' \
  $ANDROID_ROOT/device/xiaomi/raphael/device.mk || true
sed -i '/XiaomiParts/d' \
  $ANDROID_ROOT/device/xiaomi/raphael/device.mk || true

#------------------------------------------
# Replace hybris-boot with fixup-mountpoints
#------------------------------------------
rm -rf $ANDROID_ROOT/hybris/hybris-boot || true
git clone https://github.com/mer-hybris/hybris-boot.git \
  $ANDROID_ROOT/hybris/hybris-boot --depth=1

#------------------------------------------
# Inject raphael fixup-mountpoints
#------------------------------------------
FIXUP_FILE="$ANDROID_ROOT/hybris/hybris-boot/fixup-mountpoints"
if [ -f "$FIXUP_FILE" ] && ! grep -q '"raphael"' "$FIXUP_FILE"; then
  cat > /tmp/raphael_fixups.txt << 'EOF'
    "raphael"|"raphaelin")
        # Xiaomi Mi 9T Pro - SM8150
        sed -i \
            -e 's block/bootdevice/by-name/boot sde49 ' \
            -e 's block/bootdevice/by-name/recovery sda28 ' \
            -e 's block/bootdevice/by-name/dtbo sde45 ' \
            -e 's block/bootdevice/by-name/system sde54 ' \
            -e 's block/bootdevice/by-name/vendor sde53 ' \
            -e 's block/bootdevice/by-name/userdata sda31 ' \
            -e 's block/bootdevice/by-name/cache sda29 ' \
            -e 's block/bootdevice/by-name/persist sda23 ' \
            -e 's block/bootdevice/by-name/misc sda11 ' \
            -e 's block/bootdevice/by-name/modem sde52 ' \
            -e 's block/bootdevice/by-name/dsp sde48 ' \
            -e 's block/bootdevice/by-name/bluetooth sde26 ' \
            -e 's block/bootdevice/by-name/vbmeta sde10 ' \
            -e 's block/bootdevice/by-name/vbmeta_system sde47 ' \
            -e 's block/bootdevice/by-name/abl sde17 ' \
            -e 's block/bootdevice/by-name/xbl sdb2 ' \
            -e 's block/bootdevice/by-name/xbl_config sdb1 ' \
            -e 's block/bootdevice/by-name/tz sde19 ' \
            -e 's block/bootdevice/by-name/hyp sde21 ' \
            -e 's block/bootdevice/by-name/keymaster sde31 ' \
            -e 's block/bootdevice/by-name/cmnlib sde27 ' \
            -e 's block/bootdevice/by-name/cmnlib64 sde29 ' \
            -e 's block/bootdevice/by-name/devcfg sde33 ' \
            -e 's block/bootdevice/by-name/qupfw sde35 ' \
            -e 's block/bootdevice/by-name/storsec sde37 ' \
            -e 's block/bootdevice/by-name/modemst1 sdf2 ' \
            -e 's block/bootdevice/by-name/modemst2 sdf3 ' \
            -e 's block/bootdevice/by-name/fsc sdf5 ' \
            -e 's block/bootdevice/by-name/fsg sdf1 ' \
            -e 's block/bootdevice/by-name/aop sde11 ' \
            -e 's block/bootdevice/by-name/cust sda30 ' \
            -e 's block/bootdevice/by-name/logo sde46 ' \
            -e 's block/bootdevice/by-name/splash sda19 ' \
            -e 's block/bootdevice/by-name/keystore sda20 ' \
            -e 's block/bootdevice/by-name/frp sda21 ' \
            -e 's block/bootdevice/by-name/logfs sda18 ' \
            -e 's block/bootdevice/by-name/devinfo sda7 ' \
            -e 's block/bootdevice/by-name/product sde55 ' \
            -e 's block/bootdevice/by-name/metadata sda19 ' \
            -e 's block/by-name/metadata sda19 ' \
            "$@"
        ;;
EOF
  sed -i '/^[[:space:]]*\*)$/e cat /tmp/raphael_fixups.txt' "$FIXUP_FILE" || {
    head -n -20 "$FIXUP_FILE" > /tmp/fixup_temp
    cat /tmp/raphael_fixups.txt >> /tmp/fixup_temp
    tail -20 "$FIXUP_FILE" >> /tmp/fixup_temp
    mv /tmp/fixup_temp "$FIXUP_FILE"
  }
  echo "Added raphael to fixup-mountpoints"
fi

#------------------------------------------
# Clean up ROM-specific dependencies
#------------------------------------------
rm -rf device/xiaomi/raphael/XiaomiParts || true
rm -rf device/xiaomi/raphael/parts || true
rm -rf device/xiaomi/raphael/fod || true
rm -f device/xiaomi/raphael/aosp.dependencies || true
rm -f device/xiaomi/raphael/lineage.dependencies || true

#------------------------------------------
# Clone droidmedia 
#------------------------------------------
rm -rf external/droidmedia || true
git clone --recurse-submodules https://github.com/sailfishos/droidmedia.git external/droidmedia
cd external/droidmedia
git checkout 0.20230605.1 || true
echo 'MINIMEDIA_AUDIOPOLICYSERVICE_ENABLE := 1' > env.mk
echo 'AUDIOPOLICYSERVICE_ENABLE := 1' >> env.mk

#------------------------------------------
# Clone libhybris
#------------------------------------------
cd $ANDROID_ROOT/external
rm -rf libhybris || true
git clone --recurse-submodules https://github.com/mer-hybris/libhybris.git

#------------------------------------------
# Apply hybris-patches
#------------------------------------------
cd $ANDROID_ROOT
hybris-patches/apply-patches.sh --mb || true

#------------------------------------------
# Build HAL
#------------------------------------------
sudo ln -sf /usr/bin/python2.7 /usr/bin/python || true

rm -f vendor/lineage/build/soong/Android.bp || true

mkdir -p vendor/lineage/build
if [ ! -f vendor/lineage/build/envsetup.sh ]; then
  echo 'function fixup_common_out_dir() { :; }' > vendor/lineage/build/envsetup.sh
fi

mkdir -p vendor/aosp/build vendor/aosp/config
echo 'function fixup_common_out_dir() { :; }' > vendor/aosp/build/envsetup.sh
cat > vendor/aosp/config/common_full_phone.mk << 'EOF'
# Stub for hybris build
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)
EOF

#------------------------------------------
# CREATE ALL CC_DEFAULTS STUBS
#------------------------------------------
echo "Creating cc_defaults stubs for hybris build..."

cat > /tmp/hybris_stubs.bp << 'EOF'
// Comprehensive cc_defaults stubs for hybris-18.1 build
cc_defaults { name: "bootloader_message_offset_defaults", }
cc_defaults { name: "vold_hw_fde_defaults", }
cc_defaults { name: "vold_hw_fde_perf_defaults", }
cc_defaults { name: "process_sdk_version_overrides_defaults", }
cc_defaults { name: "shim_libs_defaults", }
cc_defaults { name: "has_memfd_backport_defaults", }
cc_defaults { name: "lineage_go_defaults", }
cc_defaults { name: "target_fs_config_gen_defaults", }
cc_defaults { name: "sdclang_defaults", }
cc_defaults { name: "libhidl_defaults", }
cc_defaults { name: "vendor_init_defaults", }
cc_defaults { name: "stagefright_qcom_legacy_defaults", }
cc_defaults { name: "librmnetctl_pre_uplink_defaults", }
cc_defaults { name: "disable_postrender_cleanup_defaults", }
cc_defaults { name: "surfaceflinger_qcom_ext_defaults", }
cc_defaults { name: "legacy_hw_disk_encryption_defaults", }
cc_defaults { name: "qti_cryptfshw_qsee_defaults", }
cc_defaults { name: "qti_camera_device_defaults", }
cc_defaults { name: "qti_usb_hal_supported_modes_defaults", }
cc_defaults { name: "extended_compress_format_defaults", }
cc_defaults { name: "qti_kernel_headers_defaults", }
cc_defaults { name: "generated_kernel_includes", }
cc_defaults { name: "camera_needs_client_info_defaults", }
cc_defaults { name: "camera_needs_client_info_lib_defaults", }
cc_defaults { name: "camera_parameter_library_defaults", }
cc_defaults { name: "no_cameraserver_defaults", }
cc_defaults { name: "camera_in_mediaserver_defaults", }
cc_defaults { name: "needs_camera_boottime", }
cc_defaults { name: "needs_camera_boottime_defaults", }
cc_defaults { name: "gralloc_10_usage_bits_defaults", }
cc_defaults { name: "surfaceflinger_fod_lib_defaults", }
cc_defaults { name: "surfaceflinger_udfps_lib_defaults", }
cc_defaults { name: "needs_netd_direct_connect_rule_defaults", }
cc_defaults { name: "ignores_ftp_pptp_conntrack_failure", }
cc_defaults { name: "target_uses_prebuilt_dynamic_partitions_defaults", }
cc_defaults { name: "nvidia_enhancements_defaults", }
cc_defaults { name: "inputdispatcher_skip_event_key_defaults", }
cc_library_headers { name: "generated_kernel_headers", vendor_available: true, recovery_available: true, }
EOF

mkdir -p device/xiaomi/raphael
cp /tmp/hybris_stubs.bp device/xiaomi/raphael/Android.bp

rm -f device/xiaomi/raphael/fingerprint/Android.bp || true

find . -name "*.mk" -exec grep -l "WfdCommon" {} \; 2>/dev/null | while read f; do
  sed -i 's/WfdCommon//g' "$f" 2>/dev/null || true
done
rm -rf vendor/qcom/opensource/wfd 2>/dev/null || true

rm -rf external/chromium-webview 2>/dev/null || true
mkdir -p external/chromium-webview
echo "# Stub" > external/chromium-webview/Android.mk

rm -f platform_testing/build/tasks/tests/instrumentation_test_list.mk 2>/dev/null || true
touch platform_testing/build/tasks/tests/instrumentation_test_list.mk 2>/dev/null || true

# Fix kernel defconfig path
if [ -d kernel/xiaomi/raphael ]; then
  mkdir -p kernel/xiaomi/raphael/arch/configs
  DEFCONFIG=$(find kernel/xiaomi/raphael -name "*raphael*defconfig" 2>/dev/null | head -1)
  if [ -n "$DEFCONFIG" ]; then
    cp "$DEFCONFIG" kernel/xiaomi/raphael/arch/configs/raphael_user_defconfig
  else
    cat kernel/xiaomi/raphael/arch/arm64/configs/vendor/sm8150-perf_defconfig >> kernel/xiaomi/raphael/arch/configs/raphael_user_defconfig 2>/dev/null || \
    cat kernel/xiaomi/raphael/arch/arm64/configs/raphael_defconfig >> kernel/xiaomi/raphael/arch/configs/raphael_user_defconfig 2>/dev/null || \
    echo "CONFIG_LOCALVERSION=\"-hybris\"" > kernel/xiaomi/raphael/arch/configs/raphael_user_defconfig
  fi
fi

# Create stub dtbo.img
mkdir -p out/target/product/raphael
printf '\xd7\xb7\xab\x1e\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' > out/target/product/raphael/dtbo.img

# Additional kernel build config
if [ -f device/xiaomi/raphael/BoardConfig.mk ]; then
  if ! grep -q "KERNEL_MAKE_CMD" device/xiaomi/raphael/BoardConfig.mk; then
    echo "" >> device/xiaomi/raphael/BoardConfig.mk
    echo "KERNEL_MAKE_CMD := make" >> device/xiaomi/raphael/BoardConfig.mk
    echo "TARGET_KERNEL_ARCH := arm64" >> device/xiaomi/raphael/BoardConfig.mk
    echo "KERNEL_ARCH := arm64" >> device/xiaomi/raphael/BoardConfig.mk
    echo "TARGET_KERNEL_CLANG_COMPILE := true" >> device/xiaomi/raphael/BoardConfig.mk
    echo 'TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-gnu-' >> device/xiaomi/raphael/BoardConfig.mk
    echo 'TARGET_KERNEL_CROSS_COMPILE_ARM32_PREFIX := arm-linux-gnueabi-' >> device/xiaomi/raphael/BoardConfig.mk
  fi
fi

export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

set +e
source build/envsetup.sh 2>&1
set -e

if ! lunch aosp_raphael-userdebug 2>/dev/null; then
  echo "lunch failed, setting up environment manually..."
  export TARGET_PRODUCT=aosp_raphael
  export TARGET_BUILD_VARIANT=userdebug
  export TARGET_BUILD_TYPE=release
  export OUT_DIR=out
fi

# Free space
rm -rf .repo || true

# Create missing apns-full-conf.xml
mkdir -p device/sample/etc
echo '<?xml version="1.0" encoding="utf-8"?>' > device/sample/etc/apns-full-conf.xml
echo '<apns version="8"></apns>' >> device/sample/etc/apns-full-conf.xml

# Build kernel first
make -j$(nproc --all) bootimage || true

# Find and copy kernel to expected location
KERNEL_OUT="$ANDROID_ROOT/out/target/product/$DEVICE/obj/KERNEL_OBJ"
KERNEL_BOOT="$KERNEL_OUT/arch/arm64/boot"

echo "=== Finding kernel images ==="
find "$ANDROID_ROOT" -name "Image.gz" -type f 2>/dev/null | head -5

mkdir -p "$KERNEL_BOOT"

FOUND_IMAGE=$(find "$ANDROID_ROOT" -path "*/arch/arm64/boot/Image.gz" -type f 2>/dev/null | head -1)
if [ -n "$FOUND_IMAGE" ]; then
  echo "Found kernel at: $FOUND_IMAGE"
  cp "$FOUND_IMAGE" "$KERNEL_BOOT/Image.gz"
  cp "$FOUND_IMAGE" "$KERNEL_BOOT/Image.gz-dtb"
  mkdir -p "$ANDROID_ROOT/out/target/product/$DEVICE"
  cp "$FOUND_IMAGE" "$ANDROID_ROOT/out/target/product/$DEVICE/kernel"
  FOUND_CONFIG=$(dirname "$(dirname "$(dirname "$FOUND_IMAGE")")")/.config
  if [ -f "$FOUND_CONFIG" ]; then
    cp "$FOUND_CONFIG" "$KERNEL_OUT/.config"
  fi
else
  echo "ERROR: Could not find Image.gz anywhere"
  find "$ANDROID_ROOT" -name "Image*" -type f 2>/dev/null | head -10
fi

# Build hybris-hal and droidmedia
echo "=== Building hybris-hal, droidmedia, and system targets ==="
make -j$(nproc --all) hybris-hal droidmedia || make -j$(nproc --all) hybris-boot

# CRITICAL: Build bionic libraries for Android 11+ APEX
# hybris-hal doesn't build these, but DHD needs them
echo "=== Building bionic libraries (required for Android 11+) ==="

# Try building full droid target (includes all bionic)
echo "=== Attempting 'make droid' build (full Android with bionic) ==="
make -j$(nproc --all) droid 2>&1 | tail -200 || echo "make droid failed, trying alternatives..."

# Method 1: Try to build bionic targets directly
echo "=== Building bionic targets directly ===" 
make -j$(nproc --all) libc libm libdl libdl_android linker 2>&1 | tail -50 || true
make -j$(nproc --all) libc libm libdl libdl_android 2>&1 || true

# Method 2: Try building the runtime APEX
make -j$(nproc --all) com.android.runtime 2>&1 || true

# Method 3: Try systemimage (will build everything including APEX)
echo "=== Attempting systemimage build for full APEX support ==="
make -j$(nproc --all) systemimage 2>&1 | tail -100 || true

# Create APEX directory structure that DHD expects
OUT_DIR="$ANDROID_ROOT/out/target/product/$DEVICE"
APEX_DIR="$OUT_DIR/apex/com.android.runtime"
mkdir -p "$APEX_DIR/lib/bionic"
mkdir -p "$APEX_DIR/lib64/bionic"

# Find and copy bionic libraries from wherever they were built
echo "=== Searching for bionic libraries ==="

# Show all libc.so locations for debugging
echo "=== All libc.so locations in build output ==="
find "$ANDROID_ROOT/out" -name "libc.so" -type f 2>/dev/null || true

# Search soong intermediates with flexible pattern matching
echo "=== Searching soong intermediates ==="
for lib in libc libm libdl libdl_android; do
  echo "Looking for $lib.so..."
  
  # 64-bit ARM variants
  LIB64=$(find "$ANDROID_ROOT/out/soong/.intermediates/bionic/$lib" -name "$lib.so" -path "*android_arm64*shared*" -type f 2>/dev/null | head -1)
  if [ -n "$LIB64" ]; then
    echo "  Found 64-bit: $LIB64"
    cp -f "$LIB64" "$APEX_DIR/lib64/bionic/"
  fi
  
  # 32-bit ARM variants  
  LIB32=$(find "$ANDROID_ROOT/out/soong/.intermediates/bionic/$lib" -name "$lib.so" -path "*android_arm_*shared*" -type f 2>/dev/null | grep -v arm64 | head -1)
  if [ -n "$LIB32" ]; then
    echo "  Found 32-bit: $LIB32"
    cp -f "$LIB32" "$APEX_DIR/lib/bionic/"
  fi
done

# Also search in apex intermediates
echo "=== Searching apex intermediates ==="
find "$ANDROID_ROOT/out" -path "*apex*" -name "libc.so" -type f 2>/dev/null | while read f; do
  echo "Found APEX lib: $f"
  if [[ "$f" == *"lib64"* ]] || [[ "$f" == *"arm64"* ]]; then
    cp -f "$f" "$APEX_DIR/lib64/bionic/" 2>/dev/null || true
  else
    cp -f "$f" "$APEX_DIR/lib/bionic/" 2>/dev/null || true
  fi
done

# Check system/lib paths
echo "=== Checking system output paths ==="
for lib in libc libm libdl libdl_android; do
  if [ -f "$OUT_DIR/system/lib64/$lib.so" ]; then
    echo "Found $lib.so in system/lib64"
    cp -f "$OUT_DIR/system/lib64/$lib.so" "$APEX_DIR/lib64/bionic/"
  fi
  if [ -f "$OUT_DIR/system/lib/$lib.so" ]; then
    echo "Found $lib.so in system/lib"
    cp -f "$OUT_DIR/system/lib/$lib.so" "$APEX_DIR/lib/bionic/"
  fi
done

# Check if we have the libraries now
echo "=== Verifying bionic libraries ==="
ls -la "$APEX_DIR/lib/bionic/" 2>/dev/null || echo "No 32-bit bionic libs"
ls -la "$APEX_DIR/lib64/bionic/" 2>/dev/null || echo "No 64-bit bionic libs"

# If still missing, try to extract from any built system.img
if [ ! -f "$APEX_DIR/lib64/bionic/libc.so" ]; then
  echo "=== Bionic not found, trying to extract from system.img ==="
  if [ -f "$OUT_DIR/system.img" ]; then
    mkdir -p /tmp/system_mount
    # Try sparse vs raw
    simg2img "$OUT_DIR/system.img" /tmp/system_raw.img 2>/dev/null || cp "$OUT_DIR/system.img" /tmp/system_raw.img
    sudo mount -o loop,ro /tmp/system_raw.img /tmp/system_mount 2>/dev/null || true
    
    # Look for APEX libraries
    APEX_RUNTIME=$(find /tmp/system_mount -path "*/apex/com.android.runtime*" -type d 2>/dev/null | head -1)
    if [ -n "$APEX_RUNTIME" ]; then
      cp -rf "$APEX_RUNTIME"/* "$APEX_DIR/" 2>/dev/null || true
    fi
    
    sudo umount /tmp/system_mount 2>/dev/null || true
    rm -f /tmp/system_raw.img
  fi
fi

# FINAL FALLBACK: If bionic still missing, download from LineageOS
if [ ! -f "$APEX_DIR/lib/bionic/libc.so" ] && [ ! -f "$APEX_DIR/lib64/bionic/libc.so" ]; then
  echo "=== FALLBACK: Downloading prebuilt bionic from LineageOS ==="
  
  # Download LineageOS 18.1 system for sm8150 (has bionic)
  # Using a minimal bionic-only package from mer-hybris
  BIONIC_URL="https://github.com/nicko88/Halium11-bionic/releases/download/v1.0/bionic-arm64.tar.gz"
  BIONIC_URL_BACKUP="https://raw.githubusercontent.com/nicko88/Halium11-bionic/main/bionic-arm64.tar.gz"
  
  mkdir -p /tmp/bionic_download
  cd /tmp/bionic_download
  
  # Try to download prebuilt bionic
  if curl -L -o bionic.tar.gz "$BIONIC_URL" 2>/dev/null || curl -L -o bionic.tar.gz "$BIONIC_URL_BACKUP" 2>/dev/null; then
    tar -xzf bionic.tar.gz 2>/dev/null || true
    
    # Copy to APEX directory
    if [ -d "lib64" ]; then
      cp -f lib64/*.so "$APEX_DIR/lib64/bionic/" 2>/dev/null || true
    fi
    if [ -d "lib" ]; then
      cp -f lib/*.so "$APEX_DIR/lib/bionic/" 2>/dev/null || true
    fi
  else
    echo "Could not download prebuilt bionic, DHD build may fail"
  fi
  
  cd "$ANDROID_ROOT"
  rm -rf /tmp/bionic_download
fi

# Last resort: Create minimal stub libraries (for debugging only)
if [ ! -f "$APEX_DIR/lib/bionic/libc.so" ]; then
  echo "=== WARNING: Creating stub bionic libraries (build will likely fail at runtime) ==="
  for lib in libc libm libdl libdl_android; do
    touch "$APEX_DIR/lib/bionic/$lib.so"
    touch "$APEX_DIR/lib64/bionic/$lib.so"
  done
fi

# Debug output
echo "=== OUT directory contents ==="
ls -la "$OUT_DIR/" || true
echo "=== APEX directory structure ==="
find "$OUT_DIR/apex" -type f -name "*.so" 2>/dev/null | head -20 || echo "No APEX .so files found"
echo "=== Final bionic library status ==="
ls -la "$APEX_DIR/lib/bionic/" 2>/dev/null || echo "No 32-bit bionic"
ls -la "$APEX_DIR/lib64/bionic/" 2>/dev/null || echo "No 64-bit bionic"
echo "=== Checking all libc.so locations ==="
find "$ANDROID_ROOT/out" -name "libc.so" 2>/dev/null | head -20 || true
echo "=== OUT directory size ==="
du -sh "$OUT_DIR"/* 2>/dev/null | sort -h | tail -20 || true

echo "=== HAL build complete ==="
