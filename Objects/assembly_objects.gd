extends RigidBody3D
class_name assembly_objects

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var object_body: MeshInstance3D

var ASSEMBLY_OBJECT_SCRIPT: Script = preload("res://Objects/assembly_objects.gd")
var GLOW_SHADER := preload("res://Shaders/grabbed_glow.gdshader")


var object_rotation: Vector3
var is_touching_ground: bool = false

var is_grabbed: bool = false
var recently_grabbed: bool = false
var is_released: bool = false

var base_spawn_pos: Vector3

var object_speed: Vector3
var object_speed_y: float

var is_extractable: bool = true
var shake_intensity: float = 25.0
var shake_duration: float = 3.0
var shake_timer: float = 0.0
var is_extracting: bool = false
var is_being_extracted: bool = false
var extract_in_motion: bool = false
var assembly_parts: Array[RigidBody3D] = []
var is_assembly_part: bool = false
var is_full_size: bool = false
var extraction_complete: bool = false

var base_x_rot: float
var base_y_rot: float
var base_z_rot: float
var base_x_pos: float
var base_y_pos: float
var base_z_pos: float
var ext_z_pos: float

var damp_set: bool = false
var target_damp: float = 100.0
var starting_damp: float = 10.0
var damp_ramp_time: float = 0.5  # 1 second total
var damp_elapsed_time: float = 0.0

var glow_body: MeshInstance3D
var shader: Shader
var shader_material: ShaderMaterial

var grab_particles: GPUParticles3D
var grab_particles_shader: Shader
var particles_material: ShaderMaterial

var world_object_container: Node3D

var is_stepladder: bool = false
var is_rocketship: bool = false
var is_touching_rocket: bool = false
var is_resetting: bool = false

var colliding_with_character: bool = false
const phantom_body: bool = false


### TWEENS ###

var rotate_tween: Tween
var position_tween: Tween
var scale_tween: Tween






func _ready() -> void:
	
	contact_monitor = true
	continuous_cd = true
	
	connect("body_shape_entered", Callable(self, "_on_body_shape_entered"))
	connect("body_shape_exited",  Callable(self, "_on_body_shape_exited"))
	
	shader = Shader.new()
	shader.code = GLOW_SHADER.code
	shader_material = ShaderMaterial.new()
	
	grab_particles_shader = Shader.new()
	grab_particles_shader.code = preload("res://Shaders/particle_glow.gdshader").code
	particles_material = ShaderMaterial.new()
	
	contact_monitor = true
	continuous_cd = true
	max_contacts_reported = 100
	gravity_scale = 1.25
	
	if is_in_group("Stepladder"):
		is_stepladder = true
		collision_layer = 1
		collision_mask = 1
	
	else:
		collision_layer = 2
		collision_mask = 3

	var base_mesh : MeshInstance3D = null
	for child in get_children():
		if child is MeshInstance3D:
			if child.name != "Body":
				base_mesh = child
			else:
				object_body = child 

	if base_mesh:
		var outline_mesh : Mesh = base_mesh.mesh.create_outline(0.15)
		glow_body = MeshInstance3D.new()
		glow_body.name = "Outline"
		glow_body.mesh = outline_mesh
		glow_body.material_override = shader_material
		glow_body.visible = false
		add_child(glow_body)
	else:
		push_warning("%s has no MeshInstance3D child to outline!" % name)

	for child in get_children():
		if child is RigidBody3D:
			assembly_parts.append(child)
			child.collision_layer = 0
			child.collision_mask = 0
			child.freeze = true
			child.name = "%s_%s" % [name, child.name]  # <--- this is the new line

			print('I, ', child.name, ' am an assembly part!')

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	
	if is_assembly_part and not extraction_complete:
		extraction_complete = true
	
	#if extraction_complete and not is_full_size:
		#add_part_to_grid()
		#visible = true
	
	#if is_assembly_part and not is_full_size:
		#print('huh')
		#scale_object(self, 5.0, 5.0, 5.0, 2.5, 0.5)
		#is_full_size = true
	
	var up_vector = global_transform.basis.y
	var alignment = up_vector.dot(Vector3.UP)

	if abs(alignment) < 0.01 and is_touching_ground:
		if not damp_set:
			dampen_assembly_object(delta)
	elif alignment > 0.99 and is_touching_ground:
		if not damp_set:
			dampen_assembly_object(delta)
	elif alignment < -0.99 and is_touching_ground:
		if not damp_set:
			dampen_assembly_object(delta)

	if is_grabbed:
		base_spawn_pos = global_position
		object_body.top_level = false
		object_body.global_transform = global_transform
		linear_damp = 0
		angular_damp = 0
		contact_monitor = true
		damp_elapsed_time = 0.0
		damp_set = false
		if is_in_group("Ground"):
			remove_from_group("Ground")

