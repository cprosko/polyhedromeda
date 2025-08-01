class_name MapManager
extends Node2D


# Public Parameters
@export var starting_block: MapBlock
@export var starting_player_position: Vector2i = Vector2i(3, 3)
@export var unused_block_position := Vector2i(-1000, -1000)
@export var delay_after_side_change_secs := 0.2
@export_category("Debugging:")
@export var unfold_map := false

# Public Properties
@onready var map_blocks: Array = find_children("*", "MapBlock", false)
var active_block: MapBlock
var BlockIDs: Array[int]:
	get:
		return _block_ids

# Private Variables
var _block_ids: Array[int]


# Built-in Method Overrides
func _ready() -> void:
	_assign_block_ids()
	if starting_block == null:
		starting_block = get_child(0) as MapBlock
	reset_map()


# Public Methods
func reset_map() -> void:
	active_block = starting_block
	load_blocks_from_center(active_block)
	set_player_tile(starting_player_position)


func load_nearest_blocks() -> void:
	if active_block.BlockRect.has_point(%Player.TilePosition):
		load_blocks_from_center(active_block)
		return
	var exit_dir := exit_direction()
	shift_player_by_block(Enums.vec_dir_map[exit_dir])
	match exit_dir:
		Vector2i.RIGHT:
			load_blocks_from_center(active_block.neighbor_right)
		Vector2i.LEFT:
			load_blocks_from_center(active_block.neighbor_left)
		Vector2i.UP:
			load_blocks_from_center(active_block.neighbor_up)
		Vector2i.DOWN:
			load_blocks_from_center(active_block.neighbor_down)
		_:
			push_error("Invalid exit direction ", exit_dir, " found for Player.")
	#shift_player_by_block(exit_dir)


func load_blocks_from_center(center_block: MapBlock) -> void:
	active_block = center_block
	# Position loaded blocks
	active_block.position = Vector2.ZERO
	if active_block.neighbor_up != null:
		active_block.neighbor_up.position = Vector2(
			0,
			map_to_local(-active_block.neighbor_up.Size).y
			- 0.5 * GlobalsInst.tile_size_pixels.y
		)
	if active_block.neighbor_down != null:
		active_block.neighbor_down.position = Vector2(
			0,
			map_to_local(active_block.Size).y
			- 0.5 * GlobalsInst.tile_size_pixels.y
		)
	if active_block.neighbor_left != null:
		active_block.neighbor_left.position = Vector2(
			map_to_local(-active_block.neighbor_left.Size).x
			- 0.5 * GlobalsInst.tile_size_pixels.x,
			0
		)
	if active_block.neighbor_right != null:
		active_block.neighbor_right.position = Vector2(
			map_to_local(active_block.End).x
			- 0.5 * GlobalsInst.tile_size_pixels.x,
			0
		)

	# Only make active blocks visible
	for block in map_blocks:
		var is_loaded: bool = block == active_block or block in active_block.NeighborBlocks.values()
		block.visible = is_loaded
		block.is_loaded = is_loaded
		if not is_loaded:
			block.position = unused_block_position
	if unfold_map:
		return
	for dir in Enums.Dir.values():
		active_block.NeighborBlocks[dir].visible = active_block.edge_types[dir] == Enums.Edge.NONE
		# TODO: draw edge differently  for outer vs inner blocks
	return


func shift_player_by_block(dir: Enums.Dir) -> void:
	var approach_dir: Enums.Dir = active_block.approach_dirs[dir]
	var to_block: MapBlock = active_block.NeighborBlocks[dir]
	var tile_offset: int = active_block.neighbor_offsets[dir]
	var edge_coord: int # Coordinate of edge tile of new block
	var pres_coord: int # Coordinate along edge in new block
	var hori_dirs := [Enums.Dir.LEFT, Enums.Dir.RIGHT]
	var vert_dirs := [Enums.Dir.UP, Enums.Dir.DOWN]

	# Calculate new coordinates without caring which should be 'x' or 'y'
	match approach_dir:
		Enums.Dir.RIGHT:
			edge_coord = to_block.BlockSizeTiles.x - 1
		Enums.Dir.DOWN:
			edge_coord = to_block.BlockSizeTiles.y - 1
		_:
			edge_coord = 0
	pres_coord = %Player.TilePosition.x if dir in vert_dirs else %Player.TilePosition.y
	var count_from_end: bool = (
		(dir == Enums.Dir.RIGHT and approach_dir == Enums.Dir.UP)
		or (dir == Enums.Dir.LEFT and approach_dir == Enums.Dir.DOWN)
		or (dir == Enums.Dir.UP and approach_dir == Enums.Dir.RIGHT)
		or (dir == Enums.Dir.DOWN and approach_dir == Enums.Dir.LEFT)
		or (dir == approach_dir)
	)
	print("Count from end: ", count_from_end)
	if count_from_end:
		if approach_dir in vert_dirs:
			pres_coord = to_block.BlockSizeTiles.y - pres_coord - 1 # TODO: should -1 be here?
		else:
			pres_coord = to_block.BlockSizeTiles.x - pres_coord - 1
	pres_coord += (-1 if count_from_end else +1) * tile_offset

	# Infer if new tile is (pres_coord, zero_coord) or (zero_coord, pres_coord)
	var rotate_axes: bool = (
		(dir in hori_dirs and approach_dir in vert_dirs)
		or (dir in vert_dirs and approach_dir in hori_dirs)
	)
	set_player_tile(
		Vector2i(
			pres_coord if approach_dir in vert_dirs else edge_coord,
			edge_coord if approach_dir in vert_dirs else pres_coord,
		)
	)
	# Player orientation should be opposite to the 'approach from' direction.
	%Player.set_player_orientation(
		Enums.vec_dir_map[-1 * Enums.dir_vec_map[approach_dir]]
	)
	# Enforce pause in movement after switching sides
	%Player.pause_movement(delay_after_side_change_secs)
	return


func set_player_tile(tile: Vector2i) -> void:
	%Player.TilePosition = tile
	print("set_player_tile: ", tile)
	%Player.global_position = active_block.RefLayer.to_global(
		map_to_local(%Player.TilePosition) - 0.5 * GlobalsInst.tile_size_pixels
	)


func map_to_local(tile: Vector2i) -> Vector2:
	return active_block.RefLayer.map_to_local(tile)


func exit_direction() -> Vector2i:
	var block_rect: Rect2i = active_block.BlockRect
	if %Player.TilePosition.x + 1 > active_block.End.x:
		return Vector2i.RIGHT
	if %Player.TilePosition.x < active_block.Position.x:
		return Vector2i.LEFT
	if %Player.TilePosition.y + 1 > active_block.End.y:
		return Vector2i.DOWN
	if %Player.TilePosition.y < active_block.Position.y:
		return Vector2i.UP
	push_warning("exit_direction called when Player has not exited active_block.")
	return Vector2i.ZERO


# Private Methods
func _assign_block_ids() -> void:
	_block_ids = []
	for ind in map_blocks.size():
		map_blocks[ind].id = ind
		_block_ids.append(ind)


# Signal Response Methods
func _on_player_just_moved(player_tile: Vector2i) -> void:
	if active_block.BlockRect.has_point(player_tile):
		return
	print("Player position before load_blocks: ", %Player.position, ", tile: ", %Player.TilePosition)
	load_nearest_blocks()
	print("Player position after load_blocks: ", %Player.position, ", tile: ", %Player.TilePosition)
