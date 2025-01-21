package source

WeaponType :: enum uint {
    Finger = 0,
    Crossbow,
    Lazer,
    Machinegun,
}

Weapon :: struct {
    type: WeaponType,
    name: string,
    damage: i32,
    level: i32,
    rotation: f32,
}

