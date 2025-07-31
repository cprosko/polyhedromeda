class_name MapBlock
extends Node2D

# Public Parameters
@export_category("Neighbors")
@export var neighbor_up: MapBlock
@export var neighbor_down: MapBlock
@export var neighbor_left: MapBlock
@export var neighbor_right: MapBlock

# Public Properties
@onready var BlockSizeTiles: Vector2i:
	get:
		return _block_size_tiles

# Public Variables
@onready var map_layers: Array = find_children("*", "TileMapLayer")

# Private Variables
var _block_size_tiles: Vector2i

# Built-in Method Overrides
func _ready() -> void:
	_calculate_block_size()
	_validate_neighbors()


# Private Methods
func _calculate_block_size() -> void:
	var used_rects: Array[Rect2i] = map_layers.map(
		func(x): return x.get_used_rect()
	)
	var full_rect: Rect2i = used_rects[0]
	for rect in used_rects.slice(1):
		full_rect.merge(rect)
	_block_size_tiles = full_rect.size


func _validate_neighbors() -> void:
	# TODO: fill in
	return
