extends Area2D

var amount
var is_pulled = false
var speed
onready var player = get_node("/root/world/player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# 
func _physics_process(delta):
	if is_pulled:
		# Move towards player when in magnetic sphere, without using move_and_slide since this is an area2d and not a kinetmaticbody2d
		var direction =	(player.get_global_position() - self.get_global_position()).normalized()
		# Speed is based on distance to player, speed is getting higher the closer the orbs get to the player
		speed = 10000 / (player.get_global_position() - self.get_global_position()).length()
		self.set_global_position(self.get_global_position() + direction * speed * delta)
		# If the orb is close enough to the player, remove the orb and add experience to the player
		if self.get_global_position().distance_to(player.get_global_position()) < 10:
			self._absorb()

# Set amount of experience dropped
func set_amount(add_amount):
	self.amount = add_amount

func _absorb():
	player.add_exp(self.amount)
	self.visible = false
	self.is_pulled = false
	_play_sound()

func _play_sound():
	var sound = load("res://assets/sounds/exp_collect.wav")
	$AudioStreamPlayer2D.set_stream(sound)
	$AudioStreamPlayer2D.play()

# Trigger when in players magnetic sphere 
func _on_Node2D_area_entered(area:Area2D):
	if area.get_name() == "magnetic_sphere":
		self.is_pulled = true

func _on_AudioStreamPlayer2D_finished():
	queue_free()
