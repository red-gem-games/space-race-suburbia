extends RigidBody3D

var is_rocketship: bool = true

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	rotate_y(0.001)


func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	pass

func _on_body_shape_exited(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	pass
