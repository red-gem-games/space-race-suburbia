extends AnimatableBody3D
class_name Rocket

const LERP_IN  := 5.0    # toward active pose
const LERP_OUT := 2.5    # back to base
const OFFSET   := 1.0    # local +X distance when touched

@export var player_path: NodePath
var player: Node = null   # your CharacterBody3D with touched_walls + get_rocket_walls()

# rows like: { "area": Area3D, "mesh": Node3D }
var walls: Array = []
# base LOCAL positions keyed by mesh node
var base_local_pos := {}   # Dictionary<Node3D, Vector3>

func _ready() -> void:
	# find the player
	if player_path != NodePath():
		player = get_node(player_path)
		print(player)
	else:
		var found := get_tree().get_nodes_in_group("player")
		if found.size() > 0:
			player = found[0]

	# discover walls: any direct child Area3D that has a Mesh child
	for child in get_children():
		if child is Area3D and (child as Node).has_node("Mesh"):
			var mesh := (child as Node).get_node("Mesh") as Node3D
			walls.append({ "area": child, "mesh": mesh })
			base_local_pos[mesh] = mesh.position

	if walls.is_empty():
		push_warning("No walls found under Rocket. Each Wall should be an Area3D with a 'Mesh' child.")

func _physics_process(delta: float) -> void:
	# build a set of active meshes from the player
	var active_set := {}
	if is_instance_valid(player) and "get_rocket_walls" in player:
		var active_list: Array = player.get_rocket_walls()
		for m in active_list:
			if is_instance_valid(m):
				active_set[m] = true

	for row in walls:
		var mesh := row["mesh"] as Node3D
		if !is_instance_valid(mesh):
			continue

		var active := active_set.has(mesh)
		var spd := LERP_IN if active else LERP_OUT

		# target local position: base + (+X * OFFSET) when active
		var target_pos = base_local_pos[mesh] + Vector3(OFFSET, 0.0, 0.0) if active else base_local_pos[mesh]
		mesh.position = mesh.position.lerp(target_pos, spd * delta)

		# fade via modulate alpha (1 = opaque, 0 = invisible)
		var target_alpha := 0.0 if active else 1.0
		var c = mesh.modulate
		c.a = lerp(c.a, target_alpha, spd * delta)
		mesh.modulate = c
