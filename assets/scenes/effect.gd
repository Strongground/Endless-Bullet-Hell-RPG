extends Node2D

var lifetime = null
var loop = false

func _ready():
	pass

func _process(_delta):
	if lifetime != null:
		if $Timer.remaining_time == 1:
			$Animationplayer.play('fade_out')
	
func init(type, set_loop, set_lifetime):
	# Lifetime
	if not set_loop && set_lifetime:
		$Timer.start(set_lifetime)
	# Sound
	var sound = load("res://assets/sounds/effects/"+type+".wav")
	$AudioStreamPlayer.set_stream(sound)
	$AudioStreamPlayer.play()
	# Animation
	$AnimatedSprite.animation = type
	$AnimatedSprite.play()

func _on_animation_finished():
	if not self.loop:
		queue_free()
	$AnimatedSprite.play()

func _on_lifetime_ends():
	queue_free()
