package source

import rl "vendor:raylib"
import "core:math/rand"
import "core:fmt"
import b2 "vendor:box2d"

Enemy :: struct {
    using obj: Object,
    health: i32,
}


create_enemy :: proc() -> Enemy {
    id := rand.int31_max(899999)+100000
    rand_x := rand.float32_range(g_mem.player.position.x-500, g_mem.player.position.x+500)
    rand_y := rand.float32_range(g_mem.player.position.y-500, g_mem.player.position.y+500)
    return Enemy{
        position = rl.Vector2{-50, -30},
        size = rl.Vector2{1, 1},
        texture = rl.LoadTexture("assets/enemy_placeholder.png"),
        speed = 0.1,
        rotation = 0,
        state = 0,
        body = b2.BodyDef{
            type = .dynamicBody,
            position = b2.Vec2{rand_x, rand_y},
            rotation = b2.MakeRot(0.0),
            linearVelocity = b2.Vec2{0,0},
            angularVelocity= 0,
            linearDamping = 0,
            angularDamping = 0,
            gravityScale = 1,
            sleepThreshold = 0.05,
            enableSleep=false,
            isAwake = true,
            fixedRotation=true,
            isBullet=false,
            isEnabled=true,
            automaticMass = true,
        },
        hitbox = b2.Circle{{0, 0}, 32.0},
        id = id,
        name = fmt.aprintf("enemy-%d", id),
        health = 100,
    }
}


enemy_update :: proc(enemy: ^Enemy) {
    //what to do.........
    direction: rl.Vector2 = enemy.position - g_mem.player.position
    length: f32 = rl.Vector2Length(direction)

    direction = direction * (enemy.speed / length) // Normalize and scale
    enemy.position = enemy.position - direction


}

enemy_draw :: proc(enemy: ^Enemy) {
    rl.DrawRectangleV(enemy.position, {10, 10}, rl.RED) //TODO: do the same for pick up items
    //rl.DrawTextureEx(enemy.texture, enemy.position, enemy.rotation, 0.03, rl.WHITE)
}



