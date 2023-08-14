extends Node2D

var cells = 21
var pixels = 16
var text = 'HELLOWORLD'

var info_coords = [
	[Vector3(0, 8, -1), Vector3(8, cells-1, -1)],
	[Vector3(1, 8, -1), Vector3(8, cells-2, -1)],
	[Vector3(2, 8, -1), Vector3(8, cells-3, -1)],
	[Vector3(3, 8, -1), Vector3(8, cells-4, -1)],
	[Vector3(4, 8, -1), Vector3(8, cells-5, -1)],
	[Vector3(5, 8, -1), Vector3(8, cells-6, -1)],
	[Vector3(7, 8, -1), Vector3(8, cells-7, -1)],
	[Vector3(8, 8, -1), Vector3(cells-8, 8, -1)],
	[Vector3(8, 7, -1), Vector3(cells-7, 8, -1)],
	[Vector3(8, 5, -1), Vector3(cells-6, 8, -1)],
	[Vector3(8, 4, -1), Vector3(cells-5, 8, -1)],
	[Vector3(8, 3, -1), Vector3(cells-4, 8, -1)],
	[Vector3(8, 2, -1), Vector3(cells-3, 8, -1)],
	[Vector3(8, 1, -1), Vector3(cells-2, 8, -1)],
	[Vector3(8, 0, -1), Vector3(cells-1, 8, -1)]]

# (0-7) mask patterns ; (-1) - no mask
var mask_pattern = 0

enum Mode {NUMERIC, ALPHANUMERIC, BYTE, KANJI}
enum EC {M, L, H, Q}

# Galois Field integer multiplication using Russian Peasant Multiplication algorithm 
# (faster than the standard multiplication + modular reduction)
func gf_mult(x, y, prim=285, field_charac_full=256, carryless=true):
	var r = 0
	while y: # while y is above 0
		if y & 1: r = r ^ x if carryless else r + x # y is odd, then add the corresponding x to r (the sum of all x's corresponding to odd y's will give the final product). Note that since we're in GF(2), the addition is in fact an XOR (very important because in GF(2) the multiplication and additions are carry-less, thus it changes the result!).
		y = y >> 1 # equivalent to y // 2
		x = x << 1 # equivalent to x*2
		if prim > 0 and x & field_charac_full: x = x ^ prim # GF modulo: if x >= 256 then apply modular reduction using the primitive polynomial (we just subtract, but since the primitive number can be above 256 then we directly XOR).

	return r

# Galois Field power multiplication
func gf_pow(x, n):
	var r = 1
	for i in range(n):
		r = gf_mult(r, x)
	return r

# Multiply two polynomials, inside Galois Field
func gf_poly_mult(a, b):
	var r = []
	r.resize(a.size()+b.size()-1)
	r.fill(0)
	for i in range(a.size()):
		for j in range(b.size()):
			r[i+j] = r[i+j]^gf_mult(a[i],b[j])
	return r

# Fast polynomial division by using Extended Synthetic Division 
# and optimized for GF(2^p) computations
# Returns remainder!
func gf_poly_div(dividend, divisor):
	var msg_out = dividend 
	for i in range(0, len(dividend) - (len(divisor)-1)):
		var coef = msg_out[i] 
		if coef != 0:
			for j in range(1, len(divisor)): 
				if divisor[j] != 0: 
					msg_out[i + j] ^= gf_mult(divisor[j], coef)
	var separator = -(len(divisor)-1)
	return msg_out.slice(separator, msg_out.size())

# Generate an irreducible generator polynomial 
# (necessary to encode a message into Reed-Solomon)
func generate_poly(n):
	var g = [1]
	for i in range(n):
		g = gf_poly_mult(g, [1, gf_pow(2, i)])
	return g

# Takes data string, adds nsym error-correction blocks to the end
func rs_encode_msg(msg_in, nsym):
	#breaking up the data into 8-bit binary strings
	
	var gen = generate_poly(nsym)
	# Pad the message
	var pad = []
	pad.resize(len(gen)-1)
	pad.fill(0)
	# Divide it by the irreducible generator polynomial, add remainder
	var msg_out = gf_poly_div(msg_in+pad, gen)

	# Return the codewords
	return msg_out

# Takes 5 character information string, adds 10 error-correction characters to the end
func rs_encode_inf(inf):
	var gen = [1,0,1,0,0,1,1,0,1,1,1]
	var pad = []
	pad.resize(len(gen)-1)
	pad.fill(0)
	# Pad the message, then divide it by the irreducible generator polynomial
	# The remainder is our RS code! Just append it to our original message to get our full codeword (this represents a polynomial of max 256 terms)
	var msg_out = gf_poly_div(inf+pad, gen)

#	msg_out = msg_out^21522

	return msg_out

# Draws rectangle, top-left corner is coord
func draw_rec(coord, size, tile, fill, time = 0):
	if fill:
		for i in range(size[0]):
			for j in range(size[1]):
				$TileMap.set_cell(i+coord[0],j+coord[1],tile)
				yield(get_tree().create_timer(time), "timeout")
	else:
		for i in range(size[0]):
			$TileMap.set_cell(i+coord[0],coord[1],tile)
			$TileMap.set_cell(i+coord[0],size[1]+coord[1]-1,tile)
			yield(get_tree().create_timer(time), "timeout")
		for i in range(size[1]):
			$TileMap.set_cell(coord[0],i+coord[1],tile)
			$TileMap.set_cell(size[0]+coord[0]-1,i+coord[1],tile)
			yield(get_tree().create_timer(time), "timeout")

# Alternating white and black squares
func draw_timing_patterns(coord, direction, length, time = 0):
	for i in range(0, length, 2):
		$TileMap.set_cellv(coord, 0)
		yield(get_tree().create_timer(time), "timeout")
		$TileMap.set_cellv(coord+direction, 1)
		yield(get_tree().create_timer(time), "timeout")
		coord += direction*2

