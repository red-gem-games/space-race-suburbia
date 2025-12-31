extends CharacterBody3D
class_name character

const is_character: bool = true
var start_day: bool = false

var is_clickable: bool = true

var object_data = {}
var component_data_file = "res://Components/component_data.json"
var current_component_index := 0
var current_extraction_data = []  # Will hold the JSON components array
var current_object_json: Dictionary = {}

var COMPONENT_SCRIPT: Script = preload("res://Components/components.gd")

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera: Camera3D = $Camera3D
@onready var PREM_7: Node3D = $"Camera3D/PREM-7"
@onready var HUD: Control = $HUD
@onready var char_obj_shape: CollisionShape3D

@onready var grabbed_container: Node3D = $Camera3D/Grabbed_Container
var object_position: Vector3

var manipulate_ORANGE: Color = Color(1, 0.33, 0)
var manipulate_GREEN: Color = Color(0, 1, 0)
var manipulate_BLUE: Color = Color(0, 0, 1)

var colliding_with_assembly_object: bool = false
var assembly_object_mass: float
var player_moving_forward: bool = false

var assembly_component_selection: bool = false

# Moving to physics process
var desired_direction := Vector3.ZERO
var desired_velocity := Vector3.ZERO

var glow_color: Color
var glow_opacity: float

var distance_from_character: float = 7.0
var previous_height: float
var rotate_tween: Tween

var base_rotation_sensitivity: float = 0.1
var rotation_sensitivity: float = base_rotation_sensitivity

var move_input = {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}

var new_glow_color: Color
var touched_object
var object_is_grabbed: bool = false
var initial_grab: bool = false
var grabbed_object: RigidBody3D = null
var grabbed_mesh: MeshInstance3D = null
var grabbed_collision: CollisionShape3D = null
var grabbed_initial_position: Vector3
var grabbed_initial_mouse: Vector2
var grab_offset_factor: float = 0.01  # Adjust as needed.
var grabbed_distance: float = 0.0
var grabbed_rotation: Vector3
var grabbed_initial_rotation: Vector3 = Vector3.ZERO
var grabbed_global_rotation: Vector3
var grabbed_target_position: Vector3

var grab_timer: Timer = Timer.new()
var control_timer: Timer = Timer.new()
var controlled_object: RigidBody3D

var action_wait_timer: Timer = Timer.new()

var floor_y: float = -1.5     # The floor level (adjust as needed)
var max_y: float = 30.0       # The maximum Y allowed (adjust as needed)
var base_pitch_factor: float = 3
#var pitch_factor: float = base_pitch_factor # How much camera pitch affects the Y offset

var prem7_decay_speed: float = 5.0     # Speed at which the rotation offset decays.
var mouse_speed_threshold: float = 2.0    # Mouse relative motion threshold below which decay occurs.
var last_mouse_speed: float = 0.0         # Latest mouse movement magnitude.
var last_mouse_time: float = 0.0          # Timestamp of the last mouse motion event.

var smoothed_mouse_vel_x := 0.0
var smoothed_mouse_vel_y := 0.0

var grabbed_x_rotation: float
var grabbed_y_rotation: float
var grabbed_z_rotation: float
var z_rotate_mode: bool = false

var grabbed_vertical_offset: float = 0.0

# Mouse button states
var left_mouse_down: bool = false
var right_mouse_down: bool = false
var middle_mouse_down: bool = false

const MODE_1: String = "SHIFT"
const MODE_2: String = "SUSPEND"
const MODE_3: String = "EXTRACT"
const MODE_4: String = "FUSE"
const MODE_1_COLOR: Color = Color.GREEN
const MODE_2_COLOR: Color = Color.BLUE
const MODE_3_COLOR: Color = Color.RED
const MODE_4_COLOR: Color = Color.WEB_PURPLE
var modes = [MODE_1, MODE_2, MODE_3, MODE_4]
var current_mode: String = MODE_1
var pending_mode: String = ""  # Holds the pending mode change

var pending_mode_key: int = 0  # Will store the keycode of the mode key that triggered pending_mode
var shifting_object_active: bool = false
var extracting_object_active: bool = false
var suspending_object_active: bool = false
var fusing_object_active: bool = false
var inspecting_object_active: bool = false

var extraction_recently_completed: bool = false

var pitch: float = 0.0
var pitch_set: bool = false
var base_pitch_min: float = -PI/2
var base_pitch_max: float = PI/2
var grab_pitch_min: float = -0.25
var grab_pitch_max: float = 0.9
var pitch_min: float = base_pitch_min
var pitch_max: float = base_pitch_max
var base_mouse_speed: float = 0.002
var mouse_speed: float = base_mouse_speed
var smoothing: float = 0.15
var current_mouse_speed_x: float
var current_mouse_speed_y: float

var target_pitch_min: float
var pitch_min_lerp_speed: float = 5.0  # Higher = faster adjustment
var grounded_grabbed_pitch_min: float = deg_to_rad(-10.0)  # Limit downward look when grounded with object

var is_touching_stepladder: bool = false

# Variables for camera rotation
var desired_yaw: float = 0.0
var desired_pitch: float = 0.0

var extracting_yaw: float = 0.0

var yaw: float = 0.0
var distance_factor: float = 5.0
var height_factor: float = 0.0
var last_y: float = 0.0
var change_rate: float = 0.05  # Adjust this value to control sensitivity
var fall_speed_factor: float = 0.0
var fall_sensitivity: float = 0.01  # You can tweak this to make pitch change more or less based on falling speed
var distance_to_ground: float

var object_sway_offset: Vector2 = Vector2.ZERO
var object_sway_decay_x: float = 10.0
var object_sway_decay_y: float = 10.0
var object_sway_base_x: float = 0.00025
var object_sway_base_y: float = 0.0004
var object_sway_strength_x: float = object_sway_base_x
var object_sway_strength_y: float = object_sway_base_y

# Variables for player movement
var base_movement_speed: float = 14.0
var movement_speed: float = base_movement_speed
var current_velocity: Vector3 = Vector3.ZERO

# Variables for PREM-7 rotation while shifting
var prem7_original_rotation: Vector3
var prem7_rotation_offset: Vector3 = Vector3.ZERO
var prem7_rotation_speed: float = 0.0001  # Adjust this to slow or speed up PREM-7's rotation while shifting.
 
var grounded: bool = false  
var airborne: bool = false
var jetpack_active: bool = false
var vertical_velocity: float = 0.0
var gravity_strength: float = 10.0
var current_jetpack_thrust: float = 0.0
var current_jetpack_accel: float = 0.0
var min_thrust_threshold: float = 0.2

# Max values you can tweak
var jetpack_thrust_max: float = 5.0
var jetpack_accel_max: float = 2.0
var thrust_ramp_up_speed: float = 2.5
var thrust_ramp_down_speed: float = 2.5
var hover_threshold: float = 0.2  # How close to the ground before hover softens descent
var hover_lock: bool = false
var hover_base_y: float = 0.0
var hover_bob_time: float = 0.0
# Ceiling soft clamp logic
var ceiling_buffer: float = 2.0
var ceiling_threshold: float = max_y - ceiling_buffer
var touching_ceiling: bool = false

var last_position := Vector3.ZERO
var speed_vector := Vector3.ZERO

var bounce_cooldown: float = 0.0
var bounce_decay: float = 0.1

var scroll_cooldown := 0.0
var scroll_cooldown_duration := 0.15  # Adjust to taste (0.1–0.2 is typical)

var scale_tween: Tween

var horizontal_delta
var vertical_delta
var h_sway_multiplier: float
var v_sway_multiplier: float
var shift_it: bool = false

var previous_delta: float= 0.0
var screen_resolution_set: bool = false
var screen_res_sway_multiplier: float = 1.0
var delta_threshold: float = 0.001  # sensitivity to delta changes
var previous_camera_pitch: float = 0.0  # Declare this once somewhere globally (in the class)
var beam_lock: bool = false
###force_look_at_object is now beam_lock###
var current_yaw
var current_pitch

var oscillating_1: float
var oscillating_2: float
var oscillating_3: float

var orbit_radius: float = 7.0
var target_orbit_radius: float = orbit_radius
var orbit_angle: float = 0.0  # Radians
var orbit_speed: float = 1.0  # Speed multiplier
var input_direction_x: float = 0.0
var input_direction_z: float = 0.0
var grabbed_pos_set: bool = false



var true_scale: Vector3
var extraction_scale: float
var extraction_started: bool = false
var comp_scale_x
var comp_scale_y
var comp_scale_z
var reform: bool
var alpha_x = 1.0
var extract_alpha = 0.25
var extract_edge = 1.5
var base_extract_time = 2.0
var extract_time = base_extract_time
var base_extract_speed = 0.0025
var extract_speed = base_extract_speed
var selected_component_mesh: MeshInstance3D
var selected_component_col: CollisionShape3D
var selected_component_pos: Vector3
var selected_component_scale: float
var selected_component_glow: float
var selected_component_mass: float
var selected_component_rot: Vector3
var fresh_component: RigidBody3D
var fresh_component_scale: Vector3
var f_comp: RigidBody3D
var new_component: RigidBody3D
var storing_component: bool = false
var extraction_finalized: bool = false

