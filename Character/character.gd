extends CharacterBody3D
class_name character

const is_character: bool = true
var start_day: bool = false

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var extract_anim: AnimationPlayer = $Extract_Animation
@onready var camera: Camera3D = $Camera3D
@onready var grabbed_container: Node3D = $Camera3D/Grabbed_Container
@onready var PREM_7: Node3D = $"Camera3D/PREM-7"
@onready var hud_reticle: Control = $HUD.hud_reticle
@onready var char_obj_shape: CollisionShape3D
@onready var beam: Node3D = PREM_7.beam
@onready var beam_mesh: Node3D = PREM_7.beam_mesh
@onready var beam_shader_mat := beam_mesh.get_active_material(0) as ShaderMaterial

var colliding_with_assembly_object: bool = false
var assembly_object_mass: float
var player_moving_forward: bool = false

var assembly_component_selection: bool = false

# Moving to physics process
var desired_direction := Vector3.ZERO
var desired_velocity := Vector3.ZERO
var movement_resistance: float = 1.0

var glow_color: Color

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


var floor_y: float = -1.5     # The floor level (adjust as needed)
var max_y: float = 30.0       # The maximum Y allowed (adjust as needed)
var base_pitch_factor: float = 3
#var pitch_factor: float = base_pitch_factor # How much camera pitch affects the Y offset

var prem7_decay_speed: float = 2.5     # Speed at which the rotation offset decays.
var mouse_speed_threshold: float = 2.0    # Mouse relative motion threshold below which decay occurs.
var last_mouse_speed: float = 0.0         # Latest mouse movement magnitude.
var last_mouse_time: float = 0.0          # Timestamp of the last mouse motion event.

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
var grab_pitch_max: float = 1.0
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

var orbit_radius: float = 7.0
var target_orbit_radius: float = orbit_radius
var orbit_angle: float = 0.0  # Radians
var orbit_speed: float = 1.0  # Speed multiplier
var input_direction_x: float = 0.0
var input_direction_z: float = 0.0
var grabbed_pos_set: bool = false






func _ready() -> void:
	print('General To Do List:')
	print('------ ALWAYS MAKE SURE THINGS WORK ON BOTH SCREENS ------')
	print('SUSPEND Changes')
	print('EXTRACT Changes')
	print('KEY_R: Reset Values (Which Ones?)')
	print('Right Click: SHIFT - Click and drag to rotate object, hold CTRL to rotate on Z axis. If object is suspended, WASD keys move object Up/Left/Down/Right while Shifting')
	print('KEY_Q: SUSPEND - Press Once to Suspend Object in Place - Press again to remove Suspension [Make the freeze JUICY]')
	print('KEY_E: EXTRACT - Press Once to Begin Extraction Process - Press again to Extract Selected Component [Make the Snap JUICY]')
	print('KEY_F: FUSE - Press & Hold to initiate Fuse process - 3, 2, 1 [Make the Snap JUICY]')

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Store the original rotation of PREM-7.
	prem7_original_rotation = PREM_7.rotation


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

	if grabbed_object:
		if not grabbed_object.is_suspended:
			if vertical > 0:
				distance_from_character = lerp(distance_from_character, 5.0, delta * 2.5)  # Closer
			elif vertical < 0:
				distance_from_character = lerp(distance_from_character, 10.0, delta * 2.5)  # Further
			else:
				distance_from_character = lerp(distance_from_character, 7.0, delta * 2.0)  # Neutral
			# Apply horizontal sway when strafing
			if horizontal != 0:
				var camera_right = camera.global_transform.basis.x.normalized()
				object_sway_offset.x -= horizontal * 1.75 * screen_res_sway_multiplier

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
	update_grabbed_object_physics(delta)


var _last_grabbed_pos := Vector3.ZERO

