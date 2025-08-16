extends CharacterBody3D
class_name character

const is_character: bool = true
var start_day: bool = false

var object_data = {}
var component_data_file = "res://components/component_data.json"
var current_component_index := 0
var current_extraction_data = []  # Will hold the JSON components array
var current_object_json: Dictionary = {}



@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera: Camera3D = $Camera3D
@onready var PREM_7: Node3D = $"Camera3D/PREM-7"
@onready var HUD: Control = $HUD
@onready var char_obj_shape: CollisionShape3D
#@onready var beam: Node3D = PREM_7.beam
#@onready var beam_mesh: Node3D = PREM_7.beam_mesh
#@onready var beam_shader_mat := beam_mesh.get_active_material(0) as ShaderMaterial

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
var smoothing: float = 0.15  # Smoothing factor (0-1)
var current_mouse_speed_x: float
var current_mouse_speed_y: float

var target_pitch_min: float
var pitch_min_lerp_speed: float = 5.0  # Higher = faster adjustment
var grounded_grabbed_pitch_min: float = deg_to_rad(-10.0)  # Limit downward look when grounded with object


# Variables for camera rotation
var desired_yaw: float = 0.0
var desired_pitch: float = 0.0

var extracting_yaw: float = 0.0

var yaw: float = 0.0
var distance_factor: float = 0.0
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
var scroll_cooldown_duration := 0.05  # Adjust to taste (0.1–0.2 is typical)

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

var time: float
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

var extraction_scale: float
var extract_body: MeshInstance3D
var extraction_started: bool = false
var comp_scale_x
var comp_scale_y
var comp_scale_z
var extract_alpha = 0.25
var extract_edge = 1.75
var base_extract_time = 2.0
var extract_time = base_extract_time
var base_extract_speed = 0.0025
var extract_speed = base_extract_speed
var selected_component_mesh: MeshInstance3D
var selected_component_col: CollisionShape3D
var selected_component_pos: Vector3
var selected_component_scale: float
var selected_component_rot: Vector3
var fresh_component: RigidBody3D

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
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	prem7_original_rotation = PREM_7.rotation
	object_data = load_json_file(component_data_file)


func _physics_process(delta: float) -> void:
	
	# Update ground distance
	distance_to_ground = raycast_to_ground()

	# Handle basic directional input
	var vertical = 0
	var horizontal = 0

	if not extracting_object_active:
		if move_input["up"] and not move_input["down"]:
			if not shifting_object_active:
				vertical = lerp(vertical, 1, delta)
				#prem7_rotation_offset.x -= 0.0025
		elif move_input["down"] and not move_input["up"]:
			if not shifting_object_active:
				vertical = lerp(vertical, -1, delta)
				#prem7_rotation_offset.x += 0.0025
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

	var desired_direction = Vector3.ZERO
	if vertical != 0 or horizontal != 0:
		desired_direction = ((-transform.basis.z) * vertical + (transform.basis.x) * horizontal).normalized()

	var desired_velocity = desired_direction * movement_speed
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

	move_and_slide()
	
	handle_pitch_and_yaw(delta)
	
	

	# Update jetpack thrust, hover, ceiling logic
	handle_jetpack_logic(delta)

	# Handle grounded/airborne vertical velocity
	update_vertical_velocity()

func _process(delta: float) -> void:
	
	if grabbed_object:
		if extracting_object_active:
			var x = comp_scale_x
			var y = comp_scale_y
			var z = comp_scale_z
			var s = selected_component_scale
			grabbed_object.manipulation_material.set_shader_parameter("albedo_alpha", extract_alpha)
			grabbed_object.manipulation_material.set_shader_parameter("edge_intensity", extract_edge)
			var screen_mat = PREM_7.module_screen.get_surface_override_material(0)
			var module_labels = PREM_7.module_screen.get_children()
			var power_labels = PREM_7.power_screen.get_children()
			var mass_labels = PREM_7.mass_screen.get_children()
			var lift_labels = PREM_7.lift_screen.get_children()
			var screen_labels = module_labels + power_labels + mass_labels + lift_labels
			
			if extraction_recently_completed:
				print('hmm')
				PREM_7.object_inventory.scale = lerp(PREM_7.object_inventory.scale, Vector3.ONE, delta * 2.5)
				PREM_7.object_inventory.position.y = lerp(PREM_7.object_inventory.position.y, 2.5, delta * 2.5)
				complete_extraction()
			
			if extraction_started:
				if extract_time >= 0.002:
					extract_alpha -= delta / 1.1
					extract_edge -= delta * 2.25
					extract_time -= delta
				grabbed_object.EXTRACT_MATERIAL.albedo_color.a = lerp(grabbed_object.EXTRACT_MATERIAL.albedo_color.a, 0.0, delta * 2.5)
				grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier = lerp(grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier, 0.0, delta * 2.5)
				PREM_7.module_screen.scale = lerp(PREM_7.module_screen.scale, Vector3.ZERO, delta * 3.5)
				PREM_7.power_screen.scale = lerp(PREM_7.power_screen.scale, Vector3.ZERO, delta * 3.5)
				PREM_7.mass_screen.scale = lerp(PREM_7.mass_screen.scale, Vector3.ZERO, delta * 3.5)
				PREM_7.lift_screen.scale = lerp(PREM_7.lift_screen.scale, Vector3.ZERO, delta * 3.5)
				screen_mat.albedo_color.a = lerp(screen_mat.albedo_color.a, 0.0, delta * 3.5)
				for child in screen_labels:
					child.modulate.a = lerp(child.modulate.a, 0.0, delta * 3.5)
					child.outline_modulate.a = lerp(child.outline_modulate.a, 0.0, delta * 3.5)

				if control_timer.is_stopped() == false:
					var t_left_ratio = control_timer.time_left / control_timer.wait_time
					var progress = 1.1 - t_left_ratio
					var high_extract_speed = 1.1
					extract_speed = lerp(extract_speed, high_extract_speed, progress * delta)
				if control_timer.time_left < 2.0 and control_timer.time_left > 1.0:
					selected_component_mesh.position = lerp(selected_component_mesh.position, Vector3.ZERO, delta * 2.5)
					selected_component_mesh.scale = lerp(selected_component_mesh.scale, Vector3(x*s, y*s, z*s), delta * 2.5)
					extraction_scale = x * s
				if control_timer.time_left < 1.0:
					selected_component_mesh.position = lerp(selected_component_mesh.position, Vector3(0.0, -5.0, 0.0), delta * 1.5)
					selected_component_mesh.scale = lerp(selected_component_mesh.scale, Vector3(0.0, 0.0, 0.0), delta * 5.0)

				if control_timer.time_left == 0.0:
					extract_component(selected_component_mesh, selected_component_col)
					extraction_started = false
				
				#print(selected_component_mesh.rotation_degrees)
				#print(selected_component_mesh.get_parent().rotation_degrees)
				
			else:
				if not selected_component_mesh:
					return
				extract_speed = lerp(extract_speed, base_extract_speed, delta * 7.5)
				PREM_7.module_screen.scale = lerp(PREM_7.module_screen.scale, Vector3.ONE, delta * 7.5)
				PREM_7.power_screen.scale = lerp(PREM_7.power_screen.scale, Vector3.ONE, delta * 7.5)
				PREM_7.mass_screen.scale = lerp(PREM_7.mass_screen.scale, Vector3.ONE, delta * 7.5)
				PREM_7.lift_screen.scale = lerp(PREM_7.lift_screen.scale, Vector3.ONE, delta * 7.5)
				screen_mat.albedo_color.a = lerp(screen_mat.albedo_color.a, 0.5, delta * 7.5)
				for child in screen_labels:
					child.modulate.a = lerp(child.modulate.a, 1.0, delta * 7.5)
					child.outline_modulate.a = lerp(child.outline_modulate.a, 1.0, delta * 7.5)
				grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier = lerp(grabbed_object.EXTRACT_MATERIAL.emission_energy_multiplier, 7.5, delta * 7.5)
				grabbed_object.EXTRACT_MATERIAL.albedo_color = lerp(grabbed_object.EXTRACT_MATERIAL.albedo_color, Color.WHITE, delta * 7.5)
				selected_component_mesh.position = lerp(selected_component_mesh.position, selected_component_pos, delta * 7.5)
				selected_component_mesh.scale = lerp(selected_component_mesh.scale, Vector3(x, y, z), delta * 7.5)
				extract_alpha = lerp(extract_alpha, 0.75, delta * 7.5)
				extract_edge = lerp(extract_edge, 2.0, delta * 7.5)
				extract_time = lerp(extract_time, base_extract_time, delta * 7.5)


	handle_prem7_decay(delta)

	if abs(delta - previous_delta) > delta_threshold:
		screen_res_sway_multiplier = 55.0 * delta
		previous_delta = delta
		screen_resolution_set = true
	

	
	if scroll_cooldown > 0.0:
		scroll_cooldown -= delta

	PREM_7.rotation = PREM_7.rotation.lerp(prem7_original_rotation, prem7_decay_speed * delta)
	update_reticle_targeting()

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
				print('***   Make sure to lerp these shaders / standard materials   ***')
		else:
			camera.fov = lerp(camera.fov, 75.0, delta * 10)
			if PREM_7.handling_object:
				HUD.control_color.visible = false
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
	if not grabbed_object and (extracting_object_active or fusing_object_active):
		camera.fov = lerp(camera.fov, 75.0, delta * 10)
		HUD.control_color.visible = false
		PREM_7.release_handle()
		if camera.fov >= 74.9:
			extracting_object_active = false
			grabbed_object.extract_in_motion = false
			grabbed_object.is_extracting = false
			fusing_object_active = false

