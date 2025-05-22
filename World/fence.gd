extends MultiMeshInstance3D

@export var column_spacing: float = 2.0
@export var row_spacing:    float = 1.0

const COLUMNS: int = 20
const ROWS: int = 20

func _ready() -> void:
	
	multimesh.instance_count = COLUMNS * ROWS
	
	for x in range(COLUMNS):
		for z in range(ROWS):
			var idx = z * COLUMNS + x
			var x_pos = x * column_spacing
			var z_pos = z * row_spacing
			var t = Transform3D(Basis(), Vector3(x_pos, 0, -z_pos))
			multimesh.set_instance_transform(idx, t)
