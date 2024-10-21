extends Node2D

export(String, "fire", "magic", "glow") var type = "fire"

func _ready():
	if type == "fire":
		$"./fire".visible = true
		$"./magic".visible = false
		$"./glow".visible = false
		# Fire is default, so do nothing
		# pass
	elif type == "magic":
		$"./fire".visible = false
		$"./magic".visible = true
		$"./glow".visible = false
		# $"./fire/particles".emitting = false
		# $"./fire/light".energy = 0
		# $"./magic/particles".emitting = true
		# $"./magic/light".energy = 2
	elif type == "glow":
		$"./fire".visible = false
		$"./magic".visible = false
		$"./glow".visible = true
