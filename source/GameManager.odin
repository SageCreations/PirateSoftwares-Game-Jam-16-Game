package source

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:strconv"

Game_Memory :: struct {
// GameManger
    scene: SceneState,
    timer: f32,
    timer_count: i32,
    health_check_count: i32,
    paused: bool,
    end_game: bool,
    spawn_timer: f32,
    spawn_cooldown: f32,
    is_win: bool,

    // Objects
    player: Player,
    enemies: map[string]Enemy,
    boss_id: string,
    weapon_pickups: map[string]Weapon_Pickup,
    bullets: map[string]Bullet,

    //textures
    rules_texture: rl.Texture2D,

    run: bool,
}


SceneState :: enum {
    Title,
    Rules,
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
    tally_map := make(map[string]i32)

    can_upgrade: bool = false
    to_upgrade: WeaponType
    lvl: i32
    for inventory_item in g_mem.player.inventory {
        switch inventory_item.type {
        case .None:
            // tally_array[0] reserved for none slot, nothing should be added to this.
            //fmt.printfln("no weapon in slot")
        case .Finger:
            tally_map[fmt.aprintf("1-%d", inventory_item.level)] += 1
        case .Crossbow:
            tally_map[fmt.aprintf("2-%d", inventory_item.level)] += 1
        case .Lazer:
            tally_map[fmt.aprintf("3-%d", inventory_item.level)] += 1
        case .Machinegun:
            tally_map[fmt.aprintf("4-%d", inventory_item.level)] += 1
        }
    }
    //fmt.printfln("tally arrray: %v", tally_map)
    for key, tally in tally_map {
        if tally >= 3 {
            key_split := strings.split(key, "-")
            if key_split[1] != "3" {
                can_upgrade = true
                to_upgrade = WeaponType(strconv.atoi(key_split[0]))
                lvl = i32(strconv.atoi(key_split[1]))
            }
        }
    }

    if can_upgrade {
        count: int = 1
        #reverse for inventory_item, index in g_mem.player.inventory {
            if inventory_item.type == to_upgrade && inventory_item.level == lvl {
                if count < 3 {
                    g_mem.player.inventory[index] = default_wp
                    count += 1
                } else {
                    g_mem.player.inventory[index].level += 1
                    return
                }
            }
        }
    }
}