package source

import rl "vendor:raylib"
import "core:math/rand"
import "core:fmt"

Enemy :: struct {
    using obj: Object,
    health: i32,
}


CreateEnemy :: proc() -> Enemy {
    id := rand.int31_max(899999)+100000
    rand_x := rand.float32_range(g_mem.player.position.x-500, g_mem.player.position.x+500)
    rand_y := rand.float32_range(g_mem.player.position.y-500, g_mem.player.position.y+500)
    enemy_texture := rl.LoadTexture("assets/enemy_placeholder.png")
    return Enemy{
        position = rl.Vector2{rand_x, rand_y},
        size = rl.Vector2{1, 1},
        texture =enemy_texture,
        speed = 0.5,
        rotation = 0,
        state = 0,
        hitbox = Circle{{rand_x+f32(enemy_texture.width/2), rand_y+f32(enemy_texture.height/2)}, 4.0},
        id = id,
        name = fmt.aprintf("enemy-%d", id),
        health = 100,
    }
}


UpdateEnemy :: proc(enemy: ^Enemy) {
    // check collision for other enemies

    is_colliding: bool = false
    for _, &other in g_mem.enemies {
        if enemy.name != other.name {
            delta := rl.Vector2{other.position.x - enemy.position.x, other.position.y - enemy.position.y}
            distance: f32 = rl.Vector2Distance(other.position, enemy.position)
            overlap: f32 = enemy.hitbox.radius + other.hitbox.radius - distance

            if overlap > 0 {
                is_colliding = IsColliding(enemy.hitbox, other.hitbox)

                // Normalize the delta to get the collision normal
                collision_normal := rl.Vector2Normalize(delta)

                // Proportional movement adjustment to resolve overlap
                total_radius := enemy.hitbox.radius + other.hitbox.radius
                enemy_ratio: f32 = enemy.hitbox.radius / total_radius
                other_ratio: f32 = other.hitbox.radius / total_radius

                // Adjust positions proportionally
                enemy.position = enemy.position - collision_normal * (overlap * enemy_ratio)
                enemy.hitbox.center = rl.Vector2{
                    enemy.position.x + f32(enemy.texture.width / 2),
                    enemy.position.y + f32(enemy.texture.height / 2),
                }

                other.position = other.position + collision_normal * (overlap * other_ratio)
                other.hitbox.center = rl.Vector2{
                    other.position.x + f32(other.texture.width / 2),
                    other.position.y + f32(other.texture.height / 2),
                }
            }
        }
    }


    // Movement towards the player
    direction: rl.Vector2 = enemy.position - g_mem.player.position
    length: f32 = rl.Vector2Length(direction)

    direction = direction * (enemy.speed / length) // Normalize and scale
    enemy.position = (enemy.position - direction)
    enemy.hitbox.center = rl.Vector2{enemy.position.x+f32(enemy.texture.width/2), enemy.position.y+f32(enemy.texture.height/2)}

}

DrawEnemy :: proc(enemy: ^Enemy) {
    //rl.DrawRectangleV(enemy.position, {10, 10}, rl.RED) //TODO: do the same for pick up items
    rl.DrawTextureEx(enemy.texture, enemy.position, enemy.rotation, 1, rl.WHITE)
    if DEBUG_MODE {
        DrawCollider(enemy.hitbox)
    }
}


DebugPrintEnemy :: proc(enemy: Enemy) {
    //fmt.printfln("Enemy Data:\n%v", enemy)
}


