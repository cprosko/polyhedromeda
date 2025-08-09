class_name MapEdgeDisplay
extends TileMapLayer

# Public Parameters
@export var arrow_edge_offset := 7.5
@export var arrow_oscillation_dist := 10.0
@export var tile_atlas_coord := Vector2i(0, 0)

# Public Variables
var movement_tweens: Dictionary[Enums.Dir, Tween] = {}

# Cached references
@onready var arrow_positioners: Dictionary[Enums.Dir, Node2D] = {
	Enums.Dir.LEFT:  $LeftArrowPositioner,
	Enums.Dir.RIGHT: $RightArrowPositioner,
	Enums.Dir.UP:    $UpArrowPositioner,
	Enums.Dir.DOWN:  $DownArrowPositioner,
}
@onready var arrows: Dictionary[Enums.Dir, Sprite2D] = {
	Enums.Dir.LEFT:  $LeftArrowPositioner/LeftArrow,
	Enums.Dir.RIGHT: $RightArrowPositioner/RightArrow,
	Enums.Dir.UP:    $UpArrowPositioner/UpArrow,
	Enums.Dir.DOWN:  $DownArrowPositioner/DownArrow,
}
@onready var arrow_animator: ArrowAnimator = $ArrowAnimator
var map_manager: MapManager

# Private variables
var _raw_positions: Dictionary[Enums.Dir, Vector2]


# Built-In Method Overrides
func _ready() -> void:
	map_manager = get_parent()
	arrow_animator.oscillation_dist = arrow_oscillation_dist


# Public Methods
func reset_edges() -> void:
	clear()
	for dir in Enums.Dir.values():
		arrows[dir].visible = false


func add_edge(dir: Enums.Dir, inner: bool) -> void:
	var active_block_tile_size: Vector2i = map_manager.active_block.BlockRect.size
	var active_block_size: Vector2 = Globals.TILE_SIZE_PIXELS * map_manager.active_block.BlockRect.size
	var x_midpoint: float = active_block_size.x / 2.0
	var y_midpoint: float = active_block_size.x / 2.0
	var arrow_pos: Vector2
	var true_offset: float = arrow_edge_offset
	if dir in [Enums.Dir.UP, Enums.Dir.DOWN]:
		true_offset += arrows[dir].texture.get_height() / 2.0
	else:
		true_offset += arrows[dir].texture.get_width() / 2.0

	match dir:
		Enums.Dir.LEFT:
			arrow_pos = Vector2(-true_offset, y_midpoint)
		Enums.Dir.RIGHT:
			arrow_pos = Vector2(
				active_block_size.x + true_offset, y_midpoint
			)
		Enums.Dir.UP:
			arrow_pos = Vector2(x_midpoint, -true_offset)
		Enums.Dir.DOWN:
			arrow_pos = Vector2(
				x_midpoint, active_block_size.y + true_offset
			)
	arrows[dir].visible = true
	arrow_positioners[dir].position = arrow_pos
	_raw_positions[dir] = arrow_pos
	if not inner:
		return
	var tiles_to_add: Array[Vector2i] = []
	match dir:
		Enums.Dir.LEFT:
			for i in active_block_tile_size.y:
				tiles_to_add.append(Vector2i(-1, i))
		Enums.Dir.RIGHT:
			for i in active_block_tile_size.y:
				tiles_to_add.append(Vector2i(active_block_tile_size.x, i))
		Enums.Dir.UP:
			for i in active_block_tile_size.x:
				tiles_to_add.append(Vector2i(i, -1))
		Enums.Dir.DOWN:
			for i in active_block_tile_size.x:
				tiles_to_add.append(Vector2i(i, active_block_tile_size.y))
	for tile in tiles_to_add:
		set_cell(tile, 0, tile_atlas_coord)
