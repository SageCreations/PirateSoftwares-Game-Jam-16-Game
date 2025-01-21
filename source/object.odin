package source

import rl "vendor:raylib"
import "core:c"

Object :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    texture: rl.Texture2D,
    speed: rl.Vector2,
    rotation: f32,
    tint: rl.Color,
    isActive: bool,
    state: uint,
    hitbox: rl.Rectangle,
    id: i32,
    name: string,

    // Callback function types
    on_update    : proc(obj: ^Object, delta_time: f32),
    on_draw      : proc(obj: ^Object),
    on_collision : proc(obj: ^Object, other: ^Object),
}

