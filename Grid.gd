extends Node2D

var cells
var pixels

func _draw():
	for i in range(cells+1):
		draw_line(Vector2(i*pixels, 0), Vector2(i*pixels, (cells)*pixels), Color(1,0,1,0.5), 1)
		draw_line(Vector2(0, i*pixels), Vector2(cells*pixels, i*pixels), Color(1,0,1,0.5), 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	cells = get_parent().cells
	pixels = get_parent().pixels
	update()

func _process(delta):
	update()
