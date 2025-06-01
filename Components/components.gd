extends RigidBody3D
class_name assembly_objects







@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var object_body: MeshInstance3D
var machine_name: StringName
var component_name: StringName

var COMPONENT_SCRIPT: Script = preload("res://Components/components.gd")
var GLOW_SHADER := preload("res://Shaders/grabbed_glow.gdshader")

var grid_positions: Dictionary = {}
var assigned_grid_position := Vector3.ZERO
var grid_assigned := false
var parent_global_position: Vector3
var extraction_location_set: bool = false

var object_rotation: Vector3
var is_touching_ground: bool = false
var touching_wall_count: int = 0
var touching_left_wall: bool = false
var touching_right_wall: bool = false
var touching_back_wall: bool = false
var touching_front_wall: bool = false

var is_grabbed: bool = false
var recently_grabbed: bool = false
var is_released: bool = false

var is_suspended: bool = false

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
var assembly_components: Array[RigidBody3D] = []
var is_assembly_component: bool = false
var is_full_size: bool = false
var extraction_complete: bool = false

var create_the_grid: bool = false

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

var extracted_object_container: Node3D

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


var is_controlled: bool = false


var character_body: CharacterBody3D
var character_force: Vector3

var extract_active: bool = false
var fuse_active: bool = false




func _ready() -> void:
	
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
	max_contacts_reported = 1000
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
			if child.name == "Outline":
				base_mesh = child
			else:
				object_body = child

	if base_mesh:
		#var outline_mesh = base_mesh.duplicate()
		#glow_body = outline_mesh
		#glow_body.scale = Vector3(1.15, 1.15, 1.15)
		#shader_material.shader = GLOW_SHADER
		#glow_body.set_surface_override_material(0, shader_material)
		var outline_mesh : Mesh = base_mesh.mesh.create_outline(0.075)
		glow_body = MeshInstance3D.new()
		glow_body.name = "Outline"
		glow_body.mesh = outline_mesh
		glow_body.material_override = shader_material
		shader_material.shader = shader
		glow_body.visible = false
		add_child(glow_body)
	else:
		push_warning("%s has no MeshInstance3D child to outline!" % name)

	for child in get_children():
		if child is RigidBody3D:
			assembly_components.append(child)
			child.collision_layer = 0
			child.collision_mask = 0
			child.freeze = true
			child.name = "%s_%s" % [name, child.name]  # <--- this is the new line

			#print('I, ', child.name, ' am an assembly component!')

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	
	if is_suspended:
		linear_velocity = lerp(linear_velocity, Vector3(0.0, 0.0, 0.0), delta * 1.5)
		angular_velocity = lerp(angular_velocity, Vector3(0.0, 0.0, 0.0), delta * 0.5)
	
	if is_assembly_component:
		if not extraction_complete:
			complete_extraction()
	
	var up_vector = global_transform.basis.y
	var alignment = up_vector.dot(Vector3.UP)
	
	if not is_suspended:
		if abs(alignment) < 0.01 and is_touching_ground:
			if not damp_set:
				dampen_assembly_object(delta * 0.025)
		elif alignment > 0.99 and is_touching_ground:
			if not damp_set:
				dampen_assembly_object(delta * 0.025)
		elif alignment < -0.99 and is_touching_ground:
			if not damp_set:
				dampen_assembly_object(delta * 0.025)
		else:
			linear_damp = 0
			angular_damp = 0

	if is_grabbed:
		object_body.top_level = false
		if is_suspended:
			return
		base_spawn_pos = global_position
		object_body.global_transform = global_transform
		linear_damp = 0
		angular_damp = 0
		contact_monitor = true
		damp_elapsed_time = 0.0
		damp_set = false
		if is_in_group("Ground"):
			remove_from_group("Ground")

func _process(delta: float) -> void:
	
	if fuse_active or extract_active:
		print('basically need to adjust the transparancy and alpha of grabbed object while in one of these two modes')
	
	#print(touching_wall_count)
	
	if touching_wall_count >= 2:
		sleeping = true

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
			create_the_grid = true
			rotate_object(object_body, 0.0, 0.0, 0.0, 0.0, 0.35)
			rotate_object(glow_body, 0.0, 0.0, 0.0, 0.0, 0.35)
			scale_object(object_body, 0.001, 0.001, 0.001, 0.25, 0.15)
			scale_object(glow_body, 0.001, 0.001, 0.001, 0.25, 0.15)
		elif shake_timer <= 0.0:
			is_being_extracted = true
			extract_components()
			is_extracting = false
			extract_in_motion = false


