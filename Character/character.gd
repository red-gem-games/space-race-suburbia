extends CharacterBody3D
class_name character

const is_character: bool = true

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var grabbed_anim: AnimationPlayer = $Grabbed_Animation
@onready var camera: Camera3D = $Camera3D
@onready var grabbed_container: Node3D = $Camera3D/Grabbed_Container
@onready var PREM_7: Node3D = $"Camera3D/PREM-7"
@onready var hud_reticle: Control = $HUD.hud_reticle
@onready var char_obj_shape: CollisionShape3D

var colliding_with_object: bool = false

var glow_color: Color

var distance_from_character: float = 6
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

var floor_y: float = -1.5     # The floor level (adjust as needed)
var max_y: float = 30.0       # The maximum Y allowed (adjust as needed)
var base_pitch_factor: float = 3
#var pitch_factor: float = base_pitch_factor # How much camera pitch affects the Y offset

var prem7_decay_speed: float = 5.0      # Speed at which the rotation offset decays.
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

var mode_1: String = "SHIFT"
var mode_2: String = "EXTRACT"
var mode_3: String = "SUSPEND"
var mode_4: String = "FUSE"
var modes = [mode_1, mode_2, mode_3, mode_4]
var current_mode: String = mode_1
var pending_mode: String = ""  # Holds the pending mode change
var pending_mode_key: int = 0  # Will store the keycode of the mode key that triggered pending_mode
var shifting_object_active: bool = false
var extracting_object_active: bool = false
var suspending_object_active: bool = false
var fusing_object_active: bool = false
var inspecting_object_active: bool = false

var pitch: float = 0.0
var pitch_set: bool = false
var base_pitch_min: float = -PI/2
var base_pitch_max: float = PI/2
var grab_pitch_min: float = -0.25
var grab_pitch_max: float = 1
var pitch_min: float = base_pitch_min
var pitch_max: float = base_pitch_max
var base_mouse_speed: float = 0.002
var mouse_speed: float = base_mouse_speed
var smoothing: float = 0.05  # Smoothing factor (0-1)
var current_mouse_speed_x: float
var current_mouse_speed_y: float

# Variables for camera rotation
var desired_yaw: float = 0.0
var desired_pitch: float = 0.0

var yaw: float = 0.0
var distance_factor: float = 0.0
var height_factor: float = 0.0
var last_y: float = 0.0
var change_rate: float = 0.05  # Adjust this value to control sensitivity
var fall_speed_factor: float = 0.0
var fall_sensitivity: float = 0.01  # You can tweak this to make pitch change more or less based on falling speed
var distance_to_ground: float

var object_sway_offset: Vector2 = Vector2.ZERO
var object_sway_decay_x: float = 15.0
var object_sway_decay_y: float = 5.0
var object_sway_base_x: float = 0.0001
var object_sway_base_y: float = 0.0005
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

var start_day: bool = false






func _ready() -> void:
	
	print('Work on F Key = freeing up use of right click')

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Store the original rotation of PREM-7.
	prem7_original_rotation = PREM_7.rotation


##----------------------------------------##
##------------PROCESS RESPONSE------------##
##----------------------------------------##


