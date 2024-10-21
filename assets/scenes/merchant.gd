extends Node2D
# Merchant Class
# Merchant can be of random specialization
# Specializations each define which items the merchant has to offer
# merchant.json to define specializations
# items.json to define items and which merchant offers them (as well as effect, amount and base price)
# Final price is based on base price * player traits modifiers, player level and active runes modifiers.

export (String, "potions", "items", "runes") var merchant_type

onready var activation_region = find_node("$CollisionShape2D")
onready var root = get_tree().get_current_scene()
onready var popup = root.ui.get_node("merchant_popup")

var purchasable_items = []

func _ready():
    var all_purchasable_items = root.read_json('assets/items.json')
    self.purchasable_items = all_purchasable_items[merchant_type]

func _on_container_body_shape_entered(_body_rid:RID, body:Node, _body_shape_index:int, _local_shape_index:int):
    if body.get_name() == 'player':
        popup.popup()