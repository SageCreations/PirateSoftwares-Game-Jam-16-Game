package source

import rl "vendor:raylib"

UpdateTimer :: proc(timer: f32) -> f32 {
    return timer + rl.GetFrameTime()
}