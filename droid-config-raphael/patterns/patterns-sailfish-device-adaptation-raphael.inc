# Adaptation patterns for Xiaomi Mi 9T Pro (raphael)
# SailfishOS 5.0.x / hybris-18.1 (Android 11)

%package -n patterns-sailfish-device-adaptation-raphael
Summary: Jolla HW Adaptation raphael
Requires: droid-hal-raphael
Requires: droid-hal-raphael-img-boot
Requires: droid-hal-raphael-kernel-modules
Requires: droid-hal-raphael-detritus

# Hybris packages
Requires: libhybris-libEGL
Requires: libhybris-libGLESv2
Requires: libhybris-libwayland-egl
Recommends: libhybris-tests

# Bluetooth - use bluebinder for hybris-18.1
Requires: bluebinder

# Telephony - RIL binder for Android 11
Requires: ofono-ril-binder-plugin
Requires: dummy_netd

# NFC - binder plugin
Requires: nfcd-binder-plugin

# Sensors
Requires: hybris-libsensorfw-qt5

# Vibra
Requires: ngfd-plugin-native-vibrator
Requires: qt5-feedback-haptics-native-vibrator

# Touchscreen symlink
Requires: qt5-plugin-generic-evdev

# Audio - PulseAudio with HIDL for Android 11
Requires: pulseaudio-modules-droid
Requires: pulseaudio-modules-droid-hidl
# For audio recording:
Requires: qt5-qtmultimedia-plugin-mediaservice-gstmediacapture

# Display - HWC2 for SM8150
Requires: qt5-qtwayland-wayland_egl
Requires: qt5-qpa-hwcomposer-plugin
Requires: qtscenegraph-adaptation

# Camera/Video - gstreamer droid
Requires: gstreamer1.0-droid
Requires: gmp-droid

# Dummy audioflinger for camera
Requires: audiosystem-passthrough-dummy-af

# LED notifications
Requires: mce-plugin-libhybris

# USB mode
Requires: usb-moded

# RF control
Requires: rfkill

# Device lock
Requires: jolla-devicelock-daemon-encsfa

# Fingerprint (DISABLED - may need work for SM8150
#Requires: sailfish-fpd-community
#Requires: sailfish-devicelock-fpd
#Requires: droid-fake-crypt
#Requires: droid-biometry-fp

# GPS
Requires: geoclue-provider-hybris

# FM Radio (Qualcomm)
Requires: qt5-qtmultimedia-plugin-mediaservice-irisradio
Requires: jolla-mediaplayer-radio

# Flashlight
Requires: jolla-settings-system-flashlight

# Wi-Fi suspend on Qualcomm
Requires: sailfish-connman-plugin-suspend

%description -n patterns-sailfish-device-adaptation-raphael
Pattern with packages for raphael (Xiaomi Mi 9T Pro) HW Adaptation

%files -n patterns-sailfish-device-adaptation-raphael
