extends CharacterBody2D

var speed: float = 750
var damage: float = 0

func _physics_process(delta):
	velocity = transform.x * speed
	move_and_slide()

func _on_Bullet_body_entered(body):
	if body.is_in_group("mobs"):
		body.queue_free()
	queue_free()
	
func set_damage(damage_in: float) -> void:
	damage = damage_in

func _on_visible_on_screen_notifier_2d_screen_exited():
	print("BULLET GONE")
	queue_free()
