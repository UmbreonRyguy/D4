## Engine adapter: keeps the clock, passes keys to the Session, and draws what it holds.
## It never decides rules: those live in core/session.gd.
extends Node3D

const GRID := Vector2i(48, 48)  # your call: bigger grids make the dragon feel finer
const TICK_SECONDS := 0.1
const CAMERA_OFFSET := Vector3(0, 11, 7.5)  # above and behind the head

#food vars
const FOOD_PIECE := "lollipop"  # food name
const FOOD_SPIN := 1.6  # value in radians for how fast food rotates

const DIRECTIONS := {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT,
}

var session := Session.new(GRID)
var meshes := {}  # kit piece name -> Mesh, shared by everything that shows it (Flyweight)
var segments: Array[MeshInstance3D] = []
var food := MeshInstance3D.new()
var score_label := Label.new()
var camera := Camera3D.new()
var _clock := 0.0

#instantiate food



func _ready() -> void:
	meshes = Stage.load_kit()
	_build_stage()
	_draw_dragon()
	_build_hud()
	add_child(food)
	food.mesh = meshes[FOOD_PIECE]
	_draw_food()
	_draw_score()


## Input arrives as events, so even a tap shorter than one frame is never missed.
func _unhandled_input(event: InputEvent) -> void:
	for action in DIRECTIONS:
		if event.is_action_pressed(action):
			session.dragon.turn(DIRECTIONS[action])


func _process(delta: float) -> void:
	_clock += delta
	while _clock >= TICK_SECONDS:
		_clock -= TICK_SECONDS
		session.tick()
		_draw_dragon()
		#create food and score
		_draw_food()
		_draw_score()
	food.rotate_y(FOOD_SPIN * delta)  # no rule reads the food's facing
	_follow(delta)


#new function to create a score counter for the food being collected.
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color("2b2d42"))
	score_label.add_theme_color_override("font_outline_color", Color("ffffff"))
	score_label.add_theme_constant_override("outline_size", 6)
	score_label.position = Vector2(24, 16)
	hud.add_child(score_label)
	add_child(hud)


## Sky, light, and tiles live in app/stage.gd; the camera follows the head.
func _build_stage() -> void:
	add_child(Stage.new(session.board.tiles, meshes))
	add_child(camera)
	camera.position = _center(session.dragon.body[0]) + CAMERA_OFFSET


## Ease toward the head each frame, so the camera glides while the dragon steps.
func _follow(delta: float) -> void:
	var target := _center(session.dragon.body[0]) + CAMERA_OFFSET
	camera.position = camera.position.lerp(target, 1 - exp(-3 * delta))
	camera.look_at(camera.position - CAMERA_OFFSET)


func _draw_dragon() -> void:
	var body := session.dragon.body
	while segments.size() < body.size():
		var segment := MeshInstance3D.new()
		add_child(segment)
		segments.append(segment)
	var placed := Kit.layout(body)
	for i in segments.size():
		var segment := segments[i]
		segment.visible = i < body.size()
		if not segment.visible:
			continue
		var cell := body[i]
		segment.mesh = meshes[Kit.Piece.keys()[placed[i][0]].to_lower()]
		segment.position = _center(cell)
		segment.rotation.y = placed[i][1] * PI / 2


func _center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0, cell.y + 0.5)


func _draw_score() -> void:  #prints score
	score_label.text = "Score: %d" % session.score


func _draw_food() -> void:  #creates food
	food.position = _center(session.food)
