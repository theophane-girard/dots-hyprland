-- Regles de fenetres perso. Chargees APRES hyprland/rules.lua (voir
-- hyprland.lua), donc elles gagnent en cas de conflit.
-- Portees depuis le depot stow dotfiles-gh (commit "plus de picker repete ni
-- de bandeau au partage d'ecran"), converties de la syntaxe .conf vers le Lua.

-- ######## Partage d'ecran ########

-- Picker de partage d'ecran (xdph) : tuile, il s'etale en plein ecran avec le
-- contenu tasse en haut a gauche.
-- On matche le TITRE et non la classe : hyprland-share-picker ne pose aucun
-- app_id (hyprctl clients renvoie class "", verifie sur cette machine), donc la
-- regle class = ^(hyprland-share-picker)$ du depot stow ne tombe jamais ici.
-- Le titre, lui, est fige en dur dans xdph et n'est pas traduit.
local share_picker = "^(Select what to share)$"
hl.window_rule({match = {title = share_picker }, float = true})
hl.window_rule({match = {title = share_picker }, size = {900, 650} })
hl.window_rule({match = {title = share_picker }, center = true})

-- Bandeau "X is sharing your screen" de Chrome : son bouton "Hide" demande une
-- minimisation (xdg_toplevel.set_minimized), que Hyprland n'implemente pas -- le
-- clic ne fait donc rien. On planque la fenetre soi-meme, hors des ecrans.
-- NB 1 : title est un FULL match -> le regex doit couvrir tout le titre.
-- NB 2 : le titre reel est du genre "meet.google.com is sharing your screen."
--        (verifie sur cette machine) : le nom du site prefixe la phrase, et
--        Chrome tourne en anglais ici. Les variantes francaises sont gardees au
--        cas ou la langue de l'interface change.
-- NB 3 : end-4 matche deja ".*is sharing (a window|your screen).*" dans
--        hyprland/rules.lua et pose float/pin/move vers le bas de l'ecran --
--        c'est ce qui rendait le bandeau visible malgre tout. Charge apres, le
--        move ci-dessous le remplace.
-- NB 4 : pas de "workspace special:... silent" ici -> le shell rouvre le
--        workspace special des qu'une fenetre y atterrit, le silent est annule.
local share_banner = "^(.*(is sharing (a window|your screen)|screen is being shared|partagez votre .cran|partage votre .cran|.cran est partag).*)$"
hl.window_rule({match = {title = share_banner }, float = true})
hl.window_rule({match = {title = share_banner }, move = {-4000, -4000} })
hl.window_rule({match = {title = share_banner }, no_initial_focus = true})
hl.window_rule({match = {title = share_banner }, no_anim = true})
hl.window_rule({match = {title = share_banner }, no_focus = true})
