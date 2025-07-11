extends RayCast3D 
class_name Beam

var cast_point
var collider
var beam_set: bool = false

@onready var beam_mesh: MeshInstance3D = $BeamMesh
var base_height: float
var base_y_pos: float

@onready var end_particles: GPUParticles3D = $BeamMesh/EndParticles

var object_is_grabbed: bool = false

@onready var path_beam: PathFollow3D = $Path3D/PathBeam
var beam_speed: float = 10.0

@onready var beam_polygon: CSGPolygon3D = $Path3D/CSGPolygon3D
@onready var beam_polygon2: CSGPolygon3D = $Path3D/CSGPolygon3D2
@onready var beam_polygon3: CSGPolygon3D = $Path3D/CSGPolygon3D3
@onready var beam_polygon4: CSGPolygon3D = $Path3D/CSGPolygon3D4
var base_circle: PackedVector2Array

var precomputed_wobbles: Array = []
const NUM_WOBBLE_FRAMES := 100
const BEAM_SEGMENTS := 100
const BEAM_RADIUS := 0.05
var wobble_index := 0
var wobble_timer := 0.0
const WOBBLE_RATE := 0.01  # seconds between frames
var beam_radius := 0.1
var wave_speed := 3.0
var wave_strength := 0.01
var heatwave_timer := 0.0
var update_rate := 0.1  # seconds





func _ready() -> void:
	base_height = beam_mesh.mesh.section_length
	base_y_pos = beam_mesh.position.y
	#set_process(false)
	end_particles.emitting = false
	
	#beam_polygon.visible = false
	#beam_polygon2.visible = false
	#beam_polygon3.visible = false
	#beam_polygon4.visible = false
	
	#beam_polygon.polygon = generate_circle_points(0.075, 100)
	#beam_polygon2.polygon = generate_circle_points(0.075, 100)
	#beam_polygon3.polygon = generate_circle_points(0.075, 100)
	#beam_polygon4.polygon = generate_circle_points(0.075, 100)
	#base_circle = generate_circle_points(1.0, BEAM_SEGMENTS)
	#
	## Precompute distorted circle frames
	#for i in range(NUM_WOBBLE_FRAMES):
		#var t = float(i) / NUM_WOBBLE_FRAMES * TAU
		#var shape = update_heatwave(BEAM_RADIUS, wave_speed, wave_strength, t)
		#precomputed_wobbles.append(shape)
#
	## Apply the first frame
	#beam_polygon.polygon = precomputed_wobbles[0]



func _process(delta: float) -> void:
	
	#beam_anim.play("heat_wave")

	#wobble_timer += delta
	#if wobble_timer >= WOBBLE_RATE:
		#wobble_timer = 0.0
		#wobble_index = (wobble_index + 1) % NUM_WOBBLE_FRAMES
		#beam_polygon.polygon = precomputed_wobbles[wobble_index]
	
	force_raycast_update()
	
	target_position = Vector3(0.0, -100.0, 0.0)
	
	if is_colliding():
		if get_collider() is RigidBody3D:
			collider = get_collider()
			cast_point = to_local(get_collision_point())
		
		else:
			collider = null

	else:
		collider = null


func generate_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle = (TAU / segments) * i
		var x = radius * cos(angle)  # Unit circle (radius 1.0)
		var y = radius * sin(angle)
		points.append(Vector2(x, y))
	return points



func update_heatwave(radius: float, wave_speed: float, wave_strength: float, time_offset: float) -> PackedVector2Array:
	var distorted := PackedVector2Array()
	for i in range(base_circle.size()):
		var base_point = base_circle[i]
		var angle = atan2(base_point.y, base_point.x)
		var wave = sin(angle * 4.0 + time_offset) * wave_strength
		var r = radius + wave
		distorted.append(Vector2(cos(angle) * r, sin(angle) * r))
	return distorted
