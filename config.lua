return {
    platform="lupinho",
    controller="snes", -- SNES: B=BTN_Z, A=BTN_G, L=BTN_Q, R=BTN_E, Y=BTN_F
    fallback_fps=60,
    rival_difficulty=1.15, -- 15% above the 13.1 AI pace; player physics unchanged
    projection=300,
    max_triangles=512, -- reusable triangle pool
    eye_height=0,
    draw_distance=42,
    top_speed=15,
    acceleration=7,
    brake=13,
    steering=1.5,
}
