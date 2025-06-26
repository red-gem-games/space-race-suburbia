@tool
extends Node3D
class_name Path

@export var line_radius = 0.1
@export var line_res = 180.0

func _ready() -> void:
	var circle = Cyl()
	for degree in line_res:
		var x = line_radius * sin(PI * 2 * degree / line_res)
		var y = line_radius * cos(PI * 2 * degree / line_res)
		var coords = Vector2(x, y)
		circle.append(coords)
	$CSGMesh3D.polygon = circle
