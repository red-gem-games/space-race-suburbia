extends RigidBody3D
class_name TRS_1

var is_rocketship: bool = true

var MOTIONPOINT_SCRIPT: Script = preload("res://World/wall_motionpoint.gd")

@onready var base_section: Node3D = $Base
@onready var mid_section: Node3D = $Mid
@onready var nose_section: Node3D = $Nose
var structure_walls: Array = []

func _ready() -> void:

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
							print(part.name)