var active_rocket: RigidBody3D
var under_the_hood: bool = false

@onready var extracted_component_sound = $SoundFX/extracted_component

var is_using_computer: bool = false

var storage_shed: Node3D


func _ready() -> void:
	push_warning('General To Do List:')
	push_warning('------ ALWAYS MAKE SURE THINGS WORK ON BOTH SCREENS ------')
	push_warning('SUSPEND Changes')
	push_warning('EXTRACT Changes')
	push_warning('KEY_R: Reset Values (Which Ones?)')
	
	
	
	add_child(grab_timer)
	grab_timer.one_shot = true
	add_child(control_timer)
	control_timer.one_shot = true
	add_child(action_wait_timer)
	action_wait_timer.one_shot = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	prem7_original_rotation = PREM_7.rotation
	object_data = load_json_file(component_data_file)

func _physics_process(delta: float) -> void:
	
	if extraction_started:
		HUD.extract_time_remaining = extract_time

	# Update ground distance
	distance_to_ground = raycast_to_ground()

	# Handle basic directional input
	var vertical = 0
	var horizontal = 0

	if not extracting_object_active:
		if move_input["up"] and not move_input["down"]:
			if not shifting_object_active:
				vertical = lerp(vertical, 1, delta)
				prem7_rotation_offset.x -= 0.0025
		elif move_input["down"] and not move_input["up"]:
			if not shifting_object_active:
				vertical = lerp(vertical, -1, delta)
				prem7_rotation_offset.x += 0.0025
		if move_input["right"] and not move_input["left"]:
			if not shifting_object_active:
				horizontal = lerp(horizontal, 1, delta)
				prem7_rotation_offset.y += 0.0025
		elif move_input["left"] and not move_input["right"]:
			if not shifting_object_active:
				horizontal = lerp(horizontal, -1, delta)
				prem7_rotation_offset.y -= 0.0025

	#if grabbed_object:
		#if not grabbed_object.is_suspended:
			#if vertical > 0:
				#distance_from_character = lerp(distance_from_character, 5.0, delta * 2.5)  # Closer
			#elif vertical < 0:
				#distance_from_character = lerp(distance_from_character, 10.0, delta * 2.5)  # Further
			#else:
				#distance_from_character = lerp(distance_from_character, 7.0, delta * 2.0)  # Neutral
			## Apply horizontal sway when strafing
			#if horizontal != 0:
				#var camera_right = camera.global_transform.basis.x.normalized()
				#object_sway_offset.x -= horizontal * 1.75 * screen_res_sway_multiplier

	desired_direction = Vector3.ZERO
	if vertical != 0 or horizontal != 0:
		desired_direction = ((-transform.basis.z) * vertical + (transform.basis.x) * horizontal).normalized()

	desired_velocity = desired_direction * movement_speed
	current_velocity = lerp(current_velocity, desired_velocity, smoothing)

	velocity.x = lerp(velocity.x, current_velocity.x, delta * 5)
	velocity.z = lerp(velocity.z, current_velocity.z, delta * 5)
	velocity.y = lerp(velocity.y, vertical_velocity, delta * 5)


	# Landing check
	if position.y < 2 and not grounded:
		vertical_velocity = 0.0
		airborne = false
		grounded = true
	elif position.y > 2 and jetpack_active:
		grounded = false
		airborne = true


	# Grabbed object physics update
	#update_grabbed_object_physics(delta)
	if not extracting_object_active:
		move_and_slide()
	
	#print(velocity)
	#
	#for i in range(get_slide_collision_count()):
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#
		#if collider is RigidBody3D and not collider.is_grabbed:
			#var push_force = 1000 - collider.mass
			#var direction = collision.get_normal()
			#var impulse = direction * push_force
			#print(impulse)
			#collider.apply_force(impulse, collision.get_position())
	
	handle_pitch_and_yaw()
	
	# Update jetpack thrust, hover, ceiling logic
	handle_jetpack_logic(delta)

	# Handle grounded/airborne vertical velocity
	update_vertical_velocity()

func _process(delta: float) -> void:
	
	if walls_are_moving:
		rocket_wall_check(delta)
	
	if under_the_hood and touched_walls.is_empty():
		under_the_hood = false

	
	if reform and not extraction_finalized:
		var t =+ 1
		print(t)
	
	#print(control_timer.time_left)
	
	#if fresh_component:
		#print(fresh_component.name)

	if storing_component:
		reform = true
		extraction_recently_completed = false
		storing_component = false
		complete_extraction(fresh_component, selected_component_mesh)

	if reform:
		for child in fresh_component.get_children():
			if child is MeshInstance3D:
				reform_component(child, delta, fresh_component)
				fresh_component.scale_object(child, comp_scale_x, comp_scale_y, comp_scale_z, 0.0, 1.0)
		

	if grabbed_object:
		if extracting_object_active:
			var x = comp_scale_x
			var y = comp_scale_y
			var z = comp_scale_z
			var s = selected_component_scale
			grabbed_object.manipulation_material.set_shader_parameter("albedo_alpha", extract_alpha)
			grabbed_object.manipulation_material.set_shader_parameter("edge_intensity", extract_edge)
			grabbed_object.manipulation_material.set_shader_parameter("alpha_multiplier", alpha_x)
			
			if extraction_started:
				if extract_time >= 0.002:
					extract_alpha -= delta / 1.1
					extract_edge -= delta * 2.25
					extract_time -= delta
				grabbed_object.EXTRACT_MATERIAL.albedo_color = lerp(grabbed_object.EXTRACT_MATERIAL.albedo_color, Color.DARK_ORANGE, delta)
				grabbed_object.EXTRACT_MATERIAL.emission = lerp(grabbed_object.EXTRACT_MATERIAL.emission, Color.WHITE, delta)
				grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier = lerp(grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier, 16.0, delta * 7.5)
				if control_timer.is_stopped() == false:
					var t_left_ratio = control_timer.time_left / control_timer.wait_time
					var progress = 1.0 - t_left_ratio
					var high_extract_speed = 1.25
					extract_speed = lerp(extract_speed, high_extract_speed, progress * delta * 1.25)
				if control_timer.time_left < 2.0:
					PREM_7.holo_anim.speed_scale = 0.125
					PREM_7.holo_anim.play("retract_hologram")
				if control_timer.time_left < 2.0 and control_timer.time_left > 1.0:
					alpha_x = lerp(alpha_x, 0.0, delta * 4.0)
					selected_component_mesh.position = lerp(selected_component_mesh.position, Vector3.ZERO, delta * 2.5)
					selected_component_mesh.scale = lerp(selected_component_mesh.scale, Vector3(x*s, y*s, z*s), delta * 2.5)
				if control_timer.time_left < 1.0:
					selected_component_mesh.position = lerp(selected_component_mesh.position, Vector3(0.0, -5.0, 0.0), delta * 1.5)
					selected_component_mesh.scale = lerp(selected_component_mesh.scale, Vector3(0.0, 0.0, 0.0), delta * 6.0)
				if control_timer.time_left == 0.0:
					if control_timer.is_stopped():
						extract_component(selected_component_mesh, selected_component_col)
						setup_component()
						HUD.complete_extraction()
						storing_component = true
						scroll_component_data('DOWN')
						extraction_started = false
					control_timer.start(1.0)
				



			else:
				if not selected_component_mesh:
					return
				extract_speed = lerp(extract_speed, base_extract_speed, delta * 7.5)
				grabbed_object.EXTRACT_MATERIAL.emission = lerp(grabbed_object.EXTRACT_MATERIAL.emission, Color.ORANGE_RED, delta * 7.5)
				grabbed_object.EXTRACT_MATERIAL.albedo_color = lerp(grabbed_object.EXTRACT_MATERIAL.albedo_color, Color.RED, delta * 7.5)
				grabbed_object.EXTRACT_MATERIAL.albedo_color.a = 0.9
				grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier = lerp(grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier, selected_component_glow * 2.5, delta * 7.5)
				selected_component_mesh.position = lerp(selected_component_mesh.position, selected_component_pos, delta * 7.5)
				selected_component_mesh.scale = lerp(selected_component_mesh.scale, Vector3(x, y, z), delta * 7.5)
				extract_alpha = lerp(extract_alpha, 0.25, delta * 7.5)
				extract_edge = lerp(extract_edge, 1.25, delta * 7.5)
				extract_time = lerp(extract_time, base_extract_time, delta * 7.5)
				alpha_x = lerp(alpha_x, 1.0, delta * 7.5)
				if alpha_x < 0.75:
					PREM_7.holo_anim.speed_scale = 1.0


	handle_prem7_decay(delta)

	if abs(delta - previous_delta) > delta_threshold:
		screen_res_sway_multiplier = 55.0 * delta
		previous_delta = delta
		screen_resolution_set = true

	PREM_7.rotation = PREM_7.rotation.lerp(prem7_original_rotation, prem7_decay_speed * delta)
	
	update_reticle_targeting()
	
	if scroll_cooldown > 0.0:
		scroll_cooldown -= delta



	if grabbed_object:
		if shifting_object_active or extracting_object_active or fusing_object_active:
			camera.fov = lerp(camera.fov, 55.0, delta * 10.0)
			if not PREM_7.handling_object:
				PREM_7.handle_object()
				if extracting_object_active:
					#HUD.set_highlight_color(manipulate_ORANGE, 0.5)
					grabbed_object.extract_active = true
				elif fusing_object_active:
					#HUD.set_highlight_color(manipulate_BLUE, 0.7)
					grabbed_object.fuse_active = true
				#HUD.control_color.visible = true
		else:
			camera.fov = lerp(camera.fov, 75.0, delta * 10)
			if PREM_7.handling_object:
				grabbed_object.extract_active = false
				grabbed_object.fuse_active = false
				PREM_7.release_handle()
		#grabbed_object.rotation_degrees = grabbed_rotation
		#var z_offset = abs((grabbed_object.position.z - 3.0) / 10.0)
		#if grabbed_object.is_suspended:
			#if char_obj_shape:
				#print("Clearing Char Obj Shape: ", char_obj_shape)
				#clear_char_obj_shape()
			#grabbed_object.gravity_scale = 0.0
			#grabbed_object.position = grabbed_object.position.lerp(grabbed_target_position, delta * 0.5)
			#return

		#if not shifting_object_active:
			#if z_offset >= 0.95 and z_offset <= 1.05:
				#grabbed_pos_set = true
			#if not grabbed_pos_set:
				#prem7_rotation_offset.y = lerp(prem7_rotation_offset.y, -grabbed_object.position.x / 4.5 / (z_offset * 1.25), delta * 25.0)
				#prem7_rotation_offset.x = lerp(prem7_rotation_offset.x, grabbed_object.position.y / 6.0 / z_offset, delta * 25.0)
			#elif grabbed_pos_set:
				#prem7_rotation_offset.y = lerp(prem7_rotation_offset.y, -grabbed_object.position.x / 4.5 / (z_offset * 1.25), delta * 50.0)
				#prem7_rotation_offset.x = lerp(prem7_rotation_offset.x, grabbed_object.position.y / 6.0 / z_offset, delta * 50.0)
			#object_sway_offset.x -= lerp(object_sway_offset.x, current_mouse_speed_x * object_sway_strength_x, 1.0)
			#object_sway_offset.y -= lerp(object_sway_offset.y, current_mouse_speed_y * object_sway_strength_y, 1.0)
			#object_sway_offset.x = clamp(object_sway_offset.x, -1.0, 1.0) 
			#object_sway_offset.y = clamp(object_sway_offset.y, -2.0, 2.0)
			#update_grabbed_object_sway(delta)

		#if grabbed_object.is_being_extracted:
			#handle_object('released')
	#if extracting_object_active:
		#desired_pitch = clamp(desired_pitch, 0.0, 0.35)
		#if assembly_component_selection:
			#var yaw_range = deg_to_rad(30.0)
			#desired_yaw = clamp(desired_yaw, extracting_yaw - yaw_range, extracting_yaw + yaw_range)
		#else:
			#desired_yaw = extracting_yaw
	if not grabbed_object and camera.fov < 74.9:
		camera.fov = lerp(camera.fov, 75.0, delta * 10)
		PREM_7.release_handle()
		
		print('is something happening')

