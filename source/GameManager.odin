package source

import rl "vendor:raylib"
import "core:fmt"

UpdateTimer :: proc(timer: f32) -> f32 {
    return timer + rl.GetFrameTime()
}

FormatTimer :: proc(timer: f32) -> cstring {
    minutes: i32 = i32(timer) / 60
    seconds: f32 = timer - (f32(minutes)*60)
    return fmt.ctprintf("%d:%2.2f", minutes, seconds)
}