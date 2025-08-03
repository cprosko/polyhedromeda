class_name NodeScoreLabel
extends RichTextLabel

# Cached References
@onready var map_manager: MapManager = %MapManager

# Private Variables
var _active_nodes: int = 1


# Built-In Method Overrides
func _ready() -> void:
	await get_tree().root.ready
	update_text()


# Public Methods
func update_text() -> void:
	text = str(_active_nodes)+"/"+str(map_manager.TotalNodes + 1)


# Signal Response Methods
func _on_set_node_active(active: bool) -> void:
	_active_nodes += +1 if active else -1
	update_text()
