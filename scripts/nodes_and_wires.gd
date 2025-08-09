class_name NodesAndWires
extends TileMapLayer


# Signals
signal set_node_active(active: bool)
signal loop_completed


# Public Parameters
const node_atlas_coords: Dictionary = {
	"inactive": Vector2i(0, 0),
	"starting":   Vector2i(0, 1),
}
const _node_atlas_coords_list: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2),
	Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)
]
const wire_atlas_coords: Dictionary[String, Dictionary] = {
	"wire": {
		"straight": {
			Enums.Dir.LEFT:  Vector2i(1, 0),
			Enums.Dir.RIGHT: Vector2i(1, 0),
			Enums.Dir.UP:    Vector2i(2, 0),
			Enums.Dir.DOWN:  Vector2i(2, 0),
		},
		"bend": {
			[Enums.Dir.LEFT, Enums.Dir.UP]:    Vector2i(3, 0),
			[Enums.Dir.UP, Enums.Dir.LEFT]:    Vector2i(3, 0),
			[Enums.Dir.UP, Enums.Dir.RIGHT]:   Vector2i(4, 0),
			[Enums.Dir.RIGHT, Enums.Dir.UP]:   Vector2i(4, 0),
			[Enums.Dir.RIGHT, Enums.Dir.DOWN]: Vector2i(5, 0),
			[Enums.Dir.DOWN, Enums.Dir.RIGHT]: Vector2i(5, 0),
			[Enums.Dir.DOWN, Enums.Dir.LEFT]:  Vector2i(1, 1),
			[Enums.Dir.LEFT, Enums.Dir.DOWN]:  Vector2i(1, 1),
		},
		"stub": {
			Enums.Dir.RIGHT: Vector2i(2, 1),
			Enums.Dir.DOWN:  Vector2i(3, 1),
			Enums.Dir.LEFT:  Vector2i(4, 1),
			Enums.Dir.UP:    Vector2i(5, 1),
		},
	},
	"node": {
		"straight": {
			Enums.Dir.LEFT:  Vector2i(0, 2),
			Enums.Dir.RIGHT: Vector2i(0, 2),
			Enums.Dir.UP:    Vector2i(1, 2),
			Enums.Dir.DOWN:  Vector2i(1, 2),
		},
		"bend": {
			[Enums.Dir.LEFT, Enums.Dir.UP]:    Vector2i(2, 2),
			[Enums.Dir.UP, Enums.Dir.LEFT]:    Vector2i(2, 2),
			[Enums.Dir.UP, Enums.Dir.RIGHT]:   Vector2i(3, 2),
			[Enums.Dir.RIGHT, Enums.Dir.UP]:   Vector2i(3, 2),
			[Enums.Dir.RIGHT, Enums.Dir.DOWN]: Vector2i(4, 2),
			[Enums.Dir.DOWN, Enums.Dir.RIGHT]: Vector2i(4, 2),
			[Enums.Dir.DOWN, Enums.Dir.LEFT]:  Vector2i(5, 2),
			[Enums.Dir.LEFT, Enums.Dir.DOWN]:  Vector2i(5, 2),
		}
	}
}
const one_way_collision_tile := Vector2i(0, 3)


# Public Properties
var IsActive: bool:
	get:
		return parent_block.IsActive
var TotalNodes: int:
	get:
		if _total_nodes == null or _total_nodes == 0:
			_calculate_total_nodes()
		return _total_nodes
var entry_dir: Enums.Dir
var starting_node: Vector2i

# Cached References
@onready var parent_block: MapBlock = get_parent()

# Private Variables
var _total_nodes: int
var _tile_chains: Array[Array] = []
var _all_tiles: Array[Vector2i] = []
var _just_entered: bool
var _move_is_undo: bool = false

# Built-in Method Overrides
func _ready() -> void:
	set_node_active.connect(%NodeScoreLabel._on_set_node_active)
	_calculate_total_nodes()


# Public Methods
func place_starting_node() -> void:
	set_cell(%Player.TilePosition, 0, node_atlas_coords["starting"])
	if _total_nodes == null:
		_calculate_total_nodes()
	_tile_chains.append([%Player.TilePosition])
	_all_tiles.append(_tile_chains[-1][-1])
	starting_node = %Player.TilePosition
	_just_entered = false


func enter_block() -> void:
	_just_entered = true


func leave_block() -> void:
	if _tile_chains[-1].size() == 0:
		_tile_chains.pop_back()


func is_open_tile(tile: Vector2i) -> bool:
	return tile not in _all_tiles or tile == _all_tiles[-1]


