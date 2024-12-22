extends CharacterBody2D

var controller = (ControlHandler)
var screen_size: Vector2 = Vector2.ZERO

const WALK_SPEED: float = 250.0
var walk_speed_modifier: float = 0.0
var curr_input_direction
var dash_cool_down: float = 2.0 
var can_dash = true
enum STATES {STATE_IDLE, STATE_MOVING, STATE_DASHING, STATE_ATTACK_MAIN, STATE_ATTACK_SECONDARY}
var state: STATES = STATES.STATE_IDLE

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
func input_direction() -> void:
	curr_input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if state == STATES.STATE_DASHING:
		velocity = transform.x * WALK_SPEED * 5
	else:
		look_at(get_global_mouse_position())
		velocity = velocity.lerp(curr_input_direction * (WALK_SPEED + (WALK_SPEED * walk_speed_modifier)), 0.05)

func _process(delta: float) -> void:
	match state:
		STATES.STATE_IDLE:
			if velocity != Vector2.ZERO:
				state = STATES.STATE_MOVING
			# print("IDLE")
			if Input.is_action_pressed("attack_main"):
				state = STATES.STATE_ATTACK_MAIN
			if Input.is_action_just_pressed("attack_secondary"):
				state = STATES.STATE_ATTACK_SECONDARY
			
		STATES.STATE_MOVING:
			if velocity == Vector2.ZERO:
				state = STATES.STATE_IDLE
			else:
				# print("MOVING")
				if Input.is_action_just_pressed("ui_accept") && can_dash:
					$DashTimer.stop()
					state = STATES.STATE_DASHING
					
				if Input.is_action_pressed("attack_main"):
					state = STATES.STATE_ATTACK_MAIN
				if Input.is_action_just_pressed("attack_secondary"):
					state = STATES.STATE_ATTACK_SECONDARY
				
		STATES.STATE_DASHING:
			# print("DASH")
			can_dash = false
			await(get_tree().create_timer(0.05).timeout)
			print("DASH COOLING DOWN...")
			state = STATES.STATE_MOVING
			await(get_tree().create_timer(dash_cool_down).timeout)
			print("DASH READY!")
			can_dash = true
			
		STATES.STATE_ATTACK_MAIN:
			print("ATTACK FROM MAIN")
			state = STATES.STATE_IDLE
			
		STATES.STATE_ATTACK_SECONDARY:
			print("ATTACK FROM SECONDARY")
			state = STATES.STATE_IDLE

func _physics_process(delta: float) -> void:
	input_direction()
	move_and_slide()
	
	position.x = clamp(position.x, 0, screen_size.x) # clamp will limit a value between a range
	position.y = clamp(position.y, 0, screen_size.y)
