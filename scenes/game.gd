extends Node2D

const SPEED_TIMESTEP_HARD = 0.2 # 0.2 seconds
const SPEED_TIMESTEP_EASY = 0.5 # 0.5 seconds
const TIMESTEP_CHANGE = 0.05
const DIFFICULTY_INCREASE_THRESHOLD = 10 # amount of food collected until dificulty inreases

export (PackedScene) var scene_of_food = preload("res://scenes/Food.tscn") # Will load when parsing the script.
var sum_of_spawned_food = 0 # accumulation of spawned food to determine difficulty
var rng = RandomNumberGenerator.new()
onready var map: TileMap = $Background # reference to for player accessable tiles
onready var timer: Timer = $Player/Timer_Move # reference to timer of player moves

func _ready():
	rng.randomize()


func _process(_delta):
	var has_food = false
	var object_positions = [] # positions of object in play
	# check if food is spawned
	for child in get_children():
		# get positions of existing object to prevent food spawning on them
		object_positions.append(child.position) 
		if child.has_method("_on_eat"):
			# food exists
			has_food = true
			break
	# add food if neccessary
	if has_food == false:
		# no food available
		# get empty, random location on map to spawn food at 
		var tiles = map.get_used_cells() # get possible locations
		for object_position in object_positions:
			# remove tiles already occupied
			var occupied_tile = map.world_to_map(object_position)
			var occupied_tile_index = tiles.find(occupied_tile)
			print_debug("position: ", object_position, " tile: ", occupied_tile, " index: ", occupied_tile_index)
			if occupied_tile_index >= 0:
				tiles.remove(occupied_tile_index)
		var spawn_tile = tiles[rng.randi_range(0, tiles.size()-1)] # choose random tile
		var spawn_position = map.map_to_world(spawn_tile) # get coordinates of chosen tile
		# spawn food
		var new_food = scene_of_food.instance()
		new_food.position = spawn_position
		add_child(new_food)
		sum_of_spawned_food +=1
		
		# adjust dificulty if neccessary
		if sum_of_spawned_food % DIFFICULTY_INCREASE_THRESHOLD == 0:
			var wait_time = timer.wait_time
			if wait_time > SPEED_TIMESTEP_HARD:
				timer.wait_time = wait_time - TIMESTEP_CHANGE
		
