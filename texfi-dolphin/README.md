# Распаковка архивов в Dolphin (zip, rar, 7z, tar.*)

- `texfi-extract` → `~/.local/bin/` (нужны `unrar`, `7z`, `bsdtar`; Ark не нужен)
- `texfi-extract.desktop` → `~/.local/share/kio/servicemenus/` (и `chmod +x`)

Пункты меню: «Распаковать здесь», «Распаковать в папку». Для защищённых паролем архивов спрашивает пароль через kdialog.