##--------------------------------------##
##------------INPUT RESPONSE------------##
##--------------------------------------##
func _on_action_key(status: String):
	if action_wait_timer.time_left > 0.0:
		return
	if status == "down":
		if extracting_object_active:
			control_timer.start(extract_time)
			PREM_7.ctrl_anim.play("activate")
			HUD.catalog_extraction_phase = "idle"
			HUD.extraction_complete = false
			HUD.extraction_started = true
			HUD.start_extraction(extract_time)
			extraction_started = true
	if status == "up":
		if extraction_started:
			PREM_7.ctrl_anim.play_backwards("activate")
			PREM_7.holo_anim.play_backwards("retract_hologram")
			control_timer.stop()
			HUD.extraction_started = false
			HUD.cancel_extraction()
			extraction_started = false
			

func _on_extract_key() -> void:
	if action_wait_timer.time_left > 0.0:
		return
	if extract_time < 1.9:
		return
	else:
		PREM_7.holo_anim.speed_scale = 1.0
	if fusing_object_active:
		return
	if grabbed_object.is_stepladder or grabbed_object.is_rocketship:
		return
	if grabbed_object.is_component:
		print('Add warning here:')
		print("Ah, Ah, Ah. Can't extract a component any further!")
		return

	action_wait_timer.start(0.5)
	desired_pitch = 0.0
	desired_yaw = grabbed_object.rotation.y
	#print(yaw + grabbed_object.rotation.y)
	#print(desired_yaw)
	
	extracting_object_active =! extracting_object_active
		
	if extracting_object_active:
		camera.attributes.dof_blur_near_enabled = true
		if PREM_7.extract_message.visible:
			PREM_7.extract_message.visible = false
		for child in grabbed_object.get_children():
			if child is CollisionShape3D:
				child.disabled = true
		PREM_7.ctrl_anim.play("extract")
		PREM_7.holo_anim.play("cast_hologram")
		grabbed_object.is_extracting = true
		#PREM_7.dashboard.scale = Vector3(1.0, 1.0, 1.0)
		PREM_7.dashboard.visible = true
		grabbed_object.extract_active = true
		#module = PREM_7.component_module.get_parent()
		#power = PREM_7.component_power.get_parent()
		#mass = PREM_7.component_mass.get_parent()
		#lift = PREM_7.component_lift.get_parent()
		grabbed_object.manipulation_mode('Active')
		var count = current_extraction_data.size()
		for i in range(count):
			scroll_component_data('DOWN')
		right_mouse_down = false
		handle_object('pressed')
		#grabbed_target_position.x -= 10
	else:
		camera.attributes.dof_blur_near_enabled = false
		for child in grabbed_object.get_children():
			if child is CollisionShape3D:
				child.disabled = false
		if selected_component_mesh:
			selected_component_mesh.scale.x = comp_scale_x
			selected_component_mesh.scale.y = comp_scale_y
			selected_component_mesh.scale.z = comp_scale_z
			selected_component_mesh.position = selected_component_pos
		PREM_7.ctrl_anim.play_backwards("extract")
		PREM_7.holo_anim.play_backwards("cast_hologram")
		gravity_strength = 10.0
		grabbed_object.visible = true
		grabbed_object.extract_active = false
		grabbed_object.is_extracting = false
		grabbed_object.extract_in_motion = false
		extraction_started = false
		control_timer.stop()
		handle_object('released')
		#right_mouse_down = false
		print('Stop Extracting')

func _on_reset_key() -> void:
	print('RESETTING')
	if grabbed_object:
		reset_object_position()
	else:
		pitch_min = base_pitch_min
		pitch_max = base_pitch_max


