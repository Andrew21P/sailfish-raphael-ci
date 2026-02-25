#!/bin/bash
# DHD build setup script for SailfishOS on raphael
# This script is called from the GitHub Actions workflow
set -e

echo "=== Setup DHD build for hybris-18.1 ==="
echo "ANDROID_ROOT: $ANDROID_ROOT"
echo "DEVICE: $DEVICE"
echo "WORKSPACE: $WORKSPACE"

cd $ANDROID_ROOT
rm -rf .repo || true

# Create generated_android_filesystem_config.h - FULLY SELF-CONTAINED
cat > "$ANDROID_ROOT/generated_android_filesystem_config.h" << 'EOF'
#pragma once
// Fully self-contained android_ids definition for hybris builds.
// AID values from Android 11 (R) - NO external dependencies.

struct android_id_info { const char* name; unsigned aid; };

static const struct android_id_info android_ids[] = {
    { "root",          0 },
    { "system",        1000 },
    { "radio",         1001 },
    { "bluetooth",     1002 },
    { "graphics",      1003 },
    { "input",         1004 },
    { "audio",         1005 },
    { "camera",        1006 },
    { "log",           1007 },
    { "compass",       1008 },
    { "mount",         1009 },
    { "wifi",          1010 },
    { "adb",           1011 },
    { "install",       1012 },
    { "media",         1013 },
    { "dhcp",          1014 },
    { "sdcard_rw",     1015 },
    { "vpn",           1016 },
    { "keystore",      1017 },
    { "usb",           1018 },
    { "drm",           1019 },
    { "mdnsr",         1020 },
    { "gps",           1021 },
    { "media_rw",      1023 },
    { "mtp",           1024 },
    { "nfc",           1027 },
    { "sdcard_r",      1028 },
    { "clat",          1029 },
    { "loop_radio",    1030 },
    { "mediadrm",      1031 },
    { "package_info",  1032 },
    { "sdcard_pics",   1033 },
    { "sdcard_av",     1034 },
    { "sdcard_all",    1035 },
    { "logd",          1036 },
    { "shared_relro",  1037 },
    { "dbus",          1038 },
    { "tlsdate",       1039 },
    { "mediaex",       1040 },
    { "audioserver",   1041 },
    { "metrics_coll",  1042 },
    { "metricsd",      1043 },
    { "webserv",       1044 },
    { "debuggerd",     1045 },
    { "mediacodec",    1046 },
    { "cameraserver",  1047 },
    { "firewall",      1048 },
    { "trunks",        1049 },
    { "nvram",         1050 },
    { "dns",           1051 },
    { "dns_tether",    1052 },
    { "webview_zygote",1053 },
    { "vehicle_network",1054 },
    { "media_audio",   1055 },
    { "media_video",   1056 },
    { "media_image",   1057 },
    { "tombstoned",    1058 },
    { "media_obb",     1059 },
    { "ese",           1060 },
    { "ota_update",    1061 },
    { "automotive_evs",1062 },
    { "lowpan",        1063 },
    { "hsm",           1064 },
    { "reserved_disk", 1065 },
    { "statsd",        1066 },
    { "incidentd",     1067 },
    { "secure_element",1068 },
    { "lmkd",          1069 },
    { "llkd",          1070 },
    { "iorapd",        1071 },
    { "gpu_service",   1072 },
    { "network_stack", 1073 },
    { "gsid",          1074 },
    { "fsverity_cert", 1075 },
    { "credstore",     1076 },
    { "external_storage",1077 },
    { "ext_data_rw",   1078 },
    { "ext_obb_rw",    1079 },
    { "context_hub",   1080 },
    { "virtualizationservice",1081 },
    { "shell",         2000 },
    { "cache",         2001 },
    { "diag",          2002 },
    { "oem_reserved_start", 2900 },
    { "oem_reserved_end",   2999 },
    { "net_bt_admin",  3001 },
    { "net_bt",        3002 },
    { "inet",          3003 },
    { "net_raw",       3004 },
    { "net_admin",     3005 },
    { "net_bw_stats",  3006 },
    { "net_bw_acct",   3007 },
    { "readproc",      3009 },
    { "wakelock",      3010 },
    { "uhid",          3011 },
    { "everybody",     9997 },
    { "misc",          9998 },
    { "nobody",        9999 },
};

static const unsigned int android_id_count = sizeof(android_ids) / sizeof(android_ids[0]);
EOF

#------------------------------------------
# Set git identity
#------------------------------------------
git config --global user.email "ci@github.com"
git config --global user.name "Github Actions"

# Clone hybris-installer
git clone https://github.com/sailfish-on-ginkgo/hybris-installer.git \
  $ANDROID_ROOT/hybris/hybris-installer || true

# Fix permissions on scripts from artifact
chmod +x "$ANDROID_ROOT/build/make/tools/fs_config/fs_config_generator.py" 2>/dev/null || true
find "$ANDROID_ROOT/build" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
chmod +x "$ANDROID_ROOT/hybris/hybris-boot/fixup-mountpoints" 2>/dev/null || true
find "$ANDROID_ROOT/hybris/hybris-boot" -type f -exec chmod +x {} \; 2>/dev/null || true

