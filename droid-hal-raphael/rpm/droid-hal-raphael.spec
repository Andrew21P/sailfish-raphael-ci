# droid-hal-raphael spec file
# Xiaomi Mi 9T Pro (raphael) - SM8150 / Snapdragon 855

%define device raphael
%define vendor xiaomi

# Define Android version - hybris-18.1 is Android 11
%define android_version_major 11

%define installable_zip 1
%define enable_kernel_update 1
%define enable_bootctl 0

# Straggler files cleanup
%define straggler_files \
    /init.recovery.qcom.rc \
    /ueventd.qcom.rc \
    %{nil}

%include rpm/dhd/droid-hal-device.inc

# Override for SM8150 specific paths
%define __provides_exclude_from ^/system/.*$
%define __requires_exclude ^/system/.*$
