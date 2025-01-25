package source

import rl "vendor:raylib"
//import "core:fmt"

// == Object Stuff ============================================================
Object :: struct {
    position: rl.Vector2,
    texture: rl.Texture2D,
    speed: f32,
    rotation: f32,
    state: uint,
    hitbox: Circle,
    id: i32,
    name: string,

}

// Debug info prints the Object's information
DebugPrintObject :: proc(object: Object) {
    //fmt.printfln("Object Data:\n%v", object)
}



// == Circle Stuff ============================================================
Circle :: struct {
    center: rl.Vector2,
    radius: f32,
}

// Checks between object's 1 & 2 hitbox circles to see if they are colliding
IsColliding :: proc(obj1: Circle, obj2: Circle) -> bool {
    return rl.CheckCollisionCircles(obj1.center, obj1.radius, obj2.center, obj2.radius)
}

// Draws the hitbox outline in green
DrawCollider :: proc(circle: Circle) {
    rl.DrawCircleLinesV(circle.center, circle.radius, rl.GREEN)
}




// == Procedure Groups ========================================================
DrawDebug :: proc {
    DrawCollider,
}

