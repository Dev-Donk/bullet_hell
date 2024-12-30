extends CharacterBody2D

# TODO: Move walking and possibly dashing to the mob script and make
#		the player script a CHILD of the mob script. The player is a mob
#		technically after all

signal dashing
signal hit
signal shooting
signal bullet_updated

var screen_size: Vector2 = Vector2.ZERO

var _base_health: int = 3
var _curr_health: int = _base_health

const DEFAULT_WALK_SPEED: float = 250.0
const MIN_WALK_SPEED: float = 50.0
const MAX_WALK_SPEED: float = 500.0

var _prev_walk_speed_modifier: float
var _walk_speed_modifier: float = 0.0

const MIN_COOL_DOWN: float = 0.15
const MAX_COOL_DOWN: float = 120.0

const DASH_SPEED: float = 5.0

const DASH_COOL_DOWN: float = 4.0
var is_dashing: bool = false
var _can_dash: bool = true
@export var _dash_cool_down_modifier: float = 0.0

var is_shooting: bool = false

const MAX_RECOIL_DAMPEN: float = 10.0
@export var _recoil_dampen_modifier: float = 0.0

@export var _bullet_main: PackedScene
const SHOOT_MAIN_COOL_DOWN: float = 1.5
var _can_shoot_main: bool = true
@export var _shoot_main_cool_down_modifier: float = 0.0

@export var _bullet_secondary: PackedScene
const SHOOT_SECONDARY_COOL_DOWN: float = 5.055
var _can_shoot_secondary: bool = true
@export var _shoot_secondary_cool_down_modifier: float = 0.0

# TODO: Join these states together? Add stuff like STATE_ATTACK_MAIN_IDLE and STATE_ATTACK_SECONDARY_MOVING?
enum MOVEMENT_STATES {STATE_IDLE, STATE_MOVING, STATE_DASHING}
enum ATTACK_STATES {STATE_ATTACK_NONE, STATE_ATTACK_MAIN, STATE_ATTACK_SECONDARY}

var state_movement: MOVEMENT_STATES = MOVEMENT_STATES.STATE_IDLE
var state_attack: ATTACK_STATES = ATTACK_STATES.STATE_ATTACK_NONE

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta: float) -> void:
	# Something about this state machine is that it works for THIS project, player movement isn't
	# that complex, neither is the game. For another project, one like Cubit, this might need to be
	# reconsidered. This is your first FSM, don't beat yourself up!
	
	match state_movement:
		MOVEMENT_STATES.STATE_IDLE:
			print("IDLE")
			_check_if_idle()
	
		MOVEMENT_STATES.STATE_MOVING:
			print("MOVING")
			_check_if_idle()
			if Input.is_action_just_pressed("ui_accept") && _can_dash:
				state_movement = MOVEMENT_STATES.STATE_DASHING
		
		MOVEMENT_STATES.STATE_DASHING: # Could you make a method out of this???
			dash()
			_check_if_idle()
	
	match state_attack:
		ATTACK_STATES.STATE_ATTACK_NONE:
			if Input.is_action_pressed("attack_main") && _can_shoot_main && !is_dashing:
				state_attack = ATTACK_STATES.STATE_ATTACK_MAIN
			if Input.is_action_just_pressed("attack_secondary") && _can_shoot_secondary && !is_dashing:
				state_attack = ATTACK_STATES.STATE_ATTACK_SECONDARY
		
		ATTACK_STATES.STATE_ATTACK_MAIN:
			# print("ATTACK FROM MAIN")
			_shoot(_bullet_main, _can_shoot_main, SHOOT_MAIN_COOL_DOWN, _shoot_main_cool_down_modifier)
			state_attack = ATTACK_STATES.STATE_ATTACK_NONE
		
		ATTACK_STATES.STATE_ATTACK_SECONDARY:
			# print("ATTACK FROM SECONDARY")
			_shoot(_bullet_secondary, _can_shoot_secondary, SHOOT_SECONDARY_COOL_DOWN, _shoot_secondary_cool_down_modifier)
			state_attack = ATTACK_STATES.STATE_ATTACK_NONE

func _physics_process(delta: float) -> void:
	set_velocity_and_rotation()
	move_and_slide()
	
	position.x = clamp(position.x, 0, screen_size.x) # clamp will limit a value between a range
	position.y = clamp(position.y, 0, screen_size.y)

func get_input_direction() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func set_velocity_and_rotation() -> void:
	look_at(get_global_mouse_position())
	velocity = velocity.lerp(get_input_direction() * get_net_walk_speed(), 0.05) # Does it not need delta??? look into that at some point
	

func dash() -> bool:
	
	if _can_dash && !is_dashing:
		
		_can_dash = false
		is_dashing = true
		
		emit_signal("dashing")
		velocity = transform.x * get_net_walk_speed() * DASH_SPEED
		await(get_tree().create_timer(0.05).timeout)
		# print("DASH COOLING DOWN...")
		is_dashing = false
		await(get_tree().create_timer(get_net_diff(DASH_COOL_DOWN, _dash_cool_down_modifier, MIN_COOL_DOWN, MAX_COOL_DOWN)).timeout)
		# print("DASH READY!")
		_can_dash = true
		
		return Action_States.ACTION_SUCCESS
	else:
		return Action_States.ACTION_FAIL

func recoil(intensity: float, intensity_modifier: float) -> void:
	velocity = -(transform.x * get_net_walk_speed() * get_net_diff(intensity, intensity_modifier, 1, MAX_RECOIL_DAMPEN))

func set_bullet(bullet_in: PackedScene, bullet_new: PackedScene) -> void:
	var prev_bullet = bullet_in
	bullet_in = bullet_new
	
	if bullet_in != prev_bullet:
		emit_signal("bullet_updated", bullet_in)

func get_net_sum(base_value: float, modifier_value: float, range_min: float, range_max: float) -> float:
	var ret: float = base_value + (base_value * modifier_value)
	return clamp(ret, range_min, range_max)

func get_net_diff(base_value: float, modifier_value: float, range_min: float, range_max: float) -> float:
	var ret: float = base_value - (base_value * modifier_value)
	return clamp(ret, range_min, range_max)

func get_net_walk_speed() -> float:
	return get_net_sum(DEFAULT_WALK_SPEED, _walk_speed_modifier, MIN_WALK_SPEED, MAX_WALK_SPEED)

func _shoot(bullet: PackedScene, can_shoot: bool, cool_down: float, cool_down_modifier: float) -> bool:
	if bullet != null:
		if can_shoot && !is_shooting:
			var b = bullet.instantiate()
			
			can_shoot = false
			is_shooting = true
			emit_signal("shooting")
			
			recoil(b.recoil, _recoil_dampen_modifier)
			owner.add_child(b)
			b.set_damage_amount(5)
			b.transform = $Gun.global_transform
			
			await(get_tree().create_timer(get_net_diff(cool_down, cool_down_modifier, MIN_COOL_DOWN, MAX_COOL_DOWN)).timeout)
			can_shoot = true
			is_shooting = false
			
			return Action_States.ACTION_SUCCESS
		else:
			return Action_States.ACTION_FAIL
	else:
		printerr("MISSING BULLET.")
		return Action_States.ACTION_ERROR
	
func _check_if_idle() -> void:
	if get_input_direction() != Vector2.ZERO:
		state_movement = MOVEMENT_STATES.STATE_MOVING
	else:
		state_movement = MOVEMENT_STATES.STATE_IDLE
