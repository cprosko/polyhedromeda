class_name MapBlock
extends Node2D

# Public Parameters
@export_category("Neighbors")
@export var neighbor_up: MapBlock
@export var neighbor_down: MapBlock
@export var neighbor_left: MapBlock
@export var neighbor_right: MapBlock

# Public Properties
var BlockRect: Rect2i:
	get:
		return _block_rect
var BlockSizeTiles: Vector2i:
	get:
		return _block_size_tiles

# Public Variables
@onready var map_layers: Array = find_children("*", "TileMapLayer")

# Private Variables
var _block_rect: Rect2i
var _block_size_tiles: Vector2i

# Built-in Method Overrides
func _ready() -> void:
	_calculate_block_rect()
	_validate_neighbors()


# Private Methods
func _calculate_block_rect() -> void:
	var used_rects: Array[Rect2i] = map_layers.map(
		func(x): return x.get_used_rect()
	)
	_block_rect = used_rects[0]
	for rect in used_rects.slice(1):
		_block_rect.merge(rect)
	_block_size_tiles = _block_rect.size


func _validate_neighbors() -> void:
	# TODO: fill in
	return
