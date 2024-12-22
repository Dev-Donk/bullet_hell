extends CharacterBody2D

var controller = (ControlHandler)
var screen_size: Vector2 = Vector2.ZERO

var curr_input_direction

const WALK_SPEED: float = 250.0
var _prev_walk_speed_modifier: float
var _walk_speed_modifier: float = 1.0

var _prev_dash: float
var _dash: float = 2.5

var _prev_dash_cool_down: float
const DASH_COOL_DOWN: float = 2.0
var _dash_cool_down_modifier: float = 0.0

var can_dash = true

enum STATES {STATE_IDLE, STATE_MOVING, STATE_DASHING, STATE_ATTACK_MAIN, STATE_ATTACK_SECONDARY}
var state: STATES = STATES.STATE_IDLE

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
func _input_direction() -> void:
	curr_input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if state == STATES.STATE_DASHING:
		velocity = transform.x * get_net_walk_speed() * _dash
	else:
		look_at(get_global_mouse_position())
		velocity = velocity.lerp(curr_input_direction * get_net_walk_speed(), 0.05)

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
			
			await(get_tree().create_timer(get_net_dash_cooldown()).timeout)
			print("DASH READY!")
			can_dash = true
			
		STATES.STATE_ATTACK_MAIN:
			print("ATTACK FROM MAIN")
			state = STATES.STATE_IDLE
			
		STATES.STATE_ATTACK_SECONDARY:
			print("ATTACK FROM SECONDARY")
			state = STATES.STATE_IDLE

func _physics_process(delta: float) -> void:
	_input_direction()
	move_and_slide()
	
	position.x = clamp(position.x, 0, screen_size.x) # clamp will limit a value between a range
	position.y = clamp(position.y, 0, screen_size.y)

func set_walk_speed_modifier(new_value: float) -> void:
	_walk_speed_modifier = clamp(new_value, 0.0, 1)
func add_to_walk_speed_modifier(value: float) -> void:
	_walk_speed_modifier += value
	_walk_speed_modifier = clamp(_walk_speed_modifier, 0.0, 1)
func get_net_walk_speed() -> float:
	return WALK_SPEED + (WALK_SPEED * _walk_speed_modifier)

func set_dash(new_value: float) -> void:
	_dash = clamp(new_value, 2.5, 10)
func add_to_dash(value: float) -> void:
	_dash += value
	_dash = clamp(_dash, 2.5, 10)

func set_dash_cool_down_modifier(new_value: float, flag: bool) -> void:
	if flag == true:
		_dash_cool_down_modifier = clamp(new_value, 0.0, 1)
	else:
		_dash_cool_down_modifier = new_value
func add_to_dash_cool_down_modifier(value: float, flag: bool) -> void:
	_dash_cool_down_modifier += value
	if flag == true:
		_dash_cool_down_modifier = clamp(_dash_cool_down_modifier, 0.0, 1)
func get_net_dash_cooldown() -> float:
	return DASH_COOL_DOWN - (DASH_COOL_DOWN * _dash_cool_down_modifier)
