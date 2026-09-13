#!/usr/bin/env bash
# TexFi skin installer for end-4/dots-hyprland (illogical-impulse).
#
# This does NOT install Hyprland/Quickshell/matugen/kitty/fastfetch
# themselves — it assumes the base illogical-impulse shell is already
# installed (via the upstream installer: https://end-4.github.io/dots-hyprland/).
# It only overlays the TexFi-reskinned config files and wallpapers on top.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/texfi-hypr-backup-$(date +%Y-%m-%d_%H%M%S)"

if [ -t 1 ]; then
    cat "$REPO_DIR/texfi-banner.txt"
fi

if [ ! -d "$HOME/.config/quickshell/ii" ]; then
    echo "Could not find ~/.config/quickshell/ii — looks like base illogical-impulse isn't installed yet."
    echo "Install it first: https://end-4.github.io/dots-hyprland/"
    echo "Then run this script again to lay TexFi on top."
    exit 1
fi

echo "Backing up current configs -> $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for d in hypr quickshell kitty fastfetch; do
    if [ -e "$HOME/.config/$d" ]; then
        cp -a "$HOME/.config/$d" "$BACKUP_DIR/"
    fi
done

echo "Copying TexFi configs into ~/.config ..."
mkdir -p "$HOME/.config"
cp -a "$REPO_DIR/dots/.config/." "$HOME/.config/"

echo "Installing Press Start 2P font ..."
mkdir -p "$HOME/.local/share/fonts/texfi"
cp -a "$REPO_DIR/texfi-fonts/PressStart2P-Regular.ttf" "$HOME/.local/share/fonts/texfi/"
fc-cache -f "$HOME/.local/share/fonts/texfi" >/dev/null 2>&1 || true

echo "Copying TexFi kit v2 wallpapers into ~/Pictures/texfi-wallpapers ..."
mkdir -p "$HOME/Pictures/texfi-wallpapers"
cp -a "$REPO_DIR/texfi-wallpapers/." "$HOME/Pictures/texfi-wallpapers/"

MATRIX_WALL="$HOME/Pictures/texfi-wallpapers/matrix/desktop/texfi-matrix-2560x1440-dark.png"
SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
if [ -f "$MATRIX_WALL" ] && [ -x "$SWITCHWALL" ]; then
    echo "Applying matrix as the default wallpaper ..."
    "$SWITCHWALL" "$MATRIX_WALL" || echo "Couldn't apply the wallpaper automatically — pick matrix manually from the wallpaper selector."
else
    echo "Wallpapers copied, but not applied automatically — pick texfi-matrix-2560x1440-dark.png from the wallpaper selector."
fi

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi
if pgrep -x qs >/dev/null 2>&1; then
    touch "$HOME/.config/quickshell/ii/shell.qml" 2>/dev/null || true
fi

echo
echo "Done. Your previous configs are backed up at $BACKUP_DIR —"
echo "if something looks wrong, restore files from there."
