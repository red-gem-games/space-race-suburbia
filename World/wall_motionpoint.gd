extends Area3D
class_name Wall_MotionPoint

var wall: Area3D
var wall_children
var mesh: MeshInstance3D
var body



func _ready() -> void:
	init_motionpoint()


func init_motionpoint() -> void:
	print("MotionPoint init on: ", name)
	
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited",  Callable(self, "_on_area_exited"))
	wall = self
	wall_children = wall.get_children()
	#for child in wall_children:
		#if child is MeshInstance3D:
			#mesh = child
			#mesh.name = wall.name + "_Mesh"

func _on_area_entered(area: Area3D) -> void:
	body = area.get_parent()
	if body is CharacterBody3D:
		for child in wall_children:
			if not child is CollisionShape3D:
				body.register_wall(child)
				body.touched_walls[child] = true
		#print("ADDED: ", wall.name, body.get_rocket_walls())


func _on_area_exited(area: Area3D) -> void:
	body = area.get_parent()
	if body is CharacterBody3D:
		for child in wall_children:
			if not child is CollisionShape3D:
				body.touched_walls.erase(child)
		#print("REMOVED: ", wall.name, body.get_rocket_walls())
