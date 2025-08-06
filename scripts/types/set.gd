class_name Set
extends RefCounted

const VALUE := true

var dict: Dictionary
var _start: int
var _current: int

func _init(initial_values: Variant = []):
	if initial_values is Array:
		dict = Dictionary()
		add(initial_values)
	else:
		# Allows reconstructing set from its dict attribute
		dict = initial_values
	_start = 0
	_current = 0


func _iter_init(_arg):
	_current = _start
	return _should_continue()


func _iter_next(_arg):
	_current += 1
	return _should_continue()


func _iter_get(_arg):
	return dict.keys()[_current]


func _should_continue():
	return _current < dict.size()


func clear() -> void:
	dict.clear()


func size() -> int:
	return dict.size()


func has(element) -> bool:
	return element in dict


func add(element) -> void:
	if element is Set:
		dict.merge(element.dict)
	elif element is Array:
		for el in element:
			dict[el] = VALUE
	else:
		dict[element] = VALUE


func remove(element) -> void:
	if element is Set or element is Array:
		for el in element:
			dict.erase(el)
	else:
		dict.erase(element)


func with(element) -> Set:
	var new_set := Set.new(as_array())
	new_set.add(element)
	return new_set


func intersect(other_set: Set) -> void:
	var non_intersecting_elements: Array = []
	for el in dict:
		if not other_set.has(el):
			non_intersecting_elements.append(el)
	for el in non_intersecting_elements:
		dict.erase(el)


func union(other_set: Set) -> Set:
	var new_set := Set.new()
	new_set.dict = dict.duplicate()
	new_set.dict.merge(other_set.dict)
	return new_set


func difference(other_set: Set) -> Set:
	var new_set := Set.new()
	new_set.dict = dict.duplicate()
	new_set.remove(other_set)
	return new_set


func intersection(other_set: Set) -> Set:
	var new_set := Set.new()
	new_set.dict = dict.duplicate()
	new_set.intersect(other_set)
	return new_set


func is_superset(other_set: Set, strict: bool = false) -> bool:
	for el in other_set:
		if not has(el):
			return false
	if strict:
		var found_extra_element = false
		for el in self:
			if not other_set.has(el):
				found_extra_element = true
		if found_extra_element == false:
			return false
	return true


func is_subset(other_set: Set, strict: bool = false) -> bool:
	return other_set.is_superset(self, strict)


func is_equal(other_set: Set) -> bool:
	return dict == other_set.dict


func as_array() -> Array:
	return dict.keys()


func duplicate() -> Set:
	var duplicate_set := Set.new()
	duplicate_set.dict = dict.duplicate()
	return duplicate_set


func filter(method: Callable) -> Set:
	var filtered_array := self.as_array().duplicate().filter(method)
	return Set.new(filtered_array)


func pick_random() -> Variant:
	return dict.keys().pick_random()


func map(args) -> Array:
	return dict.keys().map(args)
