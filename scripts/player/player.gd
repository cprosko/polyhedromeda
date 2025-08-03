class_name Player
extends CharacterBody2D

# Signals
signal about_to_move(new_tile: Vector2i, old_tile: Vector2i)
signal just_moved(player_tile: Vector2i, old_tile: Vector2i)

# Public Parameters
@export var movement_time: float = 0.2
@export var sprinting_movement_time: float = 0.05
@export var starting_orientation := Vector2i.DOWN
@export var shake_duration_secs := 0.1
@export var shake_distance := 5.0
@export var num_shakes := 2

# Public Properties
var TilePosition: Vector2i:
	get:
		return _tile_position
	set(val):
		_tile_position = val
var can_move := true
var is_moving := false
var move_dirs: Array[Vector2i] = []

# Cached References
@onready var sprite = $Sprite
@onready var map_manager = %MapManager

# Private Variables
var _movement_tween: Tween
var _is_shaking: bool = false
var _tile_position := Vector2i(0, 0)


# Built-in Method Overrides
func _ready() -> void:
	_play_idle_animation(starting_orientation)


func _physics_process(_delta: float) -> void:
	if (_movement_tween and _movement_tween.is_running()) or not can_move or _is_shaking:
		return
	var move_dir: Vector2i
	if Input.is_action_pressed("undo") and map_manager.undo_moves_since_start.size() > 0:
		move_dir = map_manager.undo_moves_since_start[-1]
	elif Input.is_action_pressed("move_up") and !$Rays/Up.is_colliding():
		move_dir = Vector2i.UP
	elif Input.is_action_pressed("move_down") and !$Rays/Down.is_colliding():
		move_dir = Vector2i.DOWN
	elif Input.is_action_pressed("move_left") and !$Rays/Left.is_colliding():
		move_dir = Vector2i.LEFT
	elif Input.is_action_pressed("move_right") and !$Rays/Right.is_colliding():
		move_dir = Vector2i.RIGHT
	if move_dir == null or move_dir == Vector2i.ZERO:
		return
	if map_manager.can_move(move_dir):
		_move(move_dir)
	else:
		_play_cant_move_animation(move_dir)

# Public Methods
func set_player_orientation(dir: Enums.Dir) -> void:
	_play_idle_animation(Enums.dir_vec_map[dir])


func pause_movement(duration_secs: float) -> void:
	can_move = false
	await get_tree().create_timer(duration_secs).timeout
	can_move = true


func dont_count_last_move(num_moves: int = 1) -> void:
	for i in num_moves:
		map_manager.undo_moves_since_start.pop_back()


# Private Methods
func _move(dir: Vector2i):
	if move_dirs.size() > 0 and dir not in move_dirs:
		return
	else:
		move_dirs.clear()
	is_moving = true
	if (
		map_manager.undo_moves_since_start.size() > 0
		and dir == map_manager.undo_moves_since_start[-1]
	):
		dont_count_last_move()
	else:
		map_manager.record_move(dir)
	_tile_position += dir
	about_to_move.emit(_tile_position, _tile_position - dir)
	position += Vector2(dir * GlobalsInst.TILE_SIZE_PIXELS)
	sprite.position -= Vector2(dir * GlobalsInst.TILE_SIZE_PIXELS)

	if _movement_tween:
		_movement_tween.kill()
	_movement_tween = create_tween()
	_movement_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	_play_move_animation(dir)
	_movement_tween.tween_property(
		sprite,
		"position",
		0.5 * GlobalsInst.TILE_SIZE_PIXELS,
		sprinting_movement_time if is_sprinting else movement_time
	).set_trans(Tween.TRANS_SINE)
	await _movement_tween.finished
	just_moved.emit(_tile_position, _tile_position - dir)
	if sprite.is_playing():
		await sprite.animation_finished
	is_moving = false
	_play_idle_animation(dir)


func _play_move_animation(dir: Vector2i) -> void:
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


func _play_cant_move_animation(move_dir: Vector2i) -> void:
	_is_shaking = true
	var player_pos: Vector2 = position
	var shake_dir := Vector2(move_dir)
	var shake_points: Array[Vector2] = [
		player_pos + shake_dir / 2,
		player_pos + shake_dir,
		player_pos + shake_dir / 2,
		player_pos,
		player_pos - shake_dir / 2,
		player_pos - shake_dir,
		player_pos - shake_dir / 2,
		player_pos,
	]
	for i in num_shakes:
		for shake_point in shake_points:
			position = shake_point
			await get_tree().create_timer(shake_duration_secs / shake_points.size() / num_shakes).timeout
	_is_shaking = false
	return
