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
# NOTE: Disabled - needs local buildmw, will add in future iteration
#Requires: bluebinder

# Telephony - RIL binder for Android 11
Requires: ofono-ril-binder-plugin
Requires: dummy_netd

# NFC - binder plugin
# NOTE: Disabled - needs local buildmw, will add in future iteration
#Requires: nfcd-binder-plugin

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
# NOTE: Disabled - requires external/droidmedia from Android source tree
# which is not available in CI HAL artifacts. Camera/video won't work.
#Requires: gstreamer1.0-droid
#Requires: gmp-droid

# Dummy audioflinger for camera
# NOTE: Disabled - may not be in standard repos without community-adaptation
#Requires: audiosystem-passthrough-dummy-af

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
# NOTE: Disabled - needs binder variant buildmw for Android 11
#Requires: geoclue-provider-hybris

# FM Radio (Qualcomm)
# NOTE: Disabled - irisradio plugin may not be in standard repos
#Requires: qt5-qtmultimedia-plugin-mediaservice-irisradio
#Requires: jolla-mediaplayer-radio

# Flashlight
Requires: jolla-settings-system-flashlight

# Wi-Fi suspend on Qualcomm
# NOTE: Disabled - needs local buildmw, will add in future iteration
#Requires: sailfish-connman-plugin-suspend

%description -n patterns-sailfish-device-adaptation-raphael
Pattern with packages for raphael (Xiaomi Mi 9T Pro) HW Adaptation

%files -n patterns-sailfish-device-adaptation-raphael
