extends KinematicBody2D

# Declare member variables here.
onready var root = get_tree().get_current_scene()
onready var camera = root.find_node("camera")
onready var gui = root.find_node("gui")
onready var monsterManager = root.find_node("monsterManager")
onready var spellManager = root.find_node("spellManager")
onready var health_value = gui.get_node('health_value')
onready var gold_value = gui.get_node('gold_value')
onready var exp_value = gui.get_node('exp_value')
onready var level_value = gui.get_node('level_value')
onready var playerpos_value = gui.get_node('playerpos_value')
onready var attack_cooldown = get_node('attack_cooldown')
onready var animation_player = get_node('AnimationPlayer')
export(int) var speed = 200
export(int) var health = 100
export(int) var max_health = 100
# Define in attack, not in player
export(int) var attack_cooldown_time = 2
export(int) var attack_range = 500
# Character values
export(int) var gold = 0
export(int) var experience = 0
export(int) var gravity = 1
export(int) var gravity_range = 1
# Cheats
export(bool) var godmode = false
# Members
var level = 1.0
var velocity = Vector2()
var experience_factor = 0.7
var alive = true
var chunks = {
	1: null,
	2: null,
	3: null,
	4: null,
	5: null,
	6: null,
	7: null,
	8: null,
	9: null
}
var active_spells = []

func _ready():
	attack_cooldown.start(attack_cooldown_time)
	active_spells.append("fireball")

func _physics_process(_delta):
	# Basic movement
	self.look_at(get_global_mouse_position())
	velocity = Vector2(0,0)
	if Input.is_action_pressed("ui_run") and self.health > 0:
		velocity = Vector2(speed, 0).rotated(rotation)
	velocity = move_and_slide(velocity)
	# Player stats display
	health_value.set_text(str(self.health))
	gold_value.set_text(str(self.gold))
	exp_value.set_text(str(self.experience))
	level_value.set_text(str(self.level))
	playerpos_value.set_text(str(self.get_global_position()))
	# Ded
	if self.health <= 0:
		self.alive = false
		self.hide()
	# Auto attack
	if attack_cooldown.time_left <= 0.01:
		var nearestMonster = monsterManager.get_nearest_monster_to_player()
		if nearestMonster != null && nearestMonster.get_dist_to_player() < attack_range:
			attack(active_spells[0], nearestMonster) # @TODO Multi spell?
			attack_cooldown.start(attack_cooldown_time)
	# @TODO Add gravity force to player, affecting only certain items (that have a flag?)

func attack(spellname, target):
	# Outsource this to the spell/spell manager
	var target_coords = target.get_global_position()
	var projectile_class = load("res://assets/scenes/projectile.tscn")
	var projectile_instance = projectile_class.instance()
	var spell = spellManager.get_spell(spellname)
	$AudioStreamPlayer2D.set_stream(spell.cast_sound)
	$AudioStreamPlayer2D.play()
	projectile_instance.set_global_position(self.get_global_position())
	projectile_instance.set_target(target_coords)
	root.add_child(projectile_instance, true)

func hurt(amount):
	if godmode:
		return
	animation_player.play('flash_hit')
	self.health = self.health-amount

func add_gold(amount):
	self.gold = self.gold+amount

func heal(amount):
	if self.health + amount >= 100:
		self.health = 100
	else:
		self.health = health + amount

func add_exp(amount):
	var exp_necessary_for_next_level = float(self.level * 600) * experience_factor
	if self.experience + amount > exp_necessary_for_next_level:
		self.add_level(1)
	self.experience = self.experience + amount

func add_level(amount):
	self.level = self.level + amount

func get_chunks():
	return self.chunks

func set_chunk(direction, chunk):
	self.chunks[direction] = chunk

func set_chunks(new_chunks_list):
	self.chunks = new_chunks_list

func _on_attack_cooldown_timeout():
	var nearestMonster = monsterManager.get_nearest_monster_to_player()
	if nearestMonster != null && nearestMonster.get_dist_to_player() < 600:
		attack(active_spells[0], monsterManager.get_nearest_monster_to_player())
		attack_cooldown.start(attack_cooldown_time)