##--------------------------------------##
##------------INPUT RESPONSE------------##
##--------------------------------------##

func _input(event: InputEvent) -> void:
	# Process Mouse Button events.
	if event is InputEventMouseButton:
		# Ignore events from opposite buttons if one is held.
		if left_mouse_down and event.button_index == MOUSE_BUTTON_RIGHT:
			return
		if right_mouse_down and event.button_index == MOUSE_BUTTON_LEFT:
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
					scroll_extraction_data('UP')
					return
				print('Still need to figure out INSPECT, Cycling Stored Components, etc.')
				#PREM_7.switch_hologram('Up')
				scroll_cooldown = scroll_cooldown_duration
			#if right_mouse_down and shifting_object_active:
				#if grabbed_target_position.y <= max_y:
					#if grabbed_object.is_suspended:
						#print('***Move Camera with this***')
						#grabbed_target_position.y += 0.1


		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if not middle_mouse_down and not right_mouse_down and not left_mouse_down:
				if extracting_object_active:
					scroll_extraction_data('DOWN')
					return
				print('Still need to figure out INSPECT, Cycling Stored Components, etc.')
				scroll_cooldown = scroll_cooldown_duration
			#if right_mouse_down and shifting_object_active:
				#if grabbed_target_position.y >= 0.5:
					#if grabbed_object.is_suspended:
						#print('***Move Camera with this***')
						#grabbed_target_position.y -= 0.1


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

		# camera turning still lives here
		if not extracting_object_active:
			var max_delta: float = 0.15 * screen_res_sway_multiplier
			var dx = clamp(event.relative.x * mouse_speed, -max_delta, max_delta)
			var dy = clamp(event.relative.y * mouse_speed, -max_delta, max_delta)
			desired_yaw -= dx
			desired_pitch -= dy
			desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)

	# Process Keyboard events.
	if event is InputEventKey and not event.is_echo():
		var pressed = event.is_pressed()

		var down = event.pressed

		if event.keycode == KEY_E and pressed:
			if grabbed_object:
				_on_extract_key(down)
		if event.keycode == KEY_R and pressed:
			desired_pitch = 0
			_on_reset_key()
		
		if event.keycode == KEY_Q:
			if pressed:
				_on_action_key('down')
			if not pressed:
				_on_action_key('up')
			#if released or q_timer == 0.0:
				#print("releasing q...reset timer")
			#if event.pressed:
				#suspending_object_active = true
				#print('add SUSPEND visuals')
				#print('Change the shift movement (left, right, forward, backward) to match what the character is seeing vs. actual position')
			#if not event.pressed:
				#beam_lock = false
				#grabbed_object.is_suspended =! grabbed_object.is_suspended
				#grabbed_object.object_rotation = grabbed_object.rotation_degrees
				#grab_object()
				

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
		if event.keycode == KEY_ESCAPE and pressed and not event.is_echo():
			get_tree().quit()

		# Update movement key states.
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			move_input["up"] = pressed
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.z -= 0.25
					print('This should move forward based on direction of object face')
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			move_input["down"] = pressed
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.z += 0.25
					print('This should move backward based on direction of object face')
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			move_input["left"] = pressed
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.x -= 0.25
					print('***Move Camera with this*** -- Maybe use look_at?')
					print('This should move left based on direction of object face')
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			move_input["right"] = pressed
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.x += 0.25
					print('***Move Camera with this*** -- Maybe use look_at?')
					print('This should move right based on direction of object face')

			#print("Current Player Position: ", position)

		# Process number keys (1-4) to directly change modes, if desired.
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
			print('IF YOU WAIT A FEW SECONDS BEFORE CONTROLLING, IT"S LIKE THE OBJECT SINKS???')
			print('Instead...lets do a teleport effect here - dissolve out and reappear in the PREM-7')
			#if not grabbed_object:
				#return
			#if grabbed_object.is_stepladder or grabbed_object.is_rocketship:
				#return
			#if pressed and grab_timer.time_left == 0.0:
				#control_object()
				#PREM_7.ctrl_anim.play("RESET")
				#PREM_7.ctrl_anim.play("control_down")
			#else:
				#pass


		if event.keycode == KEY_Z:
			if pressed:
				if shifting_object_active:
					z_rotate_mode = true
			else:
				z_rotate_mode = false



