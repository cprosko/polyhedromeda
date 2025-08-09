class_name WinDialog
extends Control

# Signals
signal load_next_level

# Public Properties
var active := false


# Built-in Method Overrides
func _ready() -> void:
	visible = false


func _physics_process(_delta: float) -> void:
	if active and Input.is_action_just_pressed("continue"):
		load_next_level.emit()


# Public Methods
func activate_win_state() -> void:
	visible = true
	active = true
	GlobalsInst.is_paused = true
