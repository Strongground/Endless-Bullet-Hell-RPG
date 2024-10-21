extends Node2D

export(String) var world_seed = 'blueberry-pie'
onready var root = get_tree().get_current_scene()
onready var player = root.find_node('player')

func _ready():
	seed(self.world_seed.hash())

func get_seed():
	return self.world_seed.hash()

func draw_marker(position, color, scale):
	var marker = Sprite.new()
	marker.texture = load('res://assets/marker.png')
	marker.position = position
	marker.modulate = color
	marker.scale = Vector2(scale, scale)
	marker.z_index = 100
	self.add_child(marker)

# This reads a JSON file and returns a dictionary containing all information from it.
# @input {String} the path to a file, relative to res://
# @outputs {Dictionary} A dictionary containing all nodes from the JSON file
func read_json(file_path):
	var file_contents = {}
	var file = File.new()
	file.open(file_path, file.READ)
	var text = file.get_as_text()
	file_contents = JSON.parse(text)
	file.close()
	return file_contents.result
