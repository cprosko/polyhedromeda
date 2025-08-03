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
var TotalNodes: int:
	get:
		var total = 0
		for map_block in map_blocks:
			total += map_block.nodes_and_wires.TotalNodes
		return total

# Public variables
var undo_moves_since_start: Array[Vector2i] = []

# Cached References
@onready var map_edge_display: MapEdgeDisplay = $MapEdgeDisplay

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
	set_active_block(starting_block)
	load_blocks_from_center(active_block)
	set_player_tile(starting_player_position)
	active_block.nodes_and_wires.place_starting_node()
	undo_moves_since_start.clear()


func record_move(dir: Vector2i) -> void:
	if active_block.BlockRect.has_point(%Player.TilePosition + dir):
		print(-dir)
		undo_moves_since_start.append(-dir)
		return
	var exit_dir: Vector2i = Enums.dir_vec_map[
		active_block.approach_dirs[Enums.vec_dir_map[dir]]
	]
	print("exit dir: ", exit_dir)
	undo_moves_since_start.append(exit_dir)
	return


func can_move(move_dir: Vector2i) -> bool:
	if active_block.BlockRect.has_point(%Player.TilePosition + move_dir):
		return true
	var next_block_tile: Vector2i = player_tile_in_next_block(
		Enums.vec_dir_map[move_dir]
	)
	var next_block: MapBlock = active_block.NeighborBlocks[
		Enums.vec_dir_map[move_dir]
	]
	return next_block.is_open_tile(next_block_tile)


func set_active_block(
	block: MapBlock,
	old_block: MapBlock = null,
	exit_dir: Vector2i = Globals.NULL_TILE,
) -> void:
	if old_block != null and old_block != block:
		old_block.IsActive = false
		old_block.nodes_and_wires.leave_block()
	active_block = block
	if old_block != null and old_block != block:
		var entry_dir: Enums.Dir = old_block.approach_dirs[
			Enums.vec_dir_map[exit_dir]
		]
		active_block.set_entry_dir(entry_dir)
	active_block.IsActive = true


func load_nearest_blocks() -> void:
	if active_block.BlockRect.has_point(%Player.TilePosition):
		load_blocks_from_center(active_block)
		return
	var exit_dir := exit_direction()
	shift_player_by_block(Enums.vec_dir_map[exit_dir])
	match exit_dir:
		Vector2i.RIGHT:
			load_blocks_from_center(active_block.neighbor_right, exit_dir)
		Vector2i.LEFT:
			load_blocks_from_center(active_block.neighbor_left, exit_dir)
		Vector2i.UP:
			load_blocks_from_center(active_block.neighbor_up, exit_dir)
		Vector2i.DOWN:
			load_blocks_from_center(active_block.neighbor_down, exit_dir)
		_:
			push_error("Invalid exit direction ", exit_dir, " found for Player.")
	#shift_player_by_block(exit_dir)


func load_blocks_from_center(
	center_block: MapBlock, exit_dir: Vector2i = Globals.NULL_TILE
) -> void:
	if active_block != center_block:
		set_active_block(center_block, active_block, exit_dir)
	# Position loaded blocks
	active_block.position = Vector2.ZERO
	if active_block.neighbor_up != null:
		active_block.neighbor_up.position = Vector2(
			0,
			map_to_local(-active_block.neighbor_up.Size).y
			- 0.5 * GlobalsInst.TILE_SIZE_PIXELS.y
		)
	if active_block.neighbor_down != null:
		active_block.neighbor_down.position = Vector2(
			0,
			map_to_local(active_block.Size).y
			- 0.5 * GlobalsInst.TILE_SIZE_PIXELS.y
		)
	if active_block.neighbor_left != null:
		active_block.neighbor_left.position = Vector2(
			map_to_local(-active_block.neighbor_left.Size).x
			- 0.5 * GlobalsInst.TILE_SIZE_PIXELS.x,
			0
		)
	if active_block.neighbor_right != null:
		active_block.neighbor_right.position = Vector2(
			map_to_local(active_block.End).x
			- 0.5 * GlobalsInst.TILE_SIZE_PIXELS.x,
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
	map_edge_display.reset_edges()
	for dir in Enums.Dir.values():
		active_block.NeighborBlocks[dir].visible = active_block.edge_types[dir] == Enums.Edge.NONE
		if active_block.edge_types[dir] != Enums.Edge.NONE:
			map_edge_display.add_edge(
				dir, active_block.edge_types[dir] == Enums.Edge.INNER
			)
	return


func player_tile_in_next_block(dir: Enums.Dir) -> Vector2i:
	var approach_dir: Enums.Dir = active_block.approach_dirs[dir]
	var to_block: MapBlock = active_block.NeighborBlocks[dir]
	var tile_offset: int = active_block.neighbor_offsets[dir]
	var edge_coord: int # Coordinate of edge tile of new block
	var pres_coord: int # Coordinate along edge in new block
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

	return Vector2i(
		pres_coord if approach_dir in vert_dirs else edge_coord,
		edge_coord if approach_dir in vert_dirs else pres_coord,
	)


func shift_player_by_block(dir: Enums.Dir) -> void:
	var approach_dir: Enums.Dir = active_block.approach_dirs[dir]
	set_player_tile(
		player_tile_in_next_block(dir)
	)
	# Player orientation should be opposite to the 'approach from' direction.
	await %Player.sprite.animation_finished
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
		map_to_local(%Player.TilePosition) - 0.5 * GlobalsInst.TILE_SIZE_PIXELS
	)


func map_to_local(tile: Vector2i) -> Vector2:
	return active_block.RefLayer.map_to_local(tile)


func exit_direction() -> Vector2i:
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


func _update_nodes_and_wires(player_tile: Vector2i, old_tile: Vector2i) -> void:
	active_block.nodes_and_wires.update_nodes_and_wires(player_tile, old_tile)


# Signal Response Methods
func _on_player_about_to_move(new_tile: Vector2i, old_tile: Vector2i) -> void:
	_update_nodes_and_wires(new_tile, old_tile)


func _on_player_just_moved(player_tile: Vector2i, _old_tile: Vector2i) -> void:
	if active_block.BlockRect.has_point(player_tile):
		return
	load_nearest_blocks()
	_update_nodes_and_wires(
		%Player.TilePosition,
		%Player.TilePosition + Enums.dir_vec_map[active_block.nodes_and_wires.entry_dir]
	)
