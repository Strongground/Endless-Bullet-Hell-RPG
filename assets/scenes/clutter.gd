extends Node2D

onready var sprite = get_node('Sprite')

func set_sprite(set_sprite):
	self.get_node('Sprite').set_texture(set_sprite)
