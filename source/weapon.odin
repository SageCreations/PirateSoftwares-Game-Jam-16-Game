package source

import rl "vendor:raylib"
import "core:math/rand"
import "core:fmt"

WeaponType :: enum uint {
    Finger      = 0,
    Crossbow    = 1,
    Lazer       = 2,
    Machinegun  = 3,
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
    using pickup: Pickup_Item,
    type: WeaponType,
    level: i32,
}

CreateWeapon :: proc () -> Weapon {
    weaponType := rand.int_max(len(WeaponType))
    weapon_texture: rl.Texture2D
    w_bullet_texture: rl.Texture2D
    weapon_name: string
    weapon_damage: i32 = 30 //TODO: balance this later
    weapon_level: i32 = rand.int31_max(2)+1
    switch WeaponType(weaponType) {
    case .Finger:
        weapon_texture = rl.LoadTexture("assets/FingerGun.png")
        w_bullet_texture = rl.LoadTexture("")
        weapon_name = "Finger"
    case .Crossbow:
        weapon_texture = rl.LoadTexture("assets/CrossBow.png")
        w_bullet_texture = rl.LoadTexture("")
        weapon_name = "Crossbow"
    case .Lazer:
        weapon_texture = rl.LoadTexture("assets/Edge_Chainsaw.png")
        w_bullet_texture = rl.LoadTexture("")
        weapon_name = "Lazer"
    case .Machinegun:
        weapon_texture = rl.LoadTexture("assets/MGun.png")
        w_bullet_texture = rl.LoadTexture("")
        weapon_name = "Machine gun"
    }
    fmt.printfln("||||| Weapon name: %s", weapon_name)
    return Weapon{
        type            = WeaponType(weaponType),
        texture         = weapon_texture,
        bullet_texture  = w_bullet_texture,
        name            = weapon_name,
        damage          = weapon_damage,
        level           = weapon_level,
    }
}

DrawWeaponPickup :: proc(wp: ^Weapon_Pickup) {

}

testWeaponInventory :: proc() -> [5]Weapon {
//random ints for testing TODO: delete late
    testing_inven: [5]Weapon = {}
    for i in 0..<5 {
        //TODO: used the rand-x and rand_y for pickup testing
    //        rand_x := rand.float32_range(g_mem.player.position.x-500, g_mem.player.position.x+500)
    //        rand_y := rand.float32_range(g_mem.player.position.y-500, g_mem.player.position.y+500)
        weapon := CreateWeapon()
        fmt.printfln("Weapon: %v", weapon)
        testing_inven[i] = weapon
    }
    return testing_inven
}

