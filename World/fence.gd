extends MultiMeshInstance3D

@export var plank_spacing: float = 0.625
@export var fence_width:   float = 99.5
@export var fence_depth:   float = 99.5

func _ready() -> void:
	# ——— 1) Figure out how many planks you really need ———
	var count_x = int(fence_width / plank_spacing)
	if count_x * plank_spacing < fence_width:
		count_x += 1

	var count_z = int(fence_depth / plank_spacing)
	if count_z * plank_spacing < fence_depth:
		count_z += 1

	# total = front + back + both sides
	var total = count_x * 2 + count_z * 2

	# ——— 2) Setup MultiMesh ———
	multimesh.instance_count   = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count   = total

	# ——— 3) Lay out perimeter ———
	var idx = 0

	# Front (z=0), facing +Z
	for x in range(count_x):
		var pos = Vector3(x * plank_spacing, 0, 0)
		multimesh.set_instance_transform(idx, Transform3D(Basis(), pos))
		idx += 1

	# Back (z=-depth), facing –Z
	for x in range(count_x):
		var face = Basis().rotated(Vector3.UP, PI)
		var pos  = Vector3(x * plank_spacing, 0, -fence_depth)
		multimesh.set_instance_transform(idx, Transform3D(face, pos))
		idx += 1

	# Left  (x=0), facing –X
	for z in range(count_z):
		var face = Basis().rotated(Vector3.UP, -PI/2)
		var pos  = Vector3(0, 0, -z * plank_spacing)
		multimesh.set_instance_transform(idx, Transform3D(face, pos))
		idx += 1

	# Right (x=width), facing +X
	for z in range(count_z):
		var face = Basis().rotated(Vector3.UP, PI/2)
		var pos  = Vector3(fence_width, 0, -z * plank_spacing)
		multimesh.set_instance_transform(idx, Transform3D(face, pos))
		idx += 1
