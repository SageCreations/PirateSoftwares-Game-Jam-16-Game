package source

import rl "vendor:raylib"
import "core:math/linalg"
import "core:math"

Player :: struct {
    using obj: Object,
    weapon: Weapon,
    offset: rl.Vector2,
    health: i32,
    gamepad: i32,
    inventory: [5]Weapon,
    selected: i32,
}

player_update :: proc(player: ^Player, delta_time: f32) {
    input: rl.Vector2


    if rl.IsGamepadAvailable(player.gamepad) {

        // Get axis values
        leftStickX: f32 = rl.GetGamepadAxisMovement(player.gamepad, .LEFT_X)
        leftStickY: f32 = rl.GetGamepadAxisMovement(player.gamepad, .LEFT_Y)
        rightStickX: f32 = rl.GetGamepadAxisMovement(player.gamepad, .RIGHT_X)
        rightStickY: f32 = rl.GetGamepadAxisMovement(player.gamepad, .RIGHT_Y)
        leftTrigger: f32 = rl.GetGamepadAxisMovement(player.gamepad, .LEFT_TRIGGER)
        rightTrigger: f32 = rl.GetGamepadAxisMovement(player.gamepad, .RIGHT_TRIGGER)

        // Calculate deadzones
        if leftStickX > -0.1 && leftStickX < 0.1 {leftStickX = 0.0 }
        if leftStickY > -0.1 && leftStickY < 0.1 {leftStickY = 0.0 }
        if rightStickX > -0.1 && rightStickX < 0.1 {rightStickX = 0.0 }
        if rightStickY > -0.1 && rightStickY < 0.1 {rightStickY = 0.0 }
        if leftTrigger < -0.9 { leftTrigger = -1.0 }
        if rightTrigger < -0.9 { rightTrigger = -1.0 }
        // TODO: implement controller movement

    } else {
        // Movement
        if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
            input.y -= player.speed * delta_time
        }
        if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
            input.y += player.speed * delta_time
        }
        if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
            input.x -= player.speed * delta_time
        }
        if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
            input.x += player.speed * delta_time
        }

        // Weapon Selection
        if rl.IsKeyPressed(.Q) {
            if player.selected == 0 {
                player.selected = 4
            } else {
                player.selected = player.selected - 1
            }
        }
        if rl.IsKeyPressed(.E) {
            if player.selected == 4 {
                player.selected = 0
            } else {
                player.selected = player.selected + 1
            }
        }
    }

    // move player
    input = linalg.normalize0(input)
    player.position += input * rl.GetFrameTime() * 100

    // switch weapon
    player.weapon = player.inventory[player.selected]
}

player_draw :: proc(player: ^Player) {
    rl.DrawTextureEx(player.texture, rl.Vector2{player.position.x - f32(player.texture.width/2), player.position.y - f32(player.texture.width/2)}, 0, 1, rl.WHITE)
    //rl.DrawRectangleV(player.position, {10, 10}, rl.BLUE)

    // weapon
    mouse_pos_world2d := rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())
    direction: rl.Vector2 = mouse_pos_world2d - player.position
    angleRadians: f32 = math.atan2_f32(direction.y, direction.x)
    angleDegrees: f32 = angleRadians * rl.RAD2DEG

    // 3. Rotate the offset vector to create the orbiting effect
    rotatedOffsetX: f32 = player.offset.x * math.cos_f32(angleRadians) - player.offset.y * math.sin_f32(angleRadians)
    rotatedOffsetY: f32 = player.offset.x * math.sin_f32(angleRadians) + player.offset.y * math.cos_f32(angleRadians)

    rl.DrawRectanglePro(
        rl.Rectangle{ player.position.x + rotatedOffsetX, player.position.y + rotatedOffsetY, 5, 5 },
        rl.Vector2{ 2.5, 2.5 },
        angleDegrees,
        rl.BLUE,
    )

    rl.DrawTexturePro(
        player.weapon.texture,
        rl.Rectangle{ 0, 0, f32(player.weapon.texture.width), f32(player.weapon.texture.height) }, // source
        rl.Rectangle{ player.position.x + rotatedOffsetX, player.position.y + rotatedOffsetY, f32(player.weapon.texture.width), f32(player.weapon.texture.height) }, // destination
        rl.Vector2{ f32(player.weapon.texture.width/2), f32(player.weapon.texture.height/2) }, // pivot = center
        angleDegrees,
        rl.WHITE,
    )
}


player_collision:: proc(player: ^Player, other: ^Object) {
    // TODO: handle what happens with the player on collision detection
}