# Flips the bit if mask conditions are met
func apply_mask(mask, coords):
	for coord in coords:
		var bit = int(coord.z)
		if bit == -1:
			break
		elif mask == -1:
			$TileMap.set_cell(coord.x, coord.y, bit)
		elif mask == 0 and int(coord.x+coord.y)%2 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 1 and int(coord.y)%2 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 2 and int(coord.x)%3 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 3 and int(coord.x+coord.y)%3 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 4 and int((floor(coord.y/2) + floor(coord.x/3)))%2 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 5 and int(coord.x*coord.y)%2 + int(coord.x*coord.y)%3 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 6 and (int(coord.x*coord.y)%2+int(coord.x*coord.y)%3)%2 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		elif mask == 7 and (int(coord.x+coord.y)%2+int(coord.x*coord.y)%3)%2 == 0:
			$TileMap.set_cell(coord.x, coord.y, 1^bit)
		else:
			$TileMap.set_cell(coord.x, coord.y, bit)

func calculate_data_coords():
	# First data square coord
	var coords = [Vector3(cells-1, cells-1, -1)]
	# Creates 8bit number based on adjacent cells
	var adjacent_cells = 0
	for i in range(208):
		var coord = Vector2(coords[i].x, coords[i].y)
		# Set clear tile in coord
		$TileMap.set_cellv(coord, 4)
		adjacent_cells = 0
		for k in range(8):
			var adjacent_cell = coord+Vector2(-1,-1).rotated(k*PI/4).round()
			if $TileMap.get_cellv(adjacent_cell) == -1:
				adjacent_cells += pow(2,k)
		
		#Logic of drawing based on adjacent cells
		
		#Crossing horisontal pattern up
		if coord.y == 7 and adjacent_cells in [192]:
			coord += Vector2(1,-2)
		
		#Crossing horisontal pattern down
		elif coord.y == 5 and adjacent_cells in [0]:
			coord += Vector2(1,2)
		
		# Crossing vertical pattern left
		elif coord == Vector2(7, 9):
			coord += Vector2(-2,0)
		#left
		elif adjacent_cells in [131, 128, 192, 224, 129]:
			coord += Vector2(-1,0)
		#up_right
		elif adjacent_cells in [135, 199, 6]:
			coord += Vector2(1,-1)
		#down_right
		elif adjacent_cells in [240, 241, 48, 112, 177, 49]:
			coord += Vector2(1,1)
		
		#Jumping on top of bottom-left square pattern
		elif adjacent_cells in [0]:
			coord += Vector2(-1,-8)
			
		coords.append(Vector3(coord.x, coord.y, -1))
	
	return(coords)

func draw_data(data, coords, time):
	for i in range(len(coords)):
		if coords[i].z == -1:
			for j in range(len(data)):
				coords[i+j].z = data[j]
				$TileMap.set_cell(coords[i+j].x, coords[i+j].y, coords[i+j].z)
				yield(get_tree().create_timer(time), "timeout")
			break

func draw_info(data, pos):
	for i in range(pos, pos+len(data)):
		for cell in info_coords[i]:
			print(i, ' - ', cell.x, ' - ', cell.y)
			$TileMap.set_cell(cell.x, cell.y, data[i-pos])
		yield(get_tree().create_timer(0.1), "timeout")
		
func draw_patterns():
	# Draw top-left pattern
	draw_rec(Vector2(0,8), Vector2(9,1), 4, false, 0.1)
	draw_rec(Vector2(8,0), Vector2(1,8), 4, false, 0.1)
	draw_rec(Vector2(-1,-1), Vector2(9,9), 0, false, 0.1)
	draw_rec(Vector2(0,0), Vector2(7, 7), 1, false, 0.1)
	draw_rec(Vector2(2,2), Vector2(3, 3), 1, true, 0.1)
	draw_rec(Vector2(1,1), Vector2(5, 5), 0, false, 0.1)

#	# Draw bottom-left pattern
	draw_rec(Vector2(8,cells-8), Vector2(1,8), 4, false, 0.1)
	draw_rec(Vector2(-1,cells-8), Vector2(9,9), 0, false, 0.1)
	draw_rec(Vector2(0,cells-7), Vector2(7, 7), 1, false, 0.1)
	draw_rec(Vector2(2,cells-5), Vector2(3, 3), 1, true, 0.1)
	draw_rec(Vector2(1,cells-6), Vector2(5, 5), 0, false, 0.1)
#
	# Draw top-right pattern
	draw_rec(Vector2(cells-8,8), Vector2(8,1), 4, false, 0.1)
	draw_rec(Vector2(cells-8,-1), Vector2(9,9), 0, false, 0.1)
	draw_rec(Vector2(cells-7,0), Vector2(7, 7), 1, false, 0.1)
	draw_rec(Vector2(cells-5,2), Vector2(3, 3), 1, true, 0.1)
	draw_rec(Vector2(cells-6,1), Vector2(5, 5), 0, false, 0.1)

func draw_timing_patterns2():
	# Draw timing patterns
	draw_timing_patterns(Vector2(7,6), Vector2(1, 0), 6, 0.1)
	draw_timing_patterns(Vector2(6,7), Vector2(0, 1), 6, 0.1)
	draw_timing_patterns(Vector2(7,cells-8), Vector2(1, 0), 2, 0.1)

func clear():
	for i in range(cells):
		for j in range(cells):
			$TileMap.set_cell(i,j,-1)

func _ready():
# Draw outside rectangle
	draw_rec(Vector2(-1,-1), Vector2(cells+2, cells+2), 0, false)




