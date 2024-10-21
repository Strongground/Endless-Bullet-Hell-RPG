extends RigidBody2D
onready var root = get_tree().get_current_scene()
onready var lifetime = get_node('lifetime')
onready var fade_timer = get_node('fade_timer')
onready var animation_player = get_node('AnimationPlayer')
onready var collider = get_node('CollisionShape2D')
onready var effect_class = load("res://assets/scenes/effect.tscn")
var colliding_bodies
var target
var speed = 10
var damage_type = 'fire'
var damage = 10

func _ready():
	lifetime.start(3)

func set_target(target_coords):
	self.target = target_coords
	self.add_force(Vector2(0,0), (target-self.get_global_position()).normalized()*speed)

func _physics_process(_delta):
	# Collision detection
	colliding_bodies = self.get_colliding_bodies()
	if len(colliding_bodies) > 0:
		for body in colliding_bodies:
			if "monster" in body.get_name():
				var effect_instance = effect_class.instance()
				effect_instance.init("fire_explosion3", null, null)
				root.add_child(effect_instance, true)
				effect_instance.set_global_position(self.get_global_position())
				self.speed = 0
				self.contact_monitor = false
				self._decay()
				body.hurt(self)

func _decay():
	set_sleeping(true)
	animation_player.play('fade_away')
	fade_timer.start(1)

func _kill():
	queue_free()
