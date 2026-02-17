#!/bin/sh
# Get Bluetooth MAC address for Xiaomi Mi 9T Pro (raphael)
# Reads from persist partition or generates from wifi mac

BT_MAC_FILE="/persist/bluetooth/.bt_nv.bin"
WIFI_MAC_FILE="/sys/class/net/wlan0/address"

if [ -f "$BT_MAC_FILE" ]; then
    # Read from persist partition (typical Qualcomm location)
    dd if="$BT_MAC_FILE" bs=1 skip=2 count=6 2>/dev/null | xxd -p | sed 's/\(..\)/\1:/g; s/:$//' | tr 'a-f' 'A-F'
elif [ -f "$WIFI_MAC_FILE" ]; then
    # Generate from WiFi MAC (increment last octet by 1)
    WIFI_MAC=$(cat "$WIFI_MAC_FILE" | tr 'a-f' 'A-F')
    # Add 1 to make it different from WiFi
    echo "$WIFI_MAC" | awk -F: '{printf "%s:%s:%s:%s:%s:%02X\n", $1, $2, $3, $4, $5, strtonum("0x"$6)+1}'
else
    # Fallback: generate random local MAC
    head -c 6 /dev/urandom | xxd -p | sed 's/\(..\)/\1:/g; s/:$//' | sed 's/^./2/' | tr 'a-f' 'A-F'
fi
