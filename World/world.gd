extends Node3D
class_name world

@onready var assembly_object_container: Node3D = $Assembly_Objects
var assembly_object_array: Array[RigidBody3D]

@onready var character: CharacterBody3D = $Character
var grabbed_object: RigidBody3D = null
var object_is_grabbed: bool = false

var last_held_object: RigidBody3D = null
var _last_grabbed_pos := Vector3.ZERO
var _release_velocity := Vector3.ZERO


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




func _ready() -> void:
	add_child(object_position_timer)
	var somn = assembly_object_container.get_children()
	for child in somn:
		child.character_body = character

	start_static_glow_loop()

const GRAB_STIFFNESS := 8000.0
const GRAB_DAMPING := 1200.0
const ROTATE_SPEED := 4.0  # Increase this for snappier rotation

func _physics_process(delta: float) -> void:

	
	if grabbed_object:
		
		print('----xxxxxx-----xxxx-----xxxxxx----')
		# --- Force Movement Toward Target ---
		var cam_pos = character.camera.global_transform.origin
		var cam_dir = -character.camera.global_transform.basis.z
		var target_pos = cam_pos + cam_dir * 6.0

		var obj_pos = grabbed_object.global_transform.origin
		var direction = target_pos - obj_pos
		var vel = grabbed_object.linear_velocity

		var force = (direction * GRAB_STIFFNESS) - (vel * GRAB_DAMPING)
		grabbed_object.apply_central_force(force)


		## --- Smooth LookAt Rotation ---
		var object_pos = grabbed_object.global_transform.origin
		var look_dir = -(character.global_position - object_pos).normalized()

		look_dir.y += 0.15  # tweak this until it feels right
		look_dir = look_dir.normalized()

		var desired_basis = Basis().looking_at(look_dir, Vector3.UP)
		var current_basis = grabbed_object.global_transform.basis
		var smoothed_basis = lerp(current_basis, desired_basis, delta * 10.0)

		var transform = grabbed_object.global_transform
		transform.basis = smoothed_basis
		grabbed_object.global_transform = transform
		



	for child in $Extracted_Object.get_children():
		if child.extraction_complete:
			if not child.is_full_size:
				add_component_to_grid(child)


	# When an object is grabbed:
	#if character.object_is_grabbed and not object_is_grabbed:
		#print('okay')
		#last_held_object = null
		#grabbed_object = character.grabbed_object
		#_last_grabbed_pos = grabbed_object.global_transform.origin
		#reset_rotation = true
		#object_is_grabbed = true
		#character.pitch_set = false
		#character.initial_grab = true
		#proxy_is_moving_to_character = true
		#grabbed_object.extracted_object_container = $Extracted_Object
		#if is_instance_valid(grid_parent):
			#grid_parent.queue_free()
			#grid_parent = null
		#if not character.suspending_object_active:
			#print('simple enough')
			#grabbed_object.reparent(character.grabbed_container)
#
	#
	## When the object is released:
	#elif not character.object_is_grabbed and object_is_grabbed:
		#if not is_instance_valid(grabbed_object):
			#return
		#if not grabbed_object.is_controlled:
			#grabbed_object.reparent(assembly_object_container)
		#if not grabbed_object.is_suspended:
			#grabbed_object.global_position = object_global_position
			#grabbed_object.global_position.y += 0.05
		#character.distance_from_character = base_distance_in_front
		#character.pitch_set = false
		#grabbed_object.linear_velocity = _release_velocity
		#if grabbed_object.is_controlled:
			#grabbed_object.queue_free()
		#grabbed_object = null
		#object_is_grabbed = false
		#print('still happening')
		#

	#if character.object_is_grabbed and object_is_grabbed and grabbed_object:
		#object_global_position = grabbed_object.global_position
		#if grabbed_object.is_suspended:
			#return
		#char_pos = character.camera.global_transform.origin
		#char_forward = -character.camera.global_transform.basis.z.normalized()
		#target_pos = char_pos + char_forward * character.distance_from_character
		#
		#
		#print('OH MY FUCKING GOD I DID IT')
		#grabbed_object.position.x += grabbed_object.add_to_x
		#
		#
		#print("After working all the way through the new possible grabbed_object living in the world, it can't happen -- when the object is grabbed and you're calculating the global_position, you still will need to mimic the collision a la what you just did with the original method...pointless to change and now you can focus on making it look great!")
		#
		#
		#
		#var custom_up = Vector3(0, 1, 0.001).normalized()
		#target_transform = Transform3D().looking_at(char_pos, custom_up)
		#target_transform.origin = target_pos
		#if character.grounded and not character.extracting_object_active:
			#grabbed_object.global_transform = grabbed_object.global_transform.interpolate_with(target_transform, delta * grounded_interp_speed)
		#elif not character.grounded and not character.extracting_object_active:
			#grabbed_object.global_transform = grabbed_object.global_transform.interpolate_with(target_transform, delta * airborne_interp_speed)
		#if reset_rotation:
			#character.grabbed_rotation = character.grabbed_rotation.lerp(target_grabbed_rotation, delta * 2.0)
			#grabbed_object.rotation_degrees = character.grabbed_rotation
			#if character.grabbed_rotation.distance_to(target_grabbed_rotation) < 0.05:
				#reset_rotation = false
