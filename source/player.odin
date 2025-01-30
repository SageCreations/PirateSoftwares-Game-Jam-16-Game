package source

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"
//import "core:fmt"

Player :: struct {
	using obj: Object,
	weapon:    Weapon,
	health:    i32,
	gamepad:   i32,
}

//Bullet struct
Bullet :: struct {
	using obj:     Object,
	despawn_timer: f32,
	is_shooting:   bool,
}

player_update :: proc(player: ^Player, delta_time: f32, bullet: ^Bullet) {
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
		if leftStickX > -0.1 && leftStickX < 0.1 {leftStickX = 0.0}
		if leftStickY > -0.1 && leftStickY < 0.1 {leftStickY = 0.0}
		if rightStickX > -0.1 && rightStickX < 0.1 {rightStickX = 0.0}
		if rightStickY > -0.1 && rightStickY < 0.1 {rightStickY = 0.0}
		if leftTrigger < -0.9 {leftTrigger = -1.0}
		if rightTrigger < -0.9 {rightTrigger = -1.0}
		// TODO: implement controller movement

	} else {
		direction := rl.GetMousePosition() - player.position
		distance := rl.Vector2DistanceSqrt(direction, direction)

		if distance > 0 {
			direction = direction / distance
		}
		player.weapon.rotation = math.atan2_f32(direction.y, direction.x) * rl.RAD2DEG

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

		//Adding this for bullet being is_shooting
		if rl.IsMouseButtonPressed(.LEFT) {
			bullet.is_shooting = true
		}
	}

	input = linalg.normalize0(input)
	player.position += input * rl.GetFrameTime() * 100
}

player_draw :: proc(player: ^Player, bullet: ^Bullet) {
	rl.DrawTextureEx(player.texture, player.position, 0, 1, rl.WHITE)
	//rl.DrawRectangleV(player.position, {10, 10}, rl.BLUE)

	// weapon
	mouse_pos_world2d := rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())
	//rl.GetScreenTo
	direction := mouse_pos_world2d
	//distance := rl.Vector2DistanceSqrt(direction, direction)
	//    if distance > 0 {
	//        direction = direction/distance
	//    }
	//weapon_offset := player.position


	//Adding this portion for the bullet
	if bullet.is_shooting == true {
		rl.DrawRectanglePro(g_mem.player.state, player.position, 0.0, rl.WHITE)
	}

	rl.DrawRectanglePro(
		rl.Rectangle{direction.x, direction.y, 5, 5},
		{player.position.x + 2.5, player.position.y + 2.5},
		math.atan2_f32(mouse_pos_world2d.y, mouse_pos_world2d.x) * rl.RAD2DEG,
		rl.BLUE,
	)

}


player_collision :: proc(player: ^Player, other: ^Object) {
	// TODO: handle what happens with the player on collision detection
}
