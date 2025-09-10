extends Area3D
class_name Wall_MotionPoint

var wall: Area3D
var wall_children
var mesh: MeshInstance3D
var body

func _ready() -> void:
	wall = self
	wall_children = wall.get_children()
	for child in wall_children:
		if child is MeshInstance3D:
			mesh = child
			mesh.name = wall.name + "_Mesh"

func _physics_process(delta: float) -> void:
	pass

func _on_area_entered(area: Area3D) -> void:
	body = area.get_parent()
	if body is CharacterBody3D:
		body.register_wall(mesh)
		body.touched_walls[mesh] = true
		print("ADDED: ", wall.name, body.get_rocket_walls())


func _on_area_exited(area: Area3D) -> void:
	body = area.get_parent()
	if body is CharacterBody3D:
		body.touched_walls.erase(mesh)
		print("REMOVED: ", wall.name, body.get_rocket_walls())
