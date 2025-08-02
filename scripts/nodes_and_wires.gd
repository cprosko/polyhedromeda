class_name NodesAndWires
extends TileMapLayer


# Signals
signal set_node_active(active: bool)

# Public Parameters
var node_atlas_coords: Dictionary = {
	"inactive": Vector2i(0, 0),
	"starting":   Vector2i(0, 1),
}
var _node_atlas_coords_list: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2),
	Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)
]
var wire_atlas_coords: Dictionary[String, Dictionary] = {
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

# Public Properties
var IsActive: bool:
	get:
		return parent_block.IsActive
var entry_dir: Enums.Dir
var starting_node: Vector2i

# Cached References
@onready var parent_block: MapBlock = get_parent()

# Private Variables
var _tiles_since_entering: Array[Vector2i] = []
var _tile_chains: Array[Array] = []
var _last_wire_bend_dir: Enums.Dir
var _entry_tile: Vector2i
var _last_move_dir: Enums.Dir
var _just_entered: bool

# Built-in Method Overrides
func _ready() -> void:
	await get_tree().root.ready
	if IsActive:
		place_starting_node()


# Public Methods
func place_starting_node() -> void:
	set_cell(%Player.TilePosition, 0, node_atlas_coords["starting"])
	_tile_chains.append([%Player.TilePosition])
	starting_node = %Player.TilePosition
	_just_entered = false


func enter_block() -> void:
	_just_entered = true


func leave_block() -> void:
	if _tile_chains[-1].size() == 0:
		_tile_chains.pop_back()


func remove_tile(tile: Vector2i) -> void:
	if not Input.is_action_pressed("undo"):
		%Player.dont_count_last_move(2)
	_tile_chains[-1].pop_back()
	set_cell(tile, -1)


func add_wire(tile: Vector2i, exit_dir: Enums.Dir) -> void:
	var dir_from_last_tile: Enums.Dir
	if _tile_chains[-1].size() == 0:
		dir_from_last_tile = entry_dir
	else:
		if get_cell_atlas_coords(tile) == node_atlas_coords["starting"]:
			return
		dir_from_last_tile = relative_dir(_tile_chains[-1][-1], tile)
	var wire_type: String
	if get_cell_tile_data(tile) and get_cell_atlas_coords(tile) in _node_atlas_coords_list:
		wire_type = "node"
	else:
		wire_type = "wire"
	if dir_from_last_tile == exit_dir:
		set_cell(tile, 0, wire_atlas_coords[wire_type]["straight"][exit_dir])
	else:
		set_cell(
			tile, 0, wire_atlas_coords[wire_type]["bend"][
				[Enums.vec_dir_map[-Enums.dir_vec_map[dir_from_last_tile]], exit_dir]
			]
		)
	_tile_chains[-1].append(tile)


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
		else:
			_tile_chains.append([])
		return
	if (
		get_cell_atlas_coords(old_tile) in _node_atlas_coords_list
		and _tile_chains[-1].size() > 0
		and old_tile == _tile_chains[-1][-1]
		and old_tile != starting_node
	):
		set_cell(old_tile, 0, node_atlas_coords["inactive"])
		_tile_chains[-1].pop_back()
	if (_tile_chains[-1].size() > 0 and player_tile == _tile_chains[-1][-1]):
		if not (
			get_cell_tile_data(player_tile)
			and get_cell_atlas_coords(player_tile) in _node_atlas_coords_list
		):
			await %Player.just_moved
			remove_tile(player_tile)
		return
	if _tile_chains[-1].size() == 0 and not parent_block.BlockRect.has_point(player_tile):
		return
	var move_dir := relative_dir(old_tile, player_tile)
	add_wire(old_tile, move_dir)
	return
