extends Node2D

onready var root = get_tree().get_current_scene()
onready var player = root.find_node('player')
onready var chunkManager = root.find_node('chunkManager')
onready var spawn_area = root.find_node('monster_spawn_area')
var monster_list = []

func _process(delta):
	self.clean()

# Method for spawning of monsters on defined position
# @TODO should be expanded to allow for spawning based on monster list or specific monster ID
# @input (Object) root_chunk: the chunk that the monster will be spawned in
# @input (Int) amount: Number of monsters to spawn
func spawn_monsters(root_chunk, amount):
	var position = root_chunk.get_global_position()
	var monster_class = load("res://assets/scenes/monster.tscn")
	var possible_types = root_chunk.get_landscape()['monsters']
	var monster_type
	var chunk_size = int(chunkManager.get_chunk_size())
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for _i in range(amount):
		var monster_instance = monster_class.instance()
		var x_pos = rng.randi_range(position.x-chunk_size/4, position.x+chunk_size/4)
		var y_pos = rng.randi_range(position.y-chunk_size/4, position.y+chunk_size/4)
		# root.draw_marker(Vector2(x_pos,y_pos))
		root.add_child(monster_instance, true)
		if possible_types.size() > 1:
			# select random monster type
			monster_type = possible_types[randi() % possible_types.size()]
		else:
			monster_type = possible_types[0]
		monster_instance.set_type(monster_type)
		monster_instance.set_global_position(Vector2(x_pos, y_pos))
		root_chunk.add_monster(monster_instance)
		monster_list.append(monster_instance)

# Since we create monsters in any surrounding chunks, even if the player never goes there, we regularly
# need to do garbage collection. These values will probably change later.
# Atm this also applies to dead monsters.
func clean():
	if monster_list.size() > 500:
		for monster in monster_list:
			if monster.get_dist_to_player() > 1000:
				monster_list.erase(monster)
				monster.queue_free()

func get_nearest_monster_to_player():
	if monster_list.size() > 0:
		var nearest_monster = null
		for monster in monster_list:
			if not monster.is_dead():
				if nearest_monster == null:
					nearest_monster = monster
				# get_dist_to_player() returns -1 if monster didn't yet update distance. In this case, skip the monster for now.
				elif monster.get_dist_to_player() > 0 && monster.get_dist_to_player() < nearest_monster.get_dist_to_player():
					nearest_monster = monster
		return nearest_monster