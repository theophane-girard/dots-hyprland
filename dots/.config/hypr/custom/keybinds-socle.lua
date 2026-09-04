-- ==========================================================
-- SOCLE DE BINDS — converti depuis le depot dotfiles-gh
-- ==========================================================
-- Source : dotfiles-gh/hypr/.config/hypr/keybinds.conf (syntaxe hyprlang).
-- Ici : API Lua de Hyprland 0.55 (`hl`), seule syntaxe que cette machine lit.
-- Charge par custom/keybinds.lua, donc APRES hyprland/keybinds.lua (end-4).
--
-- DEUX PIEGES, verifies a chaud sur cette machine, qui motivent le helper
-- bind() plus bas :
--
--   1. En Lua les binds S'EMPILENT. Rebinder une combo deja prise par end-4
--      n'ecrase rien : les DEUX actions se declenchent. Il faut hl.unbind.
--   2. hl.unbind matche la chaine exacte, ordre des modificateurs compris :
--      unbind("SUPER + CTRL + Left") ne touche pas un bind declare
--      "CTRL + SUPER + Left". Il faut donc essayer tous les ordres.
--   ... et une touche physique se declare sous deux noms (`code:10` ou `1`) ;
--      end-4 declare souvent les deux, donc il faut liberer les deux.
--
-- Equivalences retenues (API complete :
-- /nix/store/*-hyprland-0.55.4/share/hypr/stubs/hl.meta.lua) :
--
--   killactive              -> hl.dsp.window.close()
--   fullscreen, 1 / 0       -> hl.dsp.window.fullscreen{ mode = "maximized" / "fullscreen" }
--   togglefloating          -> hl.dsp.window.float{ action = "toggle" }
--   togglegroup             -> hl.dsp.group.toggle()
--   movefocus, X            -> hl.dsp.focus{ direction = X }
--   movewindow, X           -> hl.dsp.window.move{ direction = X }
--   movewindow, mon:X       -> hl.dsp.window.move{ monitor = X }
--   workspace, X            -> hl.dsp.focus{ workspace = X }
--   movetoworkspace, X      -> hl.dsp.window.move{ workspace = X }
--   changegroupactive, b/f  -> hl.dsp.group.prev() / hl.dsp.group.next()
--   movegroupwindow, X      -> hl.dsp.group.move_window{ direction = X }
--   layoutmsg, X            -> hl.dsp.layout("X")
--   exec, X                 -> hl.dsp.exec_cmd("X")
--   bindmd (souris)         -> bind(..., { mouse = true })
--   binde  (repetition)     -> bind(..., { repeating = true })
--   bindd  (description)    -> bind(..., { description = "..." })
--
-- Trois binds n'ont pas d'equivalent direct, voir les commentaires NOTE :
--   focuswindow first/last   -> fait main via hl.get_workspace_windows
--   resizeactive exact 100%  -> hl.window.resize veut des nombres, pas des %
--   movewindoworgroup        -> aucun equivalent typé : degrade en movewindow
--
-- Apres edition : hyprctl reload
-- ==========================================================

-- Valeurs des variables hyprlang $terminal / $terminalExec de la source.
local terminal = "foot"
local terminalExec = "foot"

local MODS = { SUPER = true, SHIFT = true, CTRL = true, ALT = true }

-- Meme touche physique, deux notations possibles : il faut liberer les deux.
local ALIAS = {
    ["code:10"] = "1", ["code:11"] = "2", ["code:12"] = "3",
    ["code:13"] = "4", ["code:14"] = "5", ["code:15"] = "6",
    ["code:16"] = "7", ["code:17"] = "8", ["code:18"] = "9",
    ["code:20"] = "Minus", ["code:21"] = "Equal",
    ["code:34"] = "BracketLeft", ["code:35"] = "BracketRight",
}

-- Tous les ordres possibles d'une liste (3 modificateurs au plus -> 6 ordres).
local function permute(list)
    if #list <= 1 then return { list } end
    local out = {}
    for i = 1, #list do
        local rest = {}
        for j = 1, #list do
            if j ~= i then rest[#rest + 1] = list[j] end
        end
        for _, tail in ipairs(permute(rest)) do
            local one = { list[i] }
            for _, v in ipairs(tail) do one[#one + 1] = v end
            out[#out + 1] = one
        end
    end
    return out
end

-- Bind en s'appropriant la combo : libere d'abord tout bind existant sur la
-- meme touche, quel que soit l'ordre des modificateurs ou la notation.
local function bind(combo, dispatcher, opts)
    local mods, key = {}, nil
    for tok in combo:gmatch("[^+%s]+") do
        if MODS[tok:upper()] then mods[#mods + 1] = tok else key = tok end
    end
    local keys = { key }
    if ALIAS[key] then keys[#keys + 1] = ALIAS[key] end
    for _, k in ipairs(keys) do
        for _, order in ipairs(permute(mods)) do
            local parts = {}
            for _, m in ipairs(order) do parts[#parts + 1] = m end
            parts[#parts + 1] = k
            hl.unbind(table.concat(parts, " + "))
        end
    end
    return hl.bind(combo, dispatcher, opts)
end

--  ==========================================================
-- HYPRLAND KEYBINDS — socle autonome
--  ==========================================================
-- Ce fichier ne contient QUE des binds qui fonctionnent avec Hyprland seul :
-- dispatchers natifs, terminal, scripts locaux autonomes.
-- 
-- Les binds qui dépendent d'un shell externe (barre, launcher, volume,
-- luminosité, screenshots, lock) ne sont PAS ici : ils se branchent via le
-- hook local.conf, hors versioning. Voir README.
-- 
-- Conventions :
-- SUPER              -> focus / lancer
-- SUPER SHIFT        -> déplacer / variante
-- SUPER CTRL         -> workspace / groupe
-- SUPER SHIFT CTRL   -> déplacer vers moniteur / workspace relatif
-- 
-- Clavier FR : les rangées de chiffres et []  sont bindées en `code:` pour
-- rester positionnelles quelle que soit la layout active (fr/us).
-- 
-- Après édition : hyprctl reload
--  ==========================================================

-- === Application Launchers ===
-- $terminal / $terminalExec : défauts dans hyprland.conf, surchargeables
-- par machine via le hook local.conf.
-- yazi reste en dur : le bind dépend de son option --cwd-file, propre à yazi.
bind("SUPER + A", hl.dsp.exec_cmd(terminal), { description = "App: Terminal" })
bind("SUPER + E", hl.dsp.exec_cmd(terminalExec .. " " .. [[bash -c 'tmp=$(mktemp); yazi --cwd-file="$tmp"; d=$(cat "$tmp"); [ -n "$d" ] && cd "$d"; rm -f "$tmp"; exec bash']]), { description = "App: File manager (yazi)" })

-- === Dictée vocale (hyprwhspr) ===
-- Toggle : une fois pour démarrer, une fois pour arrêter.
-- NOTE: chemin FHS /usr/... : inexistant sur NixOS, ce bind ne fera rien
bind("SUPER + twosuperior", hl.dsp.exec_cmd("/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record"),
    { description = "Input: Speech-to-text" })

-- === Window Management ===
bind("SUPER + C", hl.dsp.window.close(), { description = "Window: Close" })
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Window: Toggle maximize" })
bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Window: Toggle fullscreen" })
bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Toggle floating" })
bind("SUPER + W", hl.dsp.group.toggle(), { description = "Group: Toggle group" })

-- === Focus Navigation ===
bind("SUPER + Left", hl.dsp.focus({ direction = "l" }), { description = "Focus: Focus window left" })
bind("SUPER + Down", hl.dsp.focus({ direction = "d" }), { description = "Focus: Focus window down" })
bind("SUPER + Up", hl.dsp.focus({ direction = "u" }), { description = "Focus: Focus window up" })
bind("SUPER + Right", hl.dsp.focus({ direction = "r" }), { description = "Focus: Focus window right" })
bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Focus: Focus window left (vim hjkl)" })
bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
bind("SUPER + L", hl.dsp.focus({ direction = "r" }))

-- === Window Movement ===
bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "l" }), { description = "Window: Move window left" })
bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "d" }), { description = "Window: Move window down" })
bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "u" }), { description = "Window: Move window up" })
bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "r" }), { description = "Window: Move window right" })
-- NOTE: movewindoworgroup: pas d'equivalent typé en 0.55.4 -> movewindow (la fusion dans un groupe adjacent est perdue)
bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Window: Move window left (vim hjkl)" })
-- NOTE: movewindoworgroup: pas d'equivalent typé en 0.55.4 -> movewindow (la fusion dans un groupe adjacent est perdue)
bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
-- NOTE: movewindoworgroup: pas d'equivalent typé en 0.55.4 -> movewindow (la fusion dans un groupe adjacent est perdue)
bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
-- NOTE: movewindoworgroup: pas d'equivalent typé en 0.55.4 -> movewindow (la fusion dans un groupe adjacent est perdue)
bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

bind("SUPER + CTRL + H", hl.dsp.group.prev(), { repeating = true, description = "Group: Previous window in group" })
bind("SUPER + CTRL + L", hl.dsp.group.next(), { repeating = true, description = "Group: Next window in group" })

bind("SUPER + code:35", hl.dsp.group.move_window({ direction = "f" }), { description = "Group: Move window forward in group" })  -- forward  (touche ] physique)
bind("SUPER + code:34", hl.dsp.group.move_window({ direction = "b" }), { description = "Group: Move window backward in group" })  -- backward (touche [ physique)

-- === Column Navigation ===
bind("SUPER + Home", function()
        local wins = hl.get_workspace_windows(hl.get_active_workspace().id)
        if wins[1] then hl.dispatch(hl.dsp.focus({ window = wins[1] })) end
    end, { description = "Focus: First window on workspace" })
bind("SUPER + End", function()
        local wins = hl.get_workspace_windows(hl.get_active_workspace().id)
        if wins[1] then hl.dispatch(hl.dsp.focus({ window = wins[#wins] })) end
    end, { description = "Focus: Last window on workspace" })

-- === Monitor Navigation ===
-- (desactive dans la source) bind = SUPER CTRL, left, focusmonitor, l
-- (desactive dans la source) bind = SUPER CTRL, right, focusmonitor, r
-- (desactive dans la source) bind = SUPER CTRL, H, focusmonitor, l
-- (desactive dans la source) bind = SUPER CTRL, J, focusmonitor, d
-- (desactive dans la source) bind = SUPER CTRL, K, focusmonitor, u
-- (desactive dans la source) bind = SUPER CTRL, L, focusmonitor, r

-- === Move to Monitor ===
bind("SUPER + SHIFT + CTRL + Left", hl.dsp.window.move({ monitor = "l" }), { description = "Monitor: Move window to monitor left" })
bind("SUPER + SHIFT + CTRL + Down", hl.dsp.window.move({ monitor = "d" }), { description = "Monitor: Move window to monitor down" })
bind("SUPER + SHIFT + CTRL + Up", hl.dsp.window.move({ monitor = "u" }), { description = "Monitor: Move window to monitor up" })
bind("SUPER + SHIFT + CTRL + Right", hl.dsp.window.move({ monitor = "r" }), { description = "Monitor: Move window to monitor right" })
bind("SUPER + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }))
bind("SUPER + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }), { description = "Monitor: Move window to monitor down (vim hjkl)" })
bind("SUPER + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }), { description = "Monitor: Move window to monitor up (vim hjkl)" })
bind("SUPER + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }))

-- === Workspace Navigation ===
bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace: Next workspace" })
bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace: Previous workspace" })
bind("SUPER + U", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace: Next workspace" })
bind("SUPER + I", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace: Previous workspace" })
bind("SUPER + CTRL + Down", hl.dsp.window.move({ workspace = "e+1" }), { description = "Workspace: Move window to next workspace" })
bind("SUPER + CTRL + Up", hl.dsp.window.move({ workspace = "e-1" }), { description = "Workspace: Move window to previous workspace" })
bind("SUPER + CTRL + U", hl.dsp.window.move({ workspace = "e+1" }), { description = "Workspace: Move window to next workspace" })
bind("SUPER + CTRL + I", hl.dsp.window.move({ workspace = "e-1" }), { description = "Workspace: Move window to previous workspace" })
bind("SUPER + CTRL + Right", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspace: Next workspace on monitor" })
bind("SUPER + CTRL + Left", hl.dsp.focus({ workspace = "r-1" }), { description = "Workspace: Previous workspace on monitor" })
-- NOTE: doublon dans la source ; ici c'est le DERNIER qui gagne (le helper
--       bind() libere le precedent), alors que la source declenchait les
--       deux. Deja bindee plus haut sur 'movewindow mon:r') : en Lua les deux se declenchent.
bind("SUPER + SHIFT + CTRL + L", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspace: Next workspace on monitor (vim hjkl)" })
-- NOTE: doublon dans la source ; ici c'est le DERNIER qui gagne (le helper
--       bind() libere le precedent), alors que la source declenchait les
--       deux. Deja bindee plus haut sur 'movewindow mon:l') : en Lua les deux se declenchent.
bind("SUPER + SHIFT + CTRL + H", hl.dsp.focus({ workspace = "r-1" }), { description = "Workspace: Previous workspace on monitor (vim hjkl)" })

-- === Move Workspaces ===
bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }), { description = "Workspace: Move window to next workspace" })
bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "e-1" }), { description = "Workspace: Move window to previous workspace" })
bind("SUPER + SHIFT + U", hl.dsp.window.move({ workspace = "e+1" }), { description = "Workspace: Move window to next workspace" })
bind("SUPER + SHIFT + I", hl.dsp.window.move({ workspace = "e-1" }), { description = "Workspace: Move window to previous workspace" })

-- === Mouse Wheel Navigation ===
bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace: Next workspace (scroll)" })
bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace: Previous workspace (scroll)" })
bind("SUPER + CTRL + mouse_down", hl.dsp.window.move({ workspace = "e+1" }), { description = "Workspace: Move window to next workspace (scroll)" })
bind("SUPER + CTRL + mouse_up", hl.dsp.window.move({ workspace = "e-1" }), { description = "Workspace: Move window to previous workspace (scroll)" })

-- === Numbered Workspaces ===
bind("SUPER + code:10", hl.dsp.focus({ workspace = 1 }), { description = "Workspace: Focus workspace 1-9 (number row)" })
bind("SUPER + code:11", hl.dsp.focus({ workspace = 2 }))
bind("SUPER + code:12", hl.dsp.focus({ workspace = 3 }))
bind("SUPER + code:13", hl.dsp.focus({ workspace = 4 }))
bind("SUPER + code:14", hl.dsp.focus({ workspace = 5 }))
bind("SUPER + code:15", hl.dsp.focus({ workspace = 6 }))
bind("SUPER + code:16", hl.dsp.focus({ workspace = 7 }))
bind("SUPER + code:17", hl.dsp.focus({ workspace = 8 }))
bind("SUPER + code:18", hl.dsp.focus({ workspace = 9 }))

-- === Move to Numbered Workspaces ===
bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 }), { description = "Workspace: Move window to workspace 1-9 (number row)" })
bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 }))
bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 }))
bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 }))
bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 }))
bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 }))
bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 }))
bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 }))
bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 }))

-- === Column Management ===
bind("SUPER + BracketLeft", hl.dsp.layout("preselect l"), { description = "Layout: Preselect split left" })
bind("SUPER + BracketRight", hl.dsp.layout("preselect r"), { description = "Layout: Preselect split right" })

-- === Sizing & Layout ===
bind("SUPER + R", hl.dsp.layout("togglesplit"), { description = "Layout: Toggle split direction" })
-- NOTE: resizeactive exact 100% 100% : hl.window.resize n'accepte que des nombres -> taille calculee depuis le moniteur actif
bind("SUPER + CTRL + F", function()
        local m = hl.get_active_monitor()
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(m.width / m.scale),
            y = math.floor(m.height / m.scale),
            exact = true,
        }))
    end, { description = "Window: Resize to full monitor" })

-- === Move/resize windows with mainMod + LMB/RMB and dragging ===
bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Window: Move (drag)" })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Window: Resize (drag)" })

-- === Resize au clavier (scrolling layout) ===
-- scripts/hresize.sh : hyprctl + jq uniquement.
-- NOTE: chemin du script reecrit vers custom/scripts/ (emplacement end-4)
bind("SUPER + code:20", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/hresize.sh shrink h"),
    { repeating = true, description = "Window: Shrink width" })
-- NOTE: chemin du script reecrit vers custom/scripts/ (emplacement end-4)
bind("SUPER + code:21", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/hresize.sh grow h"),
    { repeating = true, description = "Window: Grow width" })
-- NOTE: chemin du script reecrit vers custom/scripts/ (emplacement end-4)
bind("SUPER + SHIFT + code:20", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/hresize.sh shrink v"),
    { repeating = true, description = "Window: Shrink height" })
-- NOTE: chemin du script reecrit vers custom/scripts/ (emplacement end-4)
bind("SUPER + SHIFT + code:21", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/hresize.sh grow v"),
    { repeating = true, description = "Window: Grow height" })

-- === System Controls ===
-- (desactive dans la source) bind = SUPER SHIFT, P, dpms, toggle
-- (desactive dans la source) bind = SUPER SHIFT, E, exit
