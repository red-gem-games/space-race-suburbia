extends Node3D
class_name PREM_7

@onready var trig_anim: AnimationPlayer = $Trigger_Animation
@onready var mode_anim: AnimationPlayer = $Mode_Animation
@onready var beam_anim: AnimationPlayer = $Beam_Animation
@onready var holo_anim: AnimationPlayer = $Hologram_Animation

@onready var back_glow: MeshInstance3D = $Multitool/Back_Glow
@onready var photon_glow: MeshInstance3D = $Multitool/Photon_Glow

#@onready var beam: RayCast3D = $Beam
@onready var beam: Node3D = $Multitool/Beam
@onready var beam_mesh: MeshInstance3D = $Multitool/Beam/Beam_Mesh
@onready var beam_mesh_2: MeshInstance3D = $Multitool/Beam/Beam_Mesh_2
@onready var beam_mesh_3: MeshInstance3D = $Multitool/Beam/Beam_Mesh_3

var handling_object: bool = false

var controlled_object: RigidBody3D
var controlled_objects: Array[StringName] = []

@onready var hologram: Node3D = $Hologram
var hologram_active: bool = false
var hologram_timer: Timer = Timer.new()


func _ready() -> void:
	beam.scale = Vector3(0.0, 0.0, 0.0)
	add_child(hologram_timer)
	hologram_timer.one_shot = true

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	if controlled_object:
		controlled_objects.insert(0, controlled_object.name)
		cast_hologram()
		controlled_object = null

	if hologram_timer.time_left == 0.0 and hologram_active:
		retract_hologram()

func cast_beam():
	beam_anim.play("cast_beam")

func retract_beam():
	beam_anim.play_backwards("cast_beam")

func handle_object():
	beam_mesh.visible = false
	beam_mesh_3.visible = false
	handling_object = true

func release_handle():
	beam_mesh.visible = true
	beam_mesh_3.visible = true
	handling_object = false




func cast_hologram():
	var comp_name = controlled_objects[0]
	var new_component = _instance_component_by_name(comp_name)
	if new_component:
		hologram.add_child(new_component)
		var hol_body = new_component.object_body.duplicate()
		hologram.add_child(hol_body)
		print(hol_body)
		new_component.visible = false
		new_component.collision_shape.disabled = true
		new_component.object_body.scale = Vector3(0.1, 0.1, 0.1)
	hologram_timer.start(5.0)
	holo_anim.play("cast_hologram")
	hologram_active = true
	print('Cast hologram of ', comp_name,'!')

func switch_hologram(dir):
	hologram_timer.start(5.0)
	if dir == 'Up':
		print('Switching hologram Up!')
	if dir == 'Down':
		print('Switching hologram Down!')

func retract_hologram():
	hologram_timer.stop()
	hologram_active = false
	print('Retracting hologram!')

func _instance_component_by_name(name: StringName) -> RigidBody3D:
	# Build the exact path: e.g. "res://Components/DryingMachine.tscn"
	var path = "res://Components/%s.tscn" % name
	if not ResourceLoader.exists(path):
		push_error("Cannot find component scene at: " + path)
		return null

	var packed = ResourceLoader.load(path) as PackedScene
	if not packed:
		push_error("Failed to load PackedScene: " + path)
		return null

	var inst = packed.instantiate()
	if not inst:
		push_error("Failed to instantiate: " + path)
		return null

	return inst as RigidBody3D


func _on_hologram_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "cast_hologram":
		holo_anim.play("spin_hologram")
