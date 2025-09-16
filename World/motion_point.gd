extends Area3D
class_name MotionPoint

var touched_walls: Array = []


func _physics_process(_delta: float) -> void:
	pass

func _on_area_entered(area: Area3D) -> void:
	if area.get_parent() is character:
		var wall = get_children()
		for child in wall:
			if child is MeshInstance3D:
				child.name = child.get_parent().name + '_Mesh'
				touched_walls.append(child)
				print(child.name, " added to Array.")
				print(touched_walls)


func _on_area_exited(area: Area3D) -> void:
	if area.get_parent() is character:
		var wall = get_children()
		for child in wall:
			if child is MeshInstance3D:
				touched_walls.erase(child)
				print(child.name, " removed from Array.")
				print(touched_walls)
