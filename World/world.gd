extends Node3D
class_name world

@onready var assembly_object_container: Node3D = $Assembly_Objects
var assembly_object_array: Array[RigidBody3D]

@onready var player_character: CharacterBody3D = $Character
var grabbed_object: RigidBody3D = null
var object_is_grabbed: bool = false

var last_held_object: RigidBody3D = null

var GRAB_STIFFNESS := BASE_GRAB_STIFFNESS
var GRAB_DAMPING := BASE_GRAB_DAMPING
var ROTATE_SPEED := BASE_ROTATE_SPEED  # Increase this for snappier rotation

const BASE_GRAB_STIFFNESS := 360.0
const BASE_GRAB_DAMPING := 36.0
const BASE_ROTATE_SPEED := 4.0  # Increase this for snappier rotation
const MIN_FORCE := -200000.0 
const MAX_FORCE := 200000.0    

var previous_grid_positions := {}
var assembly_components_global_position: Vector3

var screen_refresh_rate: float

var char_pos: Vector3
var char_forward: Vector3
var target_pos: Vector3
var target_transform: Transform3D
var target_grabbed_rotation: Vector3 = Vector3(10, 0, 0)
var reset_rotation: bool = false
var object_global_position: Vector3

var object_position_timer: Timer = Timer.new()

var proxy_is_moving_to_character: bool = false

# Desired fixed distance in front of the character (adjust as needed)
var base_distance_in_front: float = 6
# Speed factor for the interpolation (tweak for smoother/faster movement)
var grounded_interp_speed: float = 2.0
var airborne_interp_speed: float = 2.0
var movement_speed: float = 1.0

var grid_parent = Node3D.new()


var target
var grabbable_object: RigidBody3D

var stop_static_glow: bool = true
var static_glow_active: bool = false
var static_glow_task = null
var flicker_obj_a: Node = null
var flicker_obj_b: Node = null
var flicker_obj_c: Node = null

var time: float = 0.0
var current_spin_timer := 0.0
var extraction_spin_initialized: bool = false

var grab_initiated: bool = false

var first_grabbed_object: bool = true
@onready var grab_message: Label3D = $ClickToGrab

@onready var active_rocket: RigidBody3D = $"Launch_Platform/TRS-1"

var touching_launch_button = false
@onready var launch_instructions: Label3D = $Launch_Sequence/Instructions

func _activate_rocket():
	active_rocket = $"Launch_Platform/TRS-1"
	player_character.active_rocket = active_rocket

func _ready() -> void:
	
	_activate_rocket()
	
	launch_instructions.visible = false
	add_child(object_position_timer)

	start_static_glow_loop()
	
	$Launch_Sequence/Launch_Box_Anim.play("button_glow")


