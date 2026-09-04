#!/usr/bin/env bash
# Tire un fond d'ecran au hasard au demarrage de la session.
#
# Appele depuis custom/execs.lua sur hyprland.start.
#
# On delegue a QuickShell via son global "wallpaperSelectorRandom" -- le meme
# que CTRL+SUPER+ALT+T -- au lieu d'appeler switchwall.sh directement.
#
# POURQUOI, et c'est le coeur du sujet : switchwall.sh veut un --mode explicite.
# Sans lui, il devine avec
#     gsettings get org.gnome.desktop.interface color-scheme
# qui repond "No schemas installed" sur cette machine ; il retombe alors sur
# LIGHT (switchwall.sh, "Determine mode if not set") et toute la palette passe
# en clair. QuickShell, lui, passe toujours --mode dark|light
# (services/Wallpapers.qml) d'apres son propre etat, lui-meme deduit de la
# palette courante (services/MaterialThemeLoader.qml : background hslLightness
# < 0.5). Le mode sombre se conserve donc d'un boot au suivant.
#
# Bonus : le tirage, le dossier courant et le mode restent geres a un seul
# endroit, celui qu'end-4 maintient.

set -euo pipefail

# "ii" = nom du dossier de config QuickShell. Cote Hyprland c'est $qsConfig,
# mais cette variable appartient a hyprlang, elle n'existe pas dans un shell.
QS_CONFIG="ii"

# Le global n'est servi que si le shell tourne : au plus 15 s d'attente.
for _ in $(seq 30); do
    if qs -c "$QS_CONFIG" ipc call TEST_ALIVE >/dev/null 2>&1; then
        exec hyprctl dispatch 'hl.dsp.global("quickshell:wallpaperSelectorRandom")'
    fi
    sleep 0.5
done

exit 0
