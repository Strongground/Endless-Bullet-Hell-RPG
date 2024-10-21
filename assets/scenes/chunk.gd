extends Area2D

onready var root = get_tree().get_current_scene()
onready var player = root.find_node('player')
onready var monsterManager = root.find_node('monsterManager')
onready var chunkManager = root.find_node('chunkManager')
onready var ground_texture = get_node('ground_texture')
var is_visible = false
var is_active = false
var biome
var biome_name
var landscape
# Should at one point be an array of all monsters belonging to the chunk
var monsters : Array
var rng

func _process(_delta):
	pass
	# $NodeNameContainer/NodeName.bbcode_text = self.name

func _ready():
	rng = RandomNumberGenerator.new()
	# Add chunks global position to seed, hash it and use it as seed for rng
	rng.set_seed(hash(root.get_seed()+(self.global_position.x+self.global_position.y)))

func _on_chunk_body_shape_entered(_body_id, body, _body_shape, _local_shape):
	if not self.is_active:
		if body.get_name() == 'player':
			self.is_active = true
			chunkManager.set_active(self)

# Simple getter for biome
func get_biome():
	return self.biome

# Simple getter for landscape
func get_landscape():
	return self.landscape

# Getter for monster count
func get_monster_count():
	return self.monsters.size()

# Setter for monsters
func add_monster(monster):
	self.monsters.append(monster)

# Setter for ground texture
func set_ground_texture(sprites):
	# Get random sprite from array of sprites
	var sprite = sprites[rng.randi_range(0, sprites.size()-1)]
	ground_texture.set_texture(load("res://assets/textures/terrain/ground/"+sprite+'.jpg'))

# Set all terrain related properties
func set_terrain(set_biome_name):
	# var chunk_size_offset = chunkManager.get_chunk_size() / 2
	# var origin = self.get_transform().get_origin()
	# root.draw_marker(origin, Color(1, 0.4, 0.4, 1), 1)
	# var top_left = origin - Vector2(chunk_size_offset, chunk_size_offset)
	# var bottom_right = origin + Vector2(chunk_size_offset, chunk_size_offset)
	self.biome_name = set_biome_name
	self.biome = chunkManager.get_biome(set_biome_name)
	self.landscape = self._get_random_landscape(biome)
	self.monsters = self.landscape['monsters']
	self.set_ground_texture(self.landscape['ground_texture'])
	# Generate decorations
	# There is a chance (defined in biome) that this tile is a "location"
	# with predefined clutter, enemies and loot. In that case place the
	# predefined clutter instead of random.
	var location = self._get_random_location(set_biome_name)
	# print(location)
	if location:
		self._spawn_location(location)
	else:
		_create_clutter(self.landscape, self.rng)

# Guaranteed to return one of the landscape types defined in the biome,
# based on its chance.
func _get_random_landscape(get_biome):
	var rand = rng.randf()
	var current_chance = 0.0
	for curr_landscape in get_biome:
		current_chance += curr_landscape.likeliness
		if rand <= current_chance:
			return curr_landscape

# Maybe return a location name, maybe return False...
func _get_random_location(of_biome_name):
	# print("Got biome name "+str(of_biome_name))
	var rand = rng.randf()
	var locations = chunkManager.get_locations()
	for location in locations["random_locations"]:
		if self.biome_name in location.biomes && rand < (location.chance * rng.randf()):
			return location.name
	return false

func _create_clutter(is_landscape, global_rng):
	var x_pos
	var y_pos
	var clutter_class = preload("res://assets/scenes/clutter.tscn")
	for type in is_landscape['clutter_types']:
		type = is_landscape['clutter_types'][type]
		var amount_clutter = global_rng.randi_range(type['min'], type['max'])
		for _i in range(amount_clutter+1):
			var clutter_instance = clutter_class.instance()
			self.add_child(clutter_instance)
			clutter_instance.z_index = type['z-index']
			var random_sprite = global_rng.randi_range(0,type['sprites'].size()-1)
			clutter_instance.set_sprite(load('res://assets/textures/terrain/'+type['sprites'][random_sprite]))
			clutter_instance.rotate(deg2rad(global_rng.randi_range(0, 360)))
			# Set position of clutter inside chunk
			x_pos = global_rng.randi_range((chunkManager.get_chunk_size()/2*-1), chunkManager.get_chunk_size()/2)
			y_pos = global_rng.randi_range((chunkManager.get_chunk_size()/2*-1), chunkManager.get_chunk_size()/2)
			clutter_instance.position = Vector2(x_pos, y_pos)

func _spawn_location(location_name):
	var node_name = "res://assets/scenes/locations/"+location_name+".tscn"
	var location_node = load(node_name)
	var location_instance = location_node.instance()
	self.add_child(location_instance)
	location_instance.position = Vector2((chunkManager.get_chunk_size()/2*-1),(chunkManager.get_chunk_size()/2*-1))
