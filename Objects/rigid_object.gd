extends RigidBody3D
class_name rigid_object

var object_rotation: Vector3
var is_grabbed: bool = false
var is_released: bool = false

var struck_objects: Array[RigidBody3D] = []
var object_currently_struck: bool = false
var object_speed: Vector3
var object_speed_y: float

@onready var glow_body: Node3D = $Glow_Body

func _ready() -> void:
	mass = 35.0
	contact_monitor = true
	continuous_cd = true
	max_contacts_reported = 100
	glow_body.visible = false

func _physics_process(delta: float) -> void:
	#print(glow_body.get_parent().name, ' Glow Body Visible: ', glow_body.visible)
	
	if is_grabbed:
		glow_flicker()
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
		for mesh in glow_body.get_children():
			if mesh is MeshInstance3D and not mesh.has_node("OutlineMesh"):
				var outline = mesh.duplicate() as MeshInstance3D
				outline.name = "OutlineMesh"
				outline.scale *= 1.1
				var mat := StandardMaterial3D.new()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.albedo_color = color
				mat.albedo_color.a = 0.25
				mat.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
				mat.cull_mode = BaseMaterial3D.CULL_FRONT
				mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
				outline.material_override = mat
				mesh.add_child(outline)
				glow_body.visible = true
		hover_object(0.1, 0.4)
	elif status == 'RELEASE':
		for mesh in glow_body.get_children():
			if mesh is MeshInstance3D and mesh.has_node("OutlineMesh"):
				mesh.get_node("OutlineMesh").queue_free()

	elif status == 'UPDATE':
		for mesh in glow_body.get_children():
			if mesh is MeshInstance3D and mesh.has_node("OutlineMesh"):
				var outline = mesh.get_node("OutlineMesh") as MeshInstance3D
				if outline and outline.material_override is StandardMaterial3D:
					var mat := outline.material_override as StandardMaterial3D
					mat.albedo_color = color
					mat.albedo_color.a = 0.5  # maintain transparency

	elif status == 'ENHANCE':
		for mesh in glow_body.get_children():
			if mesh is MeshInstance3D and mesh.has_node("OutlineMesh"):
				var outline = mesh.get_node("OutlineMesh") as MeshInstance3D
				if outline and outline.material_override is StandardMaterial3D:
					var mat := outline.material_override as StandardMaterial3D
					mat.albedo_color.a = 0.9
					
	elif status == 'DIM':
		for mesh in glow_body.get_children():
			if mesh is MeshInstance3D and mesh.has_node("OutlineMesh"):
				var outline = mesh.get_node("OutlineMesh") as MeshInstance3D
				if outline and outline.material_override is StandardMaterial3D:
					var mat := outline.material_override as StandardMaterial3D
					mat.albedo_color.a = 0.5


func glow_flicker():
	if not is_instance_valid(glow_body):
		return

	# Kill existing tweens (safeguard)
	for tween in get_tree().get_processed_tweens():
		if tween.is_valid() and tween.is_running():
			tween.kill()

	var tween := create_tween().set_loops().bind_node(self).set_parallel()

	var original_position = glow_body.position
	var original_scale = glow_body.scale

	# Jitter loop (subtle & repeated)
	tween.tween_property(glow_body, "position", original_position + Vector3(0.01, -0.015, 0.005), 0.05)
	tween.tween_property(glow_body, "position", original_position, 0.05)

	# Scale pulse
	tween.tween_property(glow_body, "scale", original_scale * 1.03, 0.1)
	tween.tween_property(glow_body, "scale", original_scale, 0.1)

	# Visibility flicker
	tween.tween_property(glow_body, "visible", false, 0.02).set_delay(0.03)
	tween.tween_property(glow_body, "visible", true, 0.02).set_delay(0.03)


func hover_object(amt: float, dur: float) -> void:
	if not is_instance_valid(glow_body):
		return

	# Kill any old tweens that might be messing things up
	#for tween in get_tree().get_processed_tweens():
		#if tween.is_valid() and tween.is_running() and tween.is_bound(self):
			#tween.kill()

	var start_pos := glow_body.position
	var hover_up := start_pos + Vector3(0, amt, 0)
	var hover_down := start_pos - Vector3(0, amt, 0)

	var tween := create_tween().bind_node(self)
	tween.set_loops()  # infinite
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(glow_body, "position", hover_up, dur)
	tween.tween_property(glow_body, "position", hover_down, dur)

	print('Position: ', glow_body.position)
