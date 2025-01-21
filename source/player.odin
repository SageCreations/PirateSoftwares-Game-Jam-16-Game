package source


Player :: struct {
    using obj: Object,
    health: i32,

}

update_player :: proc(player: ^Player, delta_time: f32) {
    // TODO: update player code goes here
}

draw_player :: proc(player: ^Player) {

}

collision_player :: proc(player: ^Player, other: ^Object) {
    // TODO: handle what happens with the player on collision detection
}