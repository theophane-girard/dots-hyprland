#!/usr/bin/env bash
# Resize active window with consistent semantics:
#   grow   = window gets bigger
#   shrink = window gets smaller
# Works in dwindle regardless of the window's side in the split.
# Usage: hresize.sh grow|shrink [h|v] [delta_px]
#   h = horizontal (default), v = vertical

set -euo pipefail

ACTION="${1:?usage: $0 grow|shrink [h|v] [delta]}"
AXIS="${2:-h}"
DELTA="${3:-100}"

WIN=$(hyprctl activewindow -j)
FLOATING=$(echo "$WIN" | jq -r '.floating')

# Apply delta on the requested axis.
# Cette machine utilise la config Lua de Hyprland : `hyprctl dispatch` n'y
# accepte plus la syntaxe hyprlang ("resizeactive 0 10" -> erreur de syntaxe
# Lua), seulement une expression de l'API hl.
dispatch() {
    if [[ "$AXIS" == "v" ]]; then
        hyprctl dispatch "hl.dsp.window.resize({ x = 0, y = $1 })" >/dev/null
    else
        hyprctl dispatch "hl.dsp.window.resize({ x = $1, y = 0 })" >/dev/null
    fi
}

# Floating: positive always grows toward right/bottom edge.
if [[ "$FLOATING" == "true" ]]; then
    case "$ACTION" in
        grow)   dispatch  "$DELTA" ;;
        shrink) dispatch "-$DELTA" ;;
    esac
    exit 0
fi

MON_ID=$(echo "$WIN" | jq -r '.monitor')
MON=$(hyprctl monitors -j | jq -c --argjson id "$MON_ID" '.[] | select(.id == $id)')

THRESHOLD=20

if [[ "$AXIS" == "v" ]]; then
    WP=$(echo "$WIN" | jq -r '.at[1]')
    WS=$(echo "$WIN" | jq -r '.size[1]')
    MP=$(echo "$MON" | jq -r '.y')
    MS=$(echo "$MON" | jq -r '.height')
else
    WP=$(echo "$WIN" | jq -r '.at[0]')
    WS=$(echo "$WIN" | jq -r '.size[0]')
    MP=$(echo "$MON" | jq -r '.x')
    MS=$(echo "$MON" | jq -r '.width')
fi

START_GAP=$(( WP - MP ))
END_GAP=$(( (MP + MS) - (WP + WS) ))

# Mobile edge heuristic:
#   - End edge at monitor edge & start has gap -> mobile = start (left/top)
#   - Otherwise -> mobile = end (right/bottom), the default convention
if (( END_GAP <= THRESHOLD && START_GAP > THRESHOLD )); then
    case "$ACTION" in
        grow)   dispatch "-$DELTA" ;;
        shrink) dispatch  "$DELTA" ;;
    esac
else
    case "$ACTION" in
        grow)   dispatch  "$DELTA" ;;
        shrink) dispatch "-$DELTA" ;;
    esac
fi
