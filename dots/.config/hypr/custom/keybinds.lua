hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Socle de binds repris du depot dotfiles-gh (converti en Lua).
-- hyprland.lua ne source que ce fichier : tout ajout doit etre require ici.
require("custom.keybinds-socle")

-- Verrouillage remis ici : le socle s'approprie SUPER+L (focus droite) et
-- ecrase donc le "Session: Lock" d'end-4. Declare APRES le require, sinon le
-- helper bind() du socle pourrait le liberer.
--
-- ATTENTION : cette combo n'etait pas libre. Le socle y met
-- `changegroupactive f` (SUPER + CTRL + L, pendant de SUPER + CTRL + H).
-- Les binds Lua s'empilent, donc sans unbind les DEUX partiraient : cycle
-- dans le groupe *et* verrouillage. On libere les deux ordres possibles
-- (hl.unbind matche la chaine exacte, ordre des modificateurs compris).
hl.unbind("SUPER + CTRL + L")
hl.unbind("CTRL + SUPER + L")
hl.bind("CTRL + SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"),
    { description = "Session: Lock" })

-- Explorateur de fichiers end-4, deplace de SUPER+E (pris par le socle pour
-- yazi) vers SUPER+SHIFT+E. On reutilise le global `fileManager` declare par
-- hyprland/variables.lua (dolphin > nautilus > nemo > thunar > yazi) pour
-- rester aligne sur end-4 plutot que de figer un binaire.
hl.bind("SUPER + SHIFT + E",
    hl.dsp.exec_cmd(fileManager or "xdg-open ~"),
    { description = "App: File manager" })

-- Cheatsheet (liste des raccourcis) : end-4 le met sur SUPER + Slash, injouable
-- en AZERTY. Le keysym `slash` n'existe qu'au niveau shifte de la touche `:`,
-- or Hyprland matche le keysym NON shifte -> le bind ne peut jamais tomber.
-- On le remet sur SUPER + Colon, c.-a-d. SUPER + la touche `:` sans Shift.
hl.bind("SUPER + Colon", hl.dsp.global("quickshell:cheatsheetToggle"),
    { description = "Shell: Toggle cheatsheet" })
