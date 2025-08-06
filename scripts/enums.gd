class_name Enums
extends Object

enum Dir {LEFT, RIGHT, UP, DOWN}
enum Side {LEFT, RIGHT, TOP, BOTTOM}

const vec_dir_map: Dictionary[Vector2i, Dir] = {
	Vector2i.LEFT:  Dir.LEFT,
	Vector2i.RIGHT: Dir.RIGHT,
	Vector2i.UP:    Dir.UP,
	Vector2i.DOWN:  Dir.DOWN,
}
const dir_vec_map: Dictionary[Dir, Vector2i] = {
	Dir.LEFT:  Vector2i.LEFT,
	Dir.RIGHT: Vector2i.RIGHT,
	Dir.UP:    Vector2i.UP,
	Dir.DOWN:  Vector2i.DOWN,
}

enum Edge {INNER, OUTER, NONE}
