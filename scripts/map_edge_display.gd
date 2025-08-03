class_name MapEdgeDisplay
extends TileMapLayer

# Public Parameters
@export var arrow_move_dist := 15.0
@export var arrow_edge_offset := 20.0
@export var tile_atlas_coord := Vector2i(0, 0)
@export var oscillation_duration := 0.3

# Public Variables
var movement_tweens: Dictionary[Enums.Dir, Tween] = {}

# Cached references
@onready var arrows: Dictionary[Enums.Dir, Sprite2D] = {
	Enums.Dir.LEFT:  $LeftArrow,
	Enums.Dir.RIGHT: $RightArrow,
	Enums.Dir.UP:    $UpArrow,
	Enums.Dir.DOWN:  $DownArrow,
}
var map_manager: MapManager

# Private variables
var _raw_positions: Dictionary[Enums.Dir, Vector2]


# Built-In Method Overrides
func _ready() -> void:
	map_manager = get_parent()
	movement_tweens[Enums.Dir.LEFT] = create_tween()
	movement_tweens[Enums.Dir.RIGHT] = create_tween()
	movement_tweens[Enums.Dir.UP] = create_tween()
	movement_tweens[Enums.Dir.DOWN] = create_tween()


# Public Methods
func reset_edges() -> void:
	clear()
	for dir in Enums.Dir.values():
		movement_tweens[dir].kill()
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
	arrows[dir].position = arrow_pos
	_raw_positions[dir] = arrow_pos
	animate_arrow(dir)
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


func animate_arrow(dir: Enums.Dir) -> void:
	pass # TODO
	#if movement_tweens[dir]:
		#movement_tweens[dir].kill()
		#arrows[dir].position = _raw_positions[dir]
	#movement_tweens[dir] = create_tween().set_loops()
	#var oscillation_target: Vector2 = _raw_positions[dir]
	#match dir:
		#Vector2i.LEFT:
			#oscillation_target += Vector2(-arrow_move_dist, 0)
		#Vector2i.RIGHT:
			#oscillation_target += Vector2(+arrow_move_dist, 0)
		#Vector2i.UP:
			#oscillation_target += Vector2(0, -arrow_move_dist)
		#Vector2i.DOWN:
			#oscillation_target += Vector2(0, +arrow_move_dist)
	#movement_tweens[dir].tween_property(
		#arrows[dir], "position", oscillation_target, oscillation_duration,
	#)
	#movement_tweens[dir].interpolate_value()
