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
    bullet_color: rl.Color,
    name: string,
    damage: i32,
    level: i32,
    shoot_cooldown: f32,
    rotation: f32,
    pos: rl.Vector2,
}

Weapon_Pickup :: struct {
    using item: Pickup_Item,
    weapon: Weapon,
}

default_wp := Weapon{
    type = .None,
    name = "weapon",
    texture = rl.Texture2D{},
    bullet_color = rl.GREEN,
    damage = 26,
    level = 1,
    shoot_cooldown = 0.5,
}


CreateWeapon :: proc () -> Weapon {
    weaponType := rand.int_max(len(WeaponType)-1)+1
    weapon_texture: rl.Texture2D
    w_bullet_color: rl.Color
    weapon_name:= "weapon"
    weapon_damage: i32
    weapon_level: i32 = (rand.int31_max(100)+1 <=70) ? 1 : 2
    shoot_cd: f32
    switch WeaponType(weaponType) {
    case .None:
        weapon_damage = 26
        shoot_cd = 0.5
    case .Finger:
        weapon_texture = rl.LoadTexture("assets/FingerGun.png")
        w_bullet_color = rl.SKYBLUE
        weapon_damage = 50
        shoot_cd = 1.0
    case .Crossbow:
        weapon_texture = rl.LoadTexture("assets/CrossBow.png")
        w_bullet_color = rl.YELLOW
        weapon_damage = 34
        shoot_cd = 1.5
    case .Lazer:
        weapon_texture = rl.LoadTexture("assets/Edge_Chainsaw.png")
        w_bullet_color = rl.DARKGRAY
        weapon_damage = 51
        shoot_cd = 0.1
    case .Machinegun:
        weapon_texture = rl.LoadTexture("assets/MGun.png")
        w_bullet_color = rl.WHITE
        weapon_damage = 18
        shoot_cd = 0.1
    }

    return Weapon{
        type            = WeaponType(weaponType),
        texture         = weapon_texture,
        bullet_color    = w_bullet_color,
        name            = weapon_name,
        damage          = weapon_damage,
        level           = weapon_level,
        shoot_cooldown  = shoot_cd,
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
    rl.DrawTextureV(
        wp.weapon.texture,
        rl.Vector2{wp.position.x - f32(wp.weapon.texture.width/2), wp.position.y - f32(wp.weapon.texture.width/2)},
        weapon_tint,
    )
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
        name = "Chainsaw"
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


// BULLET STUFF================================================================
//Bullet struct
Bullet :: struct {
    using obj: Object,
    despawn_time: f32,
    color: rl.Color,
    size: rl.Vector2,
    damage: i32, // multiply the weapon damage by the weapon level when setting this variable
    dir: rl.Vector2,
}

CreateBullet :: proc(wp: ^Weapon) -> Bullet {
    id := rand.int31_max(10000000)
    bullet_id := fmt.aprintf("bullet-%d", id)
    d_time: f32
    spd: f32
    bullet_size: rl.Vector2
    name: string

    switch wp.type {
    case .None:
        d_time = 4.0
        spd = 1.2
        bullet_size = rl.Vector2{5, 5}
        name = "pistol"
    case .Finger:
        d_time = 2.0
        spd = 10.0
        bullet_size = rl.Vector2{5,8}
        name = "finger"
    case .Crossbow:
        d_time = 5.0
        spd = 18.0
        bullet_size = rl.Vector2{3, 10}
        name = "crossbow"
    case .Lazer:
        d_time = 0.2
        spd = 0.0
        bullet_size = rl.Vector2{16,16}
        name = "chainsaw"
    case .Machinegun:
        d_time = 5.0
        spd = 8.0
        bullet_size = rl.Vector2{7,7}
        name = "mgun"
    }
    return Bullet {
        id = bullet_id,
        name = name,
        position = g_mem.player.weapon.pos,
        speed = spd,
        despawn_time = g_mem.timer + d_time,
        rotation = wp.rotation + 90,
        color = wp.bullet_color,
        size = bullet_size,
        damage = wp.damage * wp.level,
        dir = rl.Vector2Normalize(rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera()) - g_mem.player.position),
    }
}

UpdateBullet :: proc(bullet: ^Bullet) {
    // TODO: move bullet in the direction of the rotation it spawned


    //bullet.dir = rl.Vector2Normalize(bullet.position - bullet.dir)
    //length: f32 = rl.Vector2Length(direction)

    bullet.position = bullet.position + (bullet.dir * bullet.speed * rl.GetFrameTime() * 100)
    //fmt.printfln("postion: %v", bullet.position)
    //fmt.printfln("speed: %f", bullet.speed)


    // delete bullet if despawn time is greater than timer
    if g_mem.timer >= bullet.despawn_time {
        delete_key(&g_mem.bullets, bullet.id)
    }
}


DrawBullet :: proc(bullet: ^Bullet) {
    // TODO: draw the bullet using rectangle
    rl.DrawRectanglePro(
        rl.Rectangle{
            bullet.position.x,
            bullet.position.y,
            bullet.size.x,
            bullet.size.y,
        },
        rl.Vector2{ bullet.size.x/2, bullet.size.y/2 },
        bullet.rotation,
        bullet.color,
    )
}