#!/bin/bash

set -x

source /home/mersdk/work/sailfish-raphael-ci/sailfish-raphael-ci/hadk.env
export ANDROID_ROOT=/home/mersdk/work/sailfish-raphael-ci/sailfish-raphael-ci/hadk_18.1

sudo chown -R $(whoami):$(whoami) /home/mersdk/work/sailfish-raphael-ci/sailfish-raphael-ci
cd $ANDROID_ROOT

cd ~/.scratchbox2
cp -R SailfishOS-*-$PORT_ARCH $VENDOR-$DEVICE-$PORT_ARCH
cd $VENDOR-$DEVICE-$PORT_ARCH
sed -i "s/SailfishOS-$SAILFISH_VERSION/$VENDOR-$DEVICE/g" sb2.config
sudo ln -s /srv/mer/targets/SailfishOS-$SAILFISH_VERSION-$PORT_ARCH /srv/mer/targets/$VENDOR-$DEVICE-$PORT_ARCH
sudo ln -s /srv/mer/toolings/SailfishOS-$SAILFISH_VERSION /srv/mer/toolings/$VENDOR-$DEVICE

# 3.3.0.16 hack - give write permission to boot
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R chmod 777 /boot

sdk-assistant list

cd $ANDROID_ROOT

# Remove kernel config check that requires full kernel source
sed -i '/mer_verify_kernel_config/,/\.config$/d' rpm/dhd/droid-hal-device.inc || true
sed -i 's/echo Verifying kernel config/echo "SKIPPING kernel config check"/' rpm/dhd/droid-hal-device.inc || true

sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in -y ccache python
sudo zypper in -y python

# dhd hack - use custom helpers
cd $ANDROID_ROOT
cp /home/mersdk/work/sailfish-raphael-ci/sailfish-raphael-ci/helpers/*.sh rpm/dhd/helpers/ || true
chmod +x rpm/dhd/helpers/*.sh || true

git config --global user.email "ci@github.com"
git config --global user.name "Github Actions"
git config --global --add safe.directory /home/mersdk/work/sailfish-raphael-ci/sailfish-raphael-ci

cd $ANDROID_ROOT
sudo mkdir -p /proc/sys/fs/binfmt_misc/
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

# Copy kickstart file to the expected location 
KS_SRC=/home/mersdk/work/sailfish-raphael-ci/sailfish-raphael-ci/Jolla-@RELEASE@-$DEVICE-@ARCH@.ks
if [ -f "$KS_SRC" ]; then
    echo "Copying kickstart file from $KS_SRC"
    mkdir -p $ANDROID_ROOT/../
    cp "$KS_SRC" "$ANDROID_ROOT/../Jolla-@RELEASE@-$DEVICE-@ARCH@.ks"
fi

# Build all packages including the image 
rpm/dhd/helpers/build_packages.sh

if [ "$?" -ne 0 ];then
  # if failed, show errors
  cat $ANDROID_ROOT/droid-hal-$DEVICE.log | grep -E "ERROR|error:" | tail -50
fi
#------------------------------------------
# Package the rootfs into flashable ZIP
#------------------------------------------
echo "=================================================="
echo "Creating flashable ZIP using hybris-installer..."
echo "=================================================="

# Find the MIC output directory (SailfishOScommunity-release-* or similar)
IMG_DIR=""
for d in "$ANDROID_ROOT/SailfishOScommunity-release-"*/ "$ANDROID_ROOT/SailfishOS-"*/; do
    if [ -d "$d" ]; then
        IMG_DIR="$d"
        break
    fi
done

if [ -z "$IMG_DIR" ] || [ ! -d "$IMG_DIR" ]; then
    echo "ERROR: MIC output directory not found, skipping ZIP creation"
    exit 0
fi

# Copy pack_package-droid-updater to MIC output
PACK_SCRIPT="$ANDROID_ROOT/hybris/droid-configs/kickstart/pack_package-droid-updater"
if [ -f "$PACK_SCRIPT" ]; then
    # Substitute device token
    sed -e "s/@DEVICE@/$DEVICE/g" \
        -e "s/@EXTRA_NAME@/$EXTRA_NAME/g" \
        "$PACK_SCRIPT" > "/tmp/pack_package-droid-updater"
    chmod +x /tmp/pack_package-droid-updater
    
    # Set environment and run packaging
    export IMG_OUT_DIR="$IMG_DIR"
    cd "$ANDROID_ROOT"
    bash /tmp/pack_package-droid-updater
    
    echo "=================================================="
    echo "ZIP creation complete! Files:"
    ls -la "$IMG_DIR"/*.zip 2>/dev/null || echo "No ZIP files found"
    echo "=================================================="
else
    echo "WARNING: pack_package-droid-updater not found at $PACK_SCRIPT"
fi