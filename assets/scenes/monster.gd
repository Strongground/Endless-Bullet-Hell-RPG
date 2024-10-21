extends KinematicBody2D

onready var root = get_tree().get_current_scene()
onready var monsterManager = root.find_node('monsterManager')
onready var chunkManager = root.find_node('chunkManager')
onready var player = root.find_node('player')
onready var attack_timer = get_node('attack_timer')
onready var hit_anim = get_node('hit')
onready var collider = get_node('CollisionShape2D')
export(int) var speed = 150
export(int) var health = 10
export(int) var loot_drop_chance = 50
export(int) var potion_drop_chance = 30
export(int) var gold_drop_chance = 60
var velocity = null
var dist_to_player = -1
var dead = false
var alerted = false
# Fill these initially from JSON
var level = 1
var exp_factor = 10
var type = ''

func _ready():
	pass

# Simple setter for monster type
func set_type(monster_type):
	type = monster_type

func _process(_delta):
	if not dead:
		# Keep track of distance to player
		self.dist_to_player = self.get_global_position().distance_to(player.get_global_position())
		# Basic Movement
		self.notice_player()
		# Attacking
		self.attack()
		# Dead
		if health <= 0:
			_handle_death()
		if alerted:
			follow_player()
		# Keep rotation of floating damage number straight
		$damage_number.rotation_degrees = -1 * self.rotation_degrees

func get_dist_to_player():
	return self.dist_to_player

func notice_player():
	if self.get_dist_to_player() < chunkManager.get_chunk_size()/4:
		alerted = true

func follow_player():
		look_at(player.get_global_position())
		velocity = Vector2(speed, 0).rotated(rotation)
		velocity = move_and_slide(velocity)

func attack():
	if self.dist_to_player <= 50:
		if (attack_timer.is_stopped() or attack_timer.time_left <= 0.1) and not self.dead:
			attack_timer.start(1.5)
			player.hurt(5)
	else:
		attack_timer.stop()

func is_dead():
	return dead

func get_random_location(rand_factor=10):
	var random_location = Vector2((self.get_global_position().x+randi() % rand_factor), (self.get_global_position().y+randi() % rand_factor))
	return random_location

func hurt(source):
	if !is_dead():
		self.health = health - source.damage
		show_damage(source.damage)
		hit_anim.play('hit')
		alerted = true
		
func show_damage(damage):
	$damage_number/number.bbcode_text = '[center]' + str(damage) + '[/center]'
	$AnimationPlayer.play("damage_number_float")

func _handle_death():
	if !is_dead():
		# Play some kind of death animation
		self.dead = true
		_drop_loot()
		_drop_exp()
		self.collider.disabled = true
		self.z_index = 1

func _drop_loot():
	var drop_type
	var loot_class = load("res://assets/scenes/loot.tscn")
	var amount
	randomize()
	if randi() % 100 <= self.loot_drop_chance:
		if randi() % 100 <= self.potion_drop_chance:
			drop_type = 'potion'
			amount = 1
		elif randi() % 100 <= self.gold_drop_chance:
			drop_type = 'gold'
			var amount_factor
			if self.level > 1:
				amount_factor = self.level / 3
			else:
				amount_factor = 0.5
			amount = (randi() % 300) * amount_factor
		else:
			return
		var loot_instance = loot_class.instance()
		root.add_child(loot_instance, true)
		loot_instance.set_global_position(self.get_random_location())
		loot_instance.set_type(drop_type, amount)

func _drop_exp():
	var exp_orb_class = load("res://assets/scenes/exp_orb.tscn")
	var exp_orb_amount = self.level * self.exp_factor
	print("exp_orb_amount: "+str(exp_orb_amount))
	for orb in exp_orb_amount:
		var exp_orb_instance = exp_orb_class.instance()
		root.add_child(exp_orb_instance, true)
		exp_orb_instance.set_global_position(self.get_random_location(100))
		exp_orb_instance.set_amount(self.level * self.exp_factor)