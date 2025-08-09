class_name PauseScreen
extends Panel


# Cached References
@onready var pause_button = %PauseButton

# Private Variables
var _player_could_move_pre_pause: bool
var _active: bool = true

# Built-In Method Overrides
func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _active and Input.is_action_just_pressed("pause"):
		flip_pause_state()


# Public Methods
func set_active(active: bool) -> void:
	_active = active
	pause_button.disabled = not active



func flip_pause_state() -> void:
	visible = not visible
	GlobalsInst.is_paused = visible


# Signal Response Methods
func _on_pause_button_pressed() -> void:
	flip_pause_state()


func _on_continue_button_pressed() -> void:
	flip_pause_state()
