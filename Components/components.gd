extends RigidBody3D
class_name assembly_objects

var object_set: bool = false

var object_body: MeshInstance3D
var machine_name: StringName
var component_name: StringName

var COMPONENT_SCRIPT: Script = preload("res://Components/components.gd")
var GLOW_SHADER := preload("res://Shaders/grabbed_glow.gdshader")
var MANIPULATION_SHADER:= preload("res://Shaders/manipulation.gdshader")
var manipulation_material: ShaderMaterial = ShaderMaterial.new()
var GLASS_MATERIAL: = preload("res://Shaders/Glass_Material.tres")
var GLOW_MATERIAL := preload("res://Shaders/Component_Glow.tres")
var EXTRACTION_SHADER := preload("res://Shaders/extract_selection.gdshader")
var extraction_material: ShaderMaterial = ShaderMaterial.new()
var extracted_object_mat
var EXTRACT_MATERIAL := preload("res://Shaders/Highlight_Glow.tres")

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

var ready_to_move: bool = false

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
var standard_material: StandardMaterial3D

var grab_particles: GPUParticles3D
var grab_particles_shader: Shader
var particles_material: ShaderMaterial

var is_component: bool = false
var extracted_object_container: Node3D

var is_stepladder: bool = false
var is_rocketship: bool = false
var is_rocket_system: bool = false
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

var manipulation_active: bool = false
var extract_active: bool = false
var fuse_active: bool = false

var extractables: Array[RigidBody3D] = []

var physics_mat = PhysicsMaterial.new()

var is_touched: bool = false
var is_touchable: bool = true
var glow_timer: float = 0.0
var outline
var resting_position
var c1: float
var c2: float
var c3: float

var forward
var extract_pos_x: float
var extract_pos_y: float
var extract_pos_z: float

var glitch: bool = false
var extract_hue := 0.0
var extract_speed := 0.1  # How fast the hue rotates
var current_scale: Vector3

var extract_body: MeshInstance3D
var extraction_scale: float

var is_colliding: bool
var is_on_floor: bool

var fade_extract_glow: bool = false


func _ready() -> void:
	
	shader = Shader.new()
	shader.code = GLOW_SHADER.code
	shader_material = ShaderMaterial.new()
	
	manipulation_material.shader = MANIPULATION_SHADER
	extraction_material.shader = EXTRACTION_SHADER
	extracted_object_mat = EXTRACT_MATERIAL.duplicate()
	
	
	contact_monitor = true
	continuous_cd = false
	max_contacts_reported = 100
	gravity_scale = 1.5
	
	collision_layer = 1
	collision_mask = 1
	
	mass = mass * 2
	
	physics_mat.friction = 0.9
	physics_mat.bounce = 0.0
	self.physics_material_override = physics_mat
	shader_material.shader = GLOW_SHADER
	standard_material = GLOW_MATERIAL
	for child in get_children():
		if child is MeshInstance3D:
			object_body = child
			current_scale = object_body.scale

	resting_position = global_position.y
	set_physics_process(true)

	if name == "Stepladder":
		is_stepladder = true

var prev_y_vel
var curr_y_vel
var object_falling: bool = false

var prev_y_pos
var curr_y_pos

var set_it_up

func _physics_process(delta: float) -> void:

	if not object_set:
		connect("body_shape_entered", Callable(self, "_on_body_shape_entered"))
		connect("body_shape_exited",  Callable(self, "_on_body_shape_exited"))
		object_set = true

	if is_grabbed and is_component:
		print('Make this color highlight as purple to signify component')

	if is_suspended:
		linear_velocity = lerp(linear_velocity, Vector3(0.0, 0.0, 0.0), delta * 1.5)
		angular_velocity = lerp(angular_velocity, Vector3(0.0, 0.0, 0.0), delta * 0.5)
		freeze = false
	
	#if is_assembly_component:
		#if not extraction_complete:
			#complete_extraction()

	if extract_in_motion:
		angular_velocity = Vector3(0.0, 1.0, 0.0)
	if is_grabbed:
		if position_tween:
			position_tween.kill()
		if glow_tween:
			glow_tween.kill()
		#object_body.top_level = false

		base_spawn_pos = global_position
		linear_damp = 0
		angular_damp = 0
		contact_monitor = true
		damp_elapsed_time = 0.0
		damp_set = false

var brightness_increasing: bool = true

func _process(delta: float) -> void:
	
	if fade_extract_glow:
		extracted_object_mat.emission_energy_multiplier = lerp(extracted_object_mat.emission_energy_multiplier, 0.0, delta)
		extracted_object_mat.emission.a = lerp(extracted_object_mat.emission.a, 0.0, delta * 2.5)
		extracted_object_mat.albedo_color.a = lerp(extracted_object_mat.albedo_color.a, -0.1, delta * 2.5)
		
		if extracted_object_mat.albedo_color.a < 0.0:
			for child in get_children():
				if child is MeshInstance3D:
					child.set_material_overlay(null)
			fade_extract_glow = false
	
	if not is_grabbed:
		if glow_tween:
			glow_tween.kill()
		if is_touchable:
			if is_touched:
				for child in object_body.get_children():
					child.set_material_overlay(standard_material)
					standard_material.emission = Color(0.6, 0.9, 0.6)
					standard_material.emission_energy_multiplier = 2.0
				
			if not is_touched:
				for child in object_body.get_children():
					child.set_material_overlay(null)


	if is_grabbed:
		if brightness_increasing:
			glow_timer -= delta
			standard_material.emission = lerp(standard_material.emission, Color.GREEN, delta * 3.0)
			standard_material.emission_energy_multiplier = lerp(standard_material.emission_energy_multiplier, 100.0, delta)
			if glow_timer <= 0.0:
				brightness_increasing = false
		else:
			standard_material.emission_energy_multiplier = lerp(standard_material.emission_energy_multiplier, 16.0, delta * 7.0)
			if standard_material.emission_energy_multiplier == 15.9:
				is_grabbed = false
				brightness_increasing = true

	if ready_to_move:
		assembly_components.append(self)
		is_assembly_component = true
		is_full_size = true

