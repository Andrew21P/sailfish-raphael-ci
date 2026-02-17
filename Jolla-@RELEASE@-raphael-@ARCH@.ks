# SailfishOS kickstart file for Xiaomi Mi 9T Pro (raphael)
# hybris-18.1 (Android 11) / SM8150 Snapdragon 855

lang en_US.UTF-8
keyboard us
timezone --utc UTC

### Repositories
repo --name=adaptation-community-common-raphael-@RELEASE@ --baseurl=https://repo.sailfishos.org/obs/nemo:/devel:/hw:/common/sailfish_latest_@ARCH@/
repo --name=adaptation-community-raphael-@RELEASE@ --baseurl=file://@REPO@
repo --name=apps-@RELEASE@ --baseurl=https://releases.jolla.com/jolla-apps/@RELEASE@/@ARCH@/
repo --name=hotfixes-@RELEASE@ --baseurl=https://releases.jolla.com/releases/@RELEASE@/hotfixes/@ARCH@/
repo --name=jolla-@RELEASE@ --baseurl=https://releases.jolla.com/releases/@RELEASE@/jolla/@ARCH@/

### Packages
%packages
@Jolla Configuration raphael

### For debug, add these
jolla-developer-mode
strace
vim-enhanced
less
openssh-server
openssh-clients
zypper
mce-tools
libgbinder-tools
unzip

%end

%pre --erroronfail
export SSU_RELEASE_TYPE=release
touch $INSTALL_ROOT/.bootstrap
%end

%post --erroronfail
# Set proper permissions for android directories
mkdir -p /system /vendor /firmware /persist /dsp /bt_firmware

# Fix /etc/hosts
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts

# Without this line the rpm does not get the architecture
echo -n "@ARCH@-meego-linux" > /etc/rpm/platform

# Also libzypp has problems in defaults
echo "arch = @ARCH@" >> /etc/zypp/zypp.conf

# Configure machine-id
rm -f /etc/machine-id
systemd-machine-id-setup

# Enable required services
systemctl enable usb-moded.service
systemctl enable connman.service
systemctl enable ofono.service
systemctl enable bluetooth.service
systemctl enable droid-hal-init.service

# Set proper hostname
echo "raphael" > /etc/hostname

%end

%post --nochroot
if [ -n "@EXTRA_NAME@" ]; then
  mkdir -p $INSTALL_ROOT/home/.jolla
  echo @EXTRA_NAME@ > $INSTALL_ROOT/home/.jolla/extra
fi
%end

%pack
# This section is run when packaging the image as .tar.bz2
%end