func dampen_assembly_object(time):
	damp_elapsed_time += time
	var t = clamp(damp_elapsed_time / damp_ramp_time, 0.0, 1.0)
	linear_damp = lerp(starting_damp, target_damp, t)
	angular_damp = lerp(starting_damp, target_damp, t)
	gravity_scale = 1.0
	linear_damp = 40
	damp_set = true

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if body.is_in_group("Ground"):
		if is_suspended:
			return
		is_touching_ground = true

	if body.name == 'Floor':
		add_to_group('Ground')
		print('ah haaaa')

	if body.name == "Left_Wall" and not touching_left_wall:
		touching_wall_count += 1
		touching_left_wall = true

	elif body.name == "Right_Wall" and not touching_right_wall:
		touching_wall_count += 1
		touching_right_wall = true

	elif body.name == "Back_Wall" and not touching_back_wall:
		touching_wall_count += 1
		touching_back_wall = true

	elif body.name == "Front_Wall" and not touching_front_wall:
		touching_wall_count += 1
		touching_front_wall = true

	if body is character:
		body.is_on_floor()
		character_force = character_body.current_velocity
		print(character_force)

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if body.name == "Left_Wall" and touching_left_wall:
		touching_wall_count -= 1
		touching_left_wall = false

	elif body.name == "Right_Wall" and touching_right_wall:
		touching_wall_count -= 1
		touching_right_wall = false

	elif body.name == "Back_Wall" and touching_back_wall:
		touching_wall_count -= 1
		touching_back_wall = false

	elif body.name == "Front_Wall" and touching_front_wall:
		touching_wall_count -= 1
		touching_front_wall = false

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
		glow_body.visible = true

	elif status == 'ENHANCE':
		color.a = opacity
		shader_material.set_shader_parameter("glow_color", color)
		glow_body.visible = true

	elif status == 'DIM':
		color.a = 0.25
		shader_material.set_shader_parameter("glow_color", color)
		glow_body.visible = true
		
	elif status == "EXTRACT":
		glow_body.visible = false

	elif status == "FUSE":
		glow_body.visible = false

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

func extract_components():
	var components = assembly_components.duplicate()
	assembly_components.clear()

	var shared_grid_positions = grid_positions.duplicate()


	for component in components:
		if not is_instance_valid(component):
			continue

		remove_child(component)
		extracted_object_container.add_child(component)
		
		await get_tree().process_frame  # <-- Let it reparent
		
		component.set_script(COMPONENT_SCRIPT)
		component.call_deferred("_ready")
		await get_tree().create_timer(0.001).timeout
		
		component.is_extractable = false
		component.gravity_scale = 0.0
		component.is_grabbed = false
		component.is_released = false
		component.is_assembly_component = true
		component.is_full_size = false
		component.visible = false
		component.freeze = false
		#component.parent_global_position = global_position
		print('Component Pos: ', component.global_position)
		
		component.grid_positions = shared_grid_positions
		component.assign_next_grid_position()


		# === Outline logic ===
		var base_mesh: MeshInstance3D = null
		for child in component.get_children():
			if child is MeshInstance3D:
				base_mesh = child
				break
		
		if base_mesh:
			var outline_mesh := base_mesh.mesh.create_outline(0.075)
			component.glow_body = MeshInstance3D.new()
			component.glow_body.name = "Outline"
			component.glow_body.mesh = outline_mesh

			# Create or assign a real shader material
			var glow_mat := ShaderMaterial.new()
			glow_mat.shader = GLOW_SHADER
			component.glow_body.material_override = glow_mat

			# Match transform/position
			component.glow_body.transform = base_mesh.transform
			component.glow_body.visible = false
			component.add_child(component.glow_body)
			
			
		else:
			push_warning("%s has no MeshInstance3D child to outline!" % component.name)

		component.set_physics_process(true)
		component.set_process(true)



	visible = false
	await get_tree().create_timer(0.5).timeout
	extraction_complete = true
	queue_free()

func extract_object_motion():
	print(' -------- MOTION ACTIVATED --------- ')

	if not extract_in_motion:
		base_x_rot = rotation_degrees.x
		base_y_rot = rotation_degrees.y
		base_z_rot = rotation_degrees.z

		base_x_pos = position.x
		base_y_pos = position.y
		base_z_pos=  position.z
		ext_z_pos= base_z_pos + 4.0

	extract_in_motion = true

func complete_extraction():
	component_name = name.split("_", true, 1)[1]
	machine_name = name.split("_", true, 1)[0]
	print("This component is: ", component_name)
	print("Came from machine: ", machine_name)
	global_position = assigned_grid_position
	extraction_complete = true

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

func assign_next_grid_position():
	if grid_assigned:
		return  # already done
	
	for key in grid_positions.keys():
		assigned_grid_position = grid_positions[key]
		grid_positions.erase(key)  # remove from pool
		grid_assigned = true
		break




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
