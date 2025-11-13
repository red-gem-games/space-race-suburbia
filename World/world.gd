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

@onready var computer_camera: Camera3D = $Workshop/Workbench/Computer_Camera

func _activate_rocket():
	active_rocket = $"Launch_Platform/TRS-1"
	player_character.active_rocket = active_rocket

func _ready() -> void:
	
	_activate_rocket()
	
	player_character.camera.make_current()
	
	launch_instructions.visible = false
	add_child(object_position_timer)

	start_static_glow_loop()
	
	$Launch_Sequence/Launch_Box_Anim.play("button_glow")


var computer_active: bool = false

func _physics_process(delta: float) -> void:
	
	
	#if grabbed_object:
		#if grabbed_object.extract_body:
			#print(grabbed_object.extract_body.scale)
	
	if player_character.is_using_computer:
		computer_active = true
		camera_tween(player_character.camera, 10, 0.65)
		
		#computer_camera.make_current()
	
	if active_rocket.all_systems_go:
		$Launch_Platform/Smoke_Cloud.emitting = true
		$Launch_Platform/Smoke_Cloud2.emitting = true
		
		if $Launch_Platform/Smoke_Cloud.emitting:
			$Launch_Platform/Smoke_Cloud.transparency += 0.00175
			$Launch_Platform/Smoke_Cloud2.transparency += 0.00175
	

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
				grabbed_object.extract_body.scale = lerp(grabbed_object.extract_body.scale, Vector3.ZERO, delta * 7.0)
				grabbed_object.extract_body.position.x = lerp(grabbed_object.extract_body.position.x, 0.01, delta * 7.0)
				grabbed_object.extract_body.position.y = lerp(grabbed_object.extract_body.position.y, -0.35, delta * 7.0)
				grabbed_object.extract_body.position.z = lerp(grabbed_object.extract_body.position.z, 0.1, delta * 7.0)
				player_character.PREM_7.dashboard.scale = lerp(player_character.PREM_7.dashboard.scale, Vector3.ZERO, delta * 10.0)
				if grabbed_object.object_body.scale.y > 0.01:
					grabbed_object.object_body.visible = true
				if player_character.PREM_7.dashboard.scale.y <= 0.5:
					player_character.PREM_7.dashboard.visible = false
				if grabbed_object.extract_body.scale.y <= 0.01:
					grabbed_object.extract_body.visible = false
			distance_forward = player_character.distance_factor
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
			player_character.PREM_7.dashboard.visible = true
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
				var scale_norm = player_character.extraction_scale / 3
				grabbed_object.extract_body.scale = lerp(grabbed_object.extract_body.scale, Vector3(scale_norm, scale_norm, scale_norm), delta * 5.0)
				grabbed_object.extract_body.position.x = lerp(grabbed_object.extract_body.position.x, 0.0, delta * 7.0)
				grabbed_object.extract_body.position.y = lerp(grabbed_object.extract_body.position.y, 0.1, delta * 5.0)
				grabbed_object.extract_body.position.z = lerp(grabbed_object.extract_body.position.z, -1.0, delta * 5.0)
				player_character.PREM_7.dashboard.scale = lerp(player_character.PREM_7.dashboard.scale, Vector3.ONE, delta * 5.0)
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
				grabbed_object.extract_body.rotation_degrees.z = lerp(grabbed_object.extract_body.rotation_degrees.z, 0.0, delta * 10.0)

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
	player_character.activate_component_data()



func release_object():
	#exposure_tween(player_character.camera, 0.9, 0.25)
	if player_character.PREM_7.extract_message.visible:
		player_character.PREM_7.extract_message.visible = false
	grabbed_object.linear_velocity /= 2
	grabbed_object.collision_layer = 3
	grabbed_object.collision_mask = 3
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
				for child in grabbed_object.object_body.get_children():
					child.set_material_overlay(grabbed_object.standard_material)
				exposure_tween(player_character.camera, 0.9, 0.1)
				flicker_obj_a = null
			else:
				if player_character.extracting_object_active:
					exposure_tween(player_character.camera, 0.5, 0.1)

		if event.keycode == KEY_ESCAPE and not event.is_echo():
			get_tree().quit()

		if event.keycode == KEY_SHIFT:
			if event.is_pressed():
				movement_speed = 2
			else:
				movement_speed = 1

		if event.keycode == KEY_C:
			if not event.pressed:
				if player_character.camera.is_current():
					player_character.is_using_computer = true
					#player_character.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
					#player_character.camera.make_current()
					

				else:
					player_character.is_using_computer = false
					player_character.camera.make_current()

var cam_tween: Tween

func camera_tween(cam: Camera3D, fov: float, dur: float):
	
	cam_tween = create_tween()
	
	cam_tween.tween_property(cam, "fov", fov, dur)
	#cam_tween.tween_property(cam, "rotation_degrees", new_rot, duration)
	#cam_tween.tween_property(cam, "projection", new_proj, duration)
	
	cam_tween.set_trans(Tween.TRANS_LINEAR)
	cam_tween.set_ease(Tween.EASE_IN_OUT)

var exp_tween: Tween

func exposure_tween(cam: Camera3D, exp: float, dur: float):
	
	exp_tween = create_tween()
	
	exp_tween.tween_property(cam, "attributes:exposure_multiplier", exp, dur)
	exp_tween.set_trans(Tween.TRANS_LINEAR)
	exp_tween.set_ease(Tween.EASE_IN_OUT)



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
		if flicker_obj_b and flicker_obj_c:
			if grabbed_object.is_extracting:
				grabbed_object.set_glitch(false)
			if flicker_obj_a:
				flicker_obj_a.visible = true
			flicker_obj_b.visible = true
			flicker_obj_c.visible = true
		await get_tree().create_timer(duration).timeout

		if not static_glow_active:
			break
		if flicker_obj_b and flicker_obj_c:
			if grabbed_object.is_extracting:
				grabbed_object.set_glitch(true)
			if flicker_obj_a:
				flicker_obj_a.visible = false
			flicker_obj_b.visible = false
			flicker_obj_c.visible = false
		await get_tree().create_timer(duration).timeout

	if flicker_obj_b and flicker_obj_c:
		if grabbed_object.is_extracting:
			grabbed_object.set_glitch(false)
		if flicker_obj_a:
			flicker_obj_a.visible = true
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
