class_name ContinuePrompt
extends TextureRect


# Public Parameters
@export var animation_delay_secs: float = 0.4


func _ready() -> void:
	animate_color()


func animate_color() -> void:
	while true:
		await get_tree().create_timer(animation_delay_secs).timeout
		modulate = Color.AQUA
		await get_tree().create_timer(animation_delay_secs).timeout
		modulate = Color.WHITE