func _process(delta: float) -> void:
	
	if grabbed_object:
		var current_pos = grabbed_object.global_transform.origin
		var delta_pos = current_pos - _last_grabbed_pos
		var velocity_vec = delta_pos / delta      # world-space directional velocity
		_last_grabbed_pos = current_pos

		# if you only care about direction:
		var direction = delta_pos.normalized()

		print("Velocity:", velocity_vec)
		print("Direction:", direction)

	
	if abs(delta - previous_delta) > delta_threshold:
		screen_res_sway_multiplier = 55.0 * delta
		previous_delta = delta
		screen_resolution_set = true
		print("Updated sway multiplier: ", screen_res_sway_multiplier)
	
	# Update jetpack thrust, hover, ceiling logic
	handle_jetpack_logic(delta)

	# Handle grounded/airborne vertical velocity
	update_vertical_velocity()
	
	if scroll_cooldown > 0.0:
		scroll_cooldown -= delta

	handle_pitch_and_yaw(delta)

	#_push_away_rigid_bodies()
	move_and_slide()

	# PREM-7 mouse decay effect
	handle_prem7_decay(delta)

	# Update HUD Reticle target and color
	update_reticle_targeting()

	# Update grabbed object sway
	if grabbed_object:
		grabbed_object.rotation_degrees = grabbed_rotation
		var z_offset = abs((grabbed_object.position.z - 3.0) / 10.0)
		if grabbed_object.is_suspended:
			if char_obj_shape:
				print("Clearing Char Obj Shape: ", char_obj_shape)
				clear_char_obj_shape()
			grabbed_object.gravity_scale = 0.0
			grabbed_object.position = grabbed_object.position.lerp(grabbed_target_position, delta * 0.5)
			return

		if not shifting_object_active:
			if z_offset >= 0.95 and z_offset <= 1.05:
				grabbed_pos_set = true
			if not grabbed_pos_set:
				prem7_rotation_offset.y = lerp(prem7_rotation_offset.y, -grabbed_object.position.x / 4.5 / (z_offset * 1.25), delta * 25.0)
				prem7_rotation_offset.x = lerp(prem7_rotation_offset.x, grabbed_object.position.y / 6.0 / z_offset, delta * 25.0)
			elif grabbed_pos_set:
				prem7_rotation_offset.y = lerp(prem7_rotation_offset.y, -grabbed_object.position.x / 4.5 / (z_offset * 1.25), delta * 50.0)
				prem7_rotation_offset.x = lerp(prem7_rotation_offset.x, grabbed_object.position.y / 6.0 / z_offset, delta * 50.0)
			object_sway_offset.x -= lerp(object_sway_offset.x, current_mouse_speed_x * object_sway_strength_x, 1.0)
			object_sway_offset.y -= lerp(object_sway_offset.y, current_mouse_speed_y * object_sway_strength_y, 1.0)
			object_sway_offset.x = clamp(object_sway_offset.x, -1.0, 1.0) 
			object_sway_offset.y = clamp(object_sway_offset.y, -2.0, 2.0)
			update_grabbed_object_sway(delta)

		if grabbed_object.is_being_extracted:
			control_object('released')
	if extracting_object_active:
		desired_pitch = clamp(desired_pitch, 0.0, 0.35)
		if assembly_component_selection:
			var yaw_range = deg_to_rad(30.0)
			desired_yaw = clamp(desired_yaw, extracting_yaw - yaw_range, extracting_yaw + yaw_range)
		else:
			desired_yaw = extracting_yaw


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
				else:
					grab_object()
					PREM_7.trig_anim.play("trigger_release")
					PREM_7.trig_anim.play("RESET")

		elif event.button_index == MOUSE_BUTTON_RIGHT and grabbed_object:
			if not middle_mouse_down and not left_mouse_down:
				if event.is_pressed():
					control_object('pressed')
				else:
					control_object('released')

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if scroll_cooldown <= 0.0 and not middle_mouse_down and not right_mouse_down and not left_mouse_down:
				print('cycling up')
				cycle_mode_direction(true)
				scroll_cooldown = scroll_cooldown_duration
			if right_mouse_down and shifting_object_active:
				if grabbed_target_position.y <= max_y:
					if grabbed_object.is_suspended:
						print('***Move Camera with this***')
						grabbed_target_position.y += 0.1


		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if scroll_cooldown <= 0.0 and not middle_mouse_down and not right_mouse_down and not left_mouse_down:
				print('cycling down')
				cycle_mode_direction(false)
				scroll_cooldown = scroll_cooldown_duration
			if right_mouse_down and shifting_object_active:
				if grabbed_target_position.y >= 0.5:
					if grabbed_object.is_suspended:
						print('***Move Camera with this***')
						grabbed_target_position.y -= 0.1


		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if not right_mouse_down and not left_mouse_down:
				if event.is_pressed():
					middle_mouse_down = true
					PREM_7.mode_anim.play("RESET")
					PREM_7.mode_anim.play("shift_mode_down")
					print("Object is being inspected!")
					print('Add hologram tablet above PREM-7 that shoots out of top opening')
					print('THEN, allow player to scroll through different inspection menus for object by scrolling with wheel')
					inspecting_object_active = true
				if not event.is_pressed():
					middle_mouse_down = false
					PREM_7.mode_anim.play("RESET")
					PREM_7.mode_anim.play("shift_mode_up")
					print("Object is no longer being inspected!")
					inspecting_object_active = false

	# Process Mouse Motion events.
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			
			var input_strength_x = event.relative.x
			var speed_factor_x = clamp(abs(input_strength_x), 0.0, 1.0)  # 0 at slow, 1 at fast
			var resistance_x = lerp(1.0, 0.3, speed_factor_x)  # more resistance at high speed
			
			var input_strength_y = event.relative.y
			var speed_factor_y = clamp(abs(input_strength_y), 0.0, 0.5)
			var resistance_y = lerp(1.0, 0.3, speed_factor_y)

			var max_offset = deg_to_rad(10.0)
			var max_delta: float = 0.15 * screen_res_sway_multiplier / movement_resistance #max look speed
			var dx = clamp(event.relative.x * mouse_speed, -max_delta, max_delta)
			var dy = clamp(event.relative.y * mouse_speed, -max_delta, max_delta)

			current_mouse_speed_x = event.relative.x
			current_mouse_speed_y = event.relative.y

			if not shifting_object_active:
				desired_yaw -= dx
				desired_pitch -= dy
				desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
				if grabbed_object:
					return
				else:
					prem7_rotation_offset.y += input_strength_x * prem7_rotation_speed * resistance_x
					prem7_rotation_offset.x += input_strength_y * prem7_rotation_speed * resistance_y
					prem7_rotation_offset.x = clamp(prem7_rotation_offset.x, -max_offset, max_offset)
					prem7_rotation_offset.y = clamp(prem7_rotation_offset.y, -max_offset, max_offset)
			else:
				if grabbed_object:
					shift_it = true
					prem7_rotation_offset.y -= input_strength_x * prem7_rotation_speed * resistance_x / 15.0
					if z_rotate_mode:
						print('in z rotate mode')
						grabbed_rotation.z += event.relative.x * rotation_sensitivity / 3
						var local_forward: Vector3 = grabbed_object.global_transform.basis.z
						grabbed_object.rotate(local_forward, deg_to_rad(event.relative.x * mouse_speed * 0))
					else:
						prem7_rotation_offset.x -= input_strength_y * prem7_rotation_speed * resistance_y / 15.0
						grabbed_rotation.y += event.relative.x * rotation_sensitivity / 3
						grabbed_rotation.x += event.relative.y * rotation_sensitivity / 3
						#prem7_rotation_offset.x = clamp(prem7_rotation_offset.x, -max_offset, max_offset)
						#prem7_rotation_offset.y = clamp(prem7_rotation_offset.y, -max_offset, max_offset)
						#PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset
						#horizontal_delta = event.relative.x * mouse_speed * 10
						#vertical_delta = event.relative.y * mouse_speed * 10 
						#grabbed_object.rotate_y(deg_to_rad(horizontal_delta))
						#var local_right: Vector3 = grabbed_object.global_transform.basis.x
						#grabbed_object.rotate(local_right, deg_to_rad(vertical_delta))

	# Process Keyboard events.
	if event is InputEventKey:
		var pressed = event.is_pressed()
		
		if event.keycode == KEY_Q:
			if not grabbed_object:
				return
			if event.pressed:
				print('add SUSPEND visuals')
				print('Change the shift movement (left, right, forward, backward) to match what the character is seeing vs. actual position')
			if not event.pressed:
				beam_lock = false
				grabbed_object.is_suspended =! grabbed_object.is_suspended
				grabbed_object.object_rotation = grabbed_object.rotation_degrees
				grab_object()
				

		if event.keycode == KEY_E:
			if not grabbed_object:
				return
			if event.pressed:
				print('add EXTRACT visuals')

		if event.keycode == KEY_F:
			if not grabbed_object:
				return
			if event.pressed:
				print('add FUSE visuals')

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
			print('UP!')
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.z -= 0.25
					print('This should move forward based on direction of object face')
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			move_input["down"] = pressed
			print('DOWN!')
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.z += 0.25
					print('This should move backward based on direction of object face')
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			move_input["left"] = pressed
			print('LEFT!')
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.x -= 0.25
					print('***Move Camera with this*** -- Maybe use look_at?')
					print('This should move left based on direction of object face')
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			move_input["right"] = pressed
			print('RIGHT!')
			if shifting_object_active and pressed:
				if grabbed_object and grabbed_object.is_suspended:
					grabbed_target_position.x += 0.25
					print('***Move Camera with this*** -- Maybe use look_at?')
					print('This should move right based on direction of object face')

			#print("Current Player Position: ", position)

		# Process number keys (1-4) to directly change modes, if desired.
		if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
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
						PREM_7.mode_anim.play("RESET")
						PREM_7.mode_anim.play("shift_mode_down")
						pending_mode = new_mode
						pending_mode_key = event.keycode
				elif not pressed:
					if pending_mode != "" and event.keycode == pending_mode_key:
						PREM_7.mode_anim.play("RESET")
						PREM_7.mode_anim.play("shift_mode_up")
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
				movement_speed = base_movement_speed * 2
				mouse_speed = base_mouse_speed * 2
				rotation_sensitivity = base_rotation_sensitivity * 2
				jetpack_accel_max = jetpack_accel_max * 2
				jetpack_thrust_max = jetpack_thrust_max * 2
				current_jetpack_accel = current_jetpack_accel * 2
				current_jetpack_thrust = current_jetpack_thrust * 2
			else:
				movement_speed = base_movement_speed
				mouse_speed = base_mouse_speed
				rotation_sensitivity = base_rotation_sensitivity
				jetpack_accel_max = jetpack_accel_max / 2
				jetpack_thrust_max = jetpack_thrust_max / 2
				current_jetpack_accel = current_jetpack_accel / 2
				current_jetpack_thrust = current_jetpack_thrust / 2

		if event.keycode == KEY_CTRL:
			if pressed:
				z_rotate_mode = true
			else:
				z_rotate_mode = false

		if event.keycode == KEY_R and pressed and not event.is_echo():
			print('RESETTING')
			desired_pitch = 0
			if grabbed_object:
				var current_rot = grabbed_object.rotation_degrees
				grabbed_rotation.x = shortest_angle_diff_value(-current_rot.x, 0)
				grabbed_rotation.y = shortest_angle_diff_value(-current_rot.y, 0)
				grabbed_rotation.z = shortest_angle_diff_value(-current_rot.z, 0)

				pitch_min = grab_pitch_min
				pitch_max = grab_pitch_max
				distance_factor = 0
			else:
				pitch_min = base_pitch_min
				pitch_max = base_pitch_max
				distance_factor = 0


