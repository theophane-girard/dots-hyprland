#!/usr/bin/env bash
# Ouvre un nouveau terminal dans le dossier de la fenêtre active.
# Usage: term-here.sh <terminal...>    (ex. term-here.sh foot)
#
# Le dossier retenu est celui du process en AVANT-PLAN du terminal focus, lu
# via le tpgid de son pty : c'est exactement « ce qui tourne dans cette
# fenêtre ». Aucun besoin d'OSC 7, donc ça marche quel que soit le shell, et
# ça suit les `:cd` faits dans un nvim déjà lancé — là où le Ctrl+Shift+N de
# foot, qui repose sur OSC 7, ne voit que le dernier cwd émis par le shell.
#
# Pourquoi pas « le descendant le plus profond » : un nvim qui a lancé une
# tâche dans une AUTRE fenêtre (overseer -> foot -> npm start) en reste le
# parent, et la descente sortait donc de la fenêtre pour rapporter le cwd de
# la tâche. Elle pouvait aussi tomber sur un process éphémère. Le groupe de
# process en avant-plan du pty ne franchit ni l'un ni l'autre.
#
# Fenêtre qui n'est pas un terminal (navigateur, Slack...) : pas de pty,
# tpgid = -1, on retombe sur le cwd du process de la fenêtre puis sur $HOME.
# Aucun cas d'échec : on ouvre toujours un terminal quelque part.
#
# La résolution se fait AVANT de lancer le terminal : après, `hyprctl
# activewindow` renverrait la nouvelle fenêtre.

set -euo pipefail

term=("$@")
[ ${#term[@]} -gt 0 ] || term=(foot)

# Premier cwd lisible et existant parmi les pids candidats, dans l'ordre.
first_dir() {
	local p d
	for p in "$@"; do
		[[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -gt 0 ] || continue
		d=$(readlink "/proc/$p/cwd" 2>/dev/null) || continue
		if [ -n "$d" ] && [ -d "$d" ]; then
			printf '%s\n' "$d"
			return 0
		fi
	done
	return 1
}

candidates=()
win=$(hyprctl activewindow -j | jq -r '.pid // empty')

if [[ "$win" =~ ^[0-9]+$ ]] && [ "$win" -gt 0 ]; then
	# Enfant direct rattaché à un pty = le shell du terminal.
	shell=""
	for c in $(pgrep -P "$win" 2>/dev/null || true); do
		if [ "$(ps -o tty= -p "$c" 2>/dev/null | tr -d ' ')" != "?" ]; then
			shell=$c
			break
		fi
	done
	if [ -n "$shell" ]; then
		candidates+=("$(ps -o tpgid= -p "$shell" 2>/dev/null | tr -d ' ')" "$shell")
	fi
	candidates+=("$win")
fi

dir=$(first_dir "${candidates[@]}") || dir=""
cd "${dir:-$HOME}"
# Terminal lancé nu : il hérite du cwd, donc $terminal suffit ($terminalExec
# et sa syntaxe « exécute cette commande » ne servent pas ici).
exec "${term[@]}"