func _process(delta: float) -> void:

	
	### Frame Smoothing ###
	if not is_grabbed and object_body:
		object_body.top_level = true
		object_body.global_transform = object_body.global_transform.interpolate_with(self.global_transform, delta * 25.0)
	
	if is_extracting:
		print('is currently extracting')
		shake_timer -= delta
		if not extract_in_motion:
			extract_object_motion()


	if extract_in_motion:
		if shake_timer < 3.0 and shake_timer > 2.0:
			rotate_object(object_body, 0.0, -360.0, 0.0, 0.0, 0.35)
			rotate_object(glow_body, 0.0, -360.0, 0.0, 0.0, 0.35)
		elif shake_timer < 2.0 and shake_timer > 1.0:
			rotate_object(object_body, -360.0, -360.0, 0.0, 0.0, 0.35)
			rotate_object(glow_body, -360.0, -360.0, 0.0, 0.0, 0.35)
			scale_object(object_body, 1.5, 1.5, 1.5, 0.25, 0.5)
			scale_object(glow_body, 1.5, 1.5, 1.5, 0.25, 0.5)
		elif shake_timer < 1.0 and shake_timer > 0.0:
			rotate_object(object_body, 0.0, 0.0, 0.0, 0.0, 0.35)
			rotate_object(glow_body, 0.0, 0.0, 0.0, 0.0, 0.35)
			scale_object(object_body, 0.001, 0.001, 0.001, 0.25, 0.15)
			scale_object(glow_body, 0.001, 0.001, 0.001, 0.25, 0.15)
		elif shake_timer <= 0.0:
			is_being_extracted = true
			is_extracting = false
			extract_parts()
			extract_in_motion = false


func dampen_assembly_object(time):
	damp_elapsed_time += time
	var t = clamp(damp_elapsed_time / damp_ramp_time, 0.0, 1.0)
	linear_damp = lerp(starting_damp, target_damp, t)
	angular_damp = lerp(starting_damp, target_damp, t)
	gravity_scale = 0.25
	
	if t >= 1.0:
		add_to_group("Ground")
		contact_monitor = true
		damp_set = true
		linear_damp = 10 * mass
		angular_damp = 0
		gravity_scale = 1.0
		damp_elapsed_time = 0.0
		recently_grabbed = false

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if body.is_in_group("Ground"):
		is_touching_ground = true

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	pass

func set_outline(status: String, color: Color, opacity: float) -> void:
	if not is_instance_valid(glow_body):
		return

	if status == 'GRAB':
		randomize()
		shader_material.shader = shader
		color.a = 0.25
		shader_material.set_shader_parameter("glow_color", color)
		shader_material.set_shader_parameter("fresnel_power", 0.01)
		shader_material.set_shader_parameter("random_seed", randf())
		glow_body.material_override = shader_material
		glow_body.visible = true
		create_particles()


	elif status == 'RELEASE':
		if not is_being_extracted:
			shader_material.shader = null
			glow_body.material_override = null
			glow_body.visible = false
		
		grab_particles.queue_free()
		grab_particles = null


	elif status == 'UPDATE':
		color.a = 0.25
		shader_material.set_shader_parameter("glow_color", color)

	elif status == 'ENHANCE':
		color.a = opacity
		shader_material.set_shader_parameter("glow_color", color)

	elif status == 'DIM':
		color.a = 0.25
		shader_material.set_shader_parameter("glow_color", color)
		

