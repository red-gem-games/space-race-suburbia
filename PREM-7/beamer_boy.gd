extends Node3D

@onready var path: Path3D = $Path3D
@export var mesh_to_instance: Mesh  # Assign your cylinder mesh here
@export var count := 20             # Number of segments along the path

func _ready():
	if path.curve.get_point_count() < 2:
		return

	for i in range(count):
		var t := float(i) / (count - 1)
		var pos := path.curve.sample_baked(t)
		var next_pos := path.curve.sample_baked(min(t + 0.05, 1.0))
		
		var segment = MeshInstance3D.new()
		segment.mesh = mesh_to_instance
		add_child(segment)

		segment.global_position = pos
		segment.look_at(next_pos, Vector3.UP)
		segment.scale = Vector3(0.05, 0.05, (pos - next_pos).length() * 0.5)
