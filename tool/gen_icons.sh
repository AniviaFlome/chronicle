#!/usr/bin/env bash
# Regenerate launcher icon PNGs from the SVG masters in assets/icon/.
# Requires ImageMagick (available in the nix devShell).
# Run from the repo root:  bash tool/gen_icons.sh
# Then: flutter pub run icons_launcher:create
set -euo pipefail
cd "$(dirname "$0")/.."

# Adaptive foreground (= legacy icon: rounded tile + calendar on
# transparency; outside the tile stays transparent).
magick -background none -density 384 assets/icon/icon_fg.svg \
  -resize 1024x1024 assets/icon/icon_foreground.png

# Monochrome (Android 13+ themed icon): solid glyph silhouette.
magick -background none -density 384 assets/icon/icon_mono.svg \
  -resize 1024x1024 assets/icon/icon_monochrome.png

# Adaptive background: fully transparent (launcher mask / wallpaper
# shows around the tile).
magick -size 1024x1024 xc:none assets/icon/icon_background.png

magick identify assets/icon/icon_foreground.png assets/icon/icon_monochrome.png assets/icon/icon_background.png
