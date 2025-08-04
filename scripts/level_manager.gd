class_name LevelManager
extends Node2D


# Public Parameters
@export var current_scene_name: String = "level_template"
@export var next_scene_name: String

# Public Variables
var activated_nodes: int = 0
var total_nodes: int

# Cached References
@onready var map_manager: MapManager = $MapManager


# Built-In Method Overrides
func _ready() -> void:
	GlobalsInst.current_scene_name = current_scene_name
	GlobalsInst.next_scene_name = next_scene_name
	total_nodes = map_manager.TotalNodes
	print("Total nodes: ", total_nodes)
	for map_block in map_manager.map_blocks:
		map_block.nodes_and_wires.set_node_active.connect(_on_set_node_active)
		map_block.nodes_and_wires.loop_completed.connect(_on_loop_completed)


# Public Methods
func win_level() -> void:
	%WinDialog.activate_win_state()


func load_next_scene() -> void:
	if %Player.is_moving:
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


func _on_restart_button_pressed() -> void:
	GlobalsInst.next_scene_name = current_scene_name
	load_next_scene()


func _on_exit_button_pressed() -> void:
	GlobalsInst.next_scene_name = "start_screen"
	load_next_scene()
