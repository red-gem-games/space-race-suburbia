extends Node3D

@export var spacing: float = 2.5
@export var rows: int = 4
@export var cols: int = 4
@export var offset_from_this_node: Vector3 = Vector3(0, 0, -10)

func _ready():
	var base_pos = global_transform.origin + offset_from_this_node

	for row in range(rows):
		for col in range(cols):
			var x = (col - cols / 2.0 + 0.5) * spacing
			var y = (row - rows / 2.0 + 0.5) * spacing
			var pos = base_pos + Vector3(x, y, 0)

			var cube = MeshInstance3D.new()
			cube.mesh = BoxMesh.new()
			cube.scale = Vector3.ONE * 0.2
			cube.position = pos
			add_child(cube)
			print(cube.position)
