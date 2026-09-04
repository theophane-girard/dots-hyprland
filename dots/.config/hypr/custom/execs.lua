-- Fond d'ecran aleatoire a chaque demarrage de session.
-- Le script attend que QuickShell reponde avant de lancer switchwall.sh, donc
-- il peut etre declare ici sans ordonnancement particulier.
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/random-wallpaper.sh")
end)
