package source

import rl "vendor:raylib"

WeaponType :: enum uint {
    Finger = 0,
    Crossbow,
    Lazer,
    Machinegun,
}

Weapon :: struct {
    type: WeaponType,
    texture: rl.Texture2D,
    bullet_texture: rl.Texture2D,
    name: string,
    damage: i32,
    level: i32,
    rotation: f32,
}

