class_name PlayerRays
extends Node2D


# Built-in Method Overrides
func _ready() -> void:
	var half_tile_size_pixels = GlobalsInst.TILE_SIZE_PIXELS.x / 2
	$Up.position    = Vector2(0, -half_tile_size_pixels)
	$Down.position  = Vector2(0, +half_tile_size_pixels)
	$Left.position  = Vector2(-half_tile_size_pixels, 0)
	$Right.position = Vector2(+half_tile_size_pixels, 0)
	$Up.target_position    = Vector2(0, -half_tile_size_pixels)
	$Down.target_position  = Vector2(0, +half_tile_size_pixels)
	$Left.target_position  = Vector2(-half_tile_size_pixels, 0)
	$Right.target_position = Vector2(+half_tile_size_pixels, 0)
