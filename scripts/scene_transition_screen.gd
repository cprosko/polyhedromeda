class_name SceneTransitionScreen
extends Control

# Constants
const ordered_scenes: Array[String] = [
	"start_screen",
	"level_template",
	"dummy_level_1",
	"win_screen",
]

# Public Parameters
@export var artificial_loading_time_secs: float = 0.5
var min_timeout_secs: float = 0.05

# Built-In Method Overrides
func _ready() -> void:
	await get_tree().create_timer(
		artificial_loading_time_secs
		if GlobalsInst.current_scene_name != ordered_scenes[-1]
		else min_timeout_secs
	).timeout
	get_tree().change_scene_to_file("res://scenes/"+next_scene()+".tscn")


func next_scene() -> String:
	var last_scene_ind: int = ordered_scenes.find(
		GlobalsInst.current_scene_name
	)
	return ordered_scenes[(last_scene_ind + 1) % ordered_scenes.size()]