func _input(event: InputEvent) -> void:
	if is_using_computer:
		return
	if event is InputEventMouseButton:
		if left_mouse_down and event.button_index == MOUSE_BUTTON_RIGHT:
			return
		if right_mouse_down and event.button_index == MOUSE_BUTTON_LEFT:
			return
		if not is_clickable:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if not middle_mouse_down and not right_mouse_down:
				if event.is_pressed():
					left_mouse_down = true
					PREM_7.trig_anim.play("trigger_pull")
					#grab_object()
				else:
					left_mouse_down = false
					PREM_7.trig_anim.play("trigger_release")
					PREM_7.trig_anim.play("RESET")

		elif event.button_index == MOUSE_BUTTON_RIGHT and grabbed_object:
			print('This will be used somewhere else down the line...')
			#if not middle_mouse_down and not left_mouse_down:
				#if event.is_pressed():
					#handle_object('pressed')
				#else:
					#handle_object('released')

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if not middle_mouse_down and not right_mouse_down and not left_mouse_down:
				if extracting_object_active:
					# Check cooldown before allowing scroll
					if scroll_cooldown <= 0:
						scroll_component_data('UP')
						scroll_cooldown = scroll_cooldown_duration  # Start cooldown
					return
				print('Still need to figure out INSPECT, Cycling Stored Components, etc.')

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if not middle_mouse_down and not right_mouse_down and not left_mouse_down:
				if extracting_object_active:
					# Check cooldown before allowing scroll
					if scroll_cooldown <= 0:
						scroll_component_data('DOWN')
						scroll_cooldown = scroll_cooldown_duration  # Start cooldown
					return
				print('Still need to figure out INSPECT, Cycling Stored Components, etc.')


		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if not right_mouse_down and not left_mouse_down:
				if event.is_pressed():
					middle_mouse_down = true
					PREM_7.ctrl_anim.play("RESET")
					PREM_7.ctrl_anim.play("inspect")
					print("Object is being inspected!")
					print('Add hologram tablet above PREM-7 that shoots out of top opening')
					print('THEN, allow player to scroll through different inspection menus for object by scrolling with wheel')
					inspecting_object_active = true
				if not event.is_pressed():
					middle_mouse_down = false
					PREM_7.ctrl_anim.play("RESET")
					PREM_7.ctrl_anim.play("control_up")
					print("Object is no longer being inspected!")
					inspecting_object_active = false

	# Process Mouse Motion events.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		current_mouse_speed_x = event.relative.x
		current_mouse_speed_y = event.relative.y

		if not extracting_object_active:
			var max_delta: float = 0.15 * screen_res_sway_multiplier
			var dx = clamp(event.relative.x * mouse_speed, -max_delta, max_delta)
			var dy = clamp(event.relative.y * mouse_speed, -max_delta, max_delta)
			desired_yaw -= dx
			desired_yaw = wrapf(desired_yaw, -PI, PI)
			desired_pitch -= dy
			desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)

	# Process Keyboard events.
	if event is InputEventKey and not event.is_echo():
		var pressed = event.is_pressed()

		if event.keycode == KEY_E and pressed:
			if grabbed_object:
				_on_extract_key()
		if event.keycode == KEY_R and pressed:
			desired_pitch = 0
			_on_reset_key()
		
		if event.keycode == KEY_Q:
			if pressed:
				_on_action_key('down')
			if not pressed:
				_on_action_key('up')

		if event.keycode == KEY_F:
			if not grabbed_object or extracting_object_active:
				return
			if event.pressed:
				fusing_object_active =! fusing_object_active
				if fusing_object_active:
					fuse_mode_active()
					#suspending_object_active = true
					beam_lock = false
					#grabbed_object.set_outline('FUSE', glow_color, 0.0)
					
					#grabbed_object.is_suspended =! grabbed_object.is_suspended
					#grabbed_object.object_rotation = grabbed_object.rotation_degrees
					#grab_object()
				else:
					print('Stop Fusing')
					#grabbed_object.set_outline('GRAB', glow_color, glow_opacity)
					_on_reset_key()

		if event.keycode == KEY_QUOTELEFT and pressed and not event.is_echo():
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		# Update movement key states.
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			move_input["up"] = pressed
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			move_input["down"] = pressed
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			move_input["left"] = pressed
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			move_input["right"] = pressed

		if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
			print('Need to use these to bring up components in specific slots, returning for now')
			return
			if not right_mouse_down and not left_mouse_down and not middle_mouse_down:
				if pressed and not event.is_echo():
					if pending_mode != "" and event.keycode != pending_mode_key:
						return
					if pending_mode == "":
						var new_mode = ""
						match event.keycode:
							KEY_1:
								new_mode = MODE_1
							KEY_2:
								new_mode = MODE_2
							KEY_3:
								new_mode = MODE_3
							KEY_4:
								new_mode = MODE_4
						if new_mode == current_mode:
							print("Already in mode: " + new_mode)
							return
						PREM_7.ctrl_anim.play("RESET")
						PREM_7.ctrl_anim.play("shift_mode_down")
						pending_mode = new_mode
						pending_mode_key = event.keycode
				elif not pressed:
					if pending_mode != "" and event.keycode == pending_mode_key:
						PREM_7.ctrl_anim.play("RESET")
						PREM_7.ctrl_anim.play("shift_mode_up")
						change_mode(pending_mode)
						pending_mode = ""
						pending_mode_key = 0

		# Process SPACE for jetpack functionality.
		# When SPACE is pressed, enable upward thrust.
		if event.keycode == KEY_SPACE:
			hover_lock = false
			if not airborne:
				pitch_set = false
			if pressed and not assembly_component_selection:
				jetpack_active = true
			else:
				current_jetpack_thrust = lerp(current_jetpack_accel, 0.0, 1.0)
				jetpack_active = false
		if event.keycode == KEY_ALT:
			if airborne:
				if pressed:
					hover_lock =! hover_lock
					print('Jetpack & Hover need to be unlocked later in game...')
					hover_base_y = global_position.y
					hover_bob_time = 0.0
		if event.keycode == KEY_SHIFT:
			if pressed:
				movement_speed = base_movement_speed * 1.5
				rotation_sensitivity = base_rotation_sensitivity * 2
				jetpack_accel_max = jetpack_accel_max * 2
				jetpack_thrust_max = jetpack_thrust_max * 2
				current_jetpack_accel = current_jetpack_accel * 2
				current_jetpack_thrust = current_jetpack_thrust * 2
			else:
				movement_speed = base_movement_speed
				rotation_sensitivity = base_rotation_sensitivity
				jetpack_accel_max = jetpack_accel_max / 2
				jetpack_thrust_max = jetpack_thrust_max / 2
				current_jetpack_accel = current_jetpack_accel / 2
				current_jetpack_thrust = current_jetpack_thrust / 2

		if event.keycode == KEY_CTRL:
			pass


		if event.keycode == KEY_Z:
			if pressed:
				if shifting_object_active:
					z_rotate_mode = true
			else:
				z_rotate_mode = false



##---------------------------------------##
##------------GAME MECHANICS-------------##
##---------------------------------------##


func grab_object():
	if distance_to_ground > 2.97:
		print('why would this work?')
		for child in get_children():
			if child is CollisionShape3D:
				child.disabled = true
				if is_touching_stepladder:
					child.disabled = false
	grabbed_object.extract_body = grabbed_object.object_body.duplicate()
	grabbed_object.extract_body.position = Vector3(0.0, -0.25, 0.0)
	grabbed_object.extract_body.scale = Vector3.ZERO
	PREM_7.control_position.add_child(grabbed_object.extract_body)
	print('Grab')
	extracting_object_active = false
	fusing_object_active = false
	HUD.reticle.visible = false
	var mouse_mass = 5
	mouse_speed = base_mouse_speed / mouse_mass
	pitch_max = grab_pitch_max
	object_is_grabbed = true
	grabbed_object.linear_damp = 0
	grabbed_initial_rotation = rotation_degrees
	action_wait_timer.start(0.5)
	await get_tree().create_timer(0.5).timeout
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false

func release_object():
	var children = grabbed_object.get_children()
	for child in children:
		if child is CollisionShape3D:
			child.disabled = false
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
	grabbed_object.object_body.scale = grabbed_object.current_scale
	PREM_7.dashboard.scale = Vector3.ZERO
	PREM_7.dashboard.visible = false
	PREM_7.control_position.remove_child(grabbed_object.extract_body)
	grabbed_object.extract_body = null
	if touched_object:
		touched_object.is_touched = false
		touched_object = null
	print('Release')
	#beam.object_is_grabbed = false
	orbit_radius = target_orbit_radius
	PREM_7.retract_beam()
	grabbed_pos_set = false
	initial_grab = false
	pitch_max = base_pitch_max
	HUD.reticle.visible = true
	grabbed_object.recently_grabbed = true
	grabbed_object.is_released = true
	if grabbed_object.is_suspended:
		grabbed_object.gravity_scale = 0.0
	suspending_object_active = false
	mouse_speed = base_mouse_speed
	object_is_grabbed = false
	grabbed_object = null

func handle_object(status):
	if status == 'pressed':
		PREM_7.trig_anim.play("RESET")
		PREM_7.trig_anim.play("trigger_pull")
		collision_layer = 1

	if status == 'released':
		PREM_7.trig_anim.play("trigger_release")
		PREM_7.trig_anim.play("RESET")
		collision_layer = 1
		right_mouse_down = false
		_on_reset_key()

func fuse_mode_active():
	if grabbed_object.is_component:
		print('  ')
		print("***************")
		print(" ")
		print("Disable the component's collision layer, turn object into manipulation mode but remain in front of player. This is how we will be able to fuse inside of the rocket as it pulls apart (and as the component turns GREEN to signify it can be attached in that spot).")
		print(" ")
		print("***************")
		print('  ')
	else:
		print('  ')
		print("Message Example: ")
		print('  ')
		print("***THIS ITEM CANNOT BE FUSED***")
		print("'Are you trying to wash your clothes in space?'")

func handle_pitch_and_yaw():
	if grabbed_object:
		var y = position.y
		var min_y = 2.0
		max_y = 10.0

		# Calculate blend factor (0 near ground, 1 when high in air)
		var t = clamp((y - min_y) / (max_y - min_y), 0.0, 1.0)
		t = smoothstep(min_y, max_y, y)

		# Interpolate between restricted and full downward pitch
		var clamped_pitch_min = deg_to_rad(-25)
		pitch_min = lerp(clamped_pitch_min, base_pitch_min + 0.25, t)
	else:
		pitch_min = base_pitch_min

	desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
	var angle_diff = desired_yaw - yaw
	angle_diff = wrapf(angle_diff + PI, 0, TAU) - PI
	yaw += angle_diff * smoothing
	yaw = wrapf(yaw, -PI, PI)
	pitch = lerp(pitch, desired_pitch, smoothing)
	
	rotation.y = yaw
	camera.rotation.x = pitch