func _physics_process(delta: float) -> void:
	
	if active_rocket.all_systems_go:
		$Launch_Platform/Smoke_Cloud.emitting = true
		$Launch_Platform/Smoke_Cloud2.emitting = true
		
		if $Launch_Platform/Smoke_Cloud.emitting:
			$Launch_Platform/Smoke_Cloud.transparency += 0.00175
			$Launch_Platform/Smoke_Cloud2.transparency += 0.00175
	
		
	#print('See if auto switching to next component fixes duplicate extract shader issue')
	#print('Else...find a way to delete it from that component since it will not need it to be added again...')
	#
	if player_character.new_component:
		if player_character.new_component.ready_to_move:
			player_character.new_component.reparent(assembly_object_container)
			player_character.new_component.ready_to_move = false

	if grabbed_object:
		 #--- Force Movement Toward Target ---
		var cam_transform = player_character.camera.global_transform

		var forward = -cam_transform.basis.z
		var left = -cam_transform.basis.x
		var up = cam_transform.basis.y

		# Modify these to taste
		var distance_forward
		var offset_left
		var offset_up
		var smooth_speed
		
				## --- Smooth LookAt Rotation ---
		var object_pos = grabbed_object.global_transform.origin
		var look_dir = -(player_character.global_position - object_pos).normalized()

		look_dir.y += 0.15  # tweak this until it feels right
		look_dir = look_dir.normalized()

		if not player_character.extracting_object_active:
			if grabbed_object.object_body.scale.y < 0.99:
				grabbed_object.object_body.scale = lerp(grabbed_object.object_body.scale, grabbed_object.current_scale, delta * 5.0)
				grabbed_object.extract_body.scale = lerp(grabbed_object.extract_body.scale, Vector3.ZERO, delta * 20.0)
				grabbed_object.extract_body.position.y = lerp(grabbed_object.extract_body.position.y, -0.25, delta * 20.0)
				player_character.PREM_7.machine_info.scale = lerp(player_character.PREM_7.machine_info.scale, Vector3.ZERO, delta * 10.0)
				if grabbed_object.object_body.scale.y > 0.01:
					grabbed_object.object_body.visible = true
				if player_character.PREM_7.machine_info.scale.y <= 0.5:
					player_character.PREM_7.machine_info.visible = false
				if grabbed_object.extract_body.scale.y <= 0.01:
					grabbed_object.extract_body.visible = false
			distance_forward = 6.0
			offset_left = 0.0
			offset_up = 0.0
			smooth_speed = 6.0
			current_spin_timer = 0.0
			extraction_spin_initialized = false

		else:
			if player_character.current_extraction_data.is_empty():
				player_character._on_extract_key()
				if grabbed_object:
					for child in grabbed_object.get_children():
						if child is CollisionShape3D:
							child.disabled = true
					await get_tree().create_timer(1.0).timeout
				if grabbed_object:
					for child in grabbed_object.get_children():
						if child is CollisionShape3D:
							child.disabled = false
					release_object()
					return
			player_character.PREM_7.machine_info.visible = true
			grabbed_object.extract_body.visible = true
			distance_forward = 6.0 
			offset_left = 0.0
			offset_up = 0.0
			smooth_speed = 1.0
			if grabbed_object.object_body.scale.y >= 0.01:
				grabbed_object.object_body.scale = lerp(grabbed_object.object_body.scale, Vector3.ZERO, delta * 20.0)
				if grabbed_object.object_body.scale.y < 0.02:
					grabbed_object.object_body.visible = false
			if not extraction_spin_initialized:
				grabbed_object.extract_body.rotation_degrees.x = lerp(grabbed_object.extract_body.rotation_degrees.x, 0.0, delta * 5.0)
				grabbed_object.extract_body.rotation_degrees.y = lerp(grabbed_object.extract_body.rotation_degrees.y, 0.0, delta * 5.0)
				grabbed_object.extract_body.rotation_degrees.z = lerp(grabbed_object.extract_body.rotation_degrees.z, 0.0, delta * 5.0)
				current_spin_timer += delta * 0.5
				var scale_norm = player_character.extraction_scale / 5
				grabbed_object.extract_body.scale = lerp(grabbed_object.extract_body.scale, Vector3(scale_norm, scale_norm, scale_norm), delta * 5.0)
				grabbed_object.extract_body.position.y = lerp(grabbed_object.extract_body.position.y, 0.1, delta * 5.0)
				player_character.PREM_7.machine_info.scale = lerp(player_character.PREM_7.machine_info.scale, Vector3.ONE, delta * 5.0)
				if current_spin_timer > 0.25:
					extraction_spin_initialized = true
			if extraction_spin_initialized:
				var x_spd = player_character.current_mouse_speed_x / 1000.0
				var y_spd = player_character.current_mouse_speed_y / 1000.0
				if player_character.extraction_started:
					x_spd = 0.0
					y_spd = 0.0
				grabbed_object.extract_body.rotate_y(player_character.extract_speed + x_spd)
				grabbed_object.extract_body.rotate_x(y_spd)
				if y_spd < 0.01:
					grabbed_object.extract_body.rotation_degrees.x = lerp(grabbed_object.extract_body.rotation_degrees.x, 0.0, delta)
				grabbed_object.extract_body.rotation_degrees.z = lerp(grabbed_object.extract_body.rotation_degrees.z, 0.0, delta * 5.0)

		target_pos = cam_transform.origin + forward * distance_forward + left * offset_left + up * offset_up
	
		var obj_pos = grabbed_object.global_position
		var direction = target_pos - obj_pos
		var vel = grabbed_object.linear_velocity

		if GRAB_STIFFNESS < (BASE_GRAB_STIFFNESS * grabbed_object.mass - 5):
			GRAB_STIFFNESS = lerp(GRAB_STIFFNESS, BASE_GRAB_STIFFNESS * grabbed_object.mass, delta * 5.0)
		var force = (direction * GRAB_STIFFNESS) - (vel * GRAB_DAMPING)
			
		var desired_basis = Basis.looking_at(look_dir, Vector3.UP.normalized())
		var current_basis = grabbed_object.global_transform.basis.orthonormalized()
		var smoothed_basis = lerp(current_basis, desired_basis, delta * smooth_speed)

		var trans = grabbed_object.global_transform.orthonormalized()
		trans.origin = obj_pos
		trans.basis = smoothed_basis
		if not player_character.extracting_object_active:
			grabbed_object.global_transform = trans

		grabbed_object.apply_force(force)
		

