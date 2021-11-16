extends Spatial
class_name AttenuatedCircle

export var radius: float = 32 setget set_radius
export var attentuation_radius: float = 5 setget set_attentuation_radius
export(float, 0, 1, 0.01) var attentuation_strength: float = 1 setget set_attentuation_strength
export(float, 0, 20, 0.1) var attentuation_size_multiplier: float = 10 setget set_attentuation_size_multiplier
export var max_power: float = 1
export var min_power: float = 0

onready var attentuation_size: float = _update_attentuation_size()
onready var radius_squared = _update_radius_squared()
onready var attentuation_radius_squared = _update_attentuation_radius_squared()

func set_attentuation_strength(value):
	attentuation_strength = value
	attentuation_size = _update_attentuation_size()

func set_attentuation_size_multiplier(value):
	attentuation_size_multiplier = value
	attentuation_size = _update_attentuation_size()

func set_attentuation_radius(value):
	attentuation_radius = value
	attentuation_radius_squared = _update_attentuation_radius_squared()

func set_radius(value):
	radius = value
	radius_squared = _update_radius_squared()

func _update_radius_squared():
	return radius * radius

func _update_attentuation_radius_squared():
	return attentuation_radius * attentuation_radius

func _update_attentuation_size():
	return attentuation_strength * attentuation_size_multiplier

func get_power_at_position(position: Vector3, sharp = false) -> float:
	var _translation = global_transform.origin
#	prints(position, translation)
	var _distance_squared = _translation.distance_squared_to(position)
	if _distance_squared >= radius_squared:
#		prints(position, _translation, "_distance_squared >= radius_squared")
		return min_power
	if _distance_squared <= attentuation_radius_squared:
#		prints(position, "_distance_squared <= attentuation_radius_squared")
		return max_power
	
	# thanks to JestemStefan and QbieShay
	var ratio = 1 - (
		(_distance_squared - attentuation_radius_squared) 
		/ (radius_squared - attentuation_radius_squared)
		)
	if sharp:
		ratio = 1 - abs(
			(_translation.distance_to(position) - attentuation_radius)
			/ (radius - attentuation_radius)
		)
#		print(ratio)
	return lerp(min_power, max_power, ratio) * attentuation_size
