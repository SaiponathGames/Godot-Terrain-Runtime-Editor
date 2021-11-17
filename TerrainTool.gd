extends MeshInstance

var position
var strength = 1
var radius = 3 setget set_radius_value

var mouse_pointer: Vector2 = Vector2()
export(int) var strength_factor = 1 setget set_strength_value

onready var attenuated_circle = $AttenuatedCircle

enum TerrainToolStates {SLOPE_UP, SLOPE_DOWN, SLOPE_FLATTEN}

var current_state = TerrainToolStates.SLOPE_UP

var clicked = false

onready var sound_dict = {
	TerrainToolStates.SLOPE_UP: $Raise,
	TerrainToolStates.SLOPE_DOWN: $Lower,
	TerrainToolStates.SLOPE_FLATTEN: $Flatten
}

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_pointer = event.position
		if Input.is_action_pressed("left_button") and (!event.control and !event.shift):
#			print("is being clicked?")
			clicked = true
			strength = Input.get_action_strength("left_button") * strength_factor * 2
			attenuated_circle.attentuation_strength = strength
			position = translation
			if mesh is CylinderMesh:
				radius = mesh.bottom_radius
				attenuated_circle.radius = radius
#		elif event.control and Input.is_action_pressed("left_button"):
#			set_strength_value(strength_factor+event.relative.x*0.01)
#		elif event.shift and Input.is_action_pressed("left_button"):
##			print("shift")
#			set_radius_value(radius+event.relative.x*0.02)
			

	if Input.is_action_just_pressed("left_button") and !Input.is_key_pressed(KEY_SHIFT) and !Input.is_key_pressed(KEY_CONTROL):
		position = translation
		for audio in sound_dict.values():
			audio.stop()
		sound_dict[current_state].play()

	if Input.is_action_just_released("left_button") and !Input.is_key_pressed(KEY_SHIFT) and !Input.is_key_pressed(KEY_CONTROL):
		for audio in sound_dict.values():
			audio.stop()
		clicked = false

func _physics_process(_delta):
	if !Input.is_key_pressed(KEY_CONTROL) and !Input.is_key_pressed(KEY_SHIFT):
		var camera = get_viewport().get_camera()
		var from = camera.project_ray_origin(mouse_pointer)
		var to = from + camera.project_ray_normal(mouse_pointer) * 1000
		var ray = get_world().direct_space_state.intersect_ray(from, to)
		if not ray.empty():
			show()
			translation = ray.get("position", translation)
#			print(translation)
		else:
			hide()
	
	if clicked and Input.is_action_pressed("left_button") and (!Input.is_key_pressed(KEY_CONTROL) and !Input.is_key_pressed(KEY_SHIFT)):
#		print("running?")
		strength = Input.get_action_strength("left_button") * strength_factor * 2
		attenuated_circle.attentuation_strength = strength
		mesh.surface_get_material(0).set_shader_param("attenuation_strength", strength_factor)
		position = translation
		if mesh is CylinderMesh:
			radius = mesh.bottom_radius
			attenuated_circle.radius = radius
			mesh.surface_get_material(0).set_shader_param("radius", float(radius))

func reset_values():
	position = null

func set_state(state):
	current_state = state

func set_strength_value(value):
	strength_factor = clamp(value, 0, 1)
	mesh.surface_get_material(0).set_shader_param("attenuation_strength", strength_factor)

func set_radius_value(value):
	if mesh is CylinderMesh:
		mesh.bottom_radius = value
		mesh.top_radius = value
		radius = value
		attenuated_circle.radius = radius
		mesh.surface_get_material(0).set_shader_param("radius", float(radius))

func get_strength_at_position(_position, sharp_edges):
	return attenuated_circle.get_power_at_position(_position, sharp_edges)

func _on_PanelContainer_state_changed(state):
	set_state(state)

func _on_PanelContainer_strength_changed(_strength):
	set_strength_value(_strength)

func _on_PanelContainer_radius_changed(_radius):
	set_radius_value(_radius)

func _on_PanelContainer_rotation_changed(rotation):
	pass # Replace with function body.
