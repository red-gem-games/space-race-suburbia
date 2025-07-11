extends Node3D
class_name PREM_7

@onready var trig_anim: AnimationPlayer = $Trigger_Animation
@onready var ctrl_anim: AnimationPlayer = $Control_Animation
@onready var beam_anim: AnimationPlayer = $Beam_Animation
@onready var holo_anim: AnimationPlayer = $Hologram_Animation

@onready var back_glow: MeshInstance3D = $Multitool/Back_Glow
@onready var photon_glow: GPUParticles3D = $Multitool/Photon_Glow

@onready var object_inventory: Node3D = $Multitool/Object_Inventory

#@onready var beam: RayCast3D = $Beam
#@onready var beam: Node3D = $Multitool/Beam
#@onready var beam_mesh: MeshInstance3D = $Multitool/Beam/Beam_Mesh

@onready var hologram_shader: Shader = preload("res://Shaders/hologram.gdshader")

@onready var object_info: Node3D = $Object_Info

var grabbed_object_name: StringName

var handling_object: bool = false

var hol_body

var controlled_object: RigidBody3D
var controlled_objects: Array[StringName] = []

@onready var hologram: Node3D = $Hologram
var control_hologram_active: bool = false
var control_hologram_timer: Timer = Timer.new()


@onready var bubble_1: MeshInstance3D = $"Bubble_Beam/1"
@onready var bubble_2: MeshInstance3D = $"Bubble_Beam/2"
@onready var bubble_3: MeshInstance3D = $"Bubble_Beam/3"
@onready var bubble_4: MeshInstance3D = $"Bubble_Beam/4"
@onready var bubble_5: MeshInstance3D = $"Bubble_Beam/5"
@onready var bubble_6: MeshInstance3D = $"Bubble_Beam/6"
@onready var bubble_7: MeshInstance3D = $"Bubble_Beam/7"
@onready var bubble_8: MeshInstance3D = $"Bubble_Beam/8"
@onready var bubble_9: MeshInstance3D = $"Bubble_Beam/9"

var scale_tween: Tween
var position_tween: Tween



func _ready() -> void:
	object_info.visible = false
	object_info.scale = Vector3(0.001, 0.001, 0.001)
	add_child(control_hologram_timer)
	control_hologram_timer.one_shot = true

func _input(event: InputEvent) -> void:
	pass




func _process(delta: float) -> void:

	if controlled_object:
		controlled_objects.insert(0, controlled_object.name)
		cast_hologram('Controlled')
		controlled_object = null

	if control_hologram_timer.time_left == 0.0 and control_hologram_active:
		print('lol WHAT')
		retract_hologram()

func cast_beam():
	beam_anim.play("cast_beam")

func retract_beam():
	beam_anim.play_backwards("cast_beam")

func handle_object():
	#beam_mesh.visible = false
	handling_object = true

func release_handle():
	#beam_mesh.visible = true
	handling_object = false


func cast_hologram(type: String):
	var comp_name
	var g_comp
	var c_comp
	if hol_body:
		hol_body.queue_free()
	if type == "Controlled":
		comp_name = controlled_objects[0]
		control_hologram_timer.start(5.0)
		control_hologram_active = true
		c_comp = _instance_component_by_name(comp_name)
	elif type == "Grabbed":
		comp_name = grabbed_object_name
		g_comp = _instance_component_by_name(comp_name)

	if c_comp:
		hologram.add_child(c_comp)
		hol_body = c_comp.object_body.duplicate()
		hologram.add_child(hol_body)
		# ── Create a ShaderMaterial from your .gdshader ──
		var holo_mat = ShaderMaterial.new()
		holo_mat.shader = hologram_shader

		# ── Assign that ShaderMaterial to every MeshInstance3D inside hol_body ──
		for child in hol_body.get_children():
			if child is MeshInstance3D:
				child.set_surface_override_material(0, holo_mat)
				for extra_child in child.get_children():
					if extra_child is MeshInstance3D:
						extra_child.set_surface_override_material(0, holo_mat)
					
		c_comp.visible = false
		c_comp.collision_shape.disabled = true
		c_comp.object_body.scale = Vector3(0.1, 0.1, 0.1)
		holo_anim.play("cast_hologram")
		print('Cast hologram of ', comp_name,'!')

func switch_hologram(dir):
	if not control_hologram_active:
		retract_hologram()
		await get_tree().create_timer(0.5).timeout
		holo_anim.play("cast_details")
		return
	control_hologram_timer.start(5.0)
	if dir == 'Up':
		print('Switching hologram Up!')
	if dir == 'Down':
		print('Switching hologram Down!')

func retract_hologram():
	control_hologram_timer.stop()
	control_hologram_active = false
	holo_anim.play("retract_hologram")
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


func beam_in():
	beam_out(bubble_1)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_2)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_3)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_4)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_5)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_6)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_7)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_8)
	await get_tree().create_timer(0.01).timeout
	beam_out(bubble_9)

func beam_out(obj):
	scale_object(obj, 1.36, 1.36, 1.36, 0.0, 1.0)
	move_object(obj, 0.0, 0.0, -3.16, 0.0, 1.0)


func move_object(object, x_pos: float, y_pos: float, z_pos: float, wait_time: float, duration: float):
	await get_tree().create_timer(wait_time).timeout
	
	position_tween = create_tween()
	
	position_tween.tween_property(object, "position", Vector3(x_pos, y_pos, z_pos), duration)
	
	position_tween.set_trans(Tween.TRANS_SINE)
	position_tween.set_ease(Tween.EASE_IN_OUT)

func scale_object(object, x_scale: float, y_scale: float, z_scale: float, wait_time: float, duration: float):
	await get_tree().create_timer(wait_time).timeout
	
	scale_tween = create_tween()
	
	scale_tween.tween_property(object, "scale", Vector3(x_scale, y_scale, z_scale), duration)
	
	scale_tween.set_trans(Tween.TRANS_LINEAR)
	scale_tween.set_ease(Tween.EASE_IN_OUT)
