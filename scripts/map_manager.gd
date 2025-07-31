class_name MapManager
extends Node2D


# Public Parameters
@export var starting_block: MapBlock
@export var starting_player_position: Vector2i = Vector2i(3, 3)
@export var unused_block_position := Vector2i(-1000, -1000)

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
	shift_player_by_block(exit_dir)


func load_blocks_from_center(center_block: MapBlock) -> void:
	# TODO: Account for 'normal vectors' of each mapblock
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
		var is_loaded: bool = block == active_block or block in active_block.NeighborBlocks
		block.visible = is_loaded
		block.is_loaded = is_loaded
		if not is_loaded:
			block.position = unused_block_position
	return


func shift_player_by_block(exit_dir: Vector2i) -> void:
	print("running shift_player_by_block")
	set_player_tile(active_block.position_after_entering(
		%Player.TilePosition, exit_dir
	))


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
