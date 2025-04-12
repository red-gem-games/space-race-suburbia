extends CharacterBody3D
class_name character


var target_strength: float = 1


@onready var char_anim: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera3D = $Camera3D
@onready var PREM_7: Node3D = $"Camera3D/PREM-7"
@onready var hud_reticle: Control = $HUD.hud_reticle

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

var shifting_object_active: bool = false
var dividing_object_active: bool = false
var inspecting_object_active: bool = false
var fusing_object_active: bool = false

var floor_y: float = -1     # The floor level (adjust as needed)
var max_y: float = 20.0       # The maximum Y allowed (adjust as needed)
var base_pitch_factor: float = 3
var pitch_factor: float = base_pitch_factor # How much camera pitch affects the Y offset

var prem7_decay_speed: float = 5.0      # Speed at which the rotation offset decays.
var mouse_speed_threshold: float = 2.0    # Mouse relative motion threshold below which decay occurs.
var last_mouse_speed: float = 0.0         # Latest mouse movement magnitude.
var last_mouse_time: float = 0.0          # Timestamp of the last mouse motion event.

var grabbed_x_rotation: float
var grabbed_y_rotation: float
var grabbed_z_rotation: float

# Mouse button states
var left_mouse_down: bool = false
var right_mouse_down: bool = false
var middle_mouse_down: bool = false

var mode_1: String = "SHIFT"
var mode_2: String = "DIVIDE"
var mode_3: String = "INSPECT"
var mode_4: String = "FUSE"
var modes = [mode_1, mode_2, mode_3, mode_4]
var current_mode: String = mode_1
var pending_mode: String = ""  # Holds the pending mode change
var pending_mode_key: int = 0  # Will store the keycode of the mode key that triggered pending_mode

# Variables for camera rotation
var desired_yaw: float = 0.0
var desired_pitch: float = 0.0
var yaw: float = 0.0
var pitch: float = 0.0
var base_pitch_min: float = -PI/2
var base_pitch_max: float = PI/2
var pitch_min: float = base_pitch_min
var pitch_max: float = base_pitch_max
var base_mouse_sensitivity: float = 0.002
var mouse_sensitivity: float = base_mouse_sensitivity
var smoothing: float = 0.05  # Smoothing factor (0-1)

# Variables for player movement
var base_movement_speed: float = 7.0
var movement_speed: float = base_movement_speed
var current_velocity: Vector3 = Vector3.ZERO

# Variables for PREM-7 rotation while shifting
var prem7_original_rotation: Vector3
var prem7_rotation_offset: Vector3 = Vector3.ZERO
var prem7_rotation_speed: float = 0.0001  # Adjust this to slow or speed up PREM-7's rotation while shifting.

var jetpack_active: bool = false
var jetpack_force: float = 15.0     # Adjust for how fast you want the character to rise.
var gravity: float = 20.0     
var grounded: bool = false   # Adjust for how fast the character falls.
var vertical_velocity: float = 0.0
var ground_y: float = 2.0           # The minimum height (ground level).









func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Store the original rotation of PREM-7.
	prem7_original_rotation = PREM_7.rotation

func _process(delta: float) -> void:
	
	if jetpack_active:
		pitch_min = base_pitch_min
		vertical_velocity = jetpack_force
		gravity = 20
		grounded = false  # Constant upward velocity, or you can add acceleration.
	else:
		vertical_velocity -= gravity * delta

	# Update the character's vertical position using the vertical_velocity.
	self.position.y += vertical_velocity * delta

	# Clamp the character's position so that it does not go below ground level.
	if self.position.y < 2.5 and not grounded:
		self.position.y = ground_y
		pitch_min = base_pitch_min
		pitch_max = 1
		vertical_velocity = 0
		gravity = 0
		grounded = true
	
	if grounded:
		if grabbed_object:
			pitch_min = 0
			pitch_max = 0.75
		else:
			pitch_min = base_pitch_min
			pitch_max = base_pitch_max
		

	# Perform a raycast from the camera's position forward.
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_transform.origin
	# Assuming the camera's forward direction is -z:
	var to = from + (-camera.global_transform.basis.z) * 100.0  # adjust distance as needed

	# Exclude the player (and any other objects you don't want to hit).
	var exclude = [self]
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.exclude = exclude
	var result = space_state.intersect_ray(query)



	if result:
		var collider = result.collider
		if collider is RigidBody3D:
			match current_mode:
				mode_1:
					hud_reticle.modulate = Color.GREEN
				mode_2:
					hud_reticle.modulate = Color.RED
				mode_3:
					hud_reticle.modulate = Color.AQUA
				mode_4:
					hud_reticle.modulate = Color.PURPLE
				_:
					hud_reticle.modulate = Color.WHITE
		else:
			hud_reticle.modulate = Color.WHITE
	else:
		hud_reticle.modulate = Color.WHITE


	# Smooth camera rotation.
	desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
	yaw = lerp(yaw, desired_yaw, smoothing)
	pitch = lerp(pitch, desired_pitch, smoothing)
	rotation.y = yaw
	camera.rotation.x = pitch

	# Process movement keys into vertical/horizontal values.
	var vertical = 0  # 1 for forward, -1 for backward.
	var horizontal = 0  # 1 for right, -1 for left.
	
	if move_input["up"] and not move_input["down"]:
		vertical = 1
	elif move_input["down"] and not move_input["up"]:
		vertical = -1

	if move_input["right"] and not move_input["left"]:
		horizontal = 1
	elif move_input["left"] and not move_input["right"]:
		horizontal = -1

