extends PanelContainer

signal state_changed(state)
signal radius_changed(radius)
signal strength_changed(strength)
signal rotation_changed(rotation)

var strength = 1
var radius = 3

func _ready():
	$VBoxContainer/Radius/Label2.text = "%04d" % $VBoxContainer/Radius/Radius.value
	$VBoxContainer/Strength/Label2.text = "%.2f" % $VBoxContainer/Strength/Strength.value
	$VBoxContainer/RotationDegrees/Label2.text = "%04d" % $VBoxContainer/RotationDegrees/RotationDegrees.value

func _on_Button_pressed(state):
	emit_signal("state_changed", state)


func _on_HSlider_value_changed(value):
	emit_signal("radius_changed", value)
	radius = value
	$VBoxContainer/Radius/Label2.text = "%03d" % value


func _on_Strength_value_changed(value):
	emit_signal("strength_changed", value)
	strength = value
	$VBoxContainer/Strength/Label2.text = "%.2f" % value

func _on_RotationDegrees_value_changed(value):
	emit_signal("rotation_changed", value)
	$VBoxContainer/RotationDegrees/Label2.text = "%03d" % value

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.shift and Input.is_action_pressed("left_button"):
			$VBoxContainer/Radius/Radius.value = radius+event.relative.x*0.5
			get_tree().set_input_as_handled()
		elif event.control and Input.is_action_pressed("left_button"):
			$VBoxContainer/Strength/Strength.value = strength+event.relative.x*0.01
			get_tree().set_input_as_handled()
