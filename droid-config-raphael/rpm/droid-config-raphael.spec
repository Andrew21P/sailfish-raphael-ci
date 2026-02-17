# droid-config-raphael spec file
# Xiaomi Mi 9T Pro (raphael) - SM8150

%define device raphael
%define vendor xiaomi
%define vendor_pretty Xiaomi
%define device_pretty Mi 9T Pro

%define dcd_common droid-configs-device
%define dcd_path ./

# Device-specific package configuration
%define have_modem 1
%define have_bluetooth 1
%define have_nfc 1
%define have_wifi 1
%define have_fm 1
%define have_vibrator 1
%define have_lights 1
%define have_sensors 1
%define have_fingerprint 0
%define have_camera 1
%define have_gps 1

# Screen dimensions (6.39" AMOLED 1080x2340)
%define pixel_ratio 2.25
%define icon_res 1.5

# HA config options - hybris-18.1 / API level 30
%define android_version_major 11
%define android_version_minor 0
%define android_version_patch 0

# Uses gbinder for newer Android compatibility
%define provides_own_board_mapping 1

%include %{dcd_common}/droid-configs-device.inc

Name: droid-config-%{device}
Version: 1.0.0
Release: 1
Summary: SailfishOS adaptation for %{vendor_pretty} %{device_pretty}
License: BSD
Group: Configs
BuildRequires: droid-hal-version-devel
Provides: sailfish-content-graphics-configuration-%{device}

%description
Configuration files for %{vendor_pretty} %{device_pretty} (codename %{device})
running SailfishOS with hybris-18.1

%include %{dcd_common}/droid-configs.inc
