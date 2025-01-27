package source

Pickup_Item :: struct {
    using obj: Object,
    // TODO: leave this here in case of powerups besides weapon pickups
}

ItemCollision :: proc(item: ^Pickup_Item) -> bool {
    return false
}