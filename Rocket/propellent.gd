extends RigidBody3D
class_name propellent

var is_rocketship: bool = false
var is_rocket_system: bool = true
var is_propellent: bool = true

func _ready() -> void:
	freeze = true
	gravity_scale = 0.0
