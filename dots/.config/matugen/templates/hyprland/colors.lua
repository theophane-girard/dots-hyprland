-- Bordures : end-4 mappait active_border sur outline_variant, un neutre
-- volontairement discret -- les bordures suivaient donc le theme sans jamais
-- porter la couleur d'accent. On passe sur primary, en degrade vers
-- primary_container pour garder du relief.
--
-- ATTENTION a la syntaxe : cote Lua, un degrade ne s'ecrit PAS comme en
-- hyprlang ("rgba(a) rgba(b) 45deg" -> "invalid color"). Il faut une table
-- { colors = { ... }, angle = N }. Les window_rule, elles, acceptent bien la
-- chaine hyprlang : d'ou les deux ecritures differentes dans ce fichier.
--
-- La regle "pin" utilisait deja primary : elle passe sur tertiary, sinon une
-- fenetre epinglee ne se distingue plus d'une fenetre active.
hl.config({
    general = {
        col = {
            active_border = {
                colors = {
                    "rgba({{colors.primary.default.hex_stripped}}AA)",
                    "rgba({{colors.primary_container.default.hex_stripped}}AA)",
                },
                angle = 45,
            },
            inactive_border = "rgba({{colors.surface_container_low.default.hex_stripped}}33)",
        },
    },
    misc = {
        background_color = "rgba({{colors.surface.dark.hex_stripped}}FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba({{colors.tertiary.default.hex_stripped}}AA) rgba({{colors.tertiary.default.hex_stripped}}77)",
})