func handle_jetpack(status, timing):
	# Jetpack Ceiling Clamp
	if position.y >= max_y:
		position.y = max_y
		if vertical_velocity > 0:
			vertical_velocity = 0.0

	elif position.y > ceiling_threshold and vertical_velocity > 0:
		var closeness: float = (position.y - ceiling_threshold) / ceiling_buffer
		var damp_factor: float = clamp(closeness * 0.5, 0.0, 1.0)
		var damp_strength: float = 1.0 - pow(damp_factor, 2)
		vertical_velocity *= damp_strength

	if status == '1':
		current_jetpack_thrust = lerp(current_jetpack_thrust, jetpack_thrust_max, thrust_ramp_up_speed * timing)
		current_jetpack_accel = lerp(current_jetpack_accel, jetpack_accel_max, thrust_ramp_up_speed * timing)
	elif status == '2':
		current_jetpack_thrust = lerp(current_jetpack_thrust, 0.0, thrust_ramp_down_speed * timing)
		current_jetpack_accel = lerp(current_jetpack_accel, 0.0, thrust_ramp_down_speed * timing)
	elif status == '3':
		vertical_velocity = lerp(vertical_velocity, current_jetpack_thrust, current_jetpack_accel * timing)
	elif status == '4':
		vertical_velocity *= pow(0.55, timing * 4.0)
	elif status == '5':
		var hover_gravity = -gravity_strength * (distance_to_ground / 25.0)
		vertical_velocity = lerp(vertical_velocity, hover_gravity, 3.0 * timing)
	elif status == '6':
		vertical_velocity = lerp(vertical_velocity, -gravity_strength, 1.0 * timing)
	elif status == '7':
		hover_bob_time += timing  # use delta to advance time
		var bob_strength = 0.25    # Amplitude (how far up/down)
		var bob_speed = 1.0      # Frequency (how fast)
		var bob_offset = sin(hover_bob_time * bob_speed) * bob_strength
		global_position.y = hover_base_y + bob_offset
		vertical_velocity = 0.0  # Freeze vertical momentum



##---------------------------------------##
##-----------HELPER FUNCTIONS------------##
##---------------------------------------##

func raycast_to_ground() -> float:
	var from = global_position
	var to = from - Vector3.UP * 10.0

	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.exclude = [self]

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	if result:
		return from.y - result.position.y
	return 9999.0

func update_prem7_glow() -> void:
	match current_mode:
		MODE_1:
			new_glow_color = MODE_1_COLOR
		MODE_2:
			new_glow_color = MODE_2_COLOR
		MODE_3:
			new_glow_color = MODE_3_COLOR
		MODE_4:
			new_glow_color = MODE_4_COLOR
		_:
			new_glow_color = Color.WHITE
	var back_glow_instance = PREM_7.back_glow
	var photon_glow_instance = PREM_7.photon_glow

	if back_glow_instance:
		var mat = back_glow_instance.get_surface_override_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("glow_color", Vector3(new_glow_color.r, new_glow_color.g, new_glow_color.b))

	if photon_glow_instance:
		var mat = photon_glow_instance.get_surface_override_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("glow_color", Vector3(new_glow_color.r, new_glow_color.g, new_glow_color.b))

func change_mode(new_mode: String) -> void:
	if new_mode == current_mode:
		print("Already in mode: " + new_mode)
		return
	current_mode = new_mode
	print("Multitool Mode Changed: " + current_mode)
	update_prem7_glow()

	if grabbed_object:
		match current_mode:
			MODE_1: glow_color = MODE_1_COLOR
			MODE_2: glow_color = MODE_2_COLOR
			MODE_3: glow_color = MODE_3_COLOR
			MODE_4: glow_color = MODE_4_COLOR
			_: glow_color = Color.WHITE

		#grabbed_object.set_outline('UPDATE', glow_color, 0.0)

func cycle_mode_direction(forward: bool = true) -> void:
	var current_index = modes.find(current_mode)
	var new_index = (current_index + (1 if forward else -1)) % modes.size()
	if new_index < 0:
		new_index = modes.size() - 1
	change_mode(modes[new_index])
	match current_mode:
		MODE_1: HUD.reticle.modulate = MODE_1_COLOR
		MODE_2: HUD.reticle.modulate = MODE_2_COLOR
		MODE_3: HUD.reticle.modulate = MODE_3_COLOR
		MODE_4: HUD.reticle.modulate = MODE_4_COLOR

func shortest_angle_diff_value(initial_angle: float, target_angle: float) -> float:
	initial_angle = wrapf(initial_angle, -180.0, 180.0)
	target_angle = wrapf(target_angle, -180.0, 180.0)

	var diff = target_angle - initial_angle
	if diff > 180:
		diff -= 360
	elif diff < -180:
		diff += 360
	return diff

func handle_jetpack_logic(delta: float) -> void:
	if extracting_object_active:
		if airborne:
			hover_base_y = global_position.y
			hover_bob_time = 0.0
			current_jetpack_thrust = 0.0
			current_jetpack_thrust = 0.0
			vertical_velocity = 0.0
			gravity_strength = 0.0
		return

	if jetpack_active:
		handle_jetpack('1', delta)
	else:
		if position.y > 2:
			if hover_lock:
				handle_jetpack('7', delta)
			elif current_jetpack_thrust > min_thrust_threshold:
				print('jetpack thrust: ', current_jetpack_thrust)
				handle_jetpack('3', delta)
			else:
				handle_jetpack('2', delta)

func update_vertical_velocity() -> void:
	if current_jetpack_thrust > min_thrust_threshold:
		handle_jetpack('3', get_process_delta_time())
	elif not is_on_floor():
		if not touching_ceiling:
			if vertical_velocity > 0:
				handle_jetpack('4', get_process_delta_time())
				if abs(vertical_velocity) < 0.25:
					vertical_velocity = 0.0
			else:
				if distance_to_ground < 8:
					handle_jetpack('5', get_process_delta_time())
				else:
					handle_jetpack('6', get_process_delta_time())
		else:
			handle_jetpack('6', get_process_delta_time())
	else:
		vertical_velocity = 0.0

func update_reticle_targeting() -> void:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_transform.origin
	var to = from + (-camera.global_transform.basis.z) * 100.0

	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	if result and not grabbed_object:
		
		if result.collider is RigidBody3D:
			if result.collider.is_rocket_system:
				if result.collider.is_engine:
					print("Touching Engine System")
					return
				elif result.collider.is_propellent:
					print("Touching Propellent System")
					return
			elif result.collider.is_rocketship:
				print("Touching Structure")
				return
			if touched_object:
				touched_object.is_touched = false
				touched_object = null
			match current_mode:
				MODE_1: HUD.reticle.modulate = MODE_1_COLOR
				MODE_2: HUD.reticle.modulate = MODE_2_COLOR
				MODE_3: HUD.reticle.modulate = MODE_3_COLOR
				MODE_4: HUD.reticle.modulate = MODE_4_COLOR
				_: HUD.reticle.modulate = Color.WHITE
			PREM_7.touching_object = true
			result.collider.is_touched = true
			touched_object = result.collider
			
			
			#PREM_7.shader_material.set_shader_parameter("base_alpha", 0.1)
		else:
			HUD.reticle.modulate = Color.WHITE
			if touched_object:
				touched_object.is_touched = false
				touched_object = null
				PREM_7.touching_object = false
			#PREM_7.shader_material.set_shader_parameter("base_alpha", 0.0)
	else:
		if touched_object:
			touched_object.is_touched = false
			touched_object = null
			PREM_7.touching_object = false
		HUD.reticle.modulate = Color.WHITE
		#PREM_7.shader_material.set_shader_parameter("base_alpha", 0.1)
		

func handle_prem7_decay(delta: float) -> void:
	# Smooth the raw input so it doesn't jump
	var smoothing_speed := 15.0  # lower = floatier, higher = snappier
	smoothed_mouse_vel_x = lerp(smoothed_mouse_vel_x, current_mouse_speed_x * 10, smoothing_speed * delta)
	smoothed_mouse_vel_y = lerp(smoothed_mouse_vel_y, current_mouse_speed_y * 10, smoothing_speed * delta)

	# Scale sway based on smoothed velocity
	var sway_force_x = smoothed_mouse_vel_x * prem7_rotation_speed * delta
	var sway_force_y = smoothed_mouse_vel_y * prem7_rotation_speed * delta

	if extracting_object_active:
		prem7_rotation_offset.y += -sway_force_x * 2
		prem7_rotation_offset.x += -sway_force_y * 4
	else:
		prem7_rotation_offset.y += sway_force_x * 4
		prem7_rotation_offset.x += sway_force_y * 10

	# Clamp to prevent flipping out
	var max_offset = deg_to_rad(25.0)
	prem7_rotation_offset.x = clamp(prem7_rotation_offset.x, -max_offset, max_offset)
	prem7_rotation_offset.y = clamp(prem7_rotation_offset.y, -max_offset, max_offset)

	# Decay back toward original pose
	prem7_rotation_offset = prem7_rotation_offset.lerp(Vector3.ZERO, prem7_decay_speed * delta)

	PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset

	# Decay the raw mouse speed too (optional, for safety)
	current_mouse_speed_x = lerp(current_mouse_speed_x, 0.0, 5.0 * delta)
	current_mouse_speed_y = lerp(current_mouse_speed_y, 0.0, 5.0 * delta)


