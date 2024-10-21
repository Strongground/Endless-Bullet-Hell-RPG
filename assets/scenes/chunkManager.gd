extends Node2D

export (int) var chunk_size = 1024
onready var root = get_tree().get_current_scene()
onready var monsterManager = root.find_node('monsterManager')
onready var player = root.find_node('player')
var active_chunk = null
var biomes = self._read_json('res://assets/biomes.json')
var locations = self._read_json('res://assets/locations.json')
const DIRECTION_MATRIX = {
	'N': 2,
	'NE': 3,
	'E': 6,
	'SE': 9,
	'S': 8,
	'SW': 7,
	'W': 4,
	'NW': 1,
}
var first_run = false

func _ready():
	pass

# This reads a JSON file and returns a dictionary containing all information from it.
# This is here as well as in world.gd because of the load order.
# @input {String} the path to a file, relative to res://
# @outputs {Dictionary} A dictionary containing all nodes from the JSON file
func _read_json(file_path):
	var file_contents = {}
	var file = File.new()
	file.open(file_path, file.READ)
	var text = file.get_as_text()
	file_contents = JSON.parse(text)
	if file_contents.error_string.length() > 0:
		print('Error: Could not parse JSON file: ',file_path,'; Error: ',file_contents.error_string,' in line ',str(file_contents.error_line))
		file.close()
		return false
	file.close()
	return file_contents.result

func get_locations():
	return self.locations

func set_active (chunk):
	var a_chunk = self.get_active_chunk()
	if a_chunk != null:
		a_chunk.is_active = false
	self.active_chunk = chunk
	_create_chunks()

func get_active_chunk():
	if self.active_chunk != null:
		return self.active_chunk
	else:
		return root.find_node("5")

func get_chunk_size():
	return self.chunk_size

func get_biome(biome_name):
	for biome in self.biomes:
		if biome == biome_name:
			return self.biomes[biome_name]

func get_landscape(biome, key):
	for landscape in biome['landscapes']:
		if landscape['key'] == key:
			return landscape

func get_landscapes(biome):
	if biome in self.biomes:
		return self.biomes[biome]

# get monster types based on biome and landscape
func get_monster_types(biome, landscape):
	if biome in self.biomes:
		if landscape in self.biomes[biome]:
			return self.biomes[biome][landscape]['monsters']

# Class method
# Get coordinates for new chunk to place, relative to
# a given coordinate set. It is implied the given coordinates
# are that of another chunk.
# @input {Vector2} origin
# @input {String} direction Should be one of: N, NE, E, SE, S, SW, W, NW
func _get_relative_coords(origin, direction):
	direction = int(direction)
	var coords = Vector2(0,0)
	# 5 is TYPE_VECTOR2
	if typeof(origin) == 5:
		if direction == DIRECTION_MATRIX['NW']:
			coords = Vector2(origin.x-chunk_size, origin.y-chunk_size)
		elif direction == DIRECTION_MATRIX['N']:
			coords = Vector2(origin.x, origin.y-chunk_size)
		elif direction == DIRECTION_MATRIX['NE']:
			coords = Vector2(origin.x+chunk_size, origin.y-chunk_size)
		elif direction == DIRECTION_MATRIX['W']:
			coords = Vector2(origin.x-chunk_size, origin.y)
		elif direction == DIRECTION_MATRIX['E']:
			coords = Vector2(origin.x+chunk_size, origin.y)
		elif direction == DIRECTION_MATRIX['SW']:
			coords = Vector2(origin.x-chunk_size, origin.y+chunk_size)
		elif direction == DIRECTION_MATRIX['S']:
			coords = Vector2(origin.x, origin.y+chunk_size)
		elif direction == DIRECTION_MATRIX['SE']:
			coords = Vector2(origin.x+chunk_size, origin.y+chunk_size)
		return coords

func _create_chunks():
	# For the first run, add starting chunk manually to player
	self.first_run = false
	if player.get_chunks()[5] == null:
		player.set_chunk(5, self.get_active_chunk())
		self.first_run = true
	var chunk_class = preload("res://assets/scenes/chunk.tscn")
	# Reorder the chunks according to player matrix and move direction
	# and determine the new chunks to be created
	var create_chunks = _reorder_matrix()
	# If at least one neighbour doesn't exist...
	if create_chunks.size() > 0:
		var origin = self.get_active_chunk().get_global_transform().origin
		for matrix_pos in create_chunks:
			var chunk_instance = chunk_class.instance()
			var new_chunk_pos = self._get_relative_coords(origin, matrix_pos)
			chunk_instance.set_global_position(new_chunk_pos)
			player.set_chunk(matrix_pos, chunk_instance)
			chunk_instance.set_name(str(matrix_pos))
			root.add_child(chunk_instance, true)
			# @TODO These biomes and landscapes need to be random, but based on something like Perlin Noise so
			# the transitions are soft and same-biome chunks are bundled in larger swatches
			chunk_instance.set_terrain('TEMPERATE')
			# Spawn monsters based on player level and chunk biome data
			monsterManager.spawn_monsters(chunk_instance, ceil(0.4*player.level))

func _reorder_matrix():
	var delete_chunks = []
	var create_chunks = [1,2,3,4,6,7,8,9]
	var operator = 0
	if int(self.active_chunk.get_name()) == 2:
		operator = 3
		delete_chunks = [7,8,9]
		create_chunks = [1,2,3]
	elif int(self.active_chunk.get_name()) == 8:
		operator = -3
		delete_chunks =  [1,2,3]
		create_chunks = [7,8,9]
	elif int(self.active_chunk.get_name()) == 6:
		operator = -1
		delete_chunks =  [1,4,7]
		create_chunks = [3,6,9]
	elif int(self.active_chunk.get_name()) == 4:
		operator = 1
		delete_chunks =  [3,6,9]
		create_chunks = [1,4,7]
	# Create copy of current chunk list
	var new_chunks_list = {}
	var current_chunks_list = player.get_chunks()
	# For each position in player chunk matrix, move it to its new
	# place in the player chunk matrix copy, which in the end will
	# replace the current matrix. This way we avoid overwriting references
	# we later need.
	for chunk_pos in current_chunks_list:
		var chunk = current_chunks_list[chunk_pos]
		var new_chunk_pos = chunk_pos + operator
		if chunk != null and !(int(chunk.get_name()) in delete_chunks):
			new_chunks_list[new_chunk_pos] = chunk
	# Delete chunks which are no longer needed
	for chunk_pos in delete_chunks:
		# Delete chunk from player chunks list
		var chunk = current_chunks_list[chunk_pos]
		chunk.free()
	# Finally replace current chunk list with new chunk list, if not first run
	if self.first_run == false:
		# Quickly rename all chunks first, to work around an issue with duplicate names
		for chunk_pos in player.get_chunks():
			var chunk = player.get_chunks()[chunk_pos]
			if !(chunk_pos in delete_chunks):
				chunk.set_name(str(chunk.get_name()+'_'))
		# Now replace the chunks_list
		player.set_chunks(new_chunks_list)
		for chunk_pos in new_chunks_list:
			var chunk = new_chunks_list[chunk_pos]
			if chunk != null:
				chunk.set_name(str(chunk_pos))
	return create_chunks
