extends Node2D

var casting_sounds_path = "res://assets/sounds/"
onready var root = get_tree().get_current_scene()
onready var player = root.find_node('player')

func _ready():
	pass

func get_spell(spellname):
	var spell = root.read_json('assets/spells/'+spellname+'.json')
	spell.cast_sound = load(casting_sounds_path+'/'+spell.cast_sound)
	return spell

func get_active_spell():
	return player.active_spells[0]