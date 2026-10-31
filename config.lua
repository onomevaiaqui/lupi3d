return {
    -- Current official Lupinho source: L/R = BTN_F/BTN_G, BGR555.
    -- The hardware documentation instead lists BTN_Q/BTN_E and RGB555.
    -- Switch this to "hardware" when testing that documented firmware.
    platform = "lupinho",
    detail = "fast", -- "quality" restores the v0.4 character and prop meshes
    cached_character = true, -- preprojected 3D poses; fixed camera height/distance
    speed = 2.7, -- world units per second (was 2.1 at 60 FPS)
    camera_speed = 1.5, -- radians per second
    fallback_fps = 60, -- used if the firmware does not expose ui.stat(7)
    show_stats = true, -- FPS -- means that the firmware does not report FPS
    limit = 7.0,
    max_triangles = 768,
}
