#!/usr/bin/env bash
# Wrapper autour de hyprland-share-picker, branche via screencopy:custom_picker_binary
# dans ~/.config/hypr/xdph.conf. Porte depuis le depot stow dotfiles-gh.
#
# Pourquoi : Chrome ouvre 2 sessions portal ScreenCast par partage et ne persiste
# AUCUN restore token (ses prefs display_media_* restent vides) -> xdph affiche le
# picker plusieurs fois pour un seul clic sur "Partager", et re-demande a chaque
# nouvelle reunion. allow_token_by_default ne couvre que la 2e session du meme
# partage, et seulement quand Chrome daigne repasser le token.
#
# Ce que ca fait : on memorise la derniere reponse du picker et on la rejoue sans
# UI si elle a moins de TTL secondes. Une notif signale le rejeu (jamais silencieux).
set -uo pipefail

TTL=${XDPH_PICKER_TTL:-60}
CACHE="${XDG_RUNTIME_DIR:-/tmp}/xdph-last-selection"

# NixOS : pas de /usr/bin. Le binaire du profil systeme est un wrapper qui pose
# les variables Qt dont le picker a besoin -- ne jamais appeler le .*-wrapped.
REAL=${XDPH_PICKER_BIN:-}
if [[ -z $REAL ]]; then
    for candidate in \
        /run/current-system/sw/bin/hyprland-share-picker \
        "$HOME/.nix-profile/bin/hyprland-share-picker"
    do
        [[ -x $candidate ]] && REAL=$candidate && break
    done
fi
[[ -z $REAL ]] && REAL=$(command -v hyprland-share-picker || true)
if [[ -z $REAL ]]; then
    echo "[ERROR] hyprland-share-picker introuvable" >&2
    exit 1
fi

# EPOCHSECONDS est un builtin bash 5 : pas de dependance a coreutils dans
# l'environnement (minimal) que xdph transmet au picker.
NOW=${EPOCHSECONDS:-$(date +%s)}

notify() {
    command -v hyprctl >/dev/null 2>&1 &&
        hyprctl notify 1 3000 0 "$1" >/dev/null 2>&1
}

# Le cache garde la reponse VERBATIM (1re ligne = horodatage, le reste = sortie
# du picker). xdph attend "[SELECTION]<screen|window|region>:<id>" mais peut lire
# d'autres drapeaux sur les lignes suivantes -- les rejouer tels quels evite de
# perdre p.ex. l'accord donne au restore token.
if [[ -r $CACHE ]]; then
    { read -r ts; cached=$(cat); } < "$CACHE"
    if [[ -n ${cached:-} && ${ts:-0} =~ ^[0-9]+$ ]] && (( NOW - ts < TTL )); then
        label=""
        while IFS= read -r line; do
            [[ $line == "[SELECTION]"* ]] && label=${line#"[SELECTION]"}
        done <<< "$cached"
        notify "Partage d'ecran : selection precedente reutilisee ($label)"
        printf '%s\n' "$cached"
        exit 0
    fi
fi

out=$("$REAL" "$@")
rc=$?
printf '%s\n' "$out"

# On ne memorise que les reponses contenant une selection : annulation ou plantage
# du picker ne doivent pas etre rejoues.
if [[ $out == *"[SELECTION]"* ]]; then
    { printf '%s\n' "$NOW"; printf '%s\n' "$out"; } > "$CACHE"
fi

exit $rc
