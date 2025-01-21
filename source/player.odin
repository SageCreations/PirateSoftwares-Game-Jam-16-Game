package source

import rl "vendor:raylib"
import "core:math/linalg"


Player :: struct {
    using obj: Object,
    health: i32,
    gamepad: i32,
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
    }

    input = linalg.normalize0(input)
    player.position += input * rl.GetFrameTime() * 100
}

player_draw :: proc(player: ^Player) {
    rl.DrawTextureEx(player.texture, player.position, 0, 1, rl.WHITE)
    //rl.DrawRectangleV(player.position, {10, 10}, rl.BLUE)
}

player_collision:: proc(player: ^Player, other: ^Object) {
    // TODO: handle what happens with the player on collision detection
}