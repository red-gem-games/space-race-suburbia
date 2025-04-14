extends RayCast3D

var character_airborne: bool = false

func _process(delta: float) -> void:
	if character_airborne:
		force_raycast_update()
		
		#print(get_collider())
