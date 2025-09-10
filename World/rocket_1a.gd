extends AnimatableBody3D
class_name Rocket_1A

const LERP_SPEED_IN := 5.0
const LERP_SPEED_OUT := 2.5
const OFFSET := 1.0  # how far to push when touched

@onready var north_wall_node: Node3D = $NorthWall
@onready var east_wall_node:  Node3D = $EastWall
@onready var south_wall_node: Node3D = $SouthWall
@onready var west_wall_node:  Node3D = $WestWall

@onready var north_wall_mesh: Node3D = $NorthWall/Mesh
@onready var east_wall_mesh:  Node3D = $EastWall/Mesh
@onready var south_wall_mesh: Node3D = $SouthWall/Mesh
@onready var west_wall_mesh:  Node3D = $WestWall/Mesh

@onready var motion_points: Array[MotionPoint] = [
	$NorthWall/MotionPoint,
	$EastWall/MotionPoint,
	$SouthWall/MotionPoint,
	$WestWall/MotionPoint
]

# one row per wall: which node triggers, which mesh moves, and along which axis
var walls := []
var base_pos := {}  # keyed by mesh Node3D

func _ready() -> void:
	walls = [
		{ "node": north_wall_node, "mesh": north_wall_mesh, "axis": Vector3.BACK    },   # +Z
		{ "node": east_wall_node,  "mesh": east_wall_mesh,  "axis": Vector3.LEFT   },   # -X
		{ "node": south_wall_node, "mesh": south_wall_mesh, "axis": Vector3.FORWARD    },   # -Z
		{ "node": west_wall_node,  "mesh": west_wall_mesh,  "axis": Vector3.RIGHT   }    # +X
	]
	for row in walls:
		var m: Node3D = row["mesh"]
		base_pos[m] = m.position

func _get_touched_set() -> Dictionary:
	var touched := {}
	for mp in motion_points:
		for wall in mp.touched_walls:
			touched[wall] = true
	return touched

func _physics_process(delta: float) -> void:
	var touched := _get_touched_set()

	for row in walls:
		var wall_node: Node3D = row["node"]
		var mesh: Node3D      = row["mesh"]
		var axis: Vector3     = row["axis"]

		var is_active := touched.has(wall_node)
		var target_pos = base_pos[mesh] + (axis * OFFSET if is_active else Vector3.ZERO)
		var target_alpha := 1.0 if is_active else 0.0

		# position: vector lerp
		mesh.position = mesh.position.lerp(target_pos, LERP_SPEED_IN * delta)

		# transparency: scalar lerp (assuming you’ve got a shader/uniform or script exposing this)
		mesh.transparency = lerp(mesh.transparency, target_alpha, LERP_SPEED_IN * delta)
