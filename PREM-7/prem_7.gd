extends Node3D
class_name PREM_7

@onready var trig_anim: AnimationPlayer = $Trigger_Animation
@onready var mode_anim: AnimationPlayer = $Mode_Animation

@onready var back_glow: MeshInstance3D = $Multitool/Back_Glow
@onready var photon_glow: MeshInstance3D = $Multitool/Photon_Glow

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass

func _process(delta: float) -> void:
	pass
