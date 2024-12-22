extends Area2D

var speed: float = 750
var damage: float = 0

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_Bullet_body_entered(body):
	if body.is_in_group("mobs"):
		body.queue_free()
	queue_free()
	
func set_damage(damage_in: float) -> void:
	damage = damage_in
