extends Node3D
class_name PREM_7

@onready var trig_anim: AnimationPlayer = $Trigger_Animation
@onready var mode_anim: AnimationPlayer = $Mode_Animation
@onready var beam_anim: AnimationPlayer = $Beam_Animation

@onready var back_glow: MeshInstance3D = $Multitool/Back_Glow
@onready var photon_glow: MeshInstance3D = $Multitool/Photon_Glow

#@onready var beam: RayCast3D = $Beam
@onready var beam: Node3D = $Multitool/Beam
@onready var beam_mesh: MeshInstance3D = $Multitool/Beam/Beam_Mesh
@onready var beam_mesh_2: MeshInstance3D = $Multitool/Beam/Beam_Mesh_2
@onready var beam_mesh_3: MeshInstance3D = $Multitool/Beam/Beam_Mesh_3

var controlling_object: bool = false

func _ready() -> void:
	beam.scale = Vector3(0.0, 0.0, 0.0)

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	pass

func cast_beam():
	beam_anim.play("cast_beam")
	#is_casting = true
	#cast_point = to_local(get_collision_point())
	#print('add an initial (subtle) shake when grabbing!')
	#print('can we also add a bend here?????')
	#beam_mesh.mesh.bottom_radius = 0.05
	#beam_mesh.mesh.height = cast_point.y
	#beam_mesh.position.y = cast_point.y / 2

func retract_beam():
	beam_anim.play_backwards("cast_beam")
	#beam.visible = false
	#beam_mesh.mesh.top_radius = 0.0
	#beam_mesh.mesh.bottom_radius = 0.0
	#beam_mesh.mesh.height = 0.0
	#is_casting = false

func control_object():
	beam_mesh.visible = false
	beam_mesh_3.visible = false
	controlling_object = true

func release_control():
	beam_mesh.visible = true
	beam_mesh_3.visible = true
	controlling_object = false
