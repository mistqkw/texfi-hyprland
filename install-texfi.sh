#!/usr/bin/env bash
# TexFi «hairline» installer for end-4/dots-hyprland (illogical-impulse).
#
# This does NOT install Hyprland/Quickshell/matugen themselves — it assumes the
# base illogical-impulse shell is already installed
# (https://end-4.github.io/dots-hyprland/). It lays the TexFi configs, fonts,
# wallpaper and Dolphin archive menu on top, and backs up what it replaces.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/texfi-hypr-backup-$(date +%Y-%m-%d_%H%M%S)"
WALL_DIR="$HOME/Pictures/texfi-wallpapers"
WALL="$WALL_DIR/hairline/texfi-hairline-1920x1080.png"
SHELL_CFG="$HOME/.config/illogical-impulse/config.json"

if [ -t 1 ] && [ -f "$REPO_DIR/texfi-banner.txt" ]; then
    cat "$REPO_DIR/texfi-banner.txt"
fi

if [ ! -d "$HOME/.config/quickshell/ii" ]; then
    echo "Could not find ~/.config/quickshell/ii — base illogical-impulse isn't installed yet."
    echo "Install it first: https://end-4.github.io/dots-hyprland/"
    echo "Then run this script again to lay TexFi on top."
    exit 1
fi

echo "Backing up current configs -> $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for d in hypr quickshell kitty fastfetch fuzzel matugen wlogout gtk-3.0 gtk-4.0 illogical-impulse; do
    if [ -e "$HOME/.config/$d" ]; then cp -a "$HOME/.config/$d" "$BACKUP_DIR/"; fi
done
if [ -e "$HOME/.config/kdeglobals" ]; then cp -a "$HOME/.config/kdeglobals" "$BACKUP_DIR/"; fi

echo "Copying TexFi configs ..."
mkdir -p "$HOME/.config" "$HOME/.local"
cp -a "$REPO_DIR/dots/.config/." "$HOME/.config/"
if [ -d "$REPO_DIR/dots/.local" ]; then cp -a "$REPO_DIR/dots/.local/." "$HOME/.local/"; fi

echo "Installing fonts (Unbounded, Inter) ..."
mkdir -p "$HOME/.local/share/fonts/texfi"
cp -a "$REPO_DIR"/texfi-fonts/*.ttf "$HOME/.local/share/fonts/texfi/"
fc-cache -f "$HOME/.local/share/fonts/texfi" >/dev/null 2>&1 || true
if ! fc-list | grep -qi "JetBrains"; then
    echo "  note: JetBrains Mono (Nerd) not found — install ttf-jetbrains-mono-nerd for the mono labels."
fi

echo "Copying wallpapers -> $WALL_DIR ..."
mkdir -p "$WALL_DIR"
cp -a "$REPO_DIR/texfi-wallpapers/." "$WALL_DIR/"

echo "Installing Dolphin archive menu (Extract here / Extract to folder) ..."
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kio/servicemenus"
cp -a "$REPO_DIR/texfi-dolphin/texfi-extract" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/texfi-extract"
sed "s|@HOME@|$HOME|g" "$REPO_DIR/texfi-dolphin/texfi-extract.desktop" \
    > "$HOME/.local/share/kio/servicemenus/texfi-extract.desktop"
chmod +x "$HOME/.local/share/kio/servicemenus/texfi-extract.desktop"
if ! command -v unrar >/dev/null 2>&1 && ! command -v 7z >/dev/null 2>&1; then
    echo "  note: install unrar / p7zip / libarchive to unpack rar and 7z."
fi

# Shell settings: fonts, fixed desktop clock, no dock, quiet terminal/Qt theming.
if command -v jq >/dev/null 2>&1 && [ -f "$SHELL_CFG" ]; then
    echo "Patching $SHELL_CFG ..."
    tmp="$(mktemp)"
    jq '
      .appearance.fonts.main = "Inter" | .appearance.fonts.numbers = "Inter"
      | .appearance.fonts.title = "Unbounded"
      | .appearance.wallpaperTheming.enableQtApps = false
      | .appearance.wallpaperTheming.enableTerminal = false
      | .dock.enable = false
      | .background.widgets.clock.enable = true
      | .background.widgets.clock.style = "digital"
      | .background.widgets.clock.styleLocked = "digital"
      | .background.widgets.clock.digital.font = {family:"Unbounded",roundness:0,size:120,weight:600,width:100}
    ' "$SHELL_CFG" > "$tmp" && mv "$tmp" "$SHELL_CFG"
fi

SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
if [ -f "$WALL" ] && [ -x "$SWITCHWALL" ]; then
    echo "Applying the hairline wallpaper ..."
    "$SWITCHWALL" --image "$WALL" --mode dark \
        || echo "Couldn't apply the wallpaper automatically — pick it from the wallpaper selector."
fi

if command -v hyprctl >/dev/null 2>&1; then hyprctl reload >/dev/null 2>&1 || true; fi
if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
    touch "$HOME/.config/quickshell/ii/shell.qml" 2>/dev/null || true
fi

echo
echo "Done. Previous configs are backed up at $BACKUP_DIR."
echo "New fonts load fully after a shell restart: log out and back in, or run 'qs kill; qs -c ii &'."
echo "Keyboard layout, monitors and keybinds were not touched — edit ~/.config/hypr/custom/ for those."