##---------------------------------------##
##------------GAME MECHANICS-------------##
##---------------------------------------##

func _on_action_key(status: String):
	if status == "down":
		if extracting_object_active:
			extraction_started = true
			control_timer.start(extract_time)
			PREM_7.ctrl_anim.play("activate")
	if status == "up":
		if extraction_started:
			PREM_7.ctrl_anim.play_backwards("activate")
			extraction_started = false
			control_timer.stop()

func _on_extract_key(down: bool) -> void:
	if fusing_object_active:
		return
	if grabbed_object.is_stepladder or grabbed_object.is_rocketship:
		return
		
	desired_pitch = 0
	
	if down:
		extracting_object_active =! extracting_object_active
		
	if extracting_object_active:
		#grabbed_object.object_body.scale = Vector3(0.25, 0.25, 0.25)

		#grabbed_object.visible = false
		PREM_7.ctrl_anim.play("extract")
		grabbed_object.is_extracting = true
		#PREM_7.machine_info.scale = Vector3(1.0, 1.0, 1.0)
		PREM_7.machine_info.visible = true
		grabbed_object.extract_active = true
		activate_extraction_data()
		#module = PREM_7.component_module.get_parent()
		#power = PREM_7.component_power.get_parent()
		#mass = PREM_7.component_mass.get_parent()
		#lift = PREM_7.component_lift.get_parent()
		grabbed_object.manipulation_mode('Active')
		var count = current_extraction_data.size()
		for i in range(count):
			scroll_extraction_data('DOWN')

		right_mouse_down = false
		handle_object('pressed')
		print('Start Extracting - Make all other objects invisible?')
		#grabbed_target_position.x -= 10
	else:
		selected_component_mesh.position = selected_component_pos
		PREM_7.ctrl_anim.play_backwards("extract")
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
		distance_factor = 0

