extends TileMapLayer
var movement_data

func _ready():
	## Reference variable to any particular movement cost of any particular tile
	movement_data = tile_set.movement_data

## Get the movement cost of any single cell on the map
## We pass in the grid, so that we don't take in the data from tiles that have been placed outside the play area
func get_movement_costs(grid: Grid):
	var movement_costs = []
	for y in range(grid.size.y):
		movement_costs.append([])
		for x in range(grid.size.x):
			var tile = get_cell_source_id(Vector2i(x,y))
			var movement_cost = movement_data.get(tile)
			movement_costs[y].append(movement_cost)
	return movement_costs


##TODO: Fix this up. It's old and probably gross.

##Gets the tile ID data and passes it along to the main node.
func get_tile_IDs():
	var test = get_used_rect()
	var tileIDs = []
	for y in test.size.y:
		tileIDs.append([])
		for x in test.size.x:
			var id := Vector2i(x, y)
			if get_cell_source_id(id) >= 0:
				var tile = get_cell_tile_data(id).get_custom_data("tileIDs")
				tileIDs[y].append(tile)
	return tileIDs
