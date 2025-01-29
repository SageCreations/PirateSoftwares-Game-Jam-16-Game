/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
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

	case .Settings:

	case .Gameplay:
		if rl.IsKeyPressed(.P) {
			g_mem.paused = !g_mem.paused
		}
		if !g_mem.paused {
			g_mem.timer = UpdateTimer(g_mem.timer)

			// check if its time to spawn enemies
			if g_mem.timer >= g_mem.spawn_timer + g_mem.spawn_cooldown {
				SpawnEnemies()
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
					if rand.int_max(100)+1 <= 25 {
						pass: bool = true
						new_item := CreateWeaponPickup(enemy.position)

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
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.GRAY)

//2D World
	rl.BeginMode2D(game_camera())

	switch g_mem.scene {
	case .Title:
	case .Settings:
	case .Gameplay:
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
		if rl.GuiButton(rl.Rectangle{10, 10, 200, 50}, "Settings") {
			g_mem.scene = .Settings
		}
		if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-100, f32(rl.GetScreenHeight()/2)-25, 200, 50}, "Start Game") {
			g_mem.scene = .Gameplay
		}
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
		rl.DrawText(FormatTimer(g_mem.timer), (rl.GetScreenWidth()/2)-50, 5, 50, rl.WHITE)

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

		if g_mem.paused {
			rl.DrawRectangle(10, 10, rl.GetScreenWidth()-20, rl.GetScreenHeight()-20, rl.DARKGRAY)
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 50, 400, 100}, "Restart") {
				game_init(restart=true)
			}
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 200, 400, 100}, "Return to Title") {
				game_init()
			}
		}
	case .Ending:
		if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 50, 400, 100}, "Try Again") {
			game_init(restart=true)
		}
		if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 200, 400, 100}, "Back to Title") {
			game_init()
		}
	}
	rl.EndMode2D()

	rl.EndDrawing()
}

@(export)
game_update :: proc() -> bool {
	update()
	draw()
	return !rl.WindowShouldClose()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Placeholder Name")
	//rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)

	// init global Settings here
	sound_level = 0.7
	fmt.printfln("Window Init!")
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
		weapon = Weapon{
			type = .Finger,
			name = "Finger Gun",
			texture = rl.LoadTexture("assets/FingerGun.png"),
			bullet_texture = rl.LoadTexture("assets/round_cat.png"),
			damage = 34,
			level = 1,
		},
		health = 100,
		gamepad = 0,
		inventory = {},
		selected = 0,
		invuln = false,
		invuln_time_start = 0.0,
		is_dead = false,
	}

	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		// GameManger
		scene = (restart) ? .Gameplay : .Title,
		timer = 0.0,
		timer_count = 0,
		paused = false,
		spawn_cooldown = 48.0,

		// default overwrites
		player = player_default,
		enemies = make(map[string]Enemy),
		weapon_pickups = make(map[string]Weapon_Pickup),
	}
	SpawnEnemies() // init spawn of enemies, spawn_timer gets set to timer init


	// TODO: make a forloop to create some enemies, for some reason only 1 is showing up on screen?, might all be spawning on top of each other


	game_hot_reloaded(g_mem)
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
