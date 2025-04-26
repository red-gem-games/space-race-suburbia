extends Node3D
class_name world

@onready var object_container: Node3D = $Objects
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

func _ready() -> void:
	add_child(object_position_timer)

func _process(delta: float) -> void:
	
	# When an object is grabbed:
	if character.object_is_grabbed and not object_is_grabbed:
		character.pitch_set = false
		character.initial_grab = true
		proxy_is_moving_to_character = true
		grabbed_object = character.grabbed_object 
		grabbed_object.reparent(character.grabbed_container)
		grabbed_object.world_object_container = object_container
		if grabbed_object.is_extracted:
			var machine_name = grabbed_object.name.split("_", true, 1)[0]
			var part_name = grabbed_object.name.split("_", true, 1)[1]
			print("Came from machine:", machine_name)
			print("This part is:", part_name)
		reset_rotation = true
		object_is_grabbed = true
	
	# When the object is released:
	elif not character.object_is_grabbed and object_is_grabbed:
		if not is_instance_valid(grabbed_object):
			return
		grabbed_object.reparent(object_container)
		grabbed_object.global_position = object_global_position
		grabbed_object.global_position.y += 0.05
		character.distance_from_character = base_distance_in_front
		character.pitch_set = false
		print('Object Position: ', grabbed_object.position)
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

		if is_instance_valid(character.char_obj_shape):
			if proxy_is_moving_to_character:
				var proxy_transform: Transform3D = character.char_obj_shape.global_transform
				proxy_transform.origin = proxy_transform.origin.lerp(target_pos, delta * 4.0)
				character.char_obj_shape.global_transform = proxy_transform

				if proxy_transform.origin.distance_to(target_pos) < 0.1:
					proxy_is_moving_to_character = false
			else:
				var proxy_transform := grabbed_object.global_transform
				proxy_transform.origin = target_pos
				character.char_obj_shape.global_transform = proxy_transform


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