func remove_tile(tile: Vector2i) -> void:
	_move_is_undo = true
	#if not Input.is_action_pressed("undo"):
		#%Player.dont_count_last_move(1)
	_all_tiles.pop_back()
	_tile_chains[-1].pop_back()
	set_cell(tile, -1)


func add_wire(tile: Vector2i, exit_dir: Enums.Dir) -> void:
	var dir_from_last_tile: Enums.Dir
	if _tile_chains[-1].size() == 0:
		dir_from_last_tile = Enums.vec_dir_map[-Enums.dir_vec_map[entry_dir]]
	else:
		if get_cell_atlas_coords(tile) == node_atlas_coords["starting"]:
			_tile_chains[-1].append(tile)
			_all_tiles.append(tile)
			return
		dir_from_last_tile = relative_dir(_tile_chains[-1][-1], tile)
	var wire_type: String
	if get_cell_tile_data(tile) and get_cell_atlas_coords(tile) in _node_atlas_coords_list:
		wire_type = "node"
	else:
		wire_type = "wire"
	if wire_type == "node":
		set_node_active.emit(true)
	if dir_from_last_tile == exit_dir:
		set_cell(tile, 0, wire_atlas_coords[wire_type]["straight"][exit_dir])
	else:
		set_cell(
			tile, 0, wire_atlas_coords[wire_type]["bend"][
				[Enums.vec_dir_map[-Enums.dir_vec_map[dir_from_last_tile]], exit_dir]
			]
		)
	_tile_chains[-1].append(tile)
	_all_tiles.append(tile)


func relative_dir(from_tile: Vector2i, to_tile: Vector2i) -> Enums.Dir:
	return Enums.vec_dir_map[to_tile - from_tile]


func update_nodes_and_wires(player_tile: Vector2i, old_tile: Vector2i) -> void:
	if not IsActive:
		push_warning("Tried to update nodes and wires on inactive MapBlock.")
		return
	if _just_entered:
		_just_entered = false
		if (
			_tile_chains.size() > 0
			and _tile_chains[-1].size() > 0
			and player_tile == _tile_chains[-1][-1]
		):
			remove_tile(player_tile)
		elif reconnected_starting_node(player_tile):
			loop_completed.emit()
		else:
			_tile_chains.append([])
		return
	if reconnected_starting_node(player_tile):
		loop_completed.emit()
	if (
		_tile_chains[-1].size() > 0
		and old_tile == _tile_chains[-1][-1]
		and (old_tile != starting_node or _tile_chains[-1].size() > 1)
		and get_cell_atlas_coords(old_tile) in _node_atlas_coords_list
	):
		if old_tile != starting_node:
			set_node_active.emit(false)
			set_cell(old_tile, 0, node_atlas_coords["inactive"])
		_tile_chains[-1].pop_back()
		_all_tiles.pop_back()
	if (_tile_chains[-1].size() > 0 and player_tile == _tile_chains[-1][-1]):
		if not (
			get_cell_tile_data(player_tile)
			and get_cell_atlas_coords(player_tile) in _node_atlas_coords_list
		):
			await %Player.just_moved
			remove_tile(player_tile)
		elif (
			get_cell_tile_data(player_tile)
			and player_tile != starting_node
			and get_cell_atlas_coords(player_tile) in _node_atlas_coords_list
		):
			await %Player.just_moved
			set_cell(player_tile, 0, node_atlas_coords["inactive"])
		return
	if _tile_chains[-1].size() == 0 and not parent_block.BlockRect.has_point(player_tile):
		return
	var move_dir := relative_dir(old_tile, player_tile)
	add_wire(old_tile, move_dir)
	if (
		starting_node != null
		and starting_node != Vector2i.ZERO
		and player_tile == starting_node
		and not _move_is_undo
	):
		set_player_restricted_move_directions(old_tile)
	_move_is_undo = false
	return


func reconnected_starting_node(player_tile: Vector2i) -> bool:
	return (
		starting_node != null
		and starting_node != Vector2i.ZERO
		and player_tile == starting_node
		and _tile_chains[0].size() > 1
	)


func set_player_restricted_move_directions(old_tile: Vector2i) -> void:
	%Player.move_dirs.clear()
	%Player.move_dirs.append(old_tile - starting_node)
	var dirs: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	for dir in dirs:
		if not get_cell_tile_data(starting_node + dir):
			%Player.move_dirs.append(dir)


func _calculate_total_nodes() -> void:
	_total_nodes = 0
	for node_atlas_coord in _node_atlas_coords_list:
		_total_nodes += len(get_used_cells_by_id(-1, node_atlas_coord))
