#!/usr/bin/env bash
# Tire un fond d'ecran au hasard et le passe a switchwall.sh (end-4).
#
# Appele au demarrage de Hyprland depuis custom/execs.lua.
#
# ATTENTION : changer de fond d'ecran REGENERE toute la palette matugen. Le
# shell, hyprlock, fuzzel, les bordures de fenetres et les apps GTK/Qt
# changent donc de couleur a chaque boot. C'est le fonctionnement normal de
# ces dotfiles, pas un effet de bord de ce script.
#
# switchwall.sh n'a pas besoin de QuickShell pour travailler (il ecrit
# .background.wallpaperPath dans config.json via jq, puis lance matugen).
# On attend quand meme que le shell soit vivant : matugen reecrit les fichiers
# de couleurs que QuickShell lit au demarrage, et le laisser les relire
# reactivement evite de tomber sur une ecriture a moitie faite.

set -euo pipefail

DIR="${1:-$HOME/wallpapers}"
SHELL_CONFIG="$HOME/.config/illogical-impulse/config.json"
SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"

[ -d "$DIR" ] || exit 0
[ -x "$SWITCHWALL" ] || exit 0

# Au plus 15 s d'attente : si QuickShell ne demarre pas, on tire quand meme.
for _ in $(seq 30); do
    qs -c ii ipc call TEST_ALIVE >/dev/null 2>&1 && break
    sleep 0.5
done

mapfile -t walls < <(find "$DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
[ "${#walls[@]}" -gt 0 ] || exit 0

# Ne pas retomber sur celui du boot precedent quand il y a le choix.
current="$(jq -r '.background.wallpaperPath // ""' "$SHELL_CONFIG" 2>/dev/null || true)"
if [ "${#walls[@]}" -gt 1 ] && [ -n "$current" ]; then
    filtered=()
    for w in "${walls[@]}"; do
        [ "$w" = "$current" ] || filtered+=("$w")
    done
    [ "${#filtered[@]}" -gt 0 ] && walls=("${filtered[@]}")
fi

exec "$SWITCHWALL" --image "${walls[RANDOM % ${#walls[@]}]}"
