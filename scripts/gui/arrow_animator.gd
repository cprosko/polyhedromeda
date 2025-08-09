class_name ArrowAnimator
extends AnimationPlayer

# Public Parameters
@export var oscillation_dist: float = 20.0

# Cached References
@onready var animation: Animation = get_animation("arrow_oscillation")
var track_inds: Dictionary[String,int] = {}
var oscillation_targets: Dictionary[String,Vector2] = {}

# Built-In Method Overrides
func _ready() -> void:
	_set_animation_parameters()


# Private Methods
func _set_animation_parameters() -> void:
	track_inds["left"] = animation.find_track(
		^"LeftArrowPositioner/LeftArrow:position", Animation.TYPE_VALUE
	)
	track_inds["right"] = animation.find_track(
		^"RightArrowPositioner/RightArrow:position", Animation.TYPE_VALUE
	)
	track_inds["up"] = animation.find_track(
		^"UpArrowPositioner/UpArrow:position", Animation.TYPE_VALUE
	)
	track_inds["down"] = animation.find_track(
		^"DownArrowPositioner/DownArrow:position", Animation.TYPE_VALUE
	)
	oscillation_targets["left"]  = Vector2(-oscillation_dist, 0)
	oscillation_targets["right"] = Vector2(+oscillation_dist, 0)
	oscillation_targets["up"]    = Vector2(0, -oscillation_dist)
	oscillation_targets["down"]  = Vector2(0, +oscillation_dist)

	for dir in track_inds.keys():
		animation.track_set_key_value(track_inds[dir], 0, Vector2(0, 0))
		animation.track_set_key_value(
			track_inds[dir], 1, oscillation_targets[dir]
		)
		animation.track_set_key_value(track_inds[dir], 2, Vector2(0, 0))
	play("arrow_oscillation")
