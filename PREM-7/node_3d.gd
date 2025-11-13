extends Node3D

func _ready():
	create_trapezoid_outline()

func create_trapezoid_outline():
	# Define your trapezoid corners
	var points_2d = [
		Vector2(0, 0),
		Vector2(3, 0),
		Vector2(2.5, 1),
		Vector2(0.5, 1)
	]
	
	var depth = 0.1
	
	# Create front face outline
	create_outline_loop(points_2d, 0)
	# Create back face outline
	create_outline_loop(points_2d, depth)
	
	# Create connecting lines between front and back
	for i in range(points_2d.size()):
		create_line(
			Vector3(points_2d[i].x, points_2d[i].y, 0),
			Vector3(points_2d[i].x, points_2d[i].y, depth)
		)

func create_outline_loop(points: Array, z_offset: float):
	for i in range(points.size()):
		var start = points[i]
		var end = points[(i + 1) % points.size()]
		create_line(
			Vector3(start.x, start.y, z_offset),
			Vector3(end.x, end.y, z_offset)
		)

func create_line(start: Vector3, end: Vector3):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(start)
	immediate_mesh.surface_add_vertex(end)
	immediate_mesh.surface_end()
	
	# Create cyan unshaded material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0, 1, 1, 1)
	mat.vertex_color_use_as_albedo = false
	mesh_instance.material_override = mat
