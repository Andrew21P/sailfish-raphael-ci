#!/bin/bash

set -x

source /home/mersdk/work/ci/ci/hadk.env
export ANDROID_ROOT=/home/mersdk/work/ci/ci/hadk_17.1

sudo chown -R $(whoami):$(whoami) /home/mersdk/work/ci/ci
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
sed -i '/mer_verify_kernel_config/,/\.config$/d' rpm/dhd/droid-hal-device.inc
sed -i 's/echo Verifying kernel config/echo "SKIPPING kernel config check"/' rpm/dhd/droid-hal-device.inc

sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in -y ccache python
sudo zypper in -y python

# dhd hack - use custom helpers
cd $ANDROID_ROOT
cp /home/mersdk/work/ci/ci/helpers/*.sh rpm/dhd/helpers/
chmod +x rpm/dhd/helpers/*.sh

git config --global user.email "ci@github.com"
git config --global user.name "Github Actions"
git config --global --add safe.directory /home/mersdk/work/ci/ci

cd $ANDROID_ROOT
sudo mkdir -p /proc/sys/fs/binfmt_misc/
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

rpm/dhd/helpers/build_packages.sh

if [ "$?" -ne 0 ];then
  # if failed, show errors
  cat $ANDROID_ROOT/droid-hal-$DEVICE.log | grep -E "ERROR|error:" | tail -50
fi
