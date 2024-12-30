extends CharacterBody2D

# TODO: Figure out how to make this a template so the player and other mobs can inherit???

signal health_updated(health)
signal killed

@export var max_health: int = 0
@onready var health: int = max_health : set = _set_health, get = get_health
@onready var invulnerability_timer = $InvulnerabilityTimer

func _ready() -> void:
	print("Current Health: " + str(health))

func damage(damage_in: int) -> void:
	if invulnerability_timer.is_stopped():
		invulnerability_timer.start()
		_set_health(health - damage_in)

func _set_health(new_health: int) -> void:
	var prev_health = health
	health = clamp(new_health, 0, max_health)
	
	if health != prev_health:
		emit_signal("health_updated", health)
		if health == 0:
			emit_signal("killed")
			kill()

func kill() -> void:
	queue_free()

func get_health() -> int:
	return health
