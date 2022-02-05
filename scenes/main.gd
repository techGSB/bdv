extends Node


const PLANET_SPEED := 1 # rad/s
const SHIP_SPEED := 250 # px/s
const ERROR_THRESHOLD := pow((1.0/60.0/2.0), 2) # Square of half a frame (assumes 60 FPS)
const SHIP_ROT_OFFSET := PI/2
const DIST_CUTOFF := 3

var t_max: float
var ship_launched := false
var dest:Vector2
var dir:Vector2

onready var star := $Objects/Star
onready var planet := $Objects/Star/Planet
onready var ship_traj := $Objects/ShipTrajectory
onready var ship := $Objects/Ship
onready var launch := $UI/Control/MarginContainer/VBoxContainer/Launch
onready var pop := $UI/Control/PopupPanel
onready var ship_radius: float = (ship.global_position - star.global_position).length()
onready var planet_radius: float = planet.offset.length()
onready var shortest_dist: float = abs(ship_radius - planet_radius)
onready var t_min: float = shortest_dist / SHIP_SPEED
onready var ship_init_pos:Vector2 = ship.position


func _ready():
	if shortest_dist > planet_radius:
		t_max = planet_radius * 2/SHIP_SPEED + t_min
	else:
		t_max = planet_radius * 2/SHIP_SPEED - t_min
	ship_traj.points = PoolVector2Array([ship.position, ship.position])


func _process(delta):
	if not ship_launched:
		dest = get_destination()
		ship.rotation = ship.position.angle_to_point(dest) - SHIP_ROT_OFFSET
		ship_traj.points[1] = dest
	else:
		ship.position += SHIP_SPEED * dir * delta
		if ship.position.distance_to(dest) <= DIST_CUTOFF:
			ship.position = ship_init_pos
			ship_launched = false
			launch.disabled = false
	
	planet.rotation += PLANET_SPEED * delta
	

func get_destination() -> Vector2:
	var l := t_min
	var r := t_max
	while true:
		var t := (l+r)/2
		if t == l:
			return get_planet_pos_at_time(l)
		elif t == r:
			return get_planet_pos_at_time(r)
		var planet_pos = get_planet_pos_at_time(t)
		var err:float = (planet_pos-ship.position).length_squared()/(SHIP_SPEED*SHIP_SPEED) - t*t
		if abs(err) <= ERROR_THRESHOLD:
			return planet_pos
		elif err < 0:
			r = t
		else:
			l = t
	return Vector2.ZERO


func get_planet_pos_at_time(t:float) -> Vector2:
	return planet.offset.rotated(planet.rotation + PLANET_SPEED * t) + star.position
	

func on_launch_pressed():
	ship_launched = true
	dir = ship.position.direction_to(dest)
	launch.disabled = true


func on_credits_pressed():
	pop.popup_centered()


func on_meta_clicked(meta):
# warning-ignore:return_value_discarded
	OS.shell_open(meta)
