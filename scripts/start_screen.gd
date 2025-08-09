class_name StartScreen
extends Control

# Built-In Method Overrides
func _ready() -> void:
	GlobalsInst.current_scene_name = "start_screen"


# Signal Response Methods
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/menus/scene_transition_screen.tscn"
	)
