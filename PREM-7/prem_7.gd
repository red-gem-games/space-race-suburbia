extends Node3D
class_name PREM7

@onready var trig_anim: AnimationPlayer = $Trigger_Animation
@onready var ctrl_anim: AnimationPlayer = $Control_Animation
@onready var touch_anim: AnimationPlayer = $Touch_Animation
@onready var holo_anim: AnimationPlayer = $Hologram_Animation
@onready var grab_anim: AnimationPlayer = $Grab_Animation
@onready var back_panel: MeshInstance3D = $Multitool/Back_Panel
@onready var object_inventory: Node3D = $Multitool/Object_Inventory
@onready var photon_tip: MeshInstance3D = $Multitool/Photon_Tip

@onready var hologram_shader: Shader = preload("res://Shaders/hologram.gdshader")

var GLOW_SHADER := preload("res://Shaders/grabbed_glow.gdshader")
var shader: Shader
var shader_material: ShaderMaterial

@onready var dashboard: Node3D = $Dashboard

@onready var component_name: Label3D = $Dashboard/Data/Component/Component_Name
@onready var component_name_back: Label3D = $Dashboard/Data/Component/Component_Name_Back

@onready var machine_name: Label3D = $Dashboard/Data/Information/Machine_Name
@onready var machine_class: Label3D = $Dashboard/Data/Information/Class_Data
@onready var component_system: Label3D = $Dashboard/Data/Information/System_Data
@onready var component_condition: Node3D = $Dashboard/Condition

@onready var component_rating: Node3D = $Dashboard/Rating
@onready var component_mass: Label3D = $Dashboard/Mass/Mass

@onready var component_mayhem: MeshInstance3D = $Dashboard/Mayhem
@onready var component_mayhem_pct: Label3D = $Dashboard/Mayhem/Percentage

@onready var component_force: MeshInstance3D = $Dashboard/Force
@onready var component_force_amt: Label3D = $Dashboard/Force/Force_Data

@onready var control_position: Node3D = $Control_Position
@onready var hologram_position: Node3D = $Holo_Position

var grabbed_object_name: StringName
var handling_object: bool = false
var touching_object: bool = false
var beam_active: bool = false

var inspect_object: bool = false
var suspend_object: bool = false
var extract_object: bool = false
var fuse_object: bool = false

var hol_body

var controlled_object: RigidBody3D
var controlled_objects: Array[StringName] = []

@onready var hologram: Node3D = $Hologram
var control_hologram_active: bool = false
var control_hologram_timer: Timer = Timer.new()

@onready var extract_message: Label3D = $Extract_Message

var scale_tween: Tween
var position_tween: Tween

var c1: float
var c2: float
var c3: float

var grab_object_complete: bool = false

func _ready() -> void:
	
	extract_message.visible = false
	
	dashboard.visible = false
	dashboard.scale = Vector3(0.6, 0.6, 0.6)
	add_child(control_hologram_timer)
	control_hologram_timer.one_shot = true
	grab_anim.play("RESET")
	touch_anim.play("RESET")
	holo_anim.play("research_card")
	
	#shader = Shader.new()
	#shader.code = GLOW_SHADER.code
	#shader_material = ShaderMaterial.new()
	#shader_material.shader = GLOW_SHADER
	#back_panel.set_surface_override_material(0, shader_material)
	#back_panel.material_override = shader_material
	#shader_material.set_shader_parameter("speed", 0.15)
	#shader_material.set_shader_parameter("emission_strength", 1.0)
	#shader_material.set_shader_parameter("base_alpha", 0.1)
	#shader_material.set_shader_parameter("uv_projection_mode", 2)
	
	print("1. Add 'Fade Y (Min/Max)' back into Shader")
	print("2. Launch Multicolored Beam into object when grabbing")
	print("3. Once object is completely wrapped, release the beam (meaning it stops from the PREM-7 and the end lands within the object)")
	print("--------------")
	print("4. Add Tool Tips for various modes...first up is a widened split square that rotates when in extract mode")


func _process(_delta: float) -> void:
	
	if touching_object and not beam_active:
		touch_anim.play("touching_object")
		beam_active = true
	
	if not touching_object and beam_active:
		touch_anim.play_backwards("touching_object")
		beam_active = false


	rotation_degrees.z = 0.0
	clamp(rotation_degrees.x, -0.5, 0.5)
	
	#shader_material.set_shader_parameter("emission_strength", 10.0)
	#shader_material.set_shader_parameter("base_alpha", 2.0)

	#if controlled_object:
		#controlled_objects.insert(0, controlled_object.name)
		#cast_hologram('Controlled')
		#controlled_object = null
#
	#if control_hologram_timer.time_left == 0.0 and control_hologram_active:
		#retract_hologram()

func cast_beam():
	grab_object_complete = false
	grab_anim.play("grab_object")

func retract_beam():
	if grab_object_complete:
		grab_anim.play("release_object")
	else:
		grab_anim.play("RESET")

func handle_object():
	#beam_mesh.visible = false
	handling_object = true

func release_handle():
	#beam_mesh.visible = true
	handling_object = false

#
#func cast_hologram(type: String):
	#var comp_name
	#var c_comp
	#if hol_body:
		#hol_body.queue_free()
	#if type == "Controlled":
		#comp_name = controlled_objects[0]
		#control_hologram_timer.start(5.0)
		#control_hologram_active = true
		#c_comp = _instance_component_by_name(comp_name)
	#elif type == "Grabbed":
		#comp_name = grabbed_object_name
#
	#if c_comp:
		#hologram.add_child(c_comp)
		#hol_body = c_comp.object_body.duplicate()
		#hologram.add_child(hol_body)
		## ── Create a ShaderMaterial from your .gdshader ──
		#var holo_mat = ShaderMaterial.new()
		#holo_mat.shader = hologram_shader
#
		## ── Assign that ShaderMaterial to every MeshInstance3D inside hol_body ──
		#for child in hol_body.get_children():
			#if child is MeshInstance3D:
				#child.set_surface_override_material(0, holo_mat)
				#for extra_child in child.get_children():
					#if extra_child is MeshInstance3D:
						#extra_child.set_surface_override_material(0, holo_mat)
					#
		#c_comp.visible = false
		#c_comp.collision_shape.disabled = true
		#c_comp.object_body.scale = Vector3(0.1, 0.1, 0.1)
		#holo_anim.play("cast_hologram")
		#print('Cast hologram of ', comp_name,'!')
#
#func switch_hologram(dir):
	#if not control_hologram_active:
		#retract_hologram()
		#await get_tree().create_timer(0.5).timeout
		#holo_anim.play("cast_details")
		#return
	#control_hologram_timer.start(5.0)
	#if dir == 'Up':
		#print('Switching hologram Up!')
	#if dir == 'Down':
		#print('Switching hologram Down!')

#func retract_hologram():
	#control_hologram_timer.stop()
	#control_hologram_active = false
	#holo_anim.play_backwards("cast_hologram")
	#print('Retracting hologram!')

func _instance_component_by_name(name_string: StringName) -> RigidBody3D:
	# Build the exact path: e.g. "res://Components/DryingMachine.tscn"
	var path = "res://Components/%s.tscn" % name_string
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
	if anim_name == "cast_hologram" or anim_name == "retract_hologram":
		holo_anim.play("spin_hologram")

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


func _on_grab_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "grab_object":
		grab_object_complete = true
	if anim_name == "release_object":
		if not touching_object:
			touch_anim.play_backwards("touching_object")



func _on_touch_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "touching_object":
		touch_anim.play("extended_touch")
