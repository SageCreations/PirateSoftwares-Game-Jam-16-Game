package source

import rl "vendor:raylib"
import b2 "vendor:box2d"

Object :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    texture: rl.Texture2D,
    speed: f32,
    rotation: f32,
    state: uint,
    body: b2.BodyDef,
    hitbox: b2.Circle,
    id: i32,
    name: string,

}


collision_check :: proc(obj1: ^Object, obj2: ^Object) {

}

