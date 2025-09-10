extends StaticBody3D
class_name computer


@onready var comp_anim: AnimationPlayer = $Computer_Animation

func _ready() -> void:
	comp_anim.play("light_bounce")
