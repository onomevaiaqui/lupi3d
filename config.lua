return {
    platform="lupinho", -- working BGR555 palette; "hardware" selects documented RGB555
    controller="snes", -- L=BTN_Q, R=BTN_E, B=BTN_Z, Y=BTN_F, A=BTN_G
    speed=4.2,
    camera_speed=1.5,
    jump_speed=5.4,
    gravity=15,
    fallback_fps=60,
    columns=80, -- 6-pixel wall strips, no triangles or projected character mesh
    camera_plane=0.66,
    eye_height=0.75,
    wall_height=2.0,
    shot_interval=0.25,
}