##---------------------------------------##
##------------GAME MECHANICS-------------##
##---------------------------------------##



func grab_object():
	
	left_mouse_down = false
	PREM_7.trig_anim.play("RESET")
	PREM_7.trig_anim.play("trigger_pull")

	if grabbed_object:  # An object is already grabbed; release it.
		print('Release')
		orbit_radius = target_orbit_radius
		movement_resistance = 1.0
		grabbed_pos_set = false
		initial_grab = false
		clear_char_obj_shape()
		PREM_7.retract_beam()
		grabbed_object.collision_shape.disabled = false
		grabbed_object.lock_rotation = false
		print('----ALERT ALERT ALERT ALERT -----')
		print('CAN WE CHANGE THESE (angular/linear velocity) TO DAMPEN INSTEAD OF STRAIGHT TO ZERO?????????')
		print('----ALERT ALERT ALERT ALERT -----')
		grabbed_object.angular_velocity = lerp(grabbed_object.angular_velocity, Vector3.ZERO, 1.0)
		grabbed_object.linear_velocity = lerp(grabbed_object.linear_velocity, Vector3.ZERO, 1.0)
		#grabbed_object.angular_velocity = Vector3.ZERO
		#grabbed_object.linear_velocity = Vector3.ZERO
		grabbed_object.set_outline('RELEASE', Color.WHITE, 0.0)
		hud_reticle.visible = true
		object_sway_strength_x = object_sway_base_x
		object_sway_strength_y = object_sway_base_y
		distance_factor = 0.0
		grabbed_distance = 0.0
		grabbed_object.is_grabbed = false
		grabbed_object.recently_grabbed = true
		grabbed_object.is_released = true
		beam_lock = false
		if grabbed_object.is_suspended:
			grabbed_rotation = grabbed_object.global_rotation_degrees
			grabbed_object.gravity_scale = 0.0
		else:
			grabbed_object.gravity_scale = 1.75
		suspending_object_active = false
		object_is_grabbed = false
		grabbed_object = null
		return
	else: #Grab a new object
		print('Grab')
		extracting_object_active = false
		if assembly_component_selection:
			jetpack_active = false
			vertical_velocity = 0.0
			hover_lock = false
			assembly_component_selection = false
		var space_state = get_world_3d().direct_space_state
		var from = camera.global_transform.origin
		var to = from + (-camera.global_transform.basis.z) * 100.0
		var query = PhysicsRayQueryParameters3D.new()
		query.from = from
		query.to = to
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result:
			var target_body = result.collider
			if target_body is RigidBody3D and not target_body.is_rocketship:
				grabbed_object = target_body
				grabbed_object.angular_velocity = Vector3.ZERO
				grabbed_object.is_grabbed = true
				PREM_7.cast_beam()
				movement_resistance = 2.0
				var object_children = grabbed_object.get_children()
				for child in object_children:
					if child is MeshInstance3D:
						grabbed_mesh = child
					elif child is CollisionShape3D:
						grabbed_collision = child
				hud_reticle.visible = false
				match current_mode:
					MODE_1:
						glow_color = MODE_1_COLOR
					MODE_2:
						glow_color = MODE_2_COLOR
					MODE_3:
						glow_color = MODE_3_COLOR
					MODE_4:
						glow_color = MODE_4_COLOR
				grabbed_object.set_outline('GRAB', glow_color, 0.0)
				grabbed_initial_mouse = get_viewport().get_mouse_position()
				grabbed_distance = (grabbed_object.global_transform.origin - camera.global_transform.origin).length()
				object_is_grabbed = true
				grabbed_object.gravity_scale = 1.75
				grabbed_object.is_touching_ground = false
				grabbed_target_position = grabbed_object.position
				if grabbed_object.is_suspended:
					beam_lock = true
					print('When grabbing a suspended object, this needs to be a more gradual movement in terms of both moving towards the object and the direction in which you are looking')
					grabbed_rotation = grabbed_object.global_rotation_degrees
					grabbed_object.gravity_scale = 0.0
					suspending_object_active = true
					var dir = (grabbed_object.global_transform.origin - camera.global_transform.origin)
					orbit_angle = atan2(dir.x, dir.z) + PI
					return
				suspending_object_active = false
				grabbed_object.gravity_scale = 1.75
				grabbed_initial_rotation = rotation_degrees
				grabbed_global_rotation = grabbed_object.rotation_degrees
				grabbed_rotation.x = shortest_angle_diff_value(grabbed_initial_rotation.x, grabbed_global_rotation.x)
				var sanitized_initial_y = wrapf(grabbed_initial_rotation.y, -180.0, 180.0)
				var sanitized_global_y = wrapf(grabbed_global_rotation.y, -180.0, 180.0)
				grabbed_rotation.y = shortest_angle_diff_value(sanitized_initial_y, sanitized_global_y)
				grabbed_rotation.y = shortest_angle_diff_value(grabbed_initial_rotation.y, grabbed_global_rotation.y)
				grabbed_rotation.z = shortest_angle_diff_value(grabbed_initial_rotation.z, grabbed_global_rotation.z)
				print('how are you working???')
				grabbed_object.collision_shape.disabled = true
				_last_grabbed_pos = grabbed_object.global_transform.origin
				create_char_obj_shape(grabbed_object)

			else:
				print("Object hit, but no MeshInstance3D child found!")
		else:
			print("Object is not RigidBody3D")
			return

