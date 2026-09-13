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
    echo "Не найден ~/.config/quickshell/ii — похоже, базовый illogical-impulse ещё не установлен."
    echo "Сначала поставь его: https://end-4.github.io/dots-hyprland/"
    echo "Потом запусти этот скрипт ещё раз, чтобы наложить TexFi поверх."
    exit 1
fi

echo "Бэкап текущих конфигов -> $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for d in hypr quickshell kitty fastfetch; do
    if [ -e "$HOME/.config/$d" ]; then
        cp -a "$HOME/.config/$d" "$BACKUP_DIR/"
    fi
done

echo "Копирую конфиги TexFi в ~/.config ..."
mkdir -p "$HOME/.config"
cp -a "$REPO_DIR/dots/.config/." "$HOME/.config/"

echo "Ставлю шрифт Press Start 2P ..."
mkdir -p "$HOME/.local/share/fonts/texfi"
cp -a "$REPO_DIR/texfi-fonts/PressStart2P-Regular.ttf" "$HOME/.local/share/fonts/texfi/"
fc-cache -f "$HOME/.local/share/fonts/texfi" >/dev/null 2>&1 || true

echo "Копирую обои TexFi kit v2 в ~/Pictures/texfi-wallpapers ..."
mkdir -p "$HOME/Pictures/texfi-wallpapers"
cp -a "$REPO_DIR/texfi-wallpapers/." "$HOME/Pictures/texfi-wallpapers/"

MATRIX_WALL="$HOME/Pictures/texfi-wallpapers/matrix/desktop/texfi-matrix-2560x1440-dark.png"
SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
if [ -f "$MATRIX_WALL" ] && [ -x "$SWITCHWALL" ]; then
    echo "Применяю matrix как обои по умолчанию ..."
    "$SWITCHWALL" "$MATRIX_WALL" || echo "Не получилось применить обои автоматически — выбери matrix вручную через селектор обоев."
else
    echo "Обои скопированы, но не применены автоматически — выбери texfi-matrix-2560x1440-dark.png через селектор обоев."
fi

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi
if pgrep -x qs >/dev/null 2>&1; then
    touch "$HOME/.config/quickshell/ii/shell.qml" 2>/dev/null || true
fi

echo
echo "Готово. Бэкап прежних конфигов лежит в $BACKUP_DIR — если что-то не понравится,"
echo "верни файлы оттуда обратно."
