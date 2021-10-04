extends Area2D

const TILE_SIZE = 16 # size of tile in pixels
# dictionary map for movement directions
var inputs = {"ui_right": Vector2.RIGHT,
			"ui_left": Vector2.LEFT,
			"ui_up": Vector2.UP,
			"ui_down": Vector2.DOWN}
var direction = Vector2(0,0) # buffer for direction until it is time to move
var last_moved_direction = Vector2(0,0) # last direction moved in
export (PackedScene) var scene_of_body = preload("res://scenes/Body.tscn") # Will load when parsing the script.
export (PackedScene) var scene_of_game_over_screen = preload("res://scenes/GameOver.tscn") # Will load when parsing the script.
var tail = null # list of body part segments
onready var ray = $RayCast2D
onready var sprite = $Sprite
onready var tail_spawn = $TailSpawn
onready var move_timer = $Timer_Move # adjust movement on death
var hit_object = null


# Called when the node enters the scene tree for the first time.
func _ready():
	position = position.snapped(Vector2.ONE * TILE_SIZE) # place sprite in tile
	position += Vector2.ONE * TILE_SIZE/2 # center sprite in tile
	sprite.rotation = (direction.angle()+PI/2) 

# Update direction buffer depending in pressed keys
func _unhandled_input(event):
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			if last_moved_direction * (-1) == inputs[dir]:
				# would be an 180° turn. To prevent this do nothing
				pass
			else:
				direction = inputs[dir]


func move():
	turn(direction)# rotate
	ray.force_raycast_update()
	if !ray.is_colliding():
		# no collision detected
		position += direction * TILE_SIZE # advance position 
		last_moved_direction = direction # save moved direction
		if not direction == Vector2(0,0):
			# actualy moving, not standing still at the start
			$MoveRustling.play() # play sound effects
		# move tail
		if tail != null:
			tail.move(direction)
	else:
		# collision detected
		hit_object = ray.get_collider()
		if hit_object.has_method("_on_eat"):
			# we hit food
			hit_object._on_eat()
			# add tail segment
			add_segment()
			# advance position of head after adding tail segments
			position += direction * TILE_SIZE  
			last_moved_direction = direction # save moved direction
		else:
			# we hit something else, like a wall or bodypart
			game_over()


func add_segment():
	# create bodypart
	var new_segment = scene_of_body.instance()
	# add to parent scene. it would move with this scene otherwise
	get_parent().add_child(new_segment)
	# set the spawn position
	new_segment.global_position = tail_spawn.position
	# set the movement direction, so the tail can mimic it on the next timestep
	new_segment.direction = direction
	# keep track of the tail
	if tail != null:
		# inform new segment about existing tail
		new_segment.add_segment(tail)
	tail = new_segment
	tail.orient_sprite(false) # next segments will not advance, as this is a newly spawned segment
	


# rotate sprite and move tail spawn depending on movement direction
func turn(movement_direction):
	# Vector2.angle() returns angle with respect to the x-axis. Rotate this by 90°.
	# TODO: use angles to a common reference point like 0,0
	sprite.rotation = (movement_direction.angle()+PI/2) # rotate sprite
	ray.cast_to = movement_direction * TILE_SIZE # rotate ray for collision detection
	# set spawn position at current position, as movement of head may occur
	tail_spawn.position = position


func game_over():
	var new_screen = scene_of_game_over_screen.instance()
	get_parent().add_child(new_screen)
	# stop timer to prevent new inpits and collision from being processed
	move_timer.paused = true
	print_debug(get_viewport_rect())
	new_screen.rect_size = get_viewport_rect().size
	new_screen.fade_out()


func _on_Timer_timeout():
	move()