# Calculate desired movement direction relative to the player's orientation.
	var desired_direction: Vector3 = Vector3.ZERO
	if vertical != 0 or horizontal != 0:
		desired_direction = ((-transform.basis.z) * vertical + (transform.basis.x) * horizontal).normalized()
	var desired_velocity = desired_direction * movement_speed
	current_velocity = current_velocity.lerp(desired_velocity, smoothing)
	velocity = current_velocity
	move_and_slide()
	
	if grabbed_object:
		match current_mode:
			mode_1:
				hud_reticle.modulate = Color.GREEN
			mode_2:
				hud_reticle.modulate = Color.RED
			mode_3:
				hud_reticle.modulate = Color.AQUA
			mode_4:
				hud_reticle.modulate = Color.PURPLE

		grabbed_object.rotation_degrees = grabbed_rotation

		# (Your code updating Y position remains the same.)
		var pitch_offset = camera.rotation.x
		var target_y = grabbed_initial_position.y + pitch_offset
		target_y = clamp(target_y, floor_y, max_y)

		grabbed_object.position.y = target_y


		if shifting_object_active:
			grabbed_object.rotation_degrees = grabbed_rotation

	# At the end of your _process() function:
	# Check the time since the last mouse motion.
	var time_since_last = (Time.get_ticks_msec() - last_mouse_time) / 1000.0  # in seconds

	# If the mouse isn't moving fast (or enough time has passed), decay the prem7_rotation_offset.
	if last_mouse_speed < mouse_speed_threshold or time_since_last > 0.05:
		prem7_rotation_offset = prem7_rotation_offset.lerp(Vector3.ZERO, prem7_decay_speed * delta)
		PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset


func _input(event: InputEvent) -> void:
	# Process Mouse Button events.
	if event is InputEventMouseButton:
		# Ignore events from opposite buttons if one is held.
		if left_mouse_down and event.button_index == MOUSE_BUTTON_RIGHT:
			return
		if right_mouse_down and event.button_index == MOUSE_BUTTON_LEFT:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				grab_object()
			else:
				left_mouse_down = false
				PREM_7.trig_anim.play("trigger_release")
				PREM_7.trig_anim.play("RESET")
		elif event.button_index == MOUSE_BUTTON_RIGHT and grabbed_object:
			if event.is_pressed():
				right_mouse_down = true
				PREM_7.trig_anim.play("RESET")
				PREM_7.trig_anim.play("trigger_pull")
				if current_mode == mode_1:
					print("Begin Shifting Object")
					shifting_object_active = true
				elif current_mode == mode_2:
					print("Begin Dividing Object")
					inspecting_object_active = true
				elif current_mode == mode_3:
					print("Begin Inspecting Object")
					dividing_object_active = true
				elif current_mode == mode_4:
					print("Begin Fusing Object")
					fusing_object_active = true
			else:
				right_mouse_down = false
				PREM_7.trig_anim.play("trigger_release")
				PREM_7.trig_anim.play("RESET")
				prem7_rotation_offset = Vector3.ZERO
				PREM_7.rotation = prem7_original_rotation
				print("No Longer Shifting Object")
				shifting_object_active = false

		# Use the mouse wheel to cycle through modes.
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if not middle_mouse_down:
				if grabbed_object:
					distance_from_character = clamp(distance_from_character + 0.25, 6, 24)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			if not middle_mouse_down:
				if grabbed_object:
					distance_from_character = clamp(distance_from_character - 0.25, 6, 24)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				middle_mouse_down = true
				PREM_7.mode_anim.play("RESET")
				PREM_7.mode_anim.play("shift_mode_down")
			if not event.is_pressed():
				middle_mouse_down = false
				PREM_7.mode_anim.play("RESET")
				PREM_7.mode_anim.play("shift_mode_up")
				cycle_mode()

	# Process Mouse Motion events.
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			prem7_rotation_offset.y -= event.relative.x * prem7_rotation_speed
			prem7_rotation_offset.x -= event.relative.y * prem7_rotation_speed
			var max_offset = deg_to_rad(10.0)
			prem7_rotation_offset.x = clamp(prem7_rotation_offset.x, -max_offset, max_offset)
			prem7_rotation_offset.y = clamp(prem7_rotation_offset.y, -max_offset, max_offset)
			PREM_7.rotation = prem7_original_rotation + prem7_rotation_offset

			if not shifting_object_active:
				desired_yaw -= event.relative.x * mouse_sensitivity
				desired_pitch -= event.relative.y * mouse_sensitivity
				desired_pitch = clamp(desired_pitch, pitch_min, pitch_max)
			else:
				if grabbed_object:
					grabbed_rotation.z = 0
					grabbed_rotation.y += event.relative.x * rotation_sensitivity
					grabbed_rotation.x += event.relative.y * rotation_sensitivity
					var horizontal_delta = event.relative.x * mouse_sensitivity * 10
					var vertical_delta   = event.relative.y * mouse_sensitivity * 10
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
		if event.keycode == KEY_SHIFT:
			if pressed:
				movement_speed = base_movement_speed * 2
				mouse_sensitivity = base_mouse_sensitivity * 2
				rotation_sensitivity = base_rotation_sensitivity * 2
			else:
				movement_speed = base_movement_speed
				mouse_sensitivity = base_mouse_sensitivity
				rotation_sensitivity = base_rotation_sensitivity

		if event.keycode == KEY_R and pressed and not event.is_echo():
			desired_pitch = 0
			prem7_rotation_offset = Vector3.ZERO
			PREM_7.rotation = prem7_original_rotation
			if grabbed_object and shifting_object_active:
				grabbed_rotation = grabbed_initial_rotation

		# Update movement key states.
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			move_input["up"] = pressed
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			move_input["down"] = pressed
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			move_input["left"] = pressed
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			move_input["right"] = pressed

		# Process number keys (1-4) to directly change modes, if desired.
		if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]:
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
			jetpack_active = pressed