func enable_object_glow(object: Node) -> void:
	# Start the transparency tween
	var t := create_tween()
	t.tween_property(object, "transparency", 0.875, 0.25)

func dampen_assembly_object(time):
	damp_elapsed_time += time
	var t = clamp(damp_elapsed_time / damp_ramp_time, 0.0, 1.0)
	linear_damp = lerp(starting_damp, target_damp, t)
	angular_damp = lerp(starting_damp, target_damp, t)
	gravity_scale = 1.5
	linear_damp = 40
	damp_set = true

func _on_body_shape_entered(_body_rid: RID, body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	
	if body.name == 'Floor' or body.name == "Workshop":
		is_touching_ground = true
	
	if body is character:
		body.is_on_floor()

	if name == 'Stepladder':
		if body is CharacterBody3D:
			body.is_touching_stepladder = true

func _on_body_shape_exited(_body_rid: RID, body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	if name == 'Stepladder':
		if body is CharacterBody3D:
			body.is_touching_stepladder = false


func set_outline(status: String, color: Color, opacity: float) -> void:
	if not is_instance_valid(glow_body):
		return

	if status == 'GRAB':
		randomize()
		shader_material.shader = shader
		#color.a = 0.25
		#shader_material.set_shader_parameter("albedo", color)
		#shader_material.set_shader_parameter("fresnel_power", 0.1)
		#shader_material.set_shader_parameter("random_seed", randf())
		glow_body.material_override = shader_material
		#glow_body.visible = true`
		#create_particles()


	elif status == 'RELEASE':
		if not is_being_extracted:
			shader_material.shader = null
			glow_body.material_override = null
			glow_body.visible = false
		
		if grab_particles:
			grab_particles.queue_free()
			grab_particles = null


	elif status == 'UPDATE':
		color.a = 0.25
		#shader_material.set_shader_parameter("glow_color", color)
		glow_body.visible = true

	elif status == 'ENHANCE':
		color.a = opacity
		#shader_material.set_shader_parameter("glow_color", color)
		glow_body.visible = true

	elif status == 'DIM':
		color.a = 0.25
		#shader_material.set_shader_parameter("glow_color", color)
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
	
	var extractable_children = get_children()
	for child in extractable_children:
		if child is RigidBody3D:
			extractables.append(child)
	for child in extractables:
		print(child.name)
		
	#print('Extractables: ', extractables)

func cycle_extraction_component():
	pass

func extract_component():
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
			component.outline = outline_mesh

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

#func extract_object_motion():
	#print(' -------- MOTION ACTIVATED --------- ')
#
	#if not extract_in_motion:
		#base_x_rot = rotation_degrees.x
		#base_y_rot = rotation_degrees.y
		#base_z_rot = rotation_degrees.z
#
		#base_x_pos = position.x
		#base_y_pos = position.y
		#base_z_pos=  position.z
		#ext_z_pos= base_z_pos + 4.0
#
	#extract_in_motion = true

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

var hover_tween: Tween

func hover_object(object, y_pos: float, duration: float):
	hover_tween = create_tween()
	
	hover_tween.tween_property(object, "global_position:y", y_pos, duration)
	
	hover_tween.set_trans(Tween.TRANS_SINE)
	hover_tween.set_ease(Tween.EASE_IN_OUT)
	

func scale_object(object, x_scale: float, y_scale: float, z_scale: float, wait_time: float, duration: float):
	await get_tree().create_timer(wait_time).timeout
	
	scale_tween = create_tween()
	
	scale_tween.tween_property(object, "scale", Vector3(x_scale, y_scale, z_scale), duration)
	
	scale_tween.set_trans(Tween.TRANS_LINEAR)
	scale_tween.set_ease(Tween.EASE_IN_OUT)

var glow_tween: Tween

func change_glow(object, amt: float, dur: float):

	glow_tween = create_tween()
	
	glow_tween.tween_property(object, "transparency", amt, dur)
	
	glow_tween.set_trans(Tween.TRANS_LINEAR)
	glow_tween.set_ease(Tween.EASE_IN_OUT)


func manipulation_mode(type):
	
	if type == "Active":
		
		for child in extract_body.get_children():
			if child is MeshInstance3D:
				var surface_count = child.mesh.get_surface_count()
				for i in range(surface_count):
					child.set_surface_override_material(i, manipulation_material)
					child.cast_shadow = false

	elif type == "Inactive":
		for child in extract_body.get_children():
			if child is MeshInstance3D:
				child.set_material_overlay(standard_material)

func set_glitch(status):
	manipulation_material.set_shader_parameter("enable_glitch", status)

func set_extract_glow(component, selection):
	var surface_count = component.mesh.get_surface_count()
	extracted_object_mat.albedo_color = Color.WHITE
	extracted_object_mat.emission = Color.PURPLE
	if selection == 'Selected':
		component.set_material_overlay(EXTRACT_MATERIAL)
		for i in range(surface_count):
			component.set_surface_override_material(i, null)
	elif selection == 'Deselected':
		component.set_material_overlay(null)
		for i in range(surface_count):
			component.set_surface_override_material(i, manipulation_material)
	elif selection == 'Complete':
		component.set_material_overlay(extracted_object_mat)
		for i in range(surface_count):
			component.set_surface_override_material(i, null)