func control_object(status):
	if status == 'pressed':
		var glow_opacity: float
		PREM_7.trig_anim.play("RESET")
		PREM_7.trig_anim.play("trigger_pull")
		collision_layer = 1
		right_mouse_down = true

		if current_mode == MODE_1:
			print("Begin Shifting Object")
			shifting_object_active = true
			glow_opacity = 0.5

		#elif current_mode == MODE_2:
			#print("Begin Suspending Object")
			#suspending_object_active = true
			#glow_opacity = 0.7
			#print('Things to work on for SUSPEND: ')
			#print('1. Add an additional collision layer or something here to restrict character hitting suspended object')
			#print('2. Need to be able to shift object L/R/U/D faster with SHIFT key')
			#print('3. Change the movement (left, right, forward, backward) to match what the character is seeing vs. actual position')
			#print('4. Allow for Z rotation...')

		elif current_mode == MODE_3:
			print("Extracting Assembly Parts")
			if not grabbed_object.is_assembly_component and not grabbed_object.is_stepladder:
				extracting_object_active = true
				suspending_object_active = false
				grabbed_object.is_suspended = false
				beam_lock = false
				extracting_yaw = desired_yaw
				grabbed_object.start_extraction()
				print('Things to work on for EXTRACT: ')
				print('***BUG*** Try extracting a suspended object...es no bueno ***BUG*** ')
				print('1. Instead of rotating motion, reduce alpha of main body')
				print('2. Start by highlighting one assembly component, cycle by rotating mousewheel or using A/D keys')
				print('3. As a component is highlighted, it becomes fully visible + glow state')
				print('4. Once player has decided on a component, they will then press & hold -E- to extract')
				print('5. That component snaps off and becomes the grabbed object, while the remaining body stays intact and falls to the ground')
			else:
				extract_anim.play('RESET')
				extract_anim.play("extract_negative")
			glow_opacity = 0.5

		elif current_mode == MODE_4:
			print("Begin Fusing Object")
			print('ADD FUNCTIONALITY HERE - Press & Hold for Fusion...grabbed object becomes child of object it is fusing to // objects begin to rumble and glow')
			fusing_object_active = true
			glow_opacity = 0.6

		## Set Outline Glow State AFTER Object is Grabbed
		grabbed_object.set_outline('ENHANCE', glow_color, glow_opacity)

	if status == 'released':
		PREM_7.trig_anim.play("trigger_release")
		PREM_7.trig_anim.play("RESET")
		collision_layer = 1
		right_mouse_down = false
		
		## Reset Outline Glow State BEFORE Grabbed Object is Released
		grabbed_object.set_outline('DIM', glow_color, 0.0)

		if current_mode == MODE_1:
			print("Object has been Shifted!")
			shifting_object_active = false

		#elif current_mode == MODE_2:
			#print("Object has been Suspended!")
			#grabbed_object.gravity_scale = 0.0
			#grabbed_object.is_suspended = true
			#grabbed_object.object_rotation = grabbed_object.rotation_degrees
			#grab_object()


		elif current_mode == MODE_3:
			print('***BUG*** Move Suspended Object up in air and then extract, shit goes crazyyy')
			if grabbed_object:
				if not grabbed_object.is_being_extracted and not grabbed_object.is_assembly_component:
					grabbed_object.cancel_extraction()
				else:
					if not grabbed_object.is_assembly_component:
						print("Assembly components have been Extracted!")
						grab_object()

		elif current_mode == MODE_4:
			print("Object has been Fused!")
			fusing_object_active = false

