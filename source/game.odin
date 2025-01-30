/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
      pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g_mem` global
      variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package source

import "core:fmt"
import rl "vendor:raylib"
import "core:math/rand"

PIXEL_WINDOW_HEIGHT :: 400

DEBUG_MODE :: true


g_mem: ^Game_Memory
sound_level: f32


game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = h/PIXEL_WINDOW_HEIGHT,
		target = g_mem.player.position,
		offset = { w/2, h/2 },
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = 1,
	}
}

update :: proc() {
	switch g_mem.scene {
	case .Title:

	case .Rules:

	case .Settings:

	case .Gameplay:
		if rl.IsKeyPressed(.P) {
			g_mem.paused = !g_mem.paused
		}
		if !g_mem.paused {
			g_mem.timer = UpdateTimer(g_mem.timer)

			if !g_mem.end_game && g_mem.timer > 900.00  {
				g_mem.end_game = true // set end_game flag

				// spawn in boss
				boss := CreateBoss()
				g_mem.enemies[boss.id] = boss
				g_mem.boss_id = boss.id
			}

			// check if its time to spawn enemies
			if g_mem.timer >= g_mem.spawn_timer + g_mem.spawn_cooldown {
				SpawnEnemies()
			}

			// check if player can shoot
			if g_mem.timer >= g_mem.player.shot_at_start + g_mem.player.weapon.shoot_cooldown {
				g_mem.player.can_shoot = true
				g_mem.player.shot_at_start = 0.0
			}

			player_update(&g_mem.player, rl.GetFrameTime())

			if (i32(g_mem.timer) / 60) != g_mem.timer_count  {
				g_mem.timer_count = (i32(g_mem.timer) / 60)
				CheckForWeaponUpgrades()
			}

			for key, &enemy in g_mem.enemies {
				UpdateEnemy(&enemy)
				if IsColliding(g_mem.player.hitbox, enemy.hitbox) {
					PlayerCollision(&g_mem.player, &enemy)
				}

				if enemy.is_dead {
					// chance to drop loot
					if !g_mem.end_game && rand.int_max(100)+1 <= 25 {
						pass: bool = true
						new_item := CreateWeaponPickup(enemy.position)
						// check if enemy died on top of exisiting item to not stack them
						for _, item in g_mem.weapon_pickups {
							if IsColliding(new_item.hitbox, item.hitbox) {
								pass = false
								return
							}
						}

						if pass {
							g_mem.weapon_pickups[new_item.id] = new_item
						}
					}
					// delete enemy from list. TODO: add death anim. maybe?
					delete_key(&g_mem.enemies, key)
				}
			}

			// check for collision of pickup items
			for key, &item in g_mem.weapon_pickups {
				// despawn needs to be last
				if g_mem.timer >= item.despawn_timer + 30 {
					delete_key(&g_mem.weapon_pickups, key)
				}
			}


			if g_mem.player.is_dead {
				g_mem.scene = .Ending
			}

		}
	case .Ending:
	}

	if rl.IsKeyPressed(.ESCAPE) {
		g_mem.run = false
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.GRAY)

//2D World
	rl.BeginMode2D(game_camera())

	switch g_mem.scene {
	case .Title:
	case .Settings:
	case .Rules:
	case .Gameplay:
		if g_mem.end_game {
			BossIndicator()
		}

		// player draws
		player_draw(&g_mem.player)
		// enemy draws
		for _, &enemy in g_mem.enemies {
			DrawEnemy(&enemy)
		}
		rl.DrawRectangleV({-30, -20}, {10, 10}, rl.PURPLE) //TODO: do the same for pick up items
		// pickup item draws
		for key, &item in g_mem.weapon_pickups {
			DrawWeaponPickup(&item)
			if IsColliding(g_mem.player.hitbox, item.hitbox) {
				rl.DrawText(GetPickupPrompt(item.weapon), i32(item.position.x), i32(item.position.y), 8, rl.WHITE)
				// pickup items
				if rl.IsKeyPressed(.F) {
					if WeaponToInventory(&item.weapon) {
						delete_key(&g_mem.weapon_pickups, key)
					}
				}
			}
		}
	case .Ending:
	}
	rl.EndMode2D()

//GUI
	rl.BeginMode2D(ui_camera())
	switch g_mem.scene {
	case .Title:
		// Game Title
		rl.DrawText("Place Holder", 10, 10, 100, rl.WHITE)
		// Settings button
		if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()-210), 10, 200, 50}, "Settings") {
			g_mem.scene = .Settings
		}
		// Rules button
		if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()-210), 75, 200, 50}, "Rules") {
			g_mem.scene = .Rules
		}
		// start button
		if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-100, f32(rl.GetScreenHeight()-100), 200, 50}, "Start Game") {
			g_mem.scene = .Gameplay
		}
		// controls explanation
		rl.DrawText("Controls:", 10, 200, 40, rl.WHITE)
		rl.DrawText("Movement: WASD or arrow keys", 20, 250, 20, rl.WHITE)
		rl.DrawText("Inventory switch: Q for leftward selection and E for rightward selection", 20, 275, 20, rl.WHITE)
		rl.DrawText("Pickup Weapon: F key", 20, 300, 20, rl.WHITE)
		rl.DrawText("Drop Selected Weapon: R key", 20, 325, 20, rl.WHITE)
		rl.DrawText("Pause Game: P key", 20, 350, 20, rl.WHITE)
	case .Rules:
		if rl.GuiButton(rl.Rectangle{10, 10, 200, 50}, "Back") {
			g_mem.scene = .Title
		}
		rl.DrawTextureEx(g_mem.rules_texture, {0,0}, 0, 1, rl.WHITE)
	case .Settings:
		if rl.GuiButton(rl.Rectangle{10, 10, 200, 50}, "Back") {
			g_mem.scene = .Title
		}
		rl.GuiSlider(rl.Rectangle{f32(rl.GetScreenWidth()/2) - 100.0, 100.0, 200.0, 50.0}, cstring("Sound: 0"), cstring(" 100"), &sound_level, 0.0, 1.0)
	case .Gameplay:
		// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
		// cleared at the end of the frame by the main application, meaning inside
		// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.

		if DEBUG_MODE {
			rl.DrawText(fmt.ctprintf("player_pos: %v", g_mem.player.position), 5, 5, 20, rl.WHITE)
			rl.DrawText(
			fmt.ctprintf("mouse_pos: %v", rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())), 5,  25, 20, rl.WHITE)
			rl.DrawFPS(rl.GetScreenWidth()-30, 5)
			rl.DrawText(fmt.ctprintf("Enemies Spawned in: %d", len(g_mem.enemies)), 5, 45, 20, rl.WHITE)
		}
		// timer
		if !g_mem.end_game {
			rl.DrawText(FormatTimer(g_mem.timer), (rl.GetScreenWidth()/2)-50, 5, 50, rl.WHITE)
		} else {
			rl.DrawText("15:00", (rl.GetScreenWidth()/2)-50, 5, 50, rl.WHITE)
		}

		// Inventory HUD
		for index in 0..<5 {
			scaler: i32 = i32(index) * 100
			rec := rl.Rectangle{ (f32(rl.GetScreenWidth()/2)-250) + f32(scaler), f32(rl.GetScreenHeight()-100), 100, 100 }
			rl.DrawRectangleLinesEx(rec, 5, rl.WHITE)
			rl.DrawTextureEx(
				g_mem.player.inventory[index].texture,
				rl.Vector2{(f32(rl.GetScreenWidth()/2)-245) + f32(scaler), f32(rl.GetScreenHeight()-95)},
				0,
				5.5,
				GetWeaponTint(g_mem.player.inventory[index].level),
			)
		}
		rl.DrawRectangleLinesEx(rl.Rectangle{ (f32(rl.GetScreenWidth()/2)-250) + f32(g_mem.player.selected * 100), f32(rl.GetScreenHeight()-100), 100, 100 }, 5, rl.GREEN)
		rl.DrawText(GetPickupPrompt(g_mem.player.inventory[g_mem.player.selected], true), rl.GetScreenWidth()/2-250, rl.GetScreenHeight()-125, 20, rl.WHITE)

		//Health HUD
		for i := g_mem.player.health; i > 0; i-=1 {
			scaler: i32 = i32(i) * 50
			rl.DrawRectangleV({f32(rl.GetScreenWidth()) - f32(scaler), 20.0}, {40, 40}, rl.RED)
		}

		// pause menu
		if g_mem.paused {
			rl.DrawRectangle(10, 10, rl.GetScreenWidth()-20, rl.GetScreenHeight()-20, rl.DARKGRAY)
			if rl.GuiButton(rl.Rectangle{20, 20, 200, 50}, "Back") {
				g_mem.paused = !g_mem.paused
			}
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 50, 400, 100}, "Restart") {
				game_init(restart=true)
			}
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 200, 400, 100}, "Return to Title") {
				game_init(false)
			}
		}
	case .Ending:
		if g_mem.is_win {
			rl.DrawText("Congratulations!", rl.GetScreenWidth()/2-410, 70, 100, rl.GREEN)
			rl.DrawText("You Won!!!", rl.GetScreenWidth()/2-240, 170, 100, rl.GREEN)
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 300, 400, 100}, "Play Again?") {
				game_init(restart=true)
			}
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 450, 400, 100}, "Back to Title") {
				game_init(false)
			}
		} else {
			rl.DrawText("Game Over...", rl.GetScreenWidth()/2-270, 70, 100, rl.RED)
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 300, 400, 100}, "Try Again") {
				game_init(restart=true)
			}
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 450, 400, 100}, "Back to Title") {
				game_init(false)
			}
		}
	}
	rl.EndMode2D()

	rl.EndDrawing()
}

@(export)
game_update :: proc() {
	update()
	draw()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Placeholder Name")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)
	rl.SetExitKey(nil)

	// init global Settings here
	sound_level = 0.7
}

@(export)
game_init :: proc(restart: bool = false) {
// defaults to overwrite
	player_default := Player{
		position = rl.Vector2{0, 0},
		texture = rl.LoadTexture("assets/round_cat.png"),
		speed = 2.0,
		rotation = 0,
		hitbox = Circle{{0,0}, 5.0},
		id = "player-1",
		name = "player",
		offset = rl.Vector2{16, 0},
		indicator_offset = rl.Vector2{26, 0},
		weapon = Weapon{
			type = .None,
			name = "weapon",
			texture = rl.Texture2D{},
			bullet_color = rl.GREEN,
			damage = 15,
			level = 0,
			shoot_cooldown = 0.7,
		},
		health = 4,
		gamepad = 0,
		inventory = {},
		selected = 0,
		invuln = false,
		invuln_time_start = 0.0,
		is_dead = false,
		indicator = rl.LoadTexture("assets/indicator.png"),
		can_shoot = true,
	}

	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		run=true,
		// GameManger
		scene = (restart) ? .Gameplay : .Title,
		timer = 0.0,
		timer_count = 0,
		paused = false,
		end_game = false,
		spawn_cooldown = 48.0,
		is_win = false,

		// default overwrites
		player = player_default,
		enemies = make(map[string]Enemy),
		boss_id = "",
		weapon_pickups = make(map[string]Weapon_Pickup),
		bullets = make(map[string]Bullet),

		// textures
		rules_texture = rl.LoadTexture("assets/Rules.png"),
	}
	SpawnEnemies() // init spawn of enemies, spawn_timer gets set to timer init


	// TODO: make a forloop to create some enemies, for some reason only 1 is showing up on screen?, might all be spawning on top of each other


	game_hot_reloaded(g_mem)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
	// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g_mem.run
}

@(export)
game_shutdown :: proc() {
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)

// Here you can also set your own global variables. A good idea is to make
// your global variables into pointers that point to something inside
// `g_mem`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}