class_name LevelManager
extends Node2D


# Public Parameters
@export var next_scene: String

# Public Variables
var activated_nodes: int = 0
var total_nodes: int

# Cached References
@onready var map_manager: MapManager = $MapManager


# Built-In Method Overrides
func _ready() -> void:
	GlobalsInst.current_scene_name = get_tree().current_scene.name
	total_nodes = map_manager.TotalNodes
	print("Total nodes: ", total_nodes)
	for map_block in map_manager.map_blocks:
		map_block.nodes_and_wires.set_node_active.connect(_on_set_node_active)
		map_block.nodes_and_wires.loop_completed.connect(_on_loop_completed)


# Public Methods
func win_level() -> void:
	print("Won level!")
	await %Player.just_moved
	get_tree().change_scene_to_file.bind(
		"res://scenes/scene_transition_screen.tscn"
	).call_deferred()


# Signal Response Methods
func _on_set_node_active(active: bool) -> void:
	activated_nodes += +1 if active else -1
	print("ACTIVATED NODES: ", activated_nodes)


func _on_loop_completed() -> void:
	print("LOOP COMPLETED")
	if activated_nodes >= total_nodes - 1: # -1 because starting node isn't counted
		win_level()