func handle_pitch_and_yaw(time):
	if grabbed_object:
		var y = position.y
		var min_y = 2.0       # Ground level threshold
		var max_y = 10.0      # Max height where full freedom kicks in

		# Calculate blend factor (0 near ground, 1 when high in air)
		var t = clamp((y - min_y) / (max_y - min_y), 0.0, 1.0)
		t = smoothstep(min_y, max_y, y)

		# Interpolate between restricted and full downward pitch
		var clamped_pitch_min = deg_to_rad(-15)
		pitch_min = lerp(clamped_pitch_min, base_pitch_min, t)
	else:
		pitch_min = base_pitch_min

	if beam_lock:
		var cam_pos = camera.global_transform.origin
		var target_pos = grabbed_object.global_transform.origin
		var dir = (target_pos - cam_pos).normalized()

		var target_yaw = atan2(-dir.x, -dir.z)
		var look_vector = (grabbed_object.global_transform.origin - camera.global_transform.origin).normalized()
		var target_pitch = asin(look_vector.y)
		target_pitch = clamp(target_pitch, deg_to_rad(-89), deg_to_rad(89))

		if initial_grab:
			snap_to_suspended_object(target_yaw, target_pitch, time)

		else:
			rotation.y = target_yaw
			camera.rotation.x = target_pitch


		pitch = target_pitch
		desired_pitch = target_pitch
		desired_yaw = target_yaw
		yaw = desired_yaw
		
		velocity.x = 0.0
		velocity.z = 0.0  # Kill all physics-based movement
		move_and_slide()  # Just to satisfy the engine
		input_direction_x = lerp(input_direction_x, 0.0, time * 5.0)
		input_direction_z = lerp(input_direction_z, 0.0, time * 5.0)

		if move_input["left"] and not shifting_object_active:
			input_direction_x -= 1.0
		if move_input["right"] and not shifting_object_active:
			input_direction_x += 1.0

		# Radial (toward/away from object)
		if move_input["up"] and not shifting_object_active:
			input_direction_z -= 1.0  # Move closer
		if move_input["down"] and not shifting_object_active:
			input_direction_z += 1.0  # Move away
		
		
		orbit_radius = clamp(orbit_radius + input_direction_z * time / 2, 5.0, 15.0)
		orbit_angle += input_direction_x * orbit_speed * time / orbit_radius
		orbit_angle = fmod(orbit_angle, TAU)
		
		print(orbit_angle)

		var obj_pos = grabbed_object.global_transform.origin
		var orbit_offset = Vector3(
			orbit_radius * sin(orbit_angle),
			0.0,
			orbit_radius * cos(orbit_angle)
		)

		global_position.x = lerp(global_position.x, obj_pos.x + orbit_offset.x, time * 5.0)
		global_position.z = lerp(global_position.z, obj_pos.z + orbit_offset.z, time * 5.0)

	if not beam_lock:
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

		grabbed_object.set_outline('UPDATE', glow_color, 0.0)

