extends Node3D
class_name world

@onready var assembly_object_container: Node3D = $Assembly_Objects
var assembly_object_array: Array[RigidBody3D]

@onready var character: CharacterBody3D = $Character
var grabbed_object: RigidBody3D = null
var object_is_grabbed: bool = false

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









func _ready() -> void:
	add_child(object_position_timer)


func _process(delta: float) -> void:

	# When an object is grabbed:
	if character.object_is_grabbed and not object_is_grabbed:
		grabbed_object = character.grabbed_object
		reset_rotation = true
		object_is_grabbed = true
		character.pitch_set = false
		character.initial_grab = true
		proxy_is_moving_to_character = true
		
		grabbed_object.reparent(character.grabbed_container)
		grabbed_object.world_object_container = assembly_object_container

		if grabbed_object.is_assembly_part:
			var machine_name = grabbed_object.name.split("_", true, 1)[0]
			var part_name = grabbed_object.name.split("_", true, 1)[1]
			print("Came from machine: ", machine_name)
			print("This part is: ", part_name)
		
		if is_instance_valid(grid_parent):
			grid_parent.queue_free()
			grid_parent = null
	
		spawn_grid()
	# When the object is released:
	elif not character.object_is_grabbed and object_is_grabbed:
		if not is_instance_valid(grabbed_object):
			return
		grabbed_object.reparent(assembly_object_container)
		grabbed_object.global_position = object_global_position
		grabbed_object.global_position.y += 0.05
		character.distance_from_character = base_distance_in_front
		character.pitch_set = false
		grabbed_object = null
		object_is_grabbed = false
		

	if character.object_is_grabbed and object_is_grabbed and grabbed_object:
		object_global_position = grabbed_object.global_position
		char_pos = character.camera.global_transform.origin
		char_forward = -character.camera.global_transform.basis.z.normalized()
		target_pos = char_pos + char_forward * character.distance_from_character
		var custom_up = Vector3(0, 1, 0.001).normalized()
		target_transform = Transform3D().looking_at(char_pos, custom_up)
		target_transform.origin = target_pos
		if character.grounded:
			grabbed_object.global_transform = grabbed_object.global_transform.interpolate_with(target_transform, delta * grounded_interp_speed)
		elif not character.grounded:
			grabbed_object.global_transform = grabbed_object.global_transform.interpolate_with(target_transform, delta * airborne_interp_speed)
		if reset_rotation:
			character.grabbed_rotation = character.grabbed_rotation.lerp(target_grabbed_rotation, delta * 2.0)
			grabbed_object.rotation_degrees = character.grabbed_rotation
			if character.grabbed_rotation.distance_to(target_grabbed_rotation) < 0.05:
				reset_rotation = false

		if character.shifting_object_active:
			reset_rotation = false

		#if is_instance_valid(grid_parent):
			#var char_pos = character.camera.global_transform.origin
			#var char_forward = -character.camera.global_transform.basis.z.normalized()
			#grid_parent.global_position = char_pos + char_forward * base_distance_in_front


		if is_instance_valid(character.char_obj_shape):
			if proxy_is_moving_to_character:
				var current_transform: Transform3D = character.char_obj_shape.global_transform
				var target_transform := grabbed_object.global_transform

				target_transform.origin.y += 1.0

				var interp_transform := current_transform.interpolate_with(target_transform, delta * 10.0)
				character.char_obj_shape.global_transform = interp_transform

				if interp_transform.origin.distance_to(target_transform.origin) < 0.1:
					proxy_is_moving_to_character = false
			else:
				
				var proxy_transform := grabbed_object.global_transform
				proxy_transform.origin = target_pos
				character.char_obj_shape.global_transform = grabbed_object.global_transform



func _input(event: InputEvent) -> void:

	if event is InputEventKey:
		if event.keycode == KEY_R:
			reset_rotation = true
			character.distance_from_character = base_distance_in_front

		elif event.keycode == KEY_SHIFT:
			if event.is_pressed():
				movement_speed = 2
			else:
				movement_speed = 1


func spawn_grid():
	grid_parent = Node3D.new()
	grid_parent.name = "GridContainer"
	grabbed_object.add_child(grid_parent)

	var spacing = 3.0
	var grid_size = 4
	var cube_size = 1.5
	var start_offset = Vector3(-((grid_size - 1) * spacing) / 2.0, -((grid_size - 1) * spacing) / 2.0, 0)

	for x in range(grid_size):
		for y in range(grid_size):
			var cube = MeshInstance3D.new()
			cube.mesh = BoxMesh.new()
			cube.material_override = StandardMaterial3D.new()
			cube.scale = Vector3(cube_size, cube_size, cube_size)
			var pos = Vector3(x * spacing, y * spacing, 0) + start_offset
			cube.position = pos
			grid_parent.add_child(cube)