func _process(delta: float) -> void:
	
	
	if scroll_cooldown > 0.0:
		scroll_cooldown -= delta
	
	# -------------------
	# Jetpack Logic
	# -------------------
	distance_to_ground = raycast_to_ground()
	if distance_to_ground > 5.0:
		airborne = true

	# Update thrust and acceleration values
	if jetpack_active:
		handle_jetpack('1', delta)
	else:
		handle_jetpack('2', delta)
		if hover_lock:
			handle_jetpack('7', delta)
		elif current_jetpack_thrust > min_thrust_threshold:
			handle_jetpack('3', delta)

	if current_jetpack_thrust > min_thrust_threshold:
		# Actively rising
		handle_jetpack('3', delta)

	elif not is_on_floor():
		# Jetpack is no longer active, but player is airborne
		if not touching_ceiling:
			if vertical_velocity > 0:
				handle_jetpack('4', delta)
				# Clamp vertical velocity close to zero to avoid endless float
				if abs(vertical_velocity) < 0.25:
					vertical_velocity = 0.0

			else:
				# Now descending — use your hover gravity
				if distance_to_ground < 8:
					handle_jetpack('5', delta)
				else:
					handle_jetpack('6', delta)
		else:
			handle_jetpack('6', delta)
	else:
		# On the ground
		vertical_velocity = 0.0

	velocity.y = vertical_velocity

	# -------------------
	# Horizontal Movement
	# -------------------
	var vertical = 0
	var horizontal = 0

	if move_input["up"] and not move_input["down"]:
		vertical = 1
	elif move_input["down"] and not move_input["up"]:
		vertical = -1

	if move_input["right"] and not move_input["left"]:
		horizontal = 1
	elif move_input["left"] and not move_input["right"]:
		horizontal = -1

	var desired_direction = Vector3.ZERO
	if vertical != 0 or horizontal != 0:
		desired_direction = ((-transform.basis.z) * vertical + (transform.basis.x) * horizontal).normalized()

	var desired_velocity = desired_direction * movement_speed
	current_velocity = current_velocity.lerp(desired_velocity, smoothing)
	velocity.x = current_velocity.x
	velocity.z = current_velocity.z

	move_and_slide()

	# -------------------
	# Landing Check
	# -------------------
	if is_on_floor() and not grounded:
		vertical_velocity = 0.0
		airborne = false
		grounded = true

	# -------------------
	# Grounded vs. Airborne Settings
	# -------------------
	if grounded:
		if grabbed_object:
			pass
			#pitch_min = grab_pitch_min + distance_factor / 1.5
			#pitch_max = grab_pitch_max - height_factor
		else:
			if not pitch_set:
				pitch_min = base_pitch_min
				pitch_max = base_pitch_max
				pitch_set = true
		if not start_day:
			print("When's liftoff scheduled for, again? Let's get started.")
			print("Change color of 'SUSPEND' - Blue doesn't work because of the sky")
			$Phantom_Body/CollisionShape3D.disabled = false
			start_day = true

	if airborne:
		grounded = false
		var delta_y = position.y - last_y
		height_factor += delta_y * change_rate
		height_factor = clamp(height_factor, 0.0, 1.0)
		
		
		if position.y > ceiling_threshold:
			touching_ceiling = true
		elif position.y < ceiling_threshold:
			touching_ceiling = false

		var fall_speed_factor = 0.0
		if vertical_velocity > 0:
			fall_speed_factor = -vertical_velocity * fall_sensitivity
		else:
			fall_speed_factor = -vertical_velocity * fall_sensitivity + distance_factor / 2

		if grabbed_object:
			pass
			#pitch_min = grab_pitch_min + distance_factor - height_factor + fall_speed_factor
			#pitch_max = grab_pitch_max - height_factor + fall_speed_factor
		else:
			pitch_min = base_pitch_min
			pitch_max = base_pitch_max
		if not touching_ceiling:
			last_y = position.y



	# -------------------
	# Reticle Targeting
	# -------------------
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
		if collider is RigidBody3D and not collider.is_rocketship and not collider.phantom_body:
			match current_mode:
				mode_1: hud_reticle.modulate = Color.GREEN
				mode_2: hud_reticle.modulate = Color.RED
				mode_3: hud_reticle.modulate = Color.AQUA
				mode_4: hud_reticle.modulate = Color.PURPLE
				_: hud_reticle.modulate = Color.WHITE
		else:
			hud_reticle.modulate = Color.WHITE
	elif not result:
		hud_reticle.modulate = Color.WHITE
	# -------------------
	# Camera Smoothing
	# -------------------
	
	desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
	yaw = lerp(yaw, desired_yaw, smoothing)
	pitch = lerp(pitch, desired_pitch, smoothing)
	rotation.y = yaw
	camera.rotation.x = pitch

	# -------------------
	# PREM-7 Mouse Decay
	# -------------------
	var time_since_last = (Time.get_ticks_msec() - last_mouse_time) / 1000.0
	if last_mouse_speed < mouse_speed_threshold or time_since_last > 0.05:
		prem7_rotation_offset = prem7_rotation_offset.lerp(Vector3.ZERO, prem7_decay_speed * delta)
		PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset
		object_sway_offset.x = lerp(object_sway_offset.x, 0.0, object_sway_decay_x * delta)
		object_sway_offset.y = lerp(object_sway_offset.y, 0.0, object_sway_decay_y * delta)



	# -------------------
	# Object Grabbing Logic
	# -------------------
	if grabbed_object:
		match current_mode:
			mode_1: hud_reticle.modulate = Color.GREEN
			mode_2: hud_reticle.modulate = Color.RED
			mode_3: hud_reticle.modulate = Color.AQUA
			mode_4: hud_reticle.modulate = Color.PURPLE
		
		## Collision Logic ##
		var current_position = grabbed_object.global_transform.origin
		speed_vector = (current_position - last_position) / delta
		last_position = current_position
		grabbed_object.object_speed = speed_vector
		
		## Sway Logic ##
		var pitch_range = pitch_max - pitch_min
		var pitch_center = pitch_min + pitch_range / 2.0
		var pitch_distance = abs(camera.rotation.x - pitch_center)
		var max_pitch_distance = pitch_range / 2.0
		var pitch_factor = 1.0 - clamp(pitch_distance / max_pitch_distance, 0.0, 1.0)
		object_sway_strength_y = object_sway_base_y * pitch_factor
		var pitch_offset = clamp(camera.rotation.x, -0.25, 1)
		var target_y = grabbed_initial_position.y
		var sway_x = camera.global_transform.basis.x.normalized() * object_sway_offset.x
		var sway_z = camera.global_transform.basis.y.normalized() * object_sway_offset.y
		var sway_offset = sway_x + sway_z
		target_y = clamp(target_y, floor_y, max_y)
		grabbed_object.position.y = target_y
		grabbed_object.global_position += sway_offset
		grabbed_object.rotation_degrees = grabbed_rotation
		grabbed_object.object_rotation = grabbed_object.global_rotation_degrees

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

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if scroll_cooldown <= 0.0 and not middle_mouse_down and not right_mouse_down and not left_mouse_down:
				print('cycling down')
				cycle_mode_direction(false)
				scroll_cooldown = scroll_cooldown_duration


		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if not right_mouse_down and not left_mouse_down:
				if event.is_pressed():
					middle_mouse_down = true
					PREM_7.mode_anim.play("RESET")
					PREM_7.mode_anim.play("shift_mode_down")
					print("Object is being inspected!")
					print('Add hologram tablet above PREM-7 that shoots out of top opening')
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
			prem7_rotation_offset.y -= event.relative.x * prem7_rotation_speed
			prem7_rotation_offset.x -= event.relative.y * prem7_rotation_speed
			var max_offset = deg_to_rad(10.0)
			prem7_rotation_offset.x = clamp(prem7_rotation_offset.x, -max_offset, max_offset)
			prem7_rotation_offset.y = clamp(prem7_rotation_offset.y, -max_offset, max_offset)
			PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset
			var max_delta: float = 0.1  # You can tweak this (in radians); 0.05 ≈ 2.86 degrees
			var dx = clamp(event.relative.x * mouse_speed, -max_delta, max_delta)
			var dy = clamp(event.relative.y * mouse_speed, -max_delta, max_delta)

			current_mouse_speed_x = event.relative.x
			current_mouse_speed_y = event.relative.y