func update_grabbed_object_physics(delta: float) -> void:
	if not grabbed_object:
		return
	if grabbed_object.is_suspended: 
		return
	var current_position = grabbed_object.global_transform.origin
	speed_vector = (current_position - last_position) / delta
	last_position = current_position
	grabbed_object.object_speed = speed_vector



func scale_object(object, x_scale: float, y_scale: float, z_scale: float, wait_time: float, duration: float):
	await get_tree().create_timer(wait_time).timeout
	
	scale_tween = create_tween()
	
	scale_tween.tween_property(object, "scale", Vector3(x_scale, y_scale, z_scale), duration)
	
	scale_tween.set_trans(Tween.TRANS_LINEAR)
	scale_tween.set_ease(Tween.EASE_IN_OUT)

func reset_object_position():
	var current_rot = grabbed_object.rotation_degrees
	grabbed_rotation.x = shortest_angle_diff_value(-current_rot.x, 0)
	grabbed_rotation.y = shortest_angle_diff_value(-current_rot.y, 0)
	grabbed_rotation.z = shortest_angle_diff_value(-current_rot.z, 0)

	pitch_min = grab_pitch_min
	pitch_max = grab_pitch_max


func load_json_file(filePath: String):
	if FileAccess.file_exists(filePath):
		
		var dataFile = FileAccess.open(filePath, FileAccess.READ)
		var parsedResult = JSON.parse_string(dataFile.get_as_text())
	
		if parsedResult is Dictionary:
			return parsedResult
		else:
			print("Error reading file")
	else:
		print("File Doesn't Exist")

func activate_component_data():
	var obj_name = grabbed_object.name
	if not object_data.has(obj_name):
		print("No component data found for", obj_name)
		current_extraction_data = []
		return

	current_object_json = object_data[obj_name]
	current_extraction_data = current_object_json.get("components", [])
	current_component_index = 0

	# Kill existing tweens
	if name_tween:
		name_tween.kill()
	if class_tween:
		class_tween.kill()
	
	extraction_scale = current_object_json.get("scale", 0.0)
	distance_factor = current_object_json.get("distance", 0.0)

	update_component_display()


func scroll_component_data(dir):
	if extraction_recently_completed:
		return

	selected_component_mesh.position = selected_component_pos
	selected_component_mesh.scale = Vector3(comp_scale_x, comp_scale_y, comp_scale_z)
	_on_action_key('up')

	selected_component_mesh = null
	selected_component_col = null

	if dir == "UP":
		current_component_index -= 1
	elif dir == "DOWN":
		current_component_index += 1

	var count = current_extraction_data.size()
	
	if current_extraction_data.is_empty():
		return
	else:
		current_component_index = (current_component_index + count) % count
		update_component_display()

func pad_with_dots(text: String, total_length: int) -> String:
	var text_length = text.length()
	var dots_needed = total_length - text_length
	
	if dots_needed <= 0:
		return text  # Already at or over max length
	
	return ".".repeat(dots_needed) + text


func update_component_display():
	if current_extraction_data.is_empty():
		PREM_7.machine_name.text = ""
		PREM_7.machine_class.text = ""
		PREM_7.component_name.text  = ""
		PREM_7.component_system.text = ""
		PREM_7.component_rating.text  = ""
		PREM_7.component_mass.text   = ""
		return

	var comp: Dictionary = current_extraction_data[current_component_index]

	var machine_name_text = pad_with_dots(current_object_json.get("name", "??"), 30)
	var machine_class_text = pad_with_dots(current_object_json.get("class", "??"), 31)
	var system_text_raw = comp.get("system", "??")
	var system_text = pad_with_dots(system_text_raw, 30)
	
	# Determine color based on first word
	var first_word = system_text_raw.split(" ")[0].to_upper()
	var text_color = Color.WHITE  # default
	
	if first_word.begins_with("[ENGINE]"):
		text_color = Color.from_hsv(0.062, 0.53, 1.0, 1.0)
		HUD.component_color = Color.from_hsv(0.062, 0.53, 1.0, 1.0)
	elif first_word.begins_with("[PROPELLANT]"):
		text_color = Color.from_hsv(0.422, 1.0, 0.977, 1.0)
		HUD.component_color = Color.from_hsv(0.422, 1.0, 0.977, 1.0)
	elif first_word.begins_with("[STRUCTURE]"):
		text_color = Color.from_hsv(0.532, 0.707, 1.0, 1.0)
		HUD.component_color = Color.from_hsv(0.532, 0.707, 1.0, 1.0)
	elif first_word.begins_with("[OPERATION]"):
		text_color = Color.from_hsv(0.861, 0.374, 1.0, 1.0)
		HUD.component_color = Color.from_hsv(0.861, 0.374, 1.0, 1.0)
	
	PREM_7.component_system.modulate = text_color
	
	if PREM_7.machine_name.text != machine_name_text:
		if name_tween:
			name_tween.kill()
		name_tween = animate_typing_text(PREM_7.machine_name, machine_name_text, 0.015)
	
	if PREM_7.machine_class.text != machine_class_text:
		if class_tween:
			class_tween.kill()
		class_tween = animate_typing_text(PREM_7.machine_class, machine_class_text, 0.015)
	
	if PREM_7.component_system.text != system_text_raw:
		if system_tween:
			system_tween.kill()
		system_tween = animate_typing_text(PREM_7.component_system, system_text, 0.015)
	
	PREM_7.component_name.text  = comp.get("name", "??")
	PREM_7.component_name_back.text  = comp.get("name", "??")
	
	var name_size = comp.get("size", .05)
	PREM_7.component_name.pixel_size = name_size
	PREM_7.component_name_back.pixel_size = name_size
	
	var condition = comp.get("condition", 0)
	var mass = comp.get("mass", 0)
	var mayhem = comp.get("mayhem", 0)
	var force = comp.get("force", 0.0)
	var rating = calculate_rating(condition, mass, mayhem, force)
	
	selected_component_mass  = mass
	PREM_7.component_mass.text   = str(int(comp.get("mass", 0)))
	selected_component_scale = comp.get("scale", 0.0)
	selected_component_glow  = comp.get("glow",  0.0)
	
	update_condition_display(condition)
	update_rating_display(rating)
	pulse_mass_label()
	update_mayhem_meter(mayhem)
	update_force_factor(force)

	# Find matching shape base name
	var target_id := _normalize_id(comp.get("name", ""))
	var matched_shape: CollisionShape3D = null
	var matched_base_name := ""

	for child in grabbed_object.get_children():
		if child is CollisionShape3D:
			var base := _base_from_shape(child.name)  # strips "_Shape"
			if _normalize_id(base) == target_id:
				matched_shape = child
				matched_base_name = base
				break

	selected_component_col = matched_shape  # may be null; that's OK

	var body_in_use: Node = grabbed_object.extract_body if grabbed_object.extract_body else grabbed_object.object_body
	if body_in_use == null:
		return

	selected_component_mesh = null
	for mesh in body_in_use.get_children():
		if mesh is MeshInstance3D:
			if matched_base_name != "" and mesh.name == matched_base_name:
				true_scale = mesh.scale
				grabbed_object.set_extract_glow(mesh, "Selected")
				selected_component_mesh = mesh
				selected_component_pos = mesh.position
				comp_scale_x = mesh.scale.x
				comp_scale_y = mesh.scale.y
				comp_scale_z = mesh.scale.z
			else:
				grabbed_object.set_extract_glow(mesh, "Deselected")

	if matched_base_name == "":
		print("No matching CollisionShape3D for component:", comp.get("name", "??"))

var current_condition: int = 0
var current_rating: float = 0.0
var current_mass: int = 0
var name_tween: Tween = null
var class_tween: Tween = null
var system_tween: Tween = null
var condition_tween: Tween = null
var rating_tween: Tween = null
var mass_pulse_tween: Tween = null
var mayhem_tween: Tween = null
var force_tween: Tween = null

func animate_typing_text(label: Label3D, full_text: String, duration_per_char: float = 0.03):
	# Store full text and start with empty
	var char_count = full_text.length()
	
	# Create tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Animate from 0 characters to full length
	tween.tween_method(
		func(chars): 
			var visible_chars = int(chars)
			label.text = full_text.substr(0, visible_chars),
		0.0,
		float(char_count),
		duration_per_char * char_count
	)
	
	return tween