# Create system/core/base symlink
if [ -d "$ANDROID_ROOT/system/libbase" ] && [ ! -d "$ANDROID_ROOT/system/core/base" ]; then
  mkdir -p "$ANDROID_ROOT/system/core"
  ln -sf "$ANDROID_ROOT/system/libbase" "$ANDROID_ROOT/system/core/base"
fi

# Create ALL dummy updater files
DEVICE_OUT="$ANDROID_ROOT/out/target/product/$DEVICE"
mkdir -p "$DEVICE_OUT/system/bin"
mkdir -p "$DEVICE_OUT/system/etc/init/hw"
mkdir -p "$DEVICE_OUT/obj/ROOT/hybris-boot_intermediates"

# Dummy updater binary
echo '#!/bin/sh' > "$DEVICE_OUT/system/bin/updater"
chmod +x "$DEVICE_OUT/system/bin/updater"

# Dummy hybris-updater-script
cat > "$DEVICE_OUT/hybris-updater-script" << 'EOF'
ui_print("Sailfish OS for raphael");
ui_print("Installing...");
EOF

# Dummy hybris-updater-unpack.sh
cat > "$DEVICE_OUT/hybris-updater-unpack.sh" << 'EOF'
#!/bin/sh
# Placeholder - real script provided by hybris-installer
EOF
chmod +x "$DEVICE_OUT/hybris-updater-unpack.sh"

# Dummy init binary
echo '#!/bin/sh' > "$DEVICE_OUT/system/bin/init"
chmod +x "$DEVICE_OUT/system/bin/init"

# Dummy init.rc files
touch "$DEVICE_OUT/system/etc/init/servicemanager.rc"
touch "$DEVICE_OUT/system/etc/init/hw/init.rc"
touch "$DEVICE_OUT/system/etc/init/hw/init.zygote64.rc"
touch "$DEVICE_OUT/system/etc/init/apexd.rc"
touch "$DEVICE_OUT/system/etc/init/hybris_extras.rc"

# Dummy boot-initramfs.gz
gzip -n < /dev/null > "$DEVICE_OUT/obj/ROOT/hybris-boot_intermediates/boot-initramfs.gz"

# Dummy kernel
touch "$DEVICE_OUT/kernel"

# Copy droid-hal-raphael
mkdir -p $ANDROID_ROOT/rpm
cp -r $WORKSPACE/droid-hal-raphael/rpm/* $ANDROID_ROOT/rpm/
cd $ANDROID_ROOT/rpm
git init && git add -A && git commit -m "init" || true
git clone https://github.com/mer-hybris/droid-hal-device.git $ANDROID_ROOT/rpm/dhd --depth=1

# Patch DHD to force Android 11 detection
sed -i 's/^%build$/\n%build\n# Force Android 11 mode for hybris-18.1\nandroid_version_major=11\n/' \
  $ANDROID_ROOT/rpm/dhd/droid-hal-device.inc

# Patch usergroupgen.c
sed -i 's|#include.*android_filesystem_config\.h.*|#include "generated_android_filesystem_config.h"|' \
  $ANDROID_ROOT/rpm/dhd/helpers/usergroupgen.c

cp "$ANDROID_ROOT/generated_android_filesystem_config.h" "$ANDROID_ROOT/rpm/dhd/helpers/"

# Copy droid-config-raphael
mkdir -p $ANDROID_ROOT/hybris/droid-configs
cp -r $WORKSPACE/droid-config-raphael/* $ANDROID_ROOT/hybris/droid-configs/
cd $ANDROID_ROOT/hybris/droid-configs
git init && git add -A && git commit -m "init" || true
git clone https://github.com/mer-hybris/droid-hal-configs.git $ANDROID_ROOT/hybris/droid-configs/droid-configs-device --depth=1

# Copy droid-hal-version-raphael
mkdir -p $ANDROID_ROOT/hybris/droid-hal-version-raphael
cp -r $WORKSPACE/droid-hal-version-raphael/* $ANDROID_ROOT/hybris/droid-hal-version-raphael/
cd $ANDROID_ROOT/hybris/droid-hal-version-raphael
git init && git add -A && git commit -m "init" || true
git clone https://github.com/mer-hybris/droid-hal-version.git $ANDROID_ROOT/hybris/droid-hal-version-raphael/rpm/droid-hal-version --depth=1

#------------------------------------------
# Setup Docker workspace
#------------------------------------------
sudo mkdir -p /home/runner/work/sailfish-raphael-ci/sailfish-raphael-ci/docker

#------------------------------------------
# Copy helpers scripts
#------------------------------------------
cd "$WORKSPACE"
chmod +x build-rpm.sh || true
chmod +x helpers/*.sh || true

echo "=== DHD setup complete ==="
