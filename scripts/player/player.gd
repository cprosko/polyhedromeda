extends CharacterBody2D

# Public Parameters
@export var movement_time: float = 0.2

# Private Variables
var _movement_tween: Tween
var _integer_position := Vector2i(0, 0)


# Built-in Function Overrides
func _physics_process(delta: float) -> void:
	if !(_movement_tween and _movement_tween.is_running()):
		if Input.is_action_pressed("move_up") and !$Rays/Up.is_colliding():
			_move(Vector2i.UP)
		elif Input.is_action_pressed("move_down") and !$Rays/Down.is_colliding():
			_move(Vector2i.DOWN)
		elif Input.is_action_pressed("move_left") and !$Rays/Left.is_colliding():
			_move(Vector2i.LEFT)
		elif Input.is_action_pressed("move_right") and !$Rays/Right.is_colliding():
			_move(Vector2i.RIGHT)


func _move(dir: Vector2i):
	_integer_position += dir * Globals.tile_size_pixels
	position = Vector2(_integer_position)
	$Sprite.position = -Vector2(dir * Globals.tile_size_pixels)

	if _movement_tween:
		_movement_tween.kill()
	_movement_tween = create_tween()
	_movement_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_movement_tween.tween_property(
		$Sprite,
		"position",
		Vector2.ZERO,
		movement_time
	).set_trans(Tween.TRANS_SINE)
