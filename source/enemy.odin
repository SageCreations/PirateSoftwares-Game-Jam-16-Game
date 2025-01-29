package source

import rl "vendor:raylib"
import "core:math/rand"
import "core:fmt"

Enemy :: struct {
    using obj: Object,
    health: i32,
    is_dead: bool,
}


CreateEnemy :: proc() -> Enemy {
    id := rand.int31_max(899999)+100000
    rand_y: f32 = 0.0
    rand_x := rand.float32_range(g_mem.player.position.x - f32(1280), g_mem.player.position.x + f32(1280))
    if rand_x < g_mem.player.position.x - f32(1280/2) || rand_x > g_mem.player.position.x + f32(1280/2) {
        rand_y = rand.float32_range(g_mem.player.position.y-f32(720), g_mem.player.position.y+f32(720))
    } else {
        if rand.int_max(2) == 0 {
            rand_y = rand.float32_range(g_mem.player.position.y-f32(720), g_mem.player.position.y-f32(720/2))
        } else {
            rand_y = rand.float32_range(g_mem.player.position.y+f32(720/2), g_mem.player.position.y+f32(720))
        }

    }

    enemy_texture := rl.LoadTexture("assets/enemy_placeholder.png")
    return Enemy{
        position = rl.Vector2{rand_x, rand_y},
        texture =enemy_texture,
        speed = 0.5,
        rotation = 0,
        hitbox = Circle{{rand_x+f32(enemy_texture.width/2), rand_y+f32(enemy_texture.height/2)}, 4.0},
        id = fmt.aprintf("enemy-%d", id),
        name = "enemy",
        health = 100,
        is_dead = false,
    }
}

// EnemySpawner
SpawnEnemies :: proc() {
    for _ in 0..<100 {
        enemy := CreateEnemy()
        g_mem.enemies[fmt.aprintf("enemy-%d", enemy.id)] = enemy
    }
    g_mem.spawn_timer = g_mem.timer

    if g_mem.spawn_cooldown >= 21.0 {
        g_mem.spawn_cooldown -= 3.0
    }
}


UpdateEnemy :: proc(enemy: ^Enemy) {
    // check collision for other enemies
    _EnemyCollision(enemy)

    // Movement towards the player
    direction: rl.Vector2 = enemy.position - g_mem.player.position
    length: f32 = rl.Vector2Length(direction)

    direction = direction * (enemy.speed / length) // Normalize and scale
    enemy.position = (enemy.position - direction)
    enemy.hitbox.center = rl.Vector2{enemy.position.x, enemy.position.y}

    mouse_pos_world2d: rl.Vector2 = rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())

    if IsColliding(Circle{mouse_pos_world2d, 5.0}, enemy.hitbox) {
        DamageEnemy(enemy, 110)  // TODO: testing only, pass in bullet damage later.
    }
}

DrawEnemy :: proc(enemy: ^Enemy) {
    //rl.DrawRectangleV(enemy.position, {10, 10}, rl.RED) //TODO: do the same for pick up items
    rl.DrawTextureEx(enemy.texture, rl.Vector2{enemy.position.x-f32(enemy.texture.width/2), enemy.position.y-f32(enemy.texture.height/2)}, enemy.rotation, 1, rl.WHITE)
    if DEBUG_MODE {
        DrawCollider(enemy.hitbox)
    }
}


_EnemyCollision :: proc(enemy: ^Enemy) {
    for _, &other in g_mem.enemies {
        if enemy.id != other.id {
            delta := rl.Vector2{other.position.x - enemy.position.x, other.position.y - enemy.position.y}
            distance: f32 = rl.Vector2Distance(other.position, enemy.position)
            overlap: f32 = enemy.hitbox.radius + other.hitbox.radius - distance

            if overlap > 0 {
            // Normalize the delta to get the collision normal
                collision_normal := rl.Vector2Normalize(delta)

                // Proportional movement adjustment to resolve overlap
                total_radius := enemy.hitbox.radius + other.hitbox.radius
                enemy_ratio: f32 = enemy.hitbox.radius / total_radius
                other_ratio: f32 = other.hitbox.radius / total_radius

                // Adjust positions proportionally
                enemy.position = enemy.position - collision_normal * (overlap * enemy_ratio)
                enemy.hitbox.center = rl.Vector2{
                    enemy.position.x,
                    enemy.position.y,
                }

                other.position = other.position + collision_normal * (overlap * other_ratio)
                other.hitbox.center = rl.Vector2{
                    other.position.x,
                    other.position.y,
                }
            }
        }
    }
}


DebugPrintEnemy :: proc(enemy: Enemy) {
    //fmt.printfln("Enemy Data:\n%v", enemy)
}

DamageEnemy :: proc(enemy: ^Enemy, dmg: i32) {
    enemy.health -= dmg
    if enemy.health <= 0 {
        enemy.is_dead = true
    }
}


