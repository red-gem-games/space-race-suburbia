extends RigidBody3D
class_name assembly_objects

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var ASSEMBLY_OBJECT_SCRIPT: Script = preload("res://Objects/assembly_objects.gd")

var object_rotation: Vector3
var is_grabbed: bool = false
var is_released: bool = false
var is_extractable: bool = true

var object_speed: Vector3
var object_speed_y: float

var assembly_parts: Array[RigidBody3D] = []
var is_extracted: bool = false

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

var is_rocketship: bool = false
var is_touching_rocket: bool = false
var is_resetting: bool = false

var colliding_with_character: bool = false
const phantom_body: bool = false

func _ready() -> void:
	
	contact_monitor = true
	continuous_cd = true
	
	connect("body_shape_entered", Callable(self, "_on_body_shape_entered"))
	connect("body_shape_exited",  Callable(self, "_on_body_shape_exited"))
	
	shader = Shader.new()
	shader.code = preload("res://Shaders/grabbed_glow.gdshader").code
	shader_material = ShaderMaterial.new()
	
	grab_particles_shader = Shader.new()
	grab_particles_shader.code = preload("res://Shaders/particle_glow.gdshader").code
	particles_material = ShaderMaterial.new()
	
	mass = 10
	contact_monitor = true
	continuous_cd = true
	max_contacts_reported = 100
	gravity_scale = 1.25

	var base_mesh : MeshInstance3D = null
	for child in get_children():
		if child is MeshInstance3D:
			base_mesh = child
			break
	if base_mesh:
		var outline_mesh : Mesh = base_mesh.mesh.create_outline(0.15)
		glow_body = MeshInstance3D.new()
		glow_body.name = "GlowBody"
		glow_body.mesh = outline_mesh
		glow_body.material_override = shader_material
		glow_body.visible = false    # start hidden
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
	
	if is_extracted:
		print(name, ' ', linear_damp)
	
	if not damp_set:
		if not is_grabbed:
			if global_position.y < -0.5 or global_position.z < -0.5:
				damp_elapsed_time += delta
				var t = clamp(damp_elapsed_time / damp_ramp_time, 0.0, 1.0)
				linear_damp = lerp(starting_damp, target_damp, t)
				angular_damp = lerp(starting_damp, target_damp, t)
				
				if t >= 1.0:
					contact_monitor = false
					damp_set = true

	if is_grabbed:
		linear_damp = 0
		angular_damp = 0
		contact_monitor = true
		damp_set = false
		damp_elapsed_time = 0.0

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if is_grabbed and body is RigidBody3D:
		#print(name, ' >>> is now touching >>> ', body.name)
		pass

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if is_grabbed and body is RigidBody3D:
		#print(name, ' ||| no longer touching ||| ', body.name)
		pass

func set_outline(status: String, color: Color) -> void:
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
		shader_material.shader = null
		glow_body.material_override = null
		glow_body.visible = false
		
		grab_particles.queue_free()
		grab_particles = null


	elif status == 'UPDATE':
		color.a = 0.25
		shader_material.set_shader_parameter("glow_color", color)

	elif status == 'ENHANCE':
		color.a = 0.65
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
	
		part.contact_monitor = true
		part.max_contacts_reported = 1000
		part.continuous_cd = true
		part.collision_layer = 1
		part.collision_mask = 1
		part.is_extractable = false
		part.gravity_scale = 0.0
		part.is_grabbed = false
		part.is_released = false
		part.is_extracted = true
		print(part.mass)
		
	visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()
