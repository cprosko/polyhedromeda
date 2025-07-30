extends Node2D

func _ready() -> void:
	var half_tile_size_pixels = Globals.tile_size_pixels.x / 2
	$Up.position    = Vector2(0, -half_tile_size_pixels)
	$Down.position  = Vector2(0, +half_tile_size_pixels)
	$Left.position  = Vector2(-half_tile_size_pixels, 0)
	$Right.position = Vector2(+half_tile_size_pixels, 0)
	$Up.target_position    = Vector2(0, -half_tile_size_pixels)
	$Down.target_position  = Vector2(0, +half_tile_size_pixels)
	$Left.target_position  = Vector2(-half_tile_size_pixels, 0)
	$Right.target_position = Vector2(+half_tile_size_pixels, 0)
