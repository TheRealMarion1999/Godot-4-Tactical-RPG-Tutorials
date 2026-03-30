## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D


enum TILE_NAMES {
	GRASS,
	ROAD,
	FLOWERS,
	SINGLE_BUSH,
	DOUBLE_BUSH
}


##The minimum amount needed to avoid zero interval errors with walk_along(). Don't even worry about it.
const REALLY_SMALL_NUMBER = 0.0000001
## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished

## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Resource
## Designate current unit as enemy
@export var is_enemy: bool
## Designate the current unit in a "wait" state
@export var is_wait := false
## Distance to which the unit can walk in cells.
@export var move_range := 6
## The unit's move speed when it's moving along a path.
@export var move_speed := 600.0
## The distance the unit can attack from their current position
@export var attack_range := 0

## Texture representing the unit.
@export var skin: Texture:
	set(value):
		skin = value
		if not _sprite:
			# This will resume execution after this node's _ready()
			await ready
		_sprite.texture = value
## Offset to apply to the `skin` sprite in pixels.
@export var skin_offset := Vector2.ZERO:
	set(value):
		skin_offset = value
		if not _sprite:
			await ready
		_sprite.position = value

##per-unit movement costs.
##TODO: write better documentation
@export var costs: Dictionary[TILE_NAMES, int] = {TILE_NAMES.GRASS:1,
TILE_NAMES.ROAD:1,
TILE_NAMES.FLOWERS:1,
TILE_NAMES.SINGLE_BUSH:2,
TILE_NAMES.DOUBLE_BUSH:255
}

## Coordinates of the current cell the cursor moved to.
var cell := Vector2.ZERO:
	set(value):
		# When changing the cell's value, we don't want to allow coordinates outside
		#	the grid, so we clamp them
		cell = grid.grid_clamp(value)
## Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_anim_player.play("selected")
		else:
			_anim_player.play("idle")

var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D


func _ready() -> void:
	set_process(false)
	_path_follow.rotates = false
	
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func _process(delta: float) -> void:
	_path_follow.progress += move_speed * delta
	
	if _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		emit_signal("walk_finished")


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return
	
	curve.add_point(Vector2.ZERO)
	for point in path:
		var newPoint = grid.calculate_map_position(point) - position
		#Jank solution to a problem caused by changes to Curve2d in Godot 4.6.
		#Curves now check for a minimum length of 0, which causes errors. harmless, I think but still annoying.
		if curve.get_baked_points().size() == 0 || curve.get_closest_point(newPoint) != Vector2(0, 0):
			curve.add_point(newPoint)
		else: 
			curve.add_point(newPoint + Vector2(REALLY_SMALL_NUMBER, REALLY_SMALL_NUMBER))
	cell = path[-1]
	_is_walking = true