#
		#if character.shifting_object_active:
			#reset_rotation = false
#
		#if is_instance_valid(grid_parent) and is_instance_valid(grabbed_object):
			#var raw_forward = -character.camera.global_transform.basis.z.normalized()
			#var flattened_forward = Vector3(raw_forward.x, 0, raw_forward.z).normalized()
			#var vertical_influence = clamp(raw_forward.y, 0, 0)  # limits up/down range
			#var adjusted_forward = (flattened_forward + Vector3(0, vertical_influence, 0)).normalized()
#
			## Position grid a fixed distance in front of the object (relative to camera)
			#grid_parent.global_position = char_pos + adjusted_forward * base_distance_in_front
			#var camera_pos = character.camera.global_transform.origin
			#var grid_pos = grid_parent.global_transform.origin
			#camera_pos.y = grid_pos.y
			#grid_parent.look_at(camera_pos, Vector3.UP)
#
		#if is_instance_valid(character.char_obj_shape):
			#if proxy_is_moving_to_character:
				#var current_transform: Transform3D = character.char_obj_shape.global_transform
				#var target_transform := grabbed_object.global_transform
#
				#target_transform.origin.y += 1.0
#
				#var interp_transform := current_transform.interpolate_with(target_transform, delta * 20.0)
				#character.char_obj_shape.global_transform = interp_transform
#
				#if interp_transform.origin.distance_to(target_transform.origin) < 0.1:
					#proxy_is_moving_to_character = false
			#else:
				#var proxy_transform := grabbed_object.global_transform
				#proxy_transform.origin = target_pos
				#character.char_obj_shape.global_transform = grabbed_object.global_transform
#
		#if grabbed_object.create_the_grid and not grid_parent:
			#spawn_grid()
			#grabbed_object.create_the_grid = false

func grab_object():
	grabbed_object = grabbable_object
	grabbed_object.collision_layer = 1
	grabbed_object.collision_mask = 1
	flicker_obj_a = grabbed_object.outline
	flicker_obj_b = character.PREM_7.photon_glow
	grabbed_object.enable_object_glow(grabbed_object.outline)
	grabbed_object.is_grabbed = true
	grabbed_object.is_touchable = false
	grabbed_object.freeze = false
	grabbed_object.physics_mat.friction = 0.0
	grabbed_object.axis_lock_angular_x = true
	grabbed_object.axis_lock_angular_y = true
	grabbed_object.axis_lock_angular_z = true
	character.grabbed_object = grabbed_object
	character.grab_object()


func release_object():
	#static_glow_active = false
	grabbed_object.collision_layer = 3
	grabbed_object.collision_mask = 3
	flicker_obj_a = null
	flicker_obj_b = null
	grabbed_object.is_grabbed = false
	grabbed_object.is_touchable = true
	grabbed_object.physics_mat.friction = 1.0
	grabbed_object.axis_lock_angular_x = false
	grabbed_object.axis_lock_angular_y = false
	grabbed_object.axis_lock_angular_z = false
	character.release_object()
	grabbed_object = null

func _input(event: InputEvent) -> void:
	
	# Process Mouse Button events.
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:
			target = character.touched_object
			if target is RigidBody3D:
				if target.is_rocketship:
					return
				grabbable_object = target
			else:
				grabbable_object = null
			if event.is_pressed():
				if grabbed_object:
					release_object()
					return
				if grabbable_object:
					grab_object()
					return


	if event is InputEventKey:
		if event.keycode == KEY_R:
			print('Resetting Rotation here, genius...')
			reset_rotation = true
			character.distance_from_character = base_distance_in_front
	
		if event.keycode == KEY_E or event.keycode == KEY_F or event.keycode == KEY_Q:
			if not character.extracting_object_active and not character.fusing_object_active:
				print('Resetting Rotation here, genius...')
				reset_rotation = true
				character.distance_from_character = base_distance_in_front

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
	var cube_size = 1.5
	var curve_strength = 2.0

	var camera_pos = character.camera.global_transform.origin

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
	character.assembly_component_selection = true
	character.extraction_recently_completed = true
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
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	while static_glow_active:
		var delay = rng.randf_range(1.0, 4.0)
		await get_tree().create_timer(delay).timeout

		if not static_glow_active:
			break

		await _static_glow_blink(rng)



func _static_glow_blink(rng: RandomNumberGenerator) -> void:
	var blink_pairs = rng.randi_range(3, 10)

	for i in blink_pairs:
		if not static_glow_active:
			break

		var duration = rng.randf_range(0.005, 0.015)
		if flicker_obj_a and flicker_obj_b:
			flicker_obj_a.visible = true
			flicker_obj_b.visible = true
		await get_tree().create_timer(duration).timeout

		if not static_glow_active:
			break
		if flicker_obj_a and flicker_obj_b:
			flicker_obj_a.visible = false
			flicker_obj_b.visible = false
		await get_tree().create_timer(duration).timeout

	if flicker_obj_a and flicker_obj_b:
		flicker_obj_a.visible = true
		flicker_obj_b.visible = true
