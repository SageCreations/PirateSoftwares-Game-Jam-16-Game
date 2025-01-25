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

PIXEL_WINDOW_HEIGHT :: 400

DEBUG_MODE :: true


Game_Memory :: struct {
	// GameManger
	scene: SceneState,
	timer: f32,
	paused: bool,

	// Objects
	player: Player,
	enemies: map[string]Enemy,
	pickup_items: map[string]Pickup_Item,
}


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
		if rl.IsKeyPressed(.P) || rl.IsKeyPressed(.ESCAPE) {
			g_mem.paused = !g_mem.paused
		}

		if !g_mem.paused {

			g_mem.timer = UpdateTimer(g_mem.timer)
			player_update(&g_mem.player, rl.GetFrameTime())


			for _, &enemy in g_mem.enemies {
				UpdateEnemy(&enemy)
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
		player_draw(&g_mem.player)
		for _, &enemy in g_mem.enemies {
			DrawEnemy(&enemy)
		}
		rl.DrawRectangleV({-30, -20}, {10, 10}, rl.PURPLE) //TODO: do the same for pick up items
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
		rl.GuiSlider(rl.Rectangle{f32(rl.GetScreenWidth()/2) - 100.0, 100.0, 200, 50}, cstring("Sound: 0"), cstring(" 100"), &sound_level, 0.0, 1.0)
		//fmt.printfln("number from guislider: %d", idk)

	case .Gameplay:
		// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
		// cleared at the end of the frame by the main application, meaning inside
		// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
		rl.DrawText(fmt.ctprintf("player_pos: %v", g_mem.player.position), 5, 5, 20, rl.WHITE)
		rl.DrawText(
		fmt.ctprintf("mouse_pos: %v", rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())), 5,  25, 20, rl.WHITE)
		rl.DrawFPS(rl.GetScreenWidth()-30, 5)
		rl.DrawText(FormatTimer(g_mem.timer), (rl.GetScreenWidth()/2)-50, 5, 50, rl.WHITE)

		if g_mem.paused {
			rl.DrawRectangle(10, 10, rl.GetScreenWidth()-20, rl.GetScreenHeight()-20, rl.DARKGRAY)
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 50, 400, 100}, "Restart") {
				game_init(restart=true)
			}
			if rl.GuiButton(rl.Rectangle{f32(rl.GetScreenWidth()/2)-200, 50, 400, 300}, "Return to Title") {
				game_init()
			}
		}
	case .Ending:

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
}

@(export)
game_init :: proc(restart: bool = false) {
	// defaults to overwrite
	player_default := Player{
		position = rl.Vector2{0, 0},
		texture = rl.LoadTexture("assets/round_cat.png"),
		speed = 2.0,
		rotation = 0,
		state = 0,
		hitbox = Circle{{0,0}, 32.0},
		id = 1000,
		name = "player",
		offset = rl.Vector2{16, 0},
		weapon = Weapon{
			type = .Finger,
			name = "Finger Gun",
			texture = rl.LoadTexture("assets/FingerGun.png"),
			damage = 34,
			level = 1,
			rotation = 0.0,
		},
		health = 100,
		gamepad = 0,
	}

	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		// GameManger
		scene = (restart) ? .Gameplay : .Title,
		timer = 0.0,
		paused = false,

		// default overwrites
		player = player_default,
		enemies = make(map[string]Enemy),
		pickup_items = make(map[string]Pickup_Item),
	}




	// TODO: make a forloop to create some enemies, for some reason only 1 is showing up on screen?, might all be spawning on top of each other
	for _ in 0..<100 {
		//fmt.println(i)
		enemy := CreateEnemy()
		g_mem.enemies[enemy.name] = enemy

	}

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
