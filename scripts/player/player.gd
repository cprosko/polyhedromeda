class_name Player
extends CharacterBody2D

# Signals
signal just_moved(player_tile: Vector2i)

# Public Parameters
@export var movement_time: float = 0.2
@export var sprinting_movement_time: float = 0.05

# Public Properties
var TilePosition: Vector2i:
	get:
		return _tile_position
	set(val):
		_tile_position = val

# Cached References
@onready var sprite = $Sprite

# Private Variables
var _movement_tween: Tween
var _tile_position := Vector2i(0, 0)


# Built-in Method Overrides
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


# Private Methods
func _move(dir: Vector2i):
	_tile_position += dir
	print("moved to: ", _tile_position)
	position += Vector2(dir * GlobalsInst.tile_size_pixels)
	just_moved.emit(_tile_position)
	sprite.position -= Vector2(dir * GlobalsInst.tile_size_pixels)

	if _movement_tween:
		_movement_tween.kill()
	_movement_tween = create_tween()
	_movement_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	_play_move_animation(dir, is_sprinting)
	_movement_tween.tween_property(
		sprite,
		"position",
		0.5 * GlobalsInst.tile_size_pixels,
		sprinting_movement_time if is_sprinting else movement_time
	).set_trans(Tween.TRANS_SINE)
	await _movement_tween.finished
	if sprite.is_playing():
		await sprite.animation_finished
	_play_idle_animation(dir)


func _play_move_animation(dir: Vector2i, is_sprinting: bool = false) -> void:
	match dir:
		Vector2i.LEFT:
			sprite.play("motion_left")
		Vector2i.RIGHT:
			sprite.play("motion_right")
		Vector2i.UP:
			sprite.play("motion_up")
		Vector2i.DOWN:
			sprite.play("motion_down")
	sprite.speed_scale = (
		sprite.sprite_frames.get_frame_count(sprite.animation)
		/ sprite.sprite_frames.get_animation_speed(sprite.animation)
		/ (movement_time)
	)


func _play_idle_animation(dir: Vector2i) -> void:
	match dir:
		Vector2i.LEFT:
			sprite.play("idle_left")
		Vector2i.RIGHT:
			sprite.play("idle_right")
		Vector2i.UP:
			sprite.play("idle_up")
		Vector2i.DOWN:
			sprite.play("idle_down")
