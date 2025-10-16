extends RigidBody3D
class_name TRS_1

var is_rocketship: bool = true
var is_rocket_system: bool = false
var all_systems_go: bool = false

var MOTIONPOINT_SCRIPT: Script = preload("res://World/wall_motionpoint.gd")

@onready var collision_shapes: Array

@onready var engine_system = $Engine
@onready var propellent_system = $Propellent

@onready var engine_structure: Node3D = $Engine_Structure
@onready var propellent_structure: Node3D = $Propellent_Structure
@onready var nose_structure: Node3D = $Nose_Structure
var structure_walls: Array = []

@onready var fire_particles: GPUParticles3D = $Fire
@onready var smoke_particles: GPUParticles3D = $Smoke

@onready var countdown_sound: AudioStreamPlayer3D = $SoundFX/countdown
@onready var rocket_launch_sound: AudioStreamPlayer3D = $SoundFX/rocket_launch

@onready var countdown_label = $Countdown
var launch_sequence_started: bool = false

func _ready() -> void:
	fire_particles.emitting = false
	smoke_particles.emitting = false
	countdown_label.visible = false
	
	print('-------')
	print('ADD SCRIPT TO EACH CHILD, THEN RUN THE SCRIPT (or does READY function fire??)')
	
	var sections := [engine_structure, propellent_structure, nose_structure]

	for section in sections:
		if section is Node3D:
			for wall in section.get_children():
				if wall is Node3D:
					for part in wall.get_children():
						if part.get_script() == null:
							part.set_script(MOTIONPOINT_SCRIPT)
							part.call_deferred("init_motionpoint")


	for child in self.get_children():
		if child is CollisionShape3D:
			collision_shapes.append(child)
	
func _physics_process(_delta: float) -> void:
	if all_systems_go:
		fire_particles.amount_ratio += 0.001
		gravity_scale -= .0006
		countdown_sound.volume_db -= 0.025

func launch_rocket(time):
	begin_countdown(time)
	await get_tree().create_timer(time).timeout
	await get_tree().create_timer(1.0).timeout
	freeze = false
	engine_system.freeze = false
	propellent_system.freeze = false
	
	#FEATURE: Altering the mass, gravity, freeze, etc. of each of the Systems (and Subsystems) will generate a multitude of launch sequence issues. This is needed to make each launch different, since various combinations will create differing patterns.
	
	
	all_systems_go = true
	fire_particles.emitting = true
	smoke_particles.emitting = true
	await get_tree().create_timer(0.75).timeout
	rocket_launch_sound.play()

func begin_countdown(dur):
	launch_sequence_started = true
	countdown_label.visible = true
	countdown_sound.play()
	
	# Count down from 10 to 0
	for i in range(dur, 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	
	# Hide the countdown when done
	countdown_label.visible = false