func grab_object():
	var children = grabbed_object.get_children()
	for child in children:
		if child is CollisionShape3D:
			child.disabled = true
	grabbed_object.extract_body = grabbed_object.object_body.duplicate()
	grabbed_object.extract_body.position = Vector3(0.0, -0.25, 0.0)
	grabbed_object.extract_body.scale = Vector3.ZERO
	PREM_7.control_position.add_child(grabbed_object.extract_body)
	print('Grab')
	extracting_object_active = false
	fusing_object_active = false
	HUD.reticle.visible = false
	mouse_speed = base_mouse_speed / 100.0 * 15.0
	pitch_max = grab_pitch_max
	object_is_grabbed = true
	grabbed_initial_rotation = rotation_degrees
	await get_tree().create_timer(0.05).timeout
	for child in children:
		if child is CollisionShape3D:
			child.disabled = false

func release_object():
	var children = grabbed_object.get_children()
	for child in children:
		if child is CollisionShape3D:
			child.disabled = false
	grabbed_object.object_body.scale = Vector3.ONE
	PREM_7.machine_info.scale = Vector3.ZERO
	PREM_7.machine_info.visible = false
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
	grabbed_object.is_grabbed = false
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

func control_object():
	if grabbed_object:
		grabbed_object.is_controlled = true
		controlled_object = grabbed_object
		PREM_7.controlled_object = grabbed_object
		grabbed_object.reparent(PREM_7.object_inventory)
		grabbed_object.collision_layer = 0
		grabbed_object.collision_mask = 0
		grabbed_object.scale_object(grabbed_object.object_body, 0.25, 0.25, 0.25, 0.0, 0.15)
		grabbed_object.scale_object(grabbed_object.glow_body, 0.25, 0.25, 0.25, 0.0, 0.15)
		await get_tree().create_timer(0.15).timeout
		grab_object()

func fuse_mode_active():
	print("add some logic here...release object but keep it as 'fused object' until the object player is fusing to is selected...or something like that?")

func handle_pitch_and_yaw(time):
	if grabbed_object:
		var y = position.y
		var min_y = 2.0
		var max_y = 10.0

		# Calculate blend factor (0 near ground, 1 when high in air)
		var t = clamp((y - min_y) / (max_y - min_y), 0.0, 1.0)
		t = smoothstep(min_y, max_y, y)

		# Interpolate between restricted and full downward pitch
		var clamped_pitch_min = deg_to_rad(-25)
		pitch_min = lerp(clamped_pitch_min, base_pitch_min + 0.25, t)
	else:
		pitch_min = base_pitch_min

	desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
	yaw = lerp(yaw, desired_yaw, smoothing)
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
		
		if result.collider is RigidBody3D and not result.collider.is_rocketship:
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
	distance_factor = 0


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

func activate_extraction_data():
	var obj_name = grabbed_object.name
	if not object_data.has(obj_name):
		print("No component data found for", obj_name)
		current_extraction_data = []
		return

	current_object_json = object_data[obj_name]
	current_extraction_data = current_object_json.get("components", [])
	current_component_index = 0

	# machine-level labels
	PREM_7.machine_name.text = current_object_json.get("name", "Unknown Object")
	PREM_7.machine_desc.text = current_object_json.get("description", "")
	extraction_scale = current_object_json.get("scale", 0.0)

	update_component_display()


func scroll_extraction_data(dir):
	if extraction_recently_completed:
		return

	if current_extraction_data.is_empty():
		return

	selected_component_mesh.position = selected_component_pos
	selected_component_mesh.scale = Vector3(comp_scale_x, comp_scale_y, comp_scale_z)
	_on_action_key('up')

	print('working?')
	selected_component_mesh = null
	selected_component_col = null

	if dir == "UP":
		current_component_index -= 1
	elif dir == "DOWN":
		current_component_index += 1

	var count = current_extraction_data.size()
	current_component_index = (current_component_index + count) % count

	update_component_display()

