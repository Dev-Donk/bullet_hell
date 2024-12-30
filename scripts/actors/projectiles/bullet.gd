extends Area2D

var speed: float = 750
@export var recoil: float = 1
@export var _max_damage_amount: int = 1
@onready var _damage_amount: int = _max_damage_amount : set = set_damage_amount, get = get_damage_amount

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_Bullet_body_entered(body):
	if body.is_in_group("mobs"):
		body.damage(_damage_amount)
		print(body.get_health())
	queue_free()
	
func set_damage_amount(new_damage_amount: int) -> void:
	_damage_amount = clamp(new_damage_amount, 1, _max_damage_amount)
func get_damage_amount() -> int:
	return _damage_amount

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
