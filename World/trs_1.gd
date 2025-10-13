extends RigidBody3D
class_name TRS_1

var is_rocketship: bool = true
var all_systems_go: bool = false

var MOTIONPOINT_SCRIPT: Script = preload("res://World/wall_motionpoint.gd")

@onready var base_section: Node3D = $Base
@onready var mid_section: Node3D = $Mid
@onready var nose_section: Node3D = $Nose
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
	
	var sections := [base_section, mid_section, nose_section]

	for section in sections:
		if section is Node3D:
			print(section)
			for wall in section.get_children():
				if wall is Node3D:
					for part in wall.get_children():
						if part.get_script() == null:
							part.set_script(MOTIONPOINT_SCRIPT)
							part.call_deferred("init_motionpoint")
							#print(part.name)


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
