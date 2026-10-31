return {
    -- Palette format only: keep the working BGR555 setup.
    -- "hardware" selects the RGB555 format described in the firmware docs.
    -- Controller mapping is independent, so changing controls does not change colors.
    platform = "lupinho",
    controller = "snes", -- SNES firmware: L=BTN_Q, R=BTN_E, B=BTN_Z, Y=BTN_F
    detail = "fast", -- "quality" restores the v0.4 character and prop meshes
    cached_character = true, -- preprojected 3D poses; fixed camera height/distance
    speed = 4.2, -- world units per second
    jump_speed = 5.4,
    gravity = 15.0,
    camera_speed = 1.5, -- radians per second
    fallback_fps = 60, -- used if the firmware does not expose ui.stat(7)
    show_stats = true, -- FPS -- means that the firmware does not report FPS
    limit = 7.0,
    max_triangles = 768,
}
