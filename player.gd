extends CharacterBody2D

signal dashing
signal hit
signal shooting

var controller = (ControlHandler)
var screen_size: Vector2 = Vector2.ZERO

var _base_health: int = 3
var _curr_health: int = _base_health

const DEFAULT_WALK_SPEED: float = 250.0
const MIN_WALK_SPEED: float = 50.0
const MAX_WALK_SPEED: float = 500.0

var _prev_walk_speed_modifier: float
var _walk_speed_modifier: float = 0.0

const MIN_COOL_DOWN: float = 0.25
const MAX_COOL_DOWN: float = 120.0

const DASH_SPEED: float = 5.0

const DASH_COOL_DOWN: float = 4.0
var is_dashing: bool = false
var _can_dash: bool = true
var _dash_cool_down_modifier: float = 0.0

var is_shooting: bool = false
const MIN_RECOIL_INTENSITY: float = 0.5
const MAX_RECOIL_INTENSITY: float = 10.0

var _bullet_main: PackedScene = load("res://bullet_simple.tscn")
const SHOOT_MAIN_COOL_DOWN: float = 1.5
var _can_shoot_main: bool = true
var _shoot_main_cool_down_modifier: float = 0.0
var RECOIL_INTENSITY_MAIN: float = 2
var _recoil_intensity_main_modifier: float = 0.0

var _bullet_secondary: PackedScene = load("res://bullet_simple.tscn")
const SHOOT_SECONDARY_COOL_DOWN: float = 5.055
var _can_shoot_secondary: bool = true
var _shoot_secondary_cool_down_modifier: float = 0.0
var RECOIL_INTENSITY_SECONDARY: float = 3.5
var _recoil_intensity_secondary_modifier: float = 0.0

enum MOVEMENT_STATES {STATE_IDLE, STATE_MOVING, STATE_DASHING}
enum ATTACK_STATES {STATE_ATTACK_NONE, STATE_ATTACK_MAIN, STATE_ATTACK_SECONDARY}

var state_movement: MOVEMENT_STATES = MOVEMENT_STATES.STATE_IDLE
var state_attack: ATTACK_STATES = ATTACK_STATES.STATE_ATTACK_NONE

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta: float) -> void:
	match state_movement:
		MOVEMENT_STATES.STATE_IDLE:
			if velocity != Vector2.ZERO:
				state_movement = MOVEMENT_STATES.STATE_MOVING
			# print("IDLE")
	
		MOVEMENT_STATES.STATE_MOVING:
			if velocity == Vector2.ZERO:
				state_movement = MOVEMENT_STATES.STATE_IDLE
			else:
				# print("MOVING")
				if Input.is_action_just_pressed("ui_accept") && _can_dash && !is_shooting:
					state_movement = MOVEMENT_STATES.STATE_DASHING
		
		MOVEMENT_STATES.STATE_DASHING: # Could you make a method out of this???
			# print("DASH")
			_can_dash = false
			is_dashing = true
			await(get_tree().create_timer(0.05).timeout)
			# print("DASH COOLING DOWN...")
			is_dashing = false
			dash()
			_check_if_idle()
			
			await(get_tree().create_timer(get_net_diff(DASH_COOL_DOWN, _dash_cool_down_modifier, MIN_COOL_DOWN, MAX_COOL_DOWN)).timeout)
			# print("DASH READY!")
			_can_dash = true
	
	match state_attack:
		ATTACK_STATES.STATE_ATTACK_NONE:
			if Input.is_action_pressed("attack_main") && _can_shoot_main && !is_dashing:
				state_attack = ATTACK_STATES.STATE_ATTACK_MAIN
			if Input.is_action_just_pressed("attack_secondary") && _can_shoot_secondary && !is_dashing:
				state_attack = ATTACK_STATES.STATE_ATTACK_SECONDARY
		
		ATTACK_STATES.STATE_ATTACK_MAIN: # Could you make a method out of this???
			# print("ATTACK FROM MAIN")
			
			_can_shoot_main = false
			recoil(RECOIL_INTENSITY_MAIN, _recoil_intensity_main_modifier)
			_shoot(_bullet_main)
			state_attack = ATTACK_STATES.STATE_ATTACK_NONE
			
			await(get_tree().create_timer(get_net_diff(SHOOT_MAIN_COOL_DOWN, _shoot_main_cool_down_modifier, MIN_COOL_DOWN, MAX_COOL_DOWN)).timeout)
			_can_shoot_main = true
		
		ATTACK_STATES.STATE_ATTACK_SECONDARY:
			# print("ATTACK FROM SECONDARY")
			
			_can_shoot_secondary = false
			recoil(RECOIL_INTENSITY_SECONDARY, _recoil_intensity_secondary_modifier)
			_shoot(_bullet_secondary)
			state_attack = ATTACK_STATES.STATE_ATTACK_NONE
			
			await(get_tree().create_timer(get_net_diff(SHOOT_SECONDARY_COOL_DOWN, _shoot_secondary_cool_down_modifier, MIN_COOL_DOWN, MAX_COOL_DOWN)).timeout)
			_can_shoot_secondary = true

func _physics_process(delta: float) -> void:
	set_velocity_and_rotation(delta)
	move_and_slide()
	
	position.x = clamp(position.x, 0, screen_size.x) # clamp will limit a value between a range
	position.y = clamp(position.y, 0, screen_size.y)

func get_input_direction() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func set_velocity_and_rotation(delta: float) -> void:
	look_at(get_global_mouse_position())
	velocity = velocity.lerp(get_input_direction() * get_net_walk_speed(), 0.05) # Does it not need delta??? look into that at some point

func dash() -> void:
	emit_signal("dashing")
	velocity = transform.x * get_net_walk_speed() * DASH_SPEED

func recoil(intensity: float, intensity_modifier: float) -> void:
	velocity = -(transform.x * get_net_walk_speed() * get_net_diff(intensity, intensity_modifier, MIN_RECOIL_INTENSITY, MAX_RECOIL_INTENSITY))

func set_bullet_main(bullet_new: PackedScene) -> void:
	_bullet_main = bullet_new
func set_bullet_secondary(bullet_new: PackedScene) -> void:
	_bullet_secondary = bullet_new

func get_net_sum(base_value: float, modifier_value: float, range_min: float, range_max: float) -> float:
	var ret: float = base_value + (base_value * modifier_value)
	return clamp(ret, range_min, range_max)

func get_net_diff(base_value: float, modifier_value: float, range_min: float, range_max: float) -> float:
	var ret: float = base_value - (base_value * modifier_value)
	return clamp(ret, range_min, range_max)

func get_net_walk_speed() -> float:
	return get_net_sum(DEFAULT_WALK_SPEED, _walk_speed_modifier, MIN_WALK_SPEED, MAX_WALK_SPEED)

func _shoot(bullet: PackedScene) -> void:
	var b = bullet.instantiate()
	
	is_shooting = true
	emit_signal("shooting")
	
	owner.add_child(b)
	b.set_damage(5)
	b.transform = $Gun.global_transform
	
	is_shooting = false
	
func _check_if_idle() -> void:
	if velocity != Vector2.ZERO:
		state_movement = MOVEMENT_STATES.STATE_MOVING
	else:
		state_movement = MOVEMENT_STATES.STATE_IDLE