func update_condition_display(condition_value: int):
	condition_value = clampi(condition_value, 0, 10)
	
	# If condition hasn't changed, do nothing
	if condition_value == current_condition:
		return
	
	# Kill existing tween
	if condition_tween:
		condition_tween.kill()
	
	# Create tween for sequential block appearance
	condition_tween = create_tween()
	
	# Determine direction (filling up or emptying)
	var start = current_condition
	var end = condition_value
	var is_increasing = end > start
	
	# Adjust start position based on direction
	var first_block = start + 1 if is_increasing else start
	var last_block = end if is_increasing else end + 1
	var step = 1 if is_increasing else -1
	
	# Animate each block with a slight delay
	for i in range(first_block, last_block + step, step):
		if i < 1 or i > 10:
			continue
		
		# Skip the block at the target condition when decreasing (it stays at normal size)
		if not is_increasing and i == condition_value:
			continue
		
		var block = PREM_7.component_condition.get_node_or_null(str(i))
		if block and block is MeshInstance3D:
			condition_tween.tween_callback(func():
				var pulse_tween = create_tween()
				
				if is_increasing:
					# Growing - pulse bigger, then settle at normal
					pulse_tween.tween_property(block, "scale", Vector3.ONE * 1.3, 0.15)
					pulse_tween.tween_property(block, "scale", Vector3.ONE, 0.08)
				else:
					# Shrinking - shrink from normal to zero
					pulse_tween.tween_property(block, "scale", Vector3.ZERO, 0.15)
			)
			condition_tween.tween_interval(0.05)
	
	# SAFETY: Ensure ALL blocks are at correct scale at the end
	condition_tween.tween_callback(func():
		for i in range(1, 11):
			var block = PREM_7.component_condition.get_node_or_null(str(i))
			if block and block is MeshInstance3D:
				if i <= condition_value:
					block.scale = Vector3.ONE  # Normal size
				else:
					block.scale = Vector3.ZERO  # Invisible (zero size)
	)
	
	current_condition = condition_value

func calculate_rating(condition: int, mass: int, mayhem: float, force: float) -> float:
	# Normalize all values to 0-1 scale
	var condition_norm = clampf(condition / 10.0, 0.0, 1.0)  # Higher is better
	var max_mass = 50.0
	var mass_norm = 1.0 - clampf(mass / max_mass, 0.0, 1.0)  # Lower is better, so invert
	var mayhem_norm = 1.0 - clampf(mayhem / 100.0, 0.0, 1.0)  # Lower is better, so invert
	var force_norm = clampf(force / 5.0, 0.0, 1.0)  # Higher is better
	
	var weighted_score = (
		(condition_norm * 1.5) +
		(mass_norm * 1.0) +
		(mayhem_norm * 4.5) +
		(force_norm * 4.0)
	) / 10.0
	
	# Convert to 0-5 star rating
	var rating = weighted_score * 5.0
	
	# Round to nearest 0.5 (for half stars)
	rating = round(rating * 2.0) / 2.0
	
	return clampf(rating, 0.0, 5.0)

func update_rating_display(rating_value: float):
	rating_value = clampf(rating_value, 0.0, 5.0)
	
	if rating_value == current_rating:
		return
	
	var stars_node = PREM_7.component_rating.get_node_or_null("Stars")
	if not stars_node:
		push_error("Stars node not found under Rating")
		return
	
	if rating_tween:
		rating_tween.kill()
	
	rating_tween = create_tween()
	
	var is_increasing = rating_value > current_rating
	
	var steps = []
	for i in range(1, 6): 
		steps.append({"star": i, "is_left": true, "value": float(i) - 0.5}) 
		steps.append({"star": i, "is_left": false, "value": float(i)}) 
	
	var steps_to_animate = []
	for step in steps:
		if is_increasing:
			if step.value > current_rating and step.value <= rating_value:
				steps_to_animate.append(step)
		else:
			if step.value <= current_rating and step.value > rating_value:
				steps_to_animate.append(step)
	
	if not is_increasing:
		steps_to_animate.reverse()
	
	for step in steps_to_animate:
		var star_node = stars_node.get_node_or_null(str(step.star))
		if not star_node:
			continue
		
		var left_half = star_node.get_node_or_null("Half") as MeshInstance3D
		var right_half = star_node.get_node_or_null("Full") as MeshInstance3D
		
		if not left_half or not right_half:
			continue
		
		var target_mesh = left_half if step.is_left else right_half
		
		rating_tween.tween_callback(func():
			if is_increasing:
				target_mesh.visible = true
				var pulse_tween = create_tween()
				pulse_tween.tween_property(target_mesh, "scale", Vector3.ONE * 1.3, 0.15)
				pulse_tween.tween_property(target_mesh, "scale", Vector3.ONE, 0.08)
			else:
				target_mesh.visible = false
		)
		rating_tween.tween_interval(0.05)
	
	rating_tween.tween_callback(func():
		for i in range(1, 6):
			var star_node = stars_node.get_node_or_null(str(i))
			if not star_node:
				continue
			
			var left_half = star_node.get_node_or_null("Half") as MeshInstance3D
			var right_half = star_node.get_node_or_null("Full") as MeshInstance3D
			
			if not left_half or not right_half:
				continue
			
			var star_fill = rating_value - float(i - 1)
			
			if star_fill >= 1.0:
				# Full star - both halves visible
				left_half.visible = true
				left_half.scale = Vector3.ONE
				right_half.visible = true
				right_half.scale = Vector3.ONE
			elif star_fill >= 0.5:
				# Half star - only left half visible
				left_half.visible = true
				left_half.scale = Vector3.ONE
				right_half.visible = false
			else:
				# Empty - both halves hidden
				left_half.visible = false
				right_half.visible = false
	)
	
	current_rating = rating_value

func pulse_mass_label():
	var mass_label = PREM_7.component_mass
	
	if not mass_label:
		return
	
	if mass_pulse_tween:
		mass_pulse_tween.kill()
	
	# Store original scale
	var original_scale = Vector3(0.013, 0.013, 0.013)
	
	# Create pulse: shrink fast, grow back gradually
	mass_pulse_tween = create_tween()
	mass_pulse_tween.set_ease(Tween.EASE_OUT)
	mass_pulse_tween.set_trans(Tween.TRANS_BACK)  # Adds a little bounce at the end
	
	# Drop to 0.6x size quickly
	mass_pulse_tween.tween_property(mass_label, "scale", original_scale * 0.6, 0.1)
	# Grow back to original size more gradually with bounce
	mass_pulse_tween.tween_property(mass_label, "scale", original_scale, 0.3)

func update_mayhem_meter(mayhem_value: float, max_mayhem: float = 100.0):
	# Set minimum value if below 1
	if mayhem_value < 1.0:
		mayhem_value = 0.9
	
	var mayhem_meter = PREM_7.component_mayhem 
	var mayhem_text = PREM_7.component_mayhem_pct
	
	if not mayhem_meter:
		push_error("MayhemMeter node not found")
		return
	
	var mat = mayhem_meter.get_surface_override_material(0) as ShaderMaterial
	
	if not mat:
		push_error("MayhemMeter has no ShaderMaterial")
		return
	
	var target_progress = clampf(mayhem_value / max_mayhem, 0.0, 1.0) / 2
	var current_progress = mat.get_shader_parameter("progress")
	
	var current_value = float(mayhem_text.text.replace("%", ""))
	
	if mayhem_tween:
		mayhem_tween.kill()
	
	mayhem_tween = create_tween()
	mayhem_tween.set_ease(Tween.EASE_OUT)
	mayhem_tween.set_trans(Tween.TRANS_CUBIC)
	mayhem_tween.set_parallel(true)
	
	mayhem_tween.tween_method(
		func(value): mat.set_shader_parameter("progress", value),
		current_progress,
		target_progress,
		0.5
	)
	
	mayhem_tween.tween_method(
		func(value): mayhem_text.text = str(int(value)) + "%",
		current_value,
		mayhem_value,
		0.5
	)

func update_force_factor(force_value: float, max_force: float = 5.0):
	# Set minimum value if below 1
	if force_value < 0.1:
		force_value = 0.01
	
	var force_meter = PREM_7.component_force 
	var force_text = PREM_7.component_force_amt
	
	if not force_meter:
		push_error("Force Factor meter not found")
		return
	
	var mat = force_meter.get_surface_override_material(0) as ShaderMaterial
	
	if not mat:
		push_error("Force Factor has no ShaderMaterial")
		return
	
	var target_fill = clampf(force_value / max_force, 0.0, 1.0)
	var current_fill = mat.get_shader_parameter("fill_amount")
	
	var current_value = float(force_text.text.replace("x", ""))
	
	if force_tween:
		force_tween.kill()
	
	force_tween = create_tween()
	force_tween.set_ease(Tween.EASE_OUT)
	force_tween.set_trans(Tween.TRANS_CUBIC)
	force_tween.set_parallel(true)
	
	force_tween.tween_method(
		func(value): mat.set_shader_parameter("fill_amount", value),
		current_fill,
		target_fill,
		0.5
	)
	
	force_tween.tween_method(
		func(value): force_text.text = "%.1fx" % value,
		current_value,
		force_value,
		0.5
	)













