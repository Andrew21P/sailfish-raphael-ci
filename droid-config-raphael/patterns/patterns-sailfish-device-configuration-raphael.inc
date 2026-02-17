# Configuration patterns for Xiaomi Mi 9T Pro (raphael)
# SailfishOS 5.0.x / hybris-18.1 (Android 11)

%package -n patterns-sailfish-device-configuration-raphael
Summary: Jolla Configuration raphael
Requires: patterns-sailfish-device-configuration-common-raphael
Requires: patterns-sailfish-device-adaptation-raphael

Requires: droid-config-raphael-sailfish
Requires: droid-config-raphael-pulseaudio-settings
Requires: droid-config-raphael-policy-settings
Requires: droid-config-raphael-preinit-plugin
Requires: droid-config-raphael-flashing
Requires: droid-config-raphael-bluez5
Requires: droid-hal-version-raphael

Requires: patterns-sailfish-cellular-apps

# Dev tools (exploded pattern for development)
Recommends: jolla-developer-mode
Recommends: strace
Recommends: gdb
Recommends: gdb-gdbserver
Recommends: vim-enhanced
Recommends: less
Recommends: valgrind
Recommends: lipstick-qt5-tools
Recommends: libhybris-tests
Recommends: busybox-static
Recommends: openssh-server
Recommends: zypper
Recommends: libgbinder-tools
Recommends: unzip
Recommends: mce-tools

# Enable USB early for development
Requires: jolla-rnd-device

# Jolla apps
Requires: sailfish-office
Requires: jolla-calculator
Requires: jolla-email
Requires: jolla-notes
Requires: jolla-clock
Requires: jolla-mediaplayer
Requires: jolla-calendar
#Requires: sailfish-weather

# NFC settings
Requires: jolla-settings-system-nfc
Requires: nfcd-binder-plugin
Requires: nfcd-mce-plugin

# Screen resolution icons (1.5x for 1080p AMOLED)
Requires: sailfish-content-graphics-z%{icon_res}

# Dual SIM
Requires: jolla-settings-networking-multisim

# 3rd party accounts  
Requires: jolla-settings-accounts-extensions-3rd-party-all

# Mozilla location services
Requires: geoclue-provider-mlsdb

# Jolla Store
Requires: patterns-sailfish-consumer-generic

Requires: mapplauncherd-booster-silica-qt5-media

%description -n patterns-sailfish-device-configuration-raphael
Pattern with packages for raphael configurations

%files -n patterns-sailfish-device-configuration-raphael