func grab_object():
	if first_grabbed_object:
		player_character.PREM_7.extract_message.visible = true
		grab_message.visible = false
		first_grabbed_object = false
	grab_initiated = true
	player_character.PREM_7.cast_beam()
	#await get_tree().create_timer(0.4).timeout
	grabbed_object = grabbable_object
	grabbable_object = null
	grabbed_object.continuous_cd = false
	player_character.grabbed_object = grabbed_object
	grabbed_object.collision_layer = 1
	grabbed_object.collision_mask = 1
	flicker_obj_a = grabbed_object.object_body
	flicker_obj_b = player_character.PREM_7.back_panel
	flicker_obj_c = player_character.PREM_7.photon_tip
	grabbed_object.object_falling = false
	grabbed_object.is_touchable = false
	grabbed_object.freeze = false
	grabbed_object.physics_mat.friction = 0.0
	grabbed_object.axis_lock_angular_x = true
	grabbed_object.axis_lock_angular_y = true
	grabbed_object.axis_lock_angular_z = true
	grabbed_object.is_grabbed = true
	grabbed_object.brightness_increasing = true
	grabbed_object.glow_timer = 0.25
	GRAB_STIFFNESS = 0.0
	GRAB_DAMPING = BASE_GRAB_DAMPING * grabbed_object.mass
	player_character.grab_object()



func release_object():
	if player_character.PREM_7.extract_message.visible:
		player_character.PREM_7.extract_message.visible = false
	grabbed_object.linear_velocity /= 2
	grabbed_object.collision_layer = 3
	grabbed_object.collision_mask = 3
	flicker_obj_a.visible = true
	flicker_obj_b.visible = true
	flicker_obj_c.visible = true
	flicker_obj_a = null
	flicker_obj_b = null
	flicker_obj_c = null
	grabbed_object.is_touchable = true
	grabbed_object.physics_mat.friction = 1.0
	grabbed_object.axis_lock_angular_x = false
	grabbed_object.axis_lock_angular_y = false
	grabbed_object.axis_lock_angular_z = false
	grabbed_object.is_grabbed = false
	grabbed_object.brightness_increasing = false
	grabbed_object.standard_material.emission_energy_multiplier = 3.0
	#grabbed_object.continuous_cd = true
	player_character.release_object()
	grabbed_object = null

func _input(event: InputEvent) -> void:
	
	# Process Mouse Button events.
	if event is InputEventMouseButton:

		if not player_character.is_clickable:
			return

		if event.button_index == MOUSE_BUTTON_LEFT and not (player_character.extracting_object_active or player_character.fusing_object_active):
			target = player_character.touched_object
			if target is RigidBody3D:
				if target.is_rocketship:
					return
				grabbable_object = target
			else:
				grabbable_object = null
			if event.is_pressed():
				if grabbed_object:
					grabbed_object.gravity_scale = 1.5
					grabbed_object.is_suspended = false
					release_object()
					return
				if grabbable_object:
					grab_object()
					return
		elif event.button_index == MOUSE_BUTTON_RIGHT and not (player_character.extracting_object_active or player_character.fusing_object_active):
			if event.is_pressed():
				if grabbed_object:
					player_character.PREM_7.ctrl_anim.play("suspend")
					grabbed_object.gravity_scale = 0.0
					grabbed_object.freeze = false
					grabbed_object.is_suspended = true
					player_character.PREM_7.suspend_object = true
					release_object()

	if event is InputEventKey:
		if event.keycode == KEY_R:
			print('Resetting Rotation here, genius...')
			reset_rotation = true
			player_character.distance_from_character = base_distance_in_front
	
		if event.keycode == KEY_Q:
			if touching_launch_button and not active_rocket.launch_sequence_started:
				active_rocket.launch_rocket(11)
		
		if event.keycode == KEY_E or event.keycode == KEY_F:
			if not grabbed_object:
				return
			if not player_character.extracting_object_active and not player_character.fusing_object_active:
				print('Resetting Rotation here, genius...')
				reset_rotation = true
				player_character.distance_from_character = base_distance_in_front
				flicker_obj_a = grabbed_object.object_body
				for child in grabbed_object.object_body.get_children():
					child.set_material_overlay(grabbed_object.standard_material)
				grabbed_object.set_glitch(false)
			else:
				if player_character.extracting_object_active:
					flicker_obj_a = player_character.PREM_7.machine_info
					grabbed_object.set_glitch(false)


		if event.keycode == KEY_SHIFT:
			if event.is_pressed():
				movement_speed = 2
			else:
				movement_speed = 1





