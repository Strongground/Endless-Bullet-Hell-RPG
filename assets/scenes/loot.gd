extends Node2D

onready var root = get_tree().get_current_scene()
onready var player = root.find_node('player')
onready var animation = get_node('AnimatedSprite')
export(String, "potion", "gold") var drop_type
export var amount = 1

func _ready():
	pass # Replace with function body.
	set_type(self.drop_type, self.amount)

func get_type():
	return drop_type

func set_type(type, set_amount):
	self.drop_type = type
	self.animation.play(type)
	self.amount = set_amount

func _on_Area2D_body_entered(body):
	# only continue if pickup condition satisfied
	var player_needs_health = player.health < player.max_health
	if body.name == 'player':
		if player_needs_health || self.drop_type == 'gold':
			if self.drop_type == 'gold':
				player.add_gold(self.amount)
			elif self.drop_type == 'potion':
				player.heal(30)
			$AnimatedSprite.modulate = Color(1,1,1,0)
			_play_sound(drop_type)
		
func _play_sound(loot_type):
	var sound = load("res://assets/sounds/"+loot_type+".wav")
	$AudioStreamPlayer2D.set_stream(sound)
	$AudioStreamPlayer2D.play()

func _on_AudioStreamPlayer2D_finished():
	queue_free()