func _normalize_id(s: String) -> String:
	return s.replace(" ", "").to_lower()

func _base_from_shape(name_string: String) -> String:
	if name_string.ends_with("_Shape"):
		return name_string.substr(0, name_string.length() - "_Shape".length())
	return name_string

func extract_component(mesh, col):

	fresh_component = RigidBody3D.new()
	fresh_component.name = mesh.name
	
	var fresh_mesh = mesh.duplicate()
	var fresh_col = col.duplicate()
	
	fresh_component.position = Vector3(1.0, -0.5, -3.0)
	fresh_component.add_child(fresh_mesh)
	fresh_component.add_child(fresh_col)
	
	fresh_mesh.position = Vector3.ZERO
	fresh_col.position = Vector3.ZERO
	
	fresh_mesh.scale = Vector3.ZERO
	
	var grabbed_body = grabbed_object.get_children()
	var grabbed_children
	for child in grabbed_body:
		grabbed_children = child.get_children()
	for child in grabbed_children:
		if child is MeshInstance3D:
			if mesh.name == child.name:
				child.get_parent().remove_child(child)
				child.queue_free()
				child = null

	mesh.get_parent().remove_child(mesh)
	#mesh.queue_free()
	mesh = null
	
	col.get_parent().remove_child(col)
	#col.queue_free()
	col = null
	#inventory.add_child(new_mesh)
	add_child(fresh_component)
	#fresh_component.position = Vector3(2.0, -0.85, -4.0)
	#new_mesh.rotation_degrees = Vector3(0, new_mesh.rotation_degrees.y + 28, 0)
	
	extraction_recently_completed = true
	
	print('Rigid Pos: ', fresh_component.position)
	print('Mesh Pos: ', fresh_mesh.position)
	print('Col Pos: ', fresh_col.position)

func setup_component():
	f_comp = fresh_component
	f_comp.set_script(COMPONENT_SCRIPT)
	f_comp.shader = Shader.new()
	f_comp.shader.code = f_comp.GLOW_SHADER.code
	f_comp.shader_material = ShaderMaterial.new()
	f_comp.manipulation_material.shader = f_comp.MANIPULATION_SHADER
	f_comp.extraction_material.shader = f_comp.EXTRACTION_SHADER
	f_comp.extracted_object_mat = f_comp.EXTRACT_MATERIAL.duplicate()
	f_comp.contact_monitor = true
	f_comp.continuous_cd = false
	f_comp.max_contacts_reported = 100
	f_comp.gravity_scale = 0.0
	f_comp.collision_layer = 3
	f_comp.collision_mask = 3
	f_comp.mass = selected_component_mass * 2
	f_comp.is_component = true
	f_comp.fade_extract_glow = false
	
	for child in f_comp.get_children():
		if child is MeshInstance3D:
			f_comp.object_body = child

	f_comp.current_scale = Vector3(comp_scale_x, comp_scale_y, comp_scale_z)
	print(f_comp.current_scale)
	f_comp.physics_mat.friction = 0.9
	f_comp.physics_mat.bounce = 0.0
	f_comp.physics_material_override = f_comp.physics_mat
	f_comp.shader_material.shader = f_comp.GLOW_SHADER
	f_comp.standard_material = f_comp.GLOW_MATERIAL

	f_comp.resting_position = f_comp.global_position.y

	f_comp.set_physics_process(true)
	f_comp.set_process(true)
	
	store_component(f_comp)
	
func store_component(obj):
	action_wait_timer.start(0.5)
	obj.reparent(storage_shed)
	obj.position = Vector3.ZERO
	HUD.extraction_complete = true

func reform_component(obj, time, parent):
	if current_extraction_data.is_empty():
		print('This is the function with the issues me thinks...')
		return

	for child in fresh_component.get_children():
		if child is CollisionShape3D:
			child.disabled = true
	parent.EXTRACT_MATERIAL.emission = lerp(parent.EXTRACT_MATERIAL.emission, Color.TRANSPARENT, time * 2.0)
	parent.EXTRACT_MATERIAL.albedo_color = lerp(parent.EXTRACT_MATERIAL.albedo_color, Color.TRANSPARENT, time * 2.0)
	parent.EXTRACT_MATERIAL.emission_energy_multiplier = lerp(parent.EXTRACT_MATERIAL.emission_energy_multiplier, 0.0, time)
	parent.set_extract_glow(obj, 'Complete')

	reform = false

func complete_extraction(body: RigidBody3D, mesh: MeshInstance3D):
	PREM_7.holo_anim.speed_scale = 1.0
	PREM_7.holo_anim.play_backwards("retract_hologram")
	await get_tree().create_timer(0.25).timeout
	extraction_finalized = true
	new_component = body
	body = null
	new_component.ready_to_move = true
	new_component.fade_extract_glow = true
	# Remove only the extracted entry from the data list
	var mesh_id := _normalize_id(mesh.name)
	for i in range(current_extraction_data.size() - 1, -1, -1):
		var entry = current_extraction_data[i]
		var entry_id := _normalize_id(str(entry.get("name", "")))
		if entry_id == mesh_id:
			current_extraction_data.remove_at(i)
			break
	
	scroll_component_data('DOWN')
	
	if current_extraction_data.is_empty():
		object_empty()
		return
	
	grabbed_object.manipulation_mode('Active')

func object_empty():
	print('*** Figure out what needs to happen with this animation ***')
	print("NO CLICKS UNTIL THEN :)")
	is_clickable = false








const LERP_IN  := 2.5
const LERP_OUT := 3.5
const POSITION_THRESHOLD := 0.01  # How close is "close enough" to base position
var OFFSET_X
var OFFSET_Z

var touched_walls := {}
var base_local_pos := {}
var walls_are_moving := false  # NEW: track if any wall is moving

func register_wall(mesh: Node3D) -> void:
	if mesh == null: return
	if !is_instance_valid(mesh): return
	if !base_local_pos.has(mesh):
		base_local_pos[mesh] = mesh.position

func get_rocket_walls() -> Array:
	return touched_walls.keys()

# Call this when a wall is touched
func touch_wall(mesh: Node3D) -> void:
	touched_walls[mesh] = true
	walls_are_moving = true  # Start checking again

# Call this when a wall should return
func release_wall(mesh: Node3D) -> void:
	touched_walls.erase(mesh)
func rocket_wall_check(time: float) -> void:
	# Prune dead refs
	for m in base_local_pos.keys():
		if !is_instance_valid(m):
			base_local_pos.erase(m)
			touched_walls.erase(m)
	
	var any_wall_moving := false  # Track if ANY wall is still moving
	
	# Drive ALL known meshes
	for m in base_local_pos.keys():
		var active := touched_walls.has(m)
		var spd := (LERP_IN if active else LERP_OUT)
		var piece = m.get_parent()  # e.g., "Left_Piece"
		var wall_dir = piece.get_parent()  # e.g., "+Z"
		
		# Determine offset
		if wall_dir.name.contains("+X"):
			OFFSET_X = 2.5
			OFFSET_Z = 0.0
		elif wall_dir.name.contains("+Z"):
			OFFSET_X = 0.0
			OFFSET_Z = 2.5
		elif wall_dir.name.contains("-X"):
			OFFSET_X = -2.5
			OFFSET_Z = 0.0
		elif wall_dir.name.contains("-Z"):
			OFFSET_X = 0.0
			OFFSET_Z = -2.5
		
		var target_pos = base_local_pos[m] + Vector3(OFFSET_X, 0.0, OFFSET_Z) if active else base_local_pos[m]
		m.position = m.position.lerp(target_pos, spd * time)
		
		# Check if this wall is still moving
		var is_moving = m.position.distance_to(target_pos) > POSITION_THRESHOLD
		if is_moving:
			any_wall_moving = true
		
		# Build collision name: "+Z_Propellent_Left_Collision"
		# Extract position from piece name (e.g., "Left_Piece" -> "Left")
		var pos = piece.name.replace("_Piece", "")
		var collision_name = wall_dir.name + "_" + pos + "_Collision"
		
		toggle_collision_shape(collision_name, active, is_moving)
		
		# Transparency
		var target_alpha := 1.0 if active else 0.0
		var t = m.transparency
		t = lerp(t, target_alpha, spd * time)
		m.transparency = t
	
	# Update the flag
	walls_are_moving = any_wall_moving or under_the_hood

func toggle_collision_shape(collision_name: String, is_active: bool, is_moving: bool) -> void:
	for shape in active_rocket.collision_shapes:
		if shape.name == collision_name:
			shape.disabled = is_active or is_moving
			return