func cycle_mode_direction(forward: bool = true) -> void:
	var current_index = modes.find(current_mode)
	var new_index = (current_index + (1 if forward else -1)) % modes.size()
	if new_index < 0:
		new_index = modes.size() - 1
	change_mode(modes[new_index])
	match current_mode:
		MODE_1: hud_reticle.modulate = MODE_1_COLOR
		MODE_2: hud_reticle.modulate = MODE_2_COLOR
		MODE_3: hud_reticle.modulate = MODE_3_COLOR
		MODE_4: hud_reticle.modulate = MODE_4_COLOR

func shortest_angle_diff_value(initial_angle: float, target_angle: float) -> float:
	initial_angle = wrapf(initial_angle, -180.0, 180.0)
	target_angle = wrapf(target_angle, -180.0, 180.0)

	var diff = target_angle - initial_angle
	if diff > 180:
		diff -= 360
	elif diff < -180:
		diff += 360
	return diff

func create_char_obj_shape(grabbed_object: RigidBody3D) -> void:
	if not is_instance_valid(grabbed_object):
		return

	# Find first visible mesh
	var mesh_node: MeshInstance3D = null
	for child in grabbed_object.get_children():
		if child is MeshInstance3D and child.name != "Body":
			mesh_node = child
			break

	if mesh_node == null or mesh_node.mesh == null:
		print("No valid mesh found on grabbed object.")
		return

	# Create a more accurate collision shape from mesh
	var shape := mesh_node.mesh.create_trimesh_shape()
	if not is_instance_valid(char_obj_shape):
		char_obj_shape = CollisionShape3D.new()
		add_child(char_obj_shape)

	char_obj_shape.shape = shape
	char_obj_shape.visible = true
	char_obj_shape.debug_color = Color.RED
	char_obj_shape.scale = Vector3(0.1, 0.1, 0.1)

	var object_pos = grabbed_object.global_transform.origin
	char_obj_shape.global_transform.origin = object_pos
	char_obj_shape.visible = true
	char_obj_shape.debug_fill = true
	char_obj_shape.debug_color = Color.RED
	scale_object(char_obj_shape, 1.0, 1.0, 1.0, 0.0, 1.0)
	

