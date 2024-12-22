extends CharacterBody2D

var controller = (ControlHandler)
var screen_size: Vector2 = Vector2.ZERO

var curr_input_direction

const WALK_SPEED: float = 250.0
var _prev_walk_speed_modifier: float
var _walk_speed_modifier: float = 1.0

var _dash: float = 2.5
const DASH_COOL_DOWN: float = 2.0
var _dash_cool_down_modifier: float = 0.0
var is_dashing: bool = false
var _can_dash: bool = true

var _bullet_main: PackedScene = load("res://bullet_simple.tscn")
const SHOOT_MAIN_COOL_DOWN: float = 2.0
var _shoot_main_cool_down_modifier: float = 0.0
var _can_shoot_main: bool = true

var _bullet_secondary: PackedScene = load("res://bullet_simple.tscn")
const SHOOT_SECONDARY_COOL_DOWN: float = 4.0
var _shoot_secondary_cool_down_modifier: float = 0.0
var _can_shoot_secondary: bool = true

var is_shooting: bool = false

enum STATES {STATE_IDLE, STATE_MOVING, STATE_DASHING, STATE_ATTACK_MAIN, STATE_ATTACK_SECONDARY}
var state: STATES = STATES.STATE_IDLE

# TODO: The algorithms to clamp each value could be done more effeciently, it's getting to be a bit too much

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
			if Input.is_action_pressed("attack_main") && _can_shoot_main:
				state = STATES.STATE_ATTACK_MAIN
			if Input.is_action_just_pressed("attack_secondary") && _can_shoot_secondary:
				state = STATES.STATE_ATTACK_SECONDARY
			
		STATES.STATE_MOVING:
			if velocity == Vector2.ZERO:
				state = STATES.STATE_IDLE
			else:
				# print("MOVING")
				if Input.is_action_just_pressed("ui_accept") && _can_dash && !is_shooting:
					state = STATES.STATE_DASHING
					
				if Input.is_action_pressed("attack_main") && _can_shoot_main && !is_dashing:
					state = STATES.STATE_ATTACK_MAIN
				if Input.is_action_just_pressed("attack_secondary") && _can_shoot_secondary && !is_dashing:
					state = STATES.STATE_ATTACK_SECONDARY
				
		STATES.STATE_DASHING: # Could you make a method out of this???
			# print("DASH")
			_can_dash = false
			is_dashing = true
			await(get_tree().create_timer(0.05).timeout)
			print("DASH COOLING DOWN...")
			is_dashing = false
			_check_if_idle()
			
			await(get_tree().create_timer(get_net_dash_cooldown()).timeout)
			print("DASH READY!")
			_can_dash = true

		STATES.STATE_ATTACK_MAIN: # Could you make a method out of this???
			print("ATTACK FROM MAIN")
			
			_shoot(_bullet_main)
			_check_if_idle()
			
			await(get_tree().create_timer(get_net_shoot_main_cooldown()).timeout)
			_can_shoot_main = true
			
		STATES.STATE_ATTACK_SECONDARY:
			print("ATTACK FROM SECONDARY")
			_check_if_idle()

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

func set_bullet_main(bullet_new: PackedScene) -> void:
	_bullet_main = bullet_new
func set_shoot_main_cool_down_modifier(new_value: float, flag: bool) -> void:
	if flag == true:
		_shoot_main_cool_down_modifier = clamp(new_value, 0.0, 1)
	else:
		_shoot_main_cool_down_modifier = new_value
func add_to_shoot_main_cool_down_modifier(value: float, flag: bool) -> void:
	_shoot_main_cool_down_modifier += value
	if flag == true:
		_shoot_main_cool_down_modifier = clamp(_shoot_main_cool_down_modifier, 0.0, 1)
func get_net_shoot_main_cooldown() -> float:
	return SHOOT_MAIN_COOL_DOWN - (SHOOT_MAIN_COOL_DOWN * _shoot_main_cool_down_modifier)

func set_bullet_secondary(bullet_new: PackedScene) -> void:
	_bullet_secondary = bullet_new

func _shoot(bullet: PackedScene) -> void:
	var b = bullet.instantiate()
	
	_can_shoot_main = false
	is_shooting = true
	
	owner.add_child(b)
	b.set_damage(5)
	b.transform = $Gun.global_transform
	
	is_shooting = false
	
func _check_if_idle() -> void:
	if velocity != Vector2.ZERO:
		state = STATES.STATE_MOVING
	else:
		state = STATES.STATE_IDLE
