extends RigidBody3D
class_name rigid_object

var object_rotation: Vector3
var is_grabbed: bool = false
var is_released: bool = false

var struck_objects: Array[RigidBody3D] = []
var object_currently_struck: bool = false
var object_speed: Vector3
var object_speed_y: float

func _ready() -> void:
	mass = 35.0
	contact_monitor = true
	continuous_cd = true
	max_contacts_reported = 100

func _physics_process(delta: float) -> void:
	if is_grabbed:
		for obj in struck_objects:
			if is_instance_valid(obj):
				obj.move_and_collide(object_speed * delta)
				obj.apply_impulse(Vector3.ZERO, object_speed * 0.5)
		if struck_objects.size() > 0:
			object_currently_struck = true
		else:
			object_currently_struck = false
	if is_released:
		struck_objects.clear()
		is_released = false

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if is_grabbed and body is RigidBody3D and not struck_objects.has(body):
		struck_objects.append(body)
		print(name, ' >>> is now touching >>> ', body.name)

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if is_grabbed and body is RigidBody3D and struck_objects.has(body):
		struck_objects.erase(body)
		print(name, ' ||| no longer touching ||| ', body.name)
