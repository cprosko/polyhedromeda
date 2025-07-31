class_name MapBlock
extends TileMapLayer

# Public Parameters
@export_category("Neighbors")
@export var neighbor_up: MapBlock
@export var neighbor_down: MapBlock
@export var neighbor_left: MapBlock
@export var neighbor_right: MapBlock

# Public Properties
@onready var BlockSizeTiles: Vector2i:
	get:
		return get_used_rect().size


# Built-in Method Overrides
func _ready() -> void:
	_validate_neighbors()


# Private Methods
func _validate_neighbors() -> void:
	# TODO: fill in
	return
