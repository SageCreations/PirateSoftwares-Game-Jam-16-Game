package source

import rl "vendor:raylib"
import "core:math/rand"
import "core:fmt"

WeaponType :: enum uint {
    None        = 0,
    Finger      = 1,
    Crossbow    = 2,
    Lazer       = 3,
    Machinegun  = 4,
}

Weapon :: struct {
    type: WeaponType,
    texture: rl.Texture2D,
    bullet_texture: rl.Texture2D,
    name: string,
    damage: i32,
    level: i32,
}

Weapon_Pickup :: struct {
    using item: Pickup_Item,
    weapon: Weapon,
}

CreateWeapon :: proc () -> Weapon {
    weaponType := rand.int_max(len(WeaponType)-1)+1
    weapon_texture: rl.Texture2D
    w_bullet_texture: rl.Texture2D
    weapon_name:= "weapon"
    weapon_damage: i32 = 30 //TODO: balance this later
    weapon_level: i32 = (rand.int31_max(100)+1 <=70) ? 1 : 2
    switch WeaponType(weaponType) {
    case .None:
    case .Finger:
        weapon_texture = rl.LoadTexture("assets/FingerGun.png")
        w_bullet_texture = rl.LoadTexture("")
    case .Crossbow:
        weapon_texture = rl.LoadTexture("assets/CrossBow.png")
        w_bullet_texture = rl.LoadTexture("")
    case .Lazer:
        weapon_texture = rl.LoadTexture("assets/Edge_Chainsaw.png")
        w_bullet_texture = rl.LoadTexture("")
    case .Machinegun:
        weapon_texture = rl.LoadTexture("assets/MGun.png")
        w_bullet_texture = rl.LoadTexture("")
    }

    return Weapon{
        type            = WeaponType(weaponType),
        texture         = weapon_texture,
        bullet_texture  = w_bullet_texture,
        name            = weapon_name,
        damage          = weapon_damage,
        level           = weapon_level,
    }
}

CreateWeaponPickup :: proc(pos: rl.Vector2, wp: Weapon = Weapon{}) -> Weapon_Pickup {
    // hitbox radius needs to be about 10/15 to
    id := rand.int31_max(10000000)
    weapon_id := fmt.aprintf("weapon-%d", id)
    weapon_obj: Weapon
    if wp.type == .None {
        weapon_obj = CreateWeapon()
    } else {
        weapon_obj = wp
    }

    return Weapon_Pickup{
        id = weapon_id,
        name = "weapon",
        position = pos,
        hitbox = Circle{pos, 15.0},
        weapon = weapon_obj,
        despawn_timer = g_mem.timer,
    }
}

DrawWeaponPickup :: proc(wp: ^Weapon_Pickup) {
    weapon_tint: rl.Color = GetWeaponTint(wp.weapon.level)
    rl.DrawTextureV(wp.weapon.texture, rl.Vector2{wp.position.x - f32(wp.weapon.texture.width/2), wp.position.y - f32(wp.weapon.texture.width/2)}, weapon_tint)
    if DEBUG_MODE {
        DrawCollider(wp.hitbox)
    }
}

GetWeaponTint :: proc(level: i32) -> rl.Color {
    tint: rl.Color
    switch level {
    case 1:
        tint = rl.WHITE
    case 2:
        tint = rl.PINK
    case 3:
        tint = rl.YELLOW
    }
    return tint
}

testWeaponInventory :: proc() -> [5]Weapon {
    testing_inven: [5]Weapon = {}
    for i in 0..<5 {
        weapon := CreateWeapon()
        //fmt.printfln("Weapon: %v", weapon)
        testing_inven[i] = weapon
    }
    return testing_inven
}

GetPickupPrompt :: proc(wp: Weapon, isHUD: bool = false) -> cstring {
    name: cstring
    switch wp.type {
    case .None:
        name = "Pistol"
    case .Finger:
        name = "Finger Gun"
    case .Crossbow:
        name = "Crossbow"
    case .Lazer:
        name = "Lazer Gun"
    case .Machinegun:
        name = "Machine Gun"
    }

    if isHUD {
        return fmt.ctprintf("%s - Level %d", name, wp.level)
    }
    return fmt.ctprintf("Pickup Lvl.%d - %s", wp.level, name)
}


WeaponToInventory :: proc(wp: ^Weapon) -> bool {
    for &item in g_mem.player.inventory {
        if item.type == .None {
            item = wp^
            return true
        }
    }
    return false
}