extends RayCast3D
class_name beam

@onready var beam_mesh = $BeamMesh

func _ready() -> void:
	set_process(true)
	enabled = true
	pass


func _process(delta: float) -> void:
	var cast_point
	force_raycast_update()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		
		print(cast_point)
		
		beam_mesh.mesh.height = cast_point.y
		beam_mesh.position.y = cast_point.y / 2
