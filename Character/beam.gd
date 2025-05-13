extends RayCast3D
class_name beam

@onready var beam_mesh = $BeamMesh

var cast_point: Vector3
var beam_height_current: float = 0.0
var is_casting: bool = false

func _ready() -> void:
	set_process(true)
	enabled = true
	beam_mesh.mesh.height = 0.0
	beam_mesh.mesh.top_radius = 0.0
	beam_mesh.mesh.bottom_radius = 0.0
	target_position = Vector3(0, -25.0, 0.0)
	pass

func _process(delta: float) -> void:
	force_raycast_update()
	
	if is_casting:
		print('add an initial (subtle) shake when grabbing!')
		var target_height = cast_point.y
		beam_mesh.mesh.height = lerp(beam_height_current, target_height, delta * 2.5)
		beam_mesh.mesh.top_radius = lerp(beam_mesh.mesh.top_radius, 0.2, delta * 2.5)
		beam_mesh.mesh.bottom_radius = lerp(beam_mesh.mesh.bottom_radius, 0.05, delta * 2.5)

		beam_height_current = clamp(beam_mesh.mesh.height, -5.0, 0.0)
		beam_mesh.position.y = beam_height_current / 2
		
func cast_beam():
	is_casting = true
	cast_point = to_local(get_collision_point())

	#beam_mesh.mesh.bottom_radius = 0.05
	#beam_mesh.mesh.height = cast_point.y
	#beam_mesh.position.y = cast_point.y / 2

func retract_beam():
	beam_mesh.mesh.top_radius = 0.0
	beam_mesh.mesh.bottom_radius = 0.0
	beam_mesh.mesh.height = 0.0
	is_casting = false
