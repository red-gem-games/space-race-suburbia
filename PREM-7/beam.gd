extends RayCast3D 
class_name Beam

var beam_set: bool = false

@onready var beam_mesh: MeshInstance3D = $BeamMesh
var base_height: float
var base_y_pos: float

@onready var end_particles: GPUParticles3D = $EndParticles

var object_is_grabbed: bool = false

func _ready() -> void:
	base_height = beam_mesh.mesh.height
	base_y_pos = beam_mesh.position.y
	set_process(false)
	end_particles.emitting = false

func _process(delta: float) -> void:
	var cast_point
	
	print('*** WHY CANT I GET IT TO WORK PROPERLY IF OBJECT IS VERY FAR AWAY? ***')
	
	force_raycast_update()
	
	if is_colliding() and object_is_grabbed:
		
		cast_point = to_local(get_collision_point())
		
		end_particles.position.y = lerp(end_particles.position.y, cast_point.y, delta * 10.0)
		
		beam_mesh.mesh.height = lerp(beam_mesh.mesh.height, cast_point.y / 45.0, delta * 5.0)
		beam_mesh.position.y = lerp(beam_mesh.position.y, cast_point.y / 2.0, delta * 5.0)
		
		await get_tree().create_timer(0.25).timeout
		end_particles.emitting = true

		
		print('Mess around with PREM-7 tilting left/right when moving forwards and backwards')

	if not object_is_grabbed:

		beam_mesh.mesh.height = lerp(beam_mesh.mesh.height, base_height, delta * 5.0)
		beam_mesh.position.y = lerp(beam_mesh.position.y, base_y_pos, delta * 5.0)
		
		end_particles.emitting = false
		
		#end_particles.position.y = lerp(end_particles.position.y, base_y_pos, delta * 5.0)
		
		#set_process(false)
