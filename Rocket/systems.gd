extends RigidBody3D
class_name systems

var is_rocketship: bool = false
var is_rocket_system: bool = true
var is_engine
var is_propellent

func _ready() -> void:
	if name.contains("Engine"):
		is_engine = true
	elif name.contains("Propellent"):
		is_propellent = true 
	
	freeze = false
	gravity_scale = 0.0