func create_particles():
	grab_particles= GPUParticles3D.new()
	grab_particles.name = "GrabParticles"
	grab_particles.amount = 250
	grab_particles.lifetime = 0.25
	grab_particles.one_shot = false
	grab_particles.preprocess = 0.2
	grab_particles.speed_scale = 0.05
	grab_particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.5
	material.initial_velocity_min = 4.0
	material.initial_velocity_max = 10.0
	material.gravity = Vector3.ZERO
	material.direction = Vector3(0, 0, 0)
	material.spread = 100
	grab_particles.process_material = material

	# Use a custom shader material for particle visuals
	var particle_visual_mat := ShaderMaterial.new()
	particle_visual_mat.shader = grab_particles_shader
	particle_visual_mat.set_shader_parameter("glow_color", Color(0.0, 1.0, 0.0, 0.5))
	particle_visual_mat.set_shader_parameter("pulse_speed", 2.0)
	particle_visual_mat.set_shader_parameter("glow_intensity", 1.5)

	var mesh := SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = particle_visual_mat

	grab_particles.draw_pass_1 = mesh
	grab_particles.material_override = particle_visual_mat  # <- This is key

	grab_particles.position = Vector3.ZERO
	add_child(grab_particles)
	grab_particles.restart()

func start_extraction():
	is_extracting = true
	shake_timer = shake_duration

func cancel_extraction():
	extract_in_motion = false
	if position_tween:
		position_tween.stop()
	if rotate_tween:
		rotate_tween.stop()
	if scale_tween:
		scale_tween.stop()
	#move_object(self, base_x_pos, base_y_pos, base_y_pos, 0.0, 0.5)
	is_extracting = false

func shake():
	var shake_force = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
	apply_central_impulse(shake_force)

func extract_parts():
	var parts = assembly_parts.duplicate()
	assembly_parts.clear()
	
	for part in parts:
		if not is_instance_valid(part):
			continue

		part.freeze = false
		var world_xform = part.global_transform
		world_xform.origin.y += 0.5

		remove_child(part)
		
		world_object_container.add_child(part)
		part.call_deferred("set_global_transform", world_xform)
		
		part.set_script(ASSEMBLY_OBJECT_SCRIPT)
		part.call_deferred("_ready")
		await get_tree().create_timer(0.001).timeout
		
		part.is_extractable = false
		part.gravity_scale = 0.0
		part.is_grabbed = false
		part.is_released = false
		part.is_assembly_part = true
		part.is_full_size = false
		part.visible = true
		part.freeze = false

		var rand_x_pos: float = randf_range(-50.0, 50.0)
		var rand_y_pos: float = randf_range(2.0, 10.0)

		move_object(part, rand_x_pos, rand_y_pos, base_spawn_pos.z - 50, 0.0, 15.0)

		# === Outline logic ===
		var base_mesh: MeshInstance3D = null
		for child in part.get_children():
			if child is MeshInstance3D:
				base_mesh = child
				break
		
		if base_mesh:
			var outline_mesh := base_mesh.mesh.create_outline(0.15)
			part.glow_body = MeshInstance3D.new()
			part.glow_body.name = "Outline"
			part.glow_body.mesh = outline_mesh

			# Create or assign a real shader material
			var glow_mat := ShaderMaterial.new()
			glow_mat.shader = GLOW_SHADER
			part.glow_body.material_override = glow_mat

			# Match transform/position
			part.glow_body.transform = base_mesh.transform
			part.glow_body.visible = false
			part.add_child(part.glow_body)
			
			
		else:
			push_warning("%s has no MeshInstance3D child to outline!" % part.name)

		part.set_physics_process(true)
		part.set_process(true)



	visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()

func extract_object_motion():
	print(' -------- MOTION ACTIVATED --------- ')

	if not extract_in_motion:
		base_x_rot = rotation_degrees.x
		base_y_rot = rotation_degrees.y
		base_z_rot = rotation_degrees.z
		
		print(base_x_rot)

		base_x_pos = position.x
		base_y_pos = position.y
		base_z_pos=  position.z
		ext_z_pos= base_z_pos + 4.0

	extract_in_motion = true


##### TWEENS #####

func rotate_object(object, x_rot: float, y_rot: float, z_rot: float, wait_time: float, duration: float):
	await get_tree().create_timer(wait_time).timeout
	
	rotate_tween = create_tween()
	
	rotate_tween.tween_property(object, "rotation_degrees", Vector3(x_rot, y_rot, z_rot), duration)
	
	rotate_tween.set_trans(Tween.TRANS_LINEAR)
	rotate_tween.set_ease(Tween.EASE_IN_OUT)

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
