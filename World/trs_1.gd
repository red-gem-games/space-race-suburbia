extends RigidBody3D
class_name TRS_1

var is_rocketship: bool = true

var MOTIONPOINT_SCRIPT: Script = preload("res://World/wall_motionpoint.gd")

@onready var base_section: Node3D = $Base
@onready var mid_section: Node3D = $Middle
@onready var nose_section: Node3D = $Nose
var structure_walls: Array = []

func _ready() -> void:
	print('Process to create motionpoint collision layer:')
	print('1. Generate outline of wall mesh (0.4)')
	print('2. Generate collision (Single Convex)')
	print('3. Delete Outline Mesh')
	print('4. Move Collision Layer to Area3D parent')
	
	
	print('-------')
	print('ADD SCRIPT TO EACH CHILD, THEN RUN THE SCRIPT (or does READY function fire??)')
	
	var sections := [base_section, mid_section, nose_section]

	for section in sections:
		for child in section.get_children():
			if child is Area3D:
				if child.get_script() == null:
					child.set_script(MOTIONPOINT_SCRIPT)
					child.call_deferred("init_motionpoint")
