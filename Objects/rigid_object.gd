extends RigidBody3D
class_name rigid_object

var object_rotation: Vector3
var is_grabbed: bool = false
var is_released: bool = false

var struck_objects: Array[RigidBody3D] = []
var object_currently_struck: bool = false
var object_speed: Vector3
var object_speed_y: float

@onready var glow_body: MeshInstance3D = $Glow_Body
var shader: Shader
var shader_material: ShaderMaterial

func _ready() -> void:
	mass = 35.0
	contact_monitor = true
	continuous_cd = true
	max_contacts_reported = 100
	glow_body.visible = false
	
	shader = Shader.new()
	shader.code = preload("res://Shaders/grabbed_glow.gdshader").code
	shader_material = ShaderMaterial.new()

func _physics_process(delta: float) -> void:

	if is_grabbed:
		for obj in struck_objects:
			if is_instance_valid(obj):
				obj.move_and_collide(object_speed * delta)
				obj.apply_impulse(Vector3.ZERO, object_speed * 0.5)
		if struck_objects.size() > 0:
			object_currently_struck = true
		else:
			object_currently_struck = false
	if is_released:
		struck_objects.clear()
		is_released = false

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if is_grabbed and body is RigidBody3D and not struck_objects.has(body):
		struck_objects.append(body)
		print(name, ' >>> is now touching >>> ', body.name)

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if is_grabbed and body is RigidBody3D and struck_objects.has(body):
		struck_objects.erase(body)
		print(name, ' ||| no longer touching ||| ', body.name)

func set_outline(status: String, color: Color) -> void:
	if not is_instance_valid(glow_body):
		return

	if status == 'GRAB':
		randomize()
		shader_material.shader = shader
		color.a = 0.4
		shader_material.set_shader_parameter("glow_color", color)
		shader_material.set_shader_parameter("fresnel_power", 0.01)
		shader_material.set_shader_parameter("random_seed", randf())
		glow_body.material_override = shader_material
		glow_body.visible = true

	elif status == 'RELEASE':
		shader_material.shader = null
		glow_body.material_override = null
		glow_body.visible = false

	elif status == 'UPDATE':
		color.a = 0.4
		shader_material.set_shader_parameter("glow_color", color)

	elif status == 'ENHANCE':
		color.a = 1.0
		shader_material.set_shader_parameter("glow_color", color)

					
	elif status == 'DIM':
		color.a = 0.4
		shader_material.set_shader_parameter("glow_color", color)


#func glow_flicker():
	#if not is_instance_valid(glow_body):
		#return
#
	## Kill existing tweens (safeguard)
	#for tween in get_tree().get_processed_tweens():
		#if tween.is_valid() and tween.is_running():
			#tween.kill()
#
	#var tween := create_tween().set_loops().bind_node(self).set_parallel()
#
	#var original_position = glow_body.position
	#var original_scale = glow_body.scale
#
	## Jitter loop (subtle & repeated)
	#tween.tween_property(glow_body, "position", original_position + Vector3(0.01, -0.015, 0.005), 0.05)
	#tween.tween_property(glow_body, "position", original_position, 0.05)
#
	## Scale pulse
	#tween.tween_property(glow_body, "scale", original_scale * 1.03, 0.1)
	#tween.tween_property(glow_body, "scale", original_scale, 0.1)
#
	## Visibility flicker
	#tween.tween_property(glow_body, "visible", false, 0.02).set_delay(0.03)
	#tween.tween_property(glow_body, "visible", true, 0.02).set_delay(0.03)
#
#
#func hover_object(amt: float, dur: float) -> void:
	#if not is_instance_valid(glow_body):
		#return
#
	## Kill any old tweens that might be messing things up
	##for tween in get_tree().get_processed_tweens():
		##if tween.is_valid() and tween.is_running() and tween.is_bound(self):
			##tween.kill()
#
	#var start_pos := glow_body.position
	#var hover_up := start_pos + Vector3(0, amt, 0)
	#var hover_down := start_pos - Vector3(0, amt, 0)
#
	#var tween := create_tween().bind_node(self)
	#tween.set_loops()  # infinite
	#tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#
	#tween.tween_property(glow_body, "position", hover_up, dur)
	#tween.tween_property(glow_body, "position", hover_down, dur)
#
	#print('Position: ', glow_body.position)
