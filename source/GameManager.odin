package source

import rl "vendor:raylib"
import "core:fmt"

Game_Memory :: struct {
// GameManger
    scene: SceneState,
    timer: f32,
    timer_count: i32,
    paused: bool,

    // Objects
    player: Player,
    enemies: map[string]Enemy,
    pickup_items: map[string]Pickup_Item,
}


SceneState :: enum {
    Title,
    Settings,
    Gameplay,
    Ending,
}

UpdateTimer :: proc(timer: f32) -> f32 {
    return timer + rl.GetFrameTime()
}

FormatTimer :: proc(timer: f32) -> cstring {
    minutes: i32 = i32(timer) / 60
    seconds: f32 = timer - (f32(minutes)*60)
    return fmt.ctprintf("%d:%2.2f", minutes, seconds)
}

CheckForWeaponUpgrades :: proc() {
    tally_array: [len(WeaponType)]i32 = {}
    fmt.printfln("Size of Weapon Type: %v", len(WeaponType))
    for inventory_item in g_mem.player.inventory {
        switch inventory_item.type {
        case .Finger:
            tally_array[0] = tally_array[0] + 1
        case .Crossbow:
            tally_array[1] = tally_array[1] + 1
        case .Lazer:
            tally_array[2] = tally_array[2] + 1
        case .Machinegun:
            tally_array[3] = tally_array[3] + 1
        }
    }
    fmt.printfln("tally arrray: %v", tally_array)
    // TODO: if tally reaches 3 during a check, loop backwards through inventory, delete 2, upgrade the level to +1 to the 3rd.

}