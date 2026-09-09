-- MONITOR CONFIG
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.6
})

-- 3 doigts a l'horizontale = workspace precedent / suivant.
-- Remplace le `direction = "swipe"` + `action = "move"` d'end-4 (deplacer la
-- fenetre) : l'API Lua 0.55 n'expose pas d'`ungesture`, donc un geste ne peut
-- pas etre neutralise depuis custom/general.lua -- il faut editer celui-ci.
-- "horizontal" couvre les deux sens ; "swipe" aurait aussi capte le vertical.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
-- 3 doigts a la verticale = defiler les fenetres du workspace courant.
-- `scroll_move` est le geste du layout scrolling (CScrollMoveTrackpadGesture) :
-- il fait glisser la pile de colonnes, donc avec direction = "down" il defile
-- les fenetres du workspace, sans en changer. Reglages associes deja par
-- defaut a true : gestures:scrolling:move_snap_to_grid / move_snap_cursor.
-- ATTENTION : ce geste ne peut coexister avec un 3 doigts `direction =
-- "swipe"`. Hyprland refuse la declaration -- "Previous SWIPE shadows new
-- VERTICAL" -- car swipe capte deja toutes les directions. C'est pourquoi le
-- geste ci-dessus est passe de "swipe" a "horizontal".
hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = "scroll_move"
})
hl.gesture({
    fingers = 3,
    direction = "pinch",
    action = "fullscreen"
})
hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace"
})
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end
})

hl.config({
    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    },
    general = {
        -- Layout scrolling au lieu du dwindle d'end-4 : machine a un seul
        -- ecran, les fenetres s'empilent donc dans une colonne qu'on fait
        -- defiler (voir la section `scrolling` plus bas).
        layout = "scrolling",

        -- Gaps and border
        gaps_in = 4,
        gaps_out = 5,
        gaps_workspaces = 50,

        border_size = 5,

        col = {
            active_border = "rgba(0DB7D455)",
            inactive_border = "rgba(31313600)"
        },
        resize_on_border = true,

        no_focus_fallback = true,
        allow_tearing = true, -- This just allows the `immediate` window rule to work
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true
        }
    },
    decoration = {
        -- 2 = circle, higher = squircle, 4 = very obvious squircle
        -- Fuck clearly visible squircles. 100% Apple brainrot.
        rounding_power = 2.5,
        rounding = 18,

        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            brightness = 1,
            noise = 0.05,
            contrast = 0.89,
            vibrancy = 0.5,
            vibrancy_darkness = 0.5,
            popups = false,
            popups_ignorealpha = 0.6,
            input_methods = true,
            input_methods_ignorealpha = 0.8
        },
        shadow = {
            enabled = true,
            range = 20,
            offset = {0, 2},
            render_power = 10,
            color = "rgba(00000020)"

        },
        -- Dim
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.2
    },
    animations = {
        enabled = true
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false
        -- precise_mouse_move = true,
    },
    -- direction = "down" : les nouvelles fenetres apparaissent en dessous et
    -- le layout defile verticalement (defaut "right"). A noter : cette option
    -- n'est pas validee a l'ecriture -- une valeur inconnue est acceptee sans
    -- erreur puis ignoree. C'est ce qui rend le layout "scrolling vertical" et ce
    -- sur quoi s'appuie le geste 3 doigts vertical ci-dessus.
    -- Le bloc dwindle au-dessus est conserve : sans effet tant que
    -- general.layout vaut "scrolling", il redevient utile si on y revient.
    scrolling = {
        direction = "down",
        -- Une fenetre = 100 % de la hauteur de l'ecran. Avec direction =
        -- "down", `column_width` (defaut 0.5) est l'extension de la colonne le
        -- long de l'axe de defilement, donc sa HAUTEUR : il n'existe pas de
        -- `column_height`. Verifie a chaud : 0.5 -> colonnes de 581 px,
        -- 1.0 -> 1176 px, soit la hauteur logique (1200) moins les gaps.
        -- ATTENTION : l'option ne vaut que pour les colonnes CREEES ensuite.
        -- Une colonne existante garde sa taille a travers un reload ; il faut
        -- `layoutmsg colresize 1.0` (colonne focus uniquement) pour la
        -- recadrer.
        column_width = 1.0
    },
})
-- Curves
hl.curve("expressiveFastSpatial", {
    type = "bezier",
    points = {{0.42, 1.67}, {0.21, 0.90}}
})
hl.curve("expressiveSlowSpatial", {
    type = "bezier",
    points = {{0.39, 1.29}, {0.35, 0.98}}
})
hl.curve("expressiveDefaultSpatial", {
    type = "bezier",
    points = {{0.38, 1.21}, {0.22, 1.00}}
})
hl.curve("emphasizedDecel", {
    type = "bezier",
    points = {{0.05, 0.7}, {0.1, 1}}
})
hl.curve("emphasizedAccel", {
    type = "bezier",
    points = {{0.3, 0}, {0.8, 0.15}}
})
hl.curve("standardDecel", {
    type = "bezier",
    points = {{0, 0}, {0, 1}}
})
hl.curve("menu_decel", {
    type = "bezier",
    points = {{0.1, 1}, {0, 1}}
})
hl.curve("menu_accel", {
    type = "bezier",
    points = {{0.52, 0.03}, {0.72, 0.08}}
})
hl.curve("stall", {
    type = "bezier",
    points = {{1, -0.1}, {0.7, 0.85}}
})
-- Configs
-- windows
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3,
    bezier = "emphasizedDecel",
    style = "popin 80%"
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3,
    bezier = "emphasizedDecel"
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 2,
    bezier = "emphasizedDecel",
    style = "popin 90%"
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 2,
    bezier = "emphasizedDecel"
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 3,
    bezier = "emphasizedDecel",
    style = "slide"
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 10,
    bezier = "emphasizedDecel"
})

