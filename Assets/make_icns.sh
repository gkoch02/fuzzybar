#!/bin/zsh
# Renders the icon and packages it twice: Assets/AppIcon.icns for build.sh,
# and the PNG set in Resources/Assets.xcassets/AppIcon.appiconset for the
# Xcode project (App Store archives compile the icon from the catalog).
set -euo pipefail
cd "$(dirname "$0")"
swift make_icon.swift AppIcon-1024.png
SET="../Resources/Assets.xcassets/AppIcon.appiconset"
rm -rf AppIcon.iconset && mkdir AppIcon.iconset
for s in 16 32 128 256 512; do
  sips -z $s $s AppIcon-1024.png --out AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  d=$((s*2))
  sips -z $d $d AppIcon-1024.png --out AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
cp AppIcon.iconset/*.png "$SET/"
iconutil -c icns AppIcon.iconset -o AppIcon.icns
rm -rf AppIcon.iconset
echo "Wrote Assets/AppIcon.icns and $SET/*.png"