func clear_char_obj_shape():
	if is_instance_valid(char_obj_shape):
		char_obj_shape.shape = null
		char_obj_shape.visible = false
		char_obj_shape = null

func handle_jetpack_logic(delta: float) -> void:
	if extracting_object_active:
		if airborne:
			if not hover_lock:
				hover_lock = true
				hover_base_y = global_position.y
				hover_bob_time = 0.0
			handle_jetpack('7', delta)
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
		var collider = result.collider
		if collider is RigidBody3D and not collider.is_rocketship:
			match current_mode:
				MODE_1: hud_reticle.modulate = MODE_1_COLOR
				MODE_2: hud_reticle.modulate = MODE_2_COLOR
				MODE_3: hud_reticle.modulate = MODE_3_COLOR
				MODE_4: hud_reticle.modulate = MODE_4_COLOR
				_: hud_reticle.modulate = Color.WHITE
		else:
			hud_reticle.modulate = Color.WHITE
	else:
		hud_reticle.modulate = Color.WHITE

func handle_prem7_decay(delta: float) -> void:
	var time_since_last = (Time.get_ticks_msec() - last_mouse_time) / 1000.0
	if last_mouse_speed < mouse_speed_threshold or time_since_last > 0.05:
		prem7_rotation_offset = prem7_rotation_offset.lerp(Vector3.ZERO, prem7_decay_speed * delta)
		PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset
		object_sway_offset.x = lerp(object_sway_offset.x, 0.0, object_sway_decay_x * delta)
		object_sway_offset.y = lerp(object_sway_offset.y, 0.0, object_sway_decay_y * delta)

