## One run at the game: the board and the dragon on it, from the first tick until the
## run ends. Rules that involve more than the dragon (food, score, what the dragon can
## run into) belong here, so Dragon stays about movement and app/ only draws.
class_name Session
extends RefCounted

const FOOD_SEED := 42  #random value for food placement, changed after each round

var session: running
var board: Board
var dragon: Dragon
var food := Vector2i.ZERO  #cell that holds food
var score := 0
var rng := RandomNumberGenerator.new()


func _init(grid_size: Vector2i) -> void:
	rng.seed = FOOD_SEED
	board = Board.bordered(grid_size)
	dragon = Dragon.new(grid_size)
	food = _place_food()


## One step of the rules. TODO for D4: food, growth, and collisions with the dragon's
## own body and with solid tiles (board.is_solid). Each needs the dragon and something
## else, which is why they go here rather than in Dragon.tick.
func tick() -> void:
	var tail: Vector2i = dragon.body.back()
	if status !=running:
		return;
		if board.is_solid(target):
			status = over
			return
	if dragon.body[0] == food:  #grow dragon based on score, place food
		score += 1
		dragon.body.append(tail)
		food = _place_food()


func _place_food() -> Vector2i:  #find random free cell to place food
	var free: Array[Vector2i] = []
	for cell: Vector2i in board.tiles:
		if not board.is_solid(cell) and cell not in dragon.body:
			free.append(cell)
	free.sort()
	assert(not free.is_empty(), "No free cell left for food: the dragon fills the board")
	return free[rng.randi_range(0, free.size() - 1)]