#
			#if grabbed_object:
				#if grabbed_object.is_touching_rocket:
					#print(grabbed_object.name, " is touching the rocketship!")
					#desired_yaw -= -dx * 1.25
					#desired_pitch -= -dy * 1.25
					#grabbed_object.is_resetting = true
					#grabbed_object.is_touching_rocket = false
					#return

			if not shifting_object_active:
				desired_yaw -= dx
				desired_pitch -= dy
				desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
				object_sway_offset.x -= event.relative.x * object_sway_strength_x
				object_sway_offset.y -= event.relative.y * object_sway_strength_y
				object_sway_offset.x = clamp(object_sway_offset.x, -0.2, 0.2) 
				object_sway_offset.y = clamp(object_sway_offset.y, -1.75, 1.75) 
			else:
				if grabbed_object:
					if z_rotate_mode:
						grabbed_rotation.z += event.relative.x * rotation_sensitivity / 3
						var local_forward: Vector3 = grabbed_object.global_transform.basis.z
						grabbed_object.rotate(local_forward, deg_to_rad(event.relative.x * mouse_speed * 10))
					else:
						grabbed_rotation.y += event.relative.x * rotation_sensitivity / 3
						grabbed_rotation.x += event.relative.y * rotation_sensitivity / 3
						var horizontal_delta = event.relative.x * mouse_speed * 10
						var vertical_delta = event.relative.y * mouse_speed * 10 
						grabbed_object.rotate_y(deg_to_rad(horizontal_delta))
						var local_right: Vector3 = grabbed_object.global_transform.basis.x
						grabbed_object.rotate(local_right, deg_to_rad(vertical_delta))

	# Process Keyboard events.
	if event is InputEventKey:
		var pressed = event.is_pressed()

		if event.keycode == KEY_TAB and pressed and not event.is_echo():
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.keycode == KEY_ESCAPE and pressed and not event.is_echo():
			get_tree().quit()

		# Update movement key states.
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			move_input["up"] = pressed
			#print("Current Player Position: ", position)
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			move_input["down"] = pressed
			#print("Current Player Position: ", position)
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			move_input["left"] = pressed
			#print("Current Player Position: ", position)
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			move_input["right"] = pressed
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
								new_mode = mode_1
							KEY_2:
								new_mode = mode_2
							KEY_3:
								new_mode = mode_3
							KEY_4:
								new_mode = mode_4
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
			if pressed:
				jetpack_active = true
			else:
				jetpack_active = false
		if event.keycode == KEY_ALT:
			if airborne:
				if pressed:
					hover_lock =! hover_lock
					print(hover_lock)
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
		# *Re-enable physics on the object:*
		grabbed_anim.stop()
		clear_char_obj_shape()
		grabbed_object.collision_shape.disabled = false
		grabbed_object.lock_rotation = false
		grabbed_object.angular_velocity = Vector3.ZERO
		grabbed_object.linear_velocity = Vector3.ZERO
		grabbed_object.set_outline('RELEASE', Color.WHITE)
		hud_reticle.visible = true

		object_sway_strength_x = object_sway_base_x
		object_sway_strength_y = object_sway_base_y
		distance_factor = 0.0
		grabbed_distance = 0.0
		grabbed_object.position.z = 0.0
		grabbed_collision.position.z = 0.0
		grabbed_object.mass = grabbed_object.mass / 2.0
		grabbed_object.is_grabbed = false
		grabbed_object.is_released = true
		grabbed_object.mass = 10
		if extracting_object_active and grabbed_object.is_extractable:
			grabbed_object.extract_parts()
		object_is_grabbed = false
		grabbed_object = null
	else:
		grabbed_anim.play("RESET")
		grabbed_anim.play("hover")
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
			if target_body is RigidBody3D and not target_body.is_rocketship and not target_body.phantom_body:
				grabbed_object = target_body
				grabbed_object.angular_velocity = Vector3.ZERO
				grabbed_object.is_grabbed = true
				var object_children = grabbed_object.get_children()
				for child in object_children:
					if child is MeshInstance3D:
						grabbed_mesh = child
					elif child is CollisionShape3D:
						grabbed_collision = child
				hud_reticle.visible = false
				match current_mode:
					mode_1:
						glow_color = Color.GREEN
					mode_2:
						glow_color = Color.RED
					mode_3:
						glow_color = Color.AQUA
					mode_4:
						glow_color = Color.PURPLE
				grabbed_object.set_outline('GRAB', glow_color)
				grabbed_object.mass = grabbed_object.mass * 2.0
				grabbed_initial_mouse = get_viewport().get_mouse_position()
				grabbed_distance = (grabbed_object.global_transform.origin - camera.global_transform.origin).length()
				grabbed_initial_rotation = rotation_degrees
				grabbed_global_rotation = grabbed_object.global_rotation_degrees
				grabbed_rotation.x = shortest_angle_diff_value(grabbed_initial_rotation.x, grabbed_global_rotation.x)
				var sanitized_initial_y = wrapf(grabbed_initial_rotation.y, -180.0, 180.0)
				var sanitized_global_y = wrapf(grabbed_global_rotation.y, -180.0, 180.0)
				grabbed_rotation.y = shortest_angle_diff_value(sanitized_initial_y, sanitized_global_y)
				grabbed_rotation.y = shortest_angle_diff_value(grabbed_initial_rotation.y, grabbed_global_rotation.y)
				grabbed_rotation.z = shortest_angle_diff_value(grabbed_initial_rotation.z, grabbed_global_rotation.z)
				object_is_grabbed = true
				grabbed_object.mass = 100
				grabbed_object.gravity_scale = 1.5
				grabbed_object.collision_shape.disabled = true
				create_char_obj_shape(grabbed_object)

			else:
				print("Object hit, but no MeshInstance3D child found!")
		else:
			print("Object is not RigidBody3D")
			return