func update_component_display():
	if current_extraction_data.is_empty():
		# Clear panel if you want, or just bail.
		PREM_7.component_name.text = ""
		PREM_7.component_stars.text = ""
		PREM_7.component_module.text = ""
		PREM_7.component_power.text = ""
		PREM_7.component_mass.text = ""
		PREM_7.component_lift.text = ""
		return

	var comp: Dictionary = current_extraction_data[current_component_index]

	# ---- UI: one component only ----
	PREM_7.component_name.text  = comp.get("name", "??")
	PREM_7.component_stars.text = "★".repeat(int(comp.get("stars", 0)))
	
	selected_component_scale = comp.get("scale", 0)

	# Use your new fields; fall back to old ones if missing.
	PREM_7.component_module.text = str(comp.get("module", comp.get("fit", "")))
	PREM_7.component_power.text  = str(comp.get("power",  comp.get("life", 0)))
	PREM_7.component_mass.text   = str(comp.get("mass",   comp.get("weight", 0)))
	PREM_7.component_lift.text   = str(comp.get("lift",   comp.get("durability", 0)))

	# ---- Selection: match CollisionShape3D "<Name>_Shape" ----
	var target_id := _normalize_id(comp.get("name", ""))  # "Control Panel" -> "controlpanel"

	for child in grabbed_object.get_children():
		if child is CollisionShape3D:
			var base := _base_from_shape(child.name) 
			if _normalize_id(base) == target_id:
				selected_component_col = child
				selected_component_col.name = base
				break

	# Highlight meshes under Body/object_body by base name
	var body_in_use
	if selected_component_col.name != "":
		if grabbed_object.extract_body:
			body_in_use = grabbed_object.extract_body
		else:
			body_in_use = grabbed_object.object_body
		for mesh in body_in_use.get_children():
			if mesh is MeshInstance3D:
				if mesh.name == selected_component_col.name:
					grabbed_object.set_extract_glow(mesh, "Selected")
					selected_component_mesh = mesh
					selected_component_pos = mesh.position
					comp_scale_x = selected_component_mesh.scale.x
					comp_scale_y = selected_component_mesh.scale.y
					comp_scale_z = selected_component_mesh.scale.z
				else:
					grabbed_object.set_extract_glow(mesh, "Deselected")
	else:
		# No match
		for mesh in body_in_use.get_children():
			if mesh is MeshInstance3D:
				grabbed_object.set_extract_glow(mesh, "Deselected")
		print("No matching CollisionShape3D for component:", comp.get("name", "??"))


func _normalize_id(s: String) -> String:
	return s.replace(" ", "").to_lower()

func _base_from_shape(name: String) -> String:
	if name.ends_with("_Shape"):
		return name.substr(0, name.length() - "_Shape".length())
	return name

func extract_component(mesh, col):
	
	var inventory = PREM_7.object_inventory
	var material: ShaderMaterial = ShaderMaterial.new()
	var HOLOGRAM := preload("res://Shaders/hologram.gdshader")
	material.shader = HOLOGRAM
	
	inventory.scale = Vector3.ZERO
	inventory.position.y = 0.0

	for child in inventory.get_children():
		var surface_count = child.mesh.get_surface_count()
		for i in range(surface_count):
			child.set_surface_override_material(i, material)

	material.set_shader_parameter("alpha_multiplier", 0.0)

	var new_mesh = mesh.duplicate()
	new_mesh.name = mesh.name
	
	var xtra = 1.75
	var s = extraction_scale
	
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

	new_mesh.scale = Vector3(s / xtra, s / xtra, s / xtra)

	mesh.get_parent().remove_child(mesh)
	mesh.queue_free()
	mesh = null

	inventory.add_child(new_mesh)

	new_mesh.position = Vector3.ZERO
	#new_mesh.rotation_degrees = Vector3(0, new_mesh.rotation_degrees.y + 28, 0)
	
	col.get_parent().remove_child(col)
	col.queue_free()
	col = null

	PREM_7.holo_anim.play("spin_hologram")
	
	extraction_recently_completed = true
	

func complete_extraction():
	print('uhhhh')
	pass
