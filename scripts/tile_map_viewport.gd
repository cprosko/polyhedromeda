class_name TileMapViewport
extends Sprite3D

# Public Parameters
@export var map_block: MapBlock
@export var neighbors: Dictionary[Enums.Side,TileMapViewport]
@export var approach_dirs: Dictionary[Enums.Side, Enums.Dir]
@export var edge_types: Dictionary[Enums.Side, Enums.Edge]

# Public Properties
var Size: Vector2:
	get:
		if _size == Vector2.ZERO:
			_size = _get_size()
		return _size

# Public Variables
var is_active := false

# Cached References
@onready var sub_viewport: SubViewport = $SubViewport

# Private Variables
var _size: Vector2 = Vector2.ZERO


# Private Methods
func _get_size() -> Vector2:
	return Vector2(
		sub_viewport.size.x  * pixel_size * scale.x,
		sub_viewport.size.y * pixel_size * scale.y
	)