func grab_object():
	left_mouse_down = true
	PREM_7.trig_anim.play("RESET")
	PREM_7.trig_anim.play("trigger_pull")
	print("Multitool Trigger Pulled")

	# If in GRAB mode, either grab or release the object.
	if grabbed_object:  # An object is already grabbed; release it.
		print("Released Object.")
		# *Re-enable physics on the object:*
		grabbed_object.lock_rotation = false
		grabbed_object.angular_velocity = Vector3.ZERO
		grabbed_object.linear_velocity = Vector3.ZERO
		# If you changed any other simulation parameters (e.g. custom_integrator) disable that too.

		# Optionally, you could reset any manual transform or rotation offsets if needed.
		grabbed_distance = 0.0
		grabbed_object.position.z = 0.0
		grabbed_collision.position.z = 0.0
		object_is_grabbed = false
		grabbed_object = null
	else:
		# No object grabbed yet, so perform the raycast.
		var space_state = get_world_3d().direct_space_state
		var from = camera.global_transform.origin
		var to = from + (-camera.global_transform.basis.z) * 100.0
		var query = PhysicsRayQueryParameters3D.new()
		query.from = from
		query.to = to
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result:
			var target_body = result.collider  # Likely a RigidBody3D.
			print(target_body)
			if target_body is RigidBody3D:
				grabbed_object = target_body
				# Before shifting, disable physics control on the object.
				grabbed_object.lock_rotation = true
				grabbed_object.angular_velocity = Vector3.ZERO
				# (You may also consider setting MODE_KINEMATIC or using a custom integrator
				# for full manual control while shifting.)
				
				var object_children = grabbed_object.get_children()
				for child in object_children:
					if child is MeshInstance3D:
						grabbed_mesh = child
					elif child is CollisionShape3D:
						grabbed_collision = child
				grabbed_initial_position = grabbed_object.global_transform.origin
				grabbed_initial_mouse = get_viewport().get_mouse_position()
				grabbed_distance = (grabbed_object.global_transform.origin - camera.global_transform.origin).length()
				grabbed_rotation = grabbed_initial_rotation
				object_is_grabbed = true
			else:
				print("Object hit, but no MeshInstance3D child found!")
		else:
			print("Object is not RigidBody3D")
			return


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
	var back_glow_instance = PREM_7.back_glow  # Adjust the path as needed
	var photon_glow_instance = PREM_7.photon_glow

	if back_glow_instance:
		var mat = back_glow_instance.get_surface_override_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("glow_color", Vector3(new_glow_color.r, new_glow_color.g, new_glow_color.b))

	if photon_glow_instance:
		var mat = photon_glow_instance.get_surface_override_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("glow_color", Vector3(new_glow_color.r, new_glow_color.g, new_glow_color.b))


# Function to change the mode if it's different from the current one.
func change_mode(new_mode: String) -> void:
	if new_mode == current_mode:
		print("Already in mode: " + new_mode)
		return
	current_mode = new_mode
	print("Multitool Mode Changed: " + current_mode)
	update_prem7_glow()

# Function to cycle through the modes using the spacebar.
func cycle_mode() -> void:
	var current_index = modes.find(current_mode)
	if current_index == -1:
		current_index = 0
	var new_index = (current_index + 1) % modes.size()
	change_mode(modes[new_index])


func rotate_object(object, rot_deg, time):
	rotate_tween = Tween.new()
	
	rotate_tween.tween_property(object, "rotation_degrees", rot_deg, time)
	rotate_tween.EASE_IN_OUT
