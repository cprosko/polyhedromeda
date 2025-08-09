class_name MapBlock
extends Node2D

# Public Parameters
@export_category("Neighbors")
@export var neighbor_up: MapBlock
@export var neighbor_down: MapBlock
@export var neighbor_left: MapBlock
@export var neighbor_right: MapBlock

@export_category("3D Properties")
@export var edge_types: Dictionary[Enums.Dir, Enums.Edge]
@export var approach_dirs: Dictionary[Enums.Dir, Enums.Dir]
@export var neighbor_offsets: Dictionary[Enums.Dir, int]

# Public Properties
var IsActive: bool:
	get:
		return _is_active
	set(val):
		if not _is_active and val:
			nodes_and_wires.enter_block()
		_is_active = val
var BlockRect: Rect2i:
	get:
		if _block_rect == null:
			_calculate_block_rect()
		return _block_rect
var Position: Vector2i:
	get:
		return _block_rect.position
var Size: Vector2i:
	get:
		return _block_rect.size
var End: Vector2i:
	get:
		return _block_rect.end
var BlockSizeTiles: Vector2i:
	get:
		if _block_size_tiles == null:
			_calculate_block_rect()
		return _block_size_tiles
var NeighborBlocks: Dictionary[Enums.Dir,MapBlock]:
	get:
		return _neighbor_blocks
var RefLayer: TileMapLayer:
	get:
		return _ref_layer

# Public Variables
var id: int
var is_loaded := false
@onready var map_layers: Array = find_children("*", "TileMapLayer")

# Cached References
@onready var nodes_and_wires: NodesAndWires = $NodesAndWires
@onready var ground_tiles: TileMapLayer = $Ground

# Private Variables
@onready var _neighbor_blocks: Dictionary[Enums.Dir, MapBlock] = {
	Enums.Dir.LEFT:  neighbor_left,
	Enums.Dir.RIGHT: neighbor_right,
	Enums.Dir.UP:    neighbor_up,
	Enums.Dir.DOWN:  neighbor_down
}
@onready var _ref_layer: TileMapLayer = get_child(0) as TileMapLayer
var _block_rect: Rect2i
var _block_size_tiles: Vector2i
var _is_active: bool = false


# Built-in Method Overrides
func _ready() -> void:
	_calculate_block_rect()
	get_tree().root.connect("ready", _validate_neighbors)


# Public Methods
func position_after_entering(
	original_tile: Vector2i, enter_dir: Vector2i
) -> Vector2i:
	var new_tile: Vector2i = original_tile
	match enter_dir:
		Vector2i.UP:
			new_tile.y = BlockRect.end.y - 1
			#new_tile.x = clampi(new_tile.x, BlockRect.position.x, BlockRect.end.x)
		Vector2i.DOWN:
			new_tile.y = BlockRect.position.y
			#new_tile.x = clampi(new_tile.x, BlockRect.position.x, BlockRect.end.x)
		Vector2i.LEFT:
			new_tile.x = BlockRect.end.x - 1
			#new_tile.y = clampi(new_tile.y, BlockRect.position.y, BlockRect.end.y)
		Vector2i.RIGHT:
			new_tile.x = BlockRect.position.x
			#new_tile.y = clampi(new_tile.y, BlockRect.position.y, BlockRect.end.y)
		_:
			push_error(
				"Invalid enter_dir, ", enter_dir,
				", must be (0,+-1) or (+-1, 0)."
			)
	return new_tile


func set_entry_dir(dir: Enums.Dir) -> void:
	nodes_and_wires.entry_dir = dir


func is_open_tile(tile: Vector2i) -> bool:
	if not nodes_and_wires.is_open_tile(tile):
		return false
	var used_ground_tiles: Array[Vector2i] = ground_tiles.get_used_cells()
	for ground_tile in used_ground_tiles:
		if tile != ground_tile:
			continue
		var tile_data: TileData = ground_tiles.get_cell_tile_data(tile)
		if tile_data.has_custom_data("wall") and tile_data.get_custom_data("wall"):
			return false
	return true


# Private Methods
func _calculate_block_rect() -> void:
	var used_rects: Array = map_layers.map(
		func(x): return x.get_used_rect()
	)
	_block_rect = used_rects[0]
	for rect in used_rects.slice(1):
		_block_rect.merge(rect)
	_block_size_tiles = _block_rect.size


func _validate_neighbors() -> void:
	var offending_blocks: Array[MapBlock] = []
	if neighbor_up.BlockSizeTiles.x != BlockSizeTiles.x:
		offending_blocks.append(neighbor_up)
	if neighbor_down.BlockSizeTiles.x != BlockSizeTiles.x:
		offending_blocks.append(neighbor_down)
	if neighbor_left.BlockSizeTiles.y != BlockSizeTiles.y:
		offending_blocks.append(neighbor_left)
	if neighbor_right.BlockSizeTiles.y != BlockSizeTiles.y:
		offending_blocks.append(neighbor_right)
	if offending_blocks.size() > 0:
		push_error(
			"For MapBlock ", name, ", neighboring blocks: \n",
			offending_blocks.map(func(x): return x.name),
			"\nhave incompatible sizes:\n",
			offending_blocks.map(func(x): return x.Size)
		)
	return