func spawn_grid():
	if is_instance_valid(grid_parent):
		grid_parent.queue_free()

	grid_parent = Node3D.new()
	grid_parent.name = "ExtractionGrid"
	add_child(grid_parent)
	
	previous_grid_positions.clear()
	
	assembly_components_global_position = grabbed_object.global_position

	var spacing = 3.0
	var curve_strength = 2.0

	var camera_pos = player_character.camera.global_transform.origin

	if not is_instance_valid(grabbed_object):
		return

	var component_count = grabbed_object.assembly_components.size()
	if component_count == 0:
		return

	var columns = min(5, component_count)
	var rows = 2

	# Corrected logic: top row gets the extra item if odd
	var top_row_count = int(ceil(component_count / 2.0))
	var bottom_row_count = component_count - top_row_count
	var row_counts = [bottom_row_count, top_row_count]  # Y = 0 (bottom), Y = 1 (top)

	for y in range(rows):
		var items_in_this_row = row_counts[y]
		var row_width = (items_in_this_row - 1) * spacing
		var row_start_x = -row_width / 2.0

		for x in range(items_in_this_row):
			var cube = MeshInstance3D.new()
			#cube.mesh = BoxMesh.new()
			#cube.material_override = StandardMaterial3D.new()
			#cube.scale = Vector3(cube_size, cube_size, cube_size)

			var x_offset = x * spacing
			var x_pos = row_start_x + x_offset

			# Curved placement
			var curve_center = (items_in_this_row - 1) / 2.0
			var z_curve = -pow((x - curve_center) / max(columns - 1, 1), 2) * curve_strength

			var local_pos = Vector3(x_pos, y * spacing, z_curve) + Vector3(0, 0, 3.0)
			cube.position = local_pos
			grid_parent.add_child(cube)

			await get_tree().process_frame

			var global_cube_pos = cube.global_transform.origin
			var to_camera = (camera_pos - global_cube_pos).normalized()
			to_camera.y = 0
			cube.look_at(global_cube_pos + to_camera, Vector3.UP)

			var column_letter = char(65 + x)
			var row_number = str(y + 1)
			var cube_name = "ExtractionGrid_%s%s" % [column_letter, row_number]
			cube.name = cube_name
			
			await get_tree().process_frame
			
			previous_grid_positions[cube_name] = cube.global_position
			grabbed_object.grid_positions = previous_grid_positions
			#print('Previous Grid Positions: ', previous_grid_positions)

	grabbed_object.extracted_object_container.global_position = grid_parent.global_position

func add_component_to_grid(obj):
	obj.scale = Vector3(0.01, 0.01, 0.01)
	player_character.assembly_component_selection = true
	player_character.extraction_recently_completed = true
	await get_tree().create_timer(0.025).timeout
	obj.visible = true
	obj.scale = Vector3(1.0, 1.0, 1.0)
	obj.reparent(assembly_object_container)
	obj.is_full_size = true



var rng = RandomNumberGenerator.new()

func start_static_glow_loop() -> void:

	static_glow_active = false
	await get_tree().process_frame  # kill previous loop cleanly

	static_glow_active = true
	_static_glow_loop()


func stop_static_glow_loop() -> void:
	static_glow_active = false


func _static_glow_loop() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	while static_glow_active:
		var delay = rng.randf_range(2.0, 6.0)
		await get_tree().create_timer(delay).timeout

		if not static_glow_active:
			break

		await _static_glow_blink(rng)



func _static_glow_blink(rand: RandomNumberGenerator) -> void:
	var blink_pairs = rand.randi_range(8, 16)

	for i in blink_pairs:
		if not static_glow_active:
			break

		var duration = rand.randf_range(0.005, 0.02)
		if flicker_obj_a and flicker_obj_b and flicker_obj_c:
			#if grabbed_object.is_extracting:
				#grabbed_object.set_glitch(false)
			#else:
				#for child in grabbed_object.object_body.get_children():
					#child.set_material_overlay(grabbed_object.standard_material)
			#flicker_obj_a.visible = true
			flicker_obj_b.visible = true
			flicker_obj_c.visible = true
		await get_tree().create_timer(duration).timeout

		if not static_glow_active:
			break
		if flicker_obj_a and flicker_obj_b and flicker_obj_c:
			#if grabbed_object.is_extracting:
				#
				#grabbed_object.set_glitch(true)
			#else:
				#for child in grabbed_object.object_body.get_children():
					#child.set_material_overlay(null)
			#flicker_obj_a.visible = false
			flicker_obj_b.visible = false
			flicker_obj_c.visible = false
		await get_tree().create_timer(duration).timeout

	if flicker_obj_a and flicker_obj_b and flicker_obj_c:
		#if grabbed_object.is_extracting:
			#grabbed_object.set_glitch(false)
		#else:
			#for child in grabbed_object.object_body.get_children():
				#child.set_material_overlay(grabbed_object.standard_material)
		#flicker_obj_a.visible = true
		flicker_obj_b.visible = true
		flicker_obj_c.visible = true
			




func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		$Launch_Sequence/Instructions.visible = true
		touching_launch_button = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		$Launch_Sequence/Instructions.visible = false
		touching_launch_button = false
