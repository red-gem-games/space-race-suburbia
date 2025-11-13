extends CSGPolygon3D

func _ready():
	# Your trapezoid points
	var points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(3, 0),
		Vector2(2.5, 1),
		Vector2(0.5, 1)
	])
	polygon = points
	depth = 0.1
	mode = CSGPolygon3D.MODE_DEPTH
	
	# Create wireframe material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0, 1, 1, 1)  # Cyan
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.flags_wireframe = true  # This is the key setting
	
	material = mat
