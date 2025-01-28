package shooting

import "core:c"
import "core:fmt"
import rl "vendor:raylib"

main :: proc() {

	SCREEN_WIDTH :: 1280
	SCREEN_HEIGHT :: 720

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib Testing Collision")

	colliding_box: rl.Rectangle = {10, cast(c.float)(rl.GetScreenHeight() / 2.0 - 50), 200, 100}
	colliding_box_speed: c.int = 4

	player_box: rl.Rectangle = {10, cast(c.float)(rl.GetScreenHeight() / 2.0 - 30), 60, 60}
	player_pos: rl.Vector2 = {}

	box_collision: rl.Rectangle = {}

	bullet_pos: rl.Vector2 = {}
	bullet_box: rl.Rectangle = {10, cast(c.float)(rl.GetScreenHeight() / 2.0 - 30), 80, 80}


	screen_upper_limit: c.int = 40

	moving: bool = true
	collision: bool = false
	is_paused: bool = false
	shooting: bool = false
	has_shot: bool = false

	bullet_timer: c.int = 0

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {

		if !is_paused {
			colliding_box.x += cast(c.float)colliding_box_speed
		}

		if colliding_box.x + colliding_box.width >= cast(c.float)rl.GetScreenWidth() ||
		   colliding_box.x <= 0 {
			colliding_box_speed *= -1
		}

		if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			player_box.x += 4.0
			player_pos.x += 4.0
			moving = true
		}
		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			player_box.x -= 4.0
			player_pos.x -= 4.0
			moving = true
		}
		if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
			player_box.y -= 4.0
			player_pos.y -= 4.0
			moving = true
		}
		if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
			player_box.y += 4.0
			player_pos.y += 4.0
			moving = true
		}
		if rl.IsMouseButtonPressed(.LEFT) && !shooting {
			bullet_pos *= -player_pos
			has_shot = true
			shooting = true
		}

		if has_shot == true {
			bullet_timer += 1
		}

		if bullet_timer >= 3 {
			shooting = !shooting
			has_shot = false
		}

		//Collision Checker
		if player_box.x + player_box.width >= cast(c.float)rl.GetScreenWidth() {
			player_box.x = cast(c.float)rl.GetScreenWidth() - player_box.width
		} else if player_box.x <= 0 {
			player_box.x = 0
		}

		if player_box.y + player_box.height >= cast(c.float)rl.GetScreenWidth() {
			player_box.x = cast(c.float)rl.GetScreenHeight() - player_box.height
		} else if player_box.y <= cast(c.float)screen_upper_limit {
			player_box.y = cast(c.float)screen_upper_limit
		}

		collision = rl.CheckCollisionRecs(colliding_box, player_box)

		if rl.IsKeyPressed(.SPACE) {
			is_paused = !is_paused
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawRectangle(0, 0, SCREEN_WIDTH, screen_upper_limit, collision ? rl.RED : rl.BLACK)
		rl.DrawRectangleRec(colliding_box, rl.GOLD)
		rl.DrawRectangleRec(player_box, rl.BLUE)

		if collision {
			rl.DrawRectangleRec(box_collision, rl.LIME)

			rl.DrawText(
				"COLLISION!",
				rl.GetScreenWidth() / 2 - rl.MeasureText("COLLISION!", 20) / 2,
				screen_upper_limit / 2 - 10,
				20,
				rl.BLACK,
			)

			rl.DrawText(
				rl.TextFormat(
					"Collision Area: %i",
					cast(c.int)box_collision.width * cast(c.int)box_collision.height,
				),
				rl.GetScreenWidth() / 2 - 100,
				screen_upper_limit + 10,
				20,
				rl.BLACK,
			)
		}

		if moving {
			rl.DrawText(
				rl.TextFormat("Player Current Pos: %f, %f", player_pos.x, player_pos.y),
				rl.GetScreenWidth() / 2 - 100,
				screen_upper_limit + 30,
				20,
				rl.BLACK,
			)
		}

		if has_shot {
			rl.DrawRectanglePro(bullet_box, player_pos, 0.0, rl.RED)
			fmt.println("Bullet Box Should have spawned")
		}

		rl.DrawText("Press Space to Pause/Resume", 20, SCREEN_HEIGHT - 35, 20, rl.LIGHTGRAY)
		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	rl.CloseAudioDevice()
	rl.CloseWindow()

}