-- layers
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 2.7,
    bezier = "emphasizedDecel",
    style = "popin 93%"
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 2.4,
    bezier = "menu_accel",
    style = "popin 94%"
})
-- fade
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 0.5,
    bezier = "menu_decel"
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 2.7,
    bezier = "stall"
})
-- workspaces
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "menu_decel",
    style = "slide"
})
-- specialWorkspace
hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 2.8,
    bezier = "emphasizedDecel",
    style = "slidevert"
})
hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 1.2,
    bezier = "emphasizedAccel",
    style = "slidevert"
})
-- zoom
hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 3,
    bezier = "standardDecel"
})

hl.config({
    input = {
        kb_layout = "fr",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,

        follow_mouse = 1,
        off_window_axis_events = 2,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            -- Vitesse de defilement au pad, abaissee de 0.7 a 0.1. C'est un
            -- multiplicateur applique au mouvement de scroll : plus bas =
            -- plus lent. Sans effet sur une souris externe, qui a son propre
            -- `input:scroll_factor` (laisse a 1.0), ni sur les gestes a
            -- plusieurs doigts, regles par les `gestures:*` plus haut.
            --
            -- La valeur parait absurdement basse et ne l'est pas : la plage
            -- utile est comprimee tout en bas. Teste a chaud sur ce pad, la
            -- difference entre 0.7 et 0.4 est imperceptible ; elle ne se sent
            -- qu'en dessous de ~0.2, et 0.05 est deja trop lent. Inutile donc
            -- de reajuster par petits pas depuis 1.0 : ca ne bougera pas.
            --
            -- Reglable a chaud, sans rebuild, pour retrouver le bon cran :
            --   hyprctl eval 'hl.config({ ["input.touchpad.scroll_factor"] = 0.1 })'
            scroll_factor = 0.1
        }
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty)",
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = true
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true
    },

    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1
    },

    xwayland = {
        force_zero_scaling = true
    }
})