func control_object(status):
	if status == 'pressed':
		grabbed_anim.pause()
		PREM_7.trig_anim.play("RESET")
		PREM_7.trig_anim.play("trigger_pull")
		grabbed_object.set_outline('ENHANCE', glow_color)
		if current_mode == mode_1:
			print("Begin Shifting Object")
			shifting_object_active = true
		elif current_mode == mode_2:
			print("Begin Extracting Object")
			print('ADD FUNCTIONALITY HERE - Press & Hold for Extraction...object starts to progressively shake until extraction complete')
			extracting_object_active = true
		elif current_mode == mode_3:
			print("Begin Suspending Object")
			suspending_object_active = true
		elif current_mode == mode_4:
			print("Begin Fusing Object")
			print('ADD FUNCTIONALITY HERE - Press & Hold for Fusion...grabbed object becomes child of object it is fusing to // objects begin to rumble and glow')
			fusing_object_active = true
		collision_layer = 12
		right_mouse_down = true
	if status == 'released':
		grabbed_anim.play()
		PREM_7.trig_anim.play("trigger_release")
		PREM_7.trig_anim.play("RESET")
		grabbed_object.set_outline('DIM', glow_color)
		print(glow_color)
		if current_mode == mode_1:
			print("Object has been Shifted!")
			shifting_object_active = false
		elif current_mode == mode_2:
			print("Object has been Extracted!")
			grab_object()
			extracting_object_active = false
		elif current_mode == mode_3:
			print("Object has been Suspended!")
			grabbed_object.gravity_scale = 0.0
			grab_object()
			suspending_object_active = false
		elif current_mode == mode_4:
			print("Object has been Fused!")
			fusing_object_active = false
		collision_layer = 1
		right_mouse_down = false

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
		var bob_strength = 0.5    # Amplitude (how far up/down)
		var bob_speed = 2.0       # Frequency (how fast)
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
		mode_1:
			new_glow_color = Color.GREEN
		mode_2:
			new_glow_color = Color.RED
		mode_3:
			new_glow_color = Color.AQUA
		mode_4:
			new_glow_color = Color.PURPLE
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
			mode_1: glow_color = Color.GREEN
			mode_2: glow_color = Color.RED
			mode_3: glow_color = Color.AQUA
			mode_4: glow_color = Color.PURPLE
			_: glow_color = Color.WHITE

		grabbed_object.set_outline('UPDATE', glow_color)

func cycle_mode_direction(forward: bool = true) -> void:
	var current_index = modes.find(current_mode)
	var new_index = (current_index + (1 if forward else -1)) % modes.size()
	if new_index < 0:
		new_index = modes.size() - 1
	change_mode(modes[new_index])
	match current_mode:
		mode_1: hud_reticle.modulate = Color.GREEN
		mode_2: hud_reticle.modulate = Color.RED
		mode_3: hud_reticle.modulate = Color.AQUA
		mode_4: hud_reticle.modulate = Color.PURPLE

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
		if child is MeshInstance3D:
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

	var object_pos = grabbed_object.global_transform.origin
	char_obj_shape.global_transform.origin = object_pos
	char_obj_shape.visible = true
	char_obj_shape.debug_fill = true
	char_obj_shape.debug_color = Color.RED

func clear_char_obj_shape():
	if is_instance_valid(char_obj_shape):
		char_obj_shape.shape = null
		char_obj_shape.visible = false
