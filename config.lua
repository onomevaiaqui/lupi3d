return {
    -- Current official Lupinho source: L/R = BTN_F/BTN_G, BGR555.
    -- The hardware documentation instead lists BTN_Q/BTN_E and RGB555.
    -- Switch this to "hardware" when testing that documented firmware.
    platform = "lupinho",
    speed = 0.035, -- world units per 60 Hz update
    camera_speed = 0.025,
    limit = 7.0,
    max_triangles = 2600,
}
