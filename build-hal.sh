#!/bin/bash
set -x

source hadk.env

# jdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

# hack for droidmedia
cd $ANDROID_ROOT
rm -rf external/droidmedia
git clone --recurse-submodules https://github.com/sailfishos/droidmedia.git external/droidmedia
cd external/droidmedia
git checkout 0.20230605.1
echo 'MINIMEDIA_AUDIOPOLICYSERVICE_ENABLE := 1' > env.mk
echo 'AUDIOPOLICYSERVICE_ENABLE := 1' >> env.mk

cd $ANDROID_ROOT/external
git clone --recurse-submodules https://github.com/mer-hybris/libhybris.git

# hybris-patches
cd $ANDROID_ROOT
hybris-patches/apply-patches.sh --mb

cd $ANDROID_ROOT
source build/envsetup.sh 2>&1
breakfast $DEVICE || lunch lineage_$DEVICE-userdebug || true

# get more space
rm -rf .repo

# Build hybris-hal and droidmedia
make -j$(nproc --all) hybris-hal droidmedia
