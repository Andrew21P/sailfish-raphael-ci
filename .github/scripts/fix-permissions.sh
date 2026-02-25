#!/bin/bash
# Fix permissions for artifact upload
set -e

OUT_DIR="$ANDROID_ROOT/out/target/product/$DEVICE"

echo "=== Fixing permissions for artifact upload ==="

# Remove device node directories that can't be archived
sudo rm -rf "$OUT_DIR/root/d" "$OUT_DIR/root/dev" "$OUT_DIR/vendor/d" "$OUT_DIR/vendor/dev" || true

# Remove other problematic device nodes and sockets
find "$OUT_DIR" -type b -delete 2>/dev/null || true
find "$OUT_DIR" -type c -delete 2>/dev/null || true
find "$OUT_DIR" -type s -delete 2>/dev/null || true
find "$OUT_DIR" -type p -delete 2>/dev/null || true

# Force readable permissions on everything else
sudo chmod -R 755 "$OUT_DIR" || true

# Show final size
echo "=== Final artifact directories ==="
du -sh "$OUT_DIR" "$ANDROID_ROOT/out/soong" 2>/dev/null || true
