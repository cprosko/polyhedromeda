class_name DialogManager
extends CanvasLayer

# Public Parameters
@export var delay_before_display_secs: float = 0.2

# Public variables
var current_dialog_ind: int
var active: bool = false

# Cached References
var dialog_boxes: Array
@onready var pause_screen: PauseScreen = %PauseScreen


# Built-In Method Overrides
func _ready() -> void:
	dialog_boxes = find_children("*", "Control", false)
	print("dialog boxes: ", dialog_boxes.size())
	if dialog_boxes.size() == 0:
		print("no dialog box!")
		return
	for dialog_box in dialog_boxes:
		dialog_box.visible = false
	%Player.can_move = false
	await get_tree().create_timer(delay_before_display_secs).timeout
	active = true
	pause_screen.set_active(false)
	display_dialogs()
	return


func _physics_process(_delta: float) -> void:
	if active and Input.is_action_just_pressed("continue"):
		progress_dialogs()


# Public Methods
func display_dialogs() -> void:
	current_dialog_ind = 0
	dialog_boxes[current_dialog_ind].visible = true


func progress_dialogs() -> void:
	dialog_boxes[current_dialog_ind].visible = false
	if current_dialog_ind == dialog_boxes.size() - 1:
		%Player.can_move = true
		active = false
		pause_screen.set_active(true)
		return
	current_dialog_ind += 1
	dialog_boxes[current_dialog_ind].visible = true
