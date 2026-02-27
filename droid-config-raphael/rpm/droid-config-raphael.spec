# droid-config-raphael spec file
# Xiaomi Mi 9T Pro (raphael) - SM8150

%define device raphael
%define vendor xiaomi
%define vendor_pretty Xiaomi
%define device_pretty Mi 9T Pro

# Screen dimensions (6.39" AMOLED 1080x2340)
%define pixel_ratio 2.25

# hybris-18.1 / Android 11
%define android_version_major 11

# Required by droid-configs.inc board mapping sed (even though template
# does not use %OTHERDEVICE%, RPM still expands the macro)
%define otherdevice %{device}

# droid-configs.inc contains all package definitions, build, install, files
%include droid-configs-device/droid-configs.inc
%include patterns/patterns-sailfish-device-adaptation-raphael.inc
%include patterns/patterns-sailfish-device-configuration-raphael.inc