func update_grabbed_object_physics(delta: float) -> void:
	if not grabbed_object:
		return
	if grabbed_object.is_suspended: 
		return
	var current_position = grabbed_object.global_transform.origin
	speed_vector = (current_position - last_position) / delta
	last_position = current_position
	grabbed_object.object_speed = speed_vector

func update_grabbed_object_sway(delta: float) -> void:
	# Apply grabbed rotation directly
	grabbed_object.rotation_degrees = grabbed_rotation
	grabbed_object.object_rotation = grabbed_object.global_rotation_degrees

	# Track camera pitch movement
	var pitch_now = camera.rotation.x
	var pitch_delta = pitch_now - previous_camera_pitch
	previous_camera_pitch = pitch_now

	# Prevent nonsense at vertical clamp angles
	var max_pitch_up = deg_to_rad(89.0)
	var max_pitch_down = deg_to_rad(-89.0)
	var clamped_pitch = clamp(pitch_now, max_pitch_down, max_pitch_up)
	var at_pitch_limit = abs(clamped_pitch - pitch_now) > 0.01

	# Adjust vertical sway strength based on pitch proximity
	var pitch_range = pitch_max - pitch_min
	var pitch_center = pitch_min + pitch_range * 0.5
	var pitch_distance = abs(pitch_now - pitch_center)
	var max_pitch_distance = pitch_range / 2.0
	var pitch_factor = 1.0 - clamp(pitch_distance / max_pitch_distance, 0.0, 1.0)


	object_sway_strength_y = object_sway_base_y * pitch_factor

	# Apply sway offsets
	var sway_x = camera.global_transform.basis.x.normalized() * object_sway_offset.x * 0.275 * screen_res_sway_multiplier
	var sway_z = Vector3.ZERO

	if abs(pitch_delta) > 0.01 and not at_pitch_limit:
		sway_z = camera.global_transform.basis.y.normalized() * -object_sway_offset.y * 0.5 * screen_res_sway_multiplier

	var sway_offset = sway_x + sway_z
	grabbed_object.global_position += sway_offset


func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var object = c.get_collider()
		if object is RigidBody3D:
			# Calculate a force direction
			var push_dir = -c.get_normal()
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - object.linear_velocity.dot(push_dir)
			
			velocity_diff_in_push_dir = max(0.0, velocity_diff_in_push_dir)
			
			const CHAR_MASS_KG = 80.0
			var mass_ratio = min(1.0, CHAR_MASS_KG / object.mass)
			push_dir.y = 0
			
			var push_force = mass_ratio * 10.0
			
			object.apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - object.global_position)


func scale_object(object, x_scale: float, y_scale: float, z_scale: float, wait_time: float, duration: float):
	await get_tree().create_timer(wait_time).timeout
	
	scale_tween = create_tween()
	
	scale_tween.tween_property(object, "scale", Vector3(x_scale, y_scale, z_scale), duration)
	
	scale_tween.set_trans(Tween.TRANS_LINEAR)
	scale_tween.set_ease(Tween.EASE_IN_OUT)


func snap_to_suspended_object(y_target, x_target, time):
	rotation.y = lerp(rotation.y, y_target, time * 15.0)
	camera.rotation.x = lerp(camera.rotation.x, x_target, time * 15.0)
	if abs(rotation.y - y_target) < 0.001 and abs(camera.rotation.x - x_target) < 0.001:
		initial_grab = false
	await get_tree().create_timer(0.25).timeout
	initial_grab = false
