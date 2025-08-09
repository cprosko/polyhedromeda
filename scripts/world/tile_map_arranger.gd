class_name TileMapArranger
extends Node3D

# Public Parameters
@export var starting_tile_map_viewport: TileMapViewport
@export var stacked_viewport_z_offset: float = 0.01

# Public Properties
var TileMapViewports: Set:
	get:
		if _tile_map_viewports.size() == 0:
			_assign_viewports()
		return _tile_map_viewports

# Private Variables
var _tile_map_viewports := Set.new()
var _unplaced_viewports: Set

# Built-In Method Overrides
func _ready() -> void:
	arrange_viewports()


# Public Methods
func arrange_viewports() -> void:
	_unplaced_viewports = TileMapViewports.duplicate()
	_orient_starting_block()
	arrange_neighbors(starting_tile_map_viewport)
	if _unplaced_viewports.size() > 0:
		push_error(
			"Unable to place all TileMapViewports. Check if any are disconnected.",
			"Unplaced viewports:\n",
			_unplaced_viewports
		)

func arrange_neighbors(viewport: TileMapViewport) -> void:
	for side in viewport.neighbors.keys():
		var neighbor: TileMapViewport = viewport.neighbors[side]
		if not _unplaced_viewports.has(neighbor):
			continue
		place_viewport_relative(neighbor, viewport)
		arrange_neighbors(neighbor)


func place_viewport_relative(
	viewport: TileMapViewport, reference: TileMapViewport
) -> void:
	# TODO: Place viewport
	_unplaced_viewports.remove(viewport)
	return


# Private Methods
func _assign_viewports() -> void:
	var tile_map_viewport_array := find_children(
		"*", "TileMapViewport", false
	) as Array[TileMapViewport]
	_tile_map_viewports.add(tile_map_viewport_array)


func _orient_starting_block() -> void:
	starting_tile_map_viewport.position = Vector3(0, 0, 0)
	starting_tile_map_viewport.rotation = Vector3(0, 0, 0)
	_unplaced_viewports.remove(starting_tile_map_viewport)
