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
import b2 "vendor:box2d"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	world_def: b2.WorldDef,
	world_id: b2.WorldId,

	player: Player,
	enemies: map[string]Enemy,
	pickup_items: map[string]Pickup_Item,
}

g_mem: ^Game_Memory

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
		zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
	}
}

update :: proc() {
	player_update(&g_mem.player, rl.GetFrameTime())

	for _, &enemy in g_mem.enemies {
		enemy_update(&enemy)
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(game_camera())

	player_draw(&g_mem.player)
	for _, &enemy in g_mem.enemies {
		enemy_draw(&enemy)
	}
	rl.DrawRectangleV({-30, -20}, {10, 10}, rl.PURPLE) //TODO: do the same for pick up items
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("player_pos: %v", g_mem.player.position), 5, 5, 8, rl.WHITE)

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
	rl.InitWindow(1920, 1080, "Placeholder Name")
	//rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)
	world_def_init := b2.DefaultWorldDef()

	g_mem^ = Game_Memory {
		world_def = world_def_init,
		world_id = b2.CreateWorld(world_def_init),
		player = {
			position = rl.Vector2{0, 0},
			size = rl.Vector2{1, 1},
			texture = rl.LoadTexture("assets/round_cat.png"),
			speed = 2.0,
			rotation = 0,
			state = 0,
			hitbox = b2.Circle{b2.Vec2{0,0}, 32.0},
			id = 1000,
			name = "player",
			health = 100,
			gamepad = 0,
		},
		enemies = make(map[string]Enemy),
		pickup_items = make(map[string]Pickup_Item),
	}
	g_mem.world_def.gravity = b2.Vec2{0, 0}

	// TODO: make a forloop to create some enemies, for some reason only 1 is showing up on screen?, might all be spawning on top of each other
	for i in 0..<10 {
		fmt.println(i)
		enemy := create_enemy()
		g_mem.enemies[enemy.name] = enemy
		fmt.printfln("enemy created")
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
