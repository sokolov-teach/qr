extends Node2D

var coords
var format_info = []

# for debugging in HTML5
func print5(input):
	var output = str(input)
	var text = $Control/VBoxContainer2/RichTextLabel.text + '\n' + output
	$Control/VBoxContainer2/RichTextLabel.text = text

# Converts decimal number to n-bit binary array
func dec2bin(dec, n):
	var bin = []
	for bit in range(n-1, -1, -1):
		if dec - int(pow(2,bit))<0:
			bin.append(0)
		else:
			bin.append(1)
			dec = dec - int(pow(2,bit))
#	bin.invert()
	return bin

# Converts binary array to decimal number
func bin2dec(bin):
	var dec = 0
	for i in range(len(bin)):
		if bin[i] == 1:
			dec += pow(2, len(bin) - i - 1)
	return int(dec)

func ascii2bin(text):
	var byte_array = text.to_wchar()
	
	var data = []
	for i in byte_array:
		if i != 0:
			data.append_array(dec2bin(i, 8))
	return(data)

func _process(_delta):
	pass

func _ready():
#	var t = ascii2bin('DA')
	get_viewport().connect("gui_focus_changed", self, "_on_focus_changed")
	
#	# Encoding Mode
#	$Control/VBoxContainer/EncodingMode.add_item('(1) NUMERIC - not available', 1)
#	$Control/VBoxContainer/EncodingMode.add_item('(2) ALPHANUMERIC - not available', 2)
#	$Control/VBoxContainer/EncodingMode.add_item('(4) BYTE', 4)
#	$Control/VBoxContainer/EncodingMode.add_item('(8) KANJI - not available', 8)
	
	
#	$Control/VBoxContainer/EncodingMode.set_item_disabled(0, true)
#	$Control/VBoxContainer/EncodingMode.set_item_disabled(1, true)
#	$Control/VBoxContainer/EncodingMode.set_item_disabled(3, true)
	
	$Control/VBoxContainer/EncodingMode.select(-1)
	$Control/VBoxContainer/EncodingMode.set_item_text(-1, 'Encoding mode')
	
	# Error Correction Level
	$Control/VBoxContainer/EC_Level.add_item('(1) L - 17 characters', 1)
	$Control/VBoxContainer/EC_Level.set_item_metadata(0, 17)
	$Control/VBoxContainer/EC_Level.add_item('(0) M - 14 characters', 0)
	$Control/VBoxContainer/EC_Level.set_item_metadata(1, 14)
	$Control/VBoxContainer/EC_Level.add_item('(3) Q - 11 characters', 3)
	$Control/VBoxContainer/EC_Level.set_item_metadata(2, 11)
	$Control/VBoxContainer/EC_Level.add_item('(2) H - 7 characters', 2)
	$Control/VBoxContainer/EC_Level.set_item_metadata(3, 7)
	$Control/VBoxContainer/EC_Level.select(-1)
	$Control/VBoxContainer/EC_Level.set_item_text(-1, 'Error Correction Level')
	
	# Mask Type
	$Control/VBoxContainer/Mask.add_item('0', 0)
	$Control/VBoxContainer/Mask.add_item('1', 1)
	$Control/VBoxContainer/Mask.add_item('2', 2)
	$Control/VBoxContainer/Mask.add_item('3', 3)
	$Control/VBoxContainer/Mask.add_item('4', 4)
	$Control/VBoxContainer/Mask.add_item('5', 5)
	$Control/VBoxContainer/Mask.add_item('6', 6)
	$Control/VBoxContainer/Mask.add_item('7', 7)
	$Control/VBoxContainer/Mask.select(-1)
	$Control/VBoxContainer/Mask.set_item_text(-1, 'Mask Type')

func _on_Draw_Patterns_pressed():
	$QR.draw_patterns()
	$Control/VBoxContainer/DrawPatterns.set_disabled(true)

func _on_DrawTimingPatterns_pressed():
	$QR.draw_timing_patterns2()
	$Control/VBoxContainer/DrawTimingPatterns.set_disabled(true)
	yield(get_tree().create_timer(1), "timeout")
	coords = $QR.calculate_data_coords()

func _on_EncodingMode_item_selected(index):
	if index in range(4):
		$Control/VBoxContainer/EncodingMode.set_disabled(true)
		var encoding_mode = $Control/VBoxContainer/EncodingMode.get_item_id(index)
		$QR.draw_data(dec2bin(encoding_mode, 4), coords, 0.1)

func _on_EC_Level_item_selected(index):
	if index in range(4):
		var id = $Control/VBoxContainer/EC_Level.get_item_id(index)
		$Control/VBoxContainer/EC_Level.set_disabled(true)
		$QR.draw_info(dec2bin(id, 2), 0)
		$Control/VBoxContainer/TextEdit.length = $Control/VBoxContainer/EC_Level.get_item_metadata(index)

func _on_DrawLength_pressed():
	$Control/VBoxContainer/TextEdit.readonly = true
	$Control/VBoxContainer/DrawLength.set_disabled(true)
	var data = dec2bin($Control/VBoxContainer/TextEdit.text.length(), 8)
	$QR.draw_data(data, coords, 0.1)

func _on_DrawText_pressed():
	$Control/VBoxContainer/DrawText.set_disabled(true)
	var data = ascii2bin($Control/VBoxContainer/TextEdit.text)
	$QR.draw_data(data, coords, 0.1)

func _on_DrawEnd_pressed():
	$Control/VBoxContainer/DrawEnd.set_disabled(true)
	$QR.draw_data([0,0,0,0], coords, 0.1)

func _on_DrawPadSimbols_pressed():
	$Control/VBoxContainer/DrawPadSimbols.set_disabled(true)
	var max_length = $Control/VBoxContainer/EC_Level.get_selected_metadata()
	var length = $Control/VBoxContainer/TextEdit.text.length()
	var data = []
	for i in range(max_length-length):
		if i%2 == 0:
			data.append_array(dec2bin(236, 8))
		else:
			data.append_array(dec2bin(17, 8))
	$QR.draw_data(data, coords, 0.1)

func _on_DrawECBlocks_pressed():
	$Control/VBoxContainer/DrawECBlocks.set_disabled(true)
	var max_length = $Control/VBoxContainer/EC_Level.get_selected_metadata()
	var msg_in = []
	var data = []
	
	for i in range(len(coords)):
		if coords[i].z == -1:
			break
		else:
			data.append(coords[i].z)
	for i in range(len(data)):
		if i % 8 == 0:
#			print(data.slice(i, i+7))
			msg_in.append(bin2dec(data.slice(i, i+7)))
	
	var EC_codewords = $QR.rs_encode_msg(msg_in, 26 - max_length - 2)
	var EC_binary = []
	for i in EC_codewords:
		EC_binary.append_array(dec2bin(i, 8))
	$QR.draw_data(EC_binary, coords, 0.1)

func _on_Mask_item_selected(index):
	$Control/VBoxContainer/Mask.set_disabled(true)
	$QR.draw_info(dec2bin(index, 3), 2)

func _on_ApplyMask_pressed():
	$Control/VBoxContainer/ApplyMask.set_disabled(true)
	$QR.apply_mask($Control/VBoxContainer/Mask.get_selected_id(), coords)

func _on_DrawECFormatBits_pressed():
	$Control/VBoxContainer/DrawECFormatBits.set_disabled(true)
	
	var Format_bits = []
	var EC_Level = $Control/VBoxContainer/EC_Level.get_selected_id()
	var Mask = $Control/VBoxContainer/Mask.get_selected_id()
	
	Format_bits.append_array(dec2bin(EC_Level, 2))
	Format_bits.append_array(dec2bin(Mask, 3))
	var EC_Format_bits = $QR.rs_encode_inf(Format_bits)
	$QR.draw_info(EC_Format_bits, 5)
	format_info.append_array(Format_bits)
	format_info.append_array(EC_Format_bits)
	
func _on_MaskFormat_pressed():
	$Control/VBoxContainer/MaskFormat.set_disabled(true)
	var data = dec2bin(bin2dec(format_info)^21522, 15)
	$QR.draw_info(data, 0)

func _on_Clear_pressed():
	$QR.clear()
	
	format_info.clear()
	coords.clear()
	
	$Control/VBoxContainer/DrawPatterns.set_disabled(false)
	
	$Control/VBoxContainer/DrawTimingPatterns.set_disabled(false)
	
	$Control/VBoxContainer/EncodingMode.set_disabled(false)
	$Control/VBoxContainer/EncodingMode.select(-1)
	$Control/VBoxContainer/EncodingMode.set_item_text(-1, 'Encoding mode')
	
	$Control/VBoxContainer/EC_Level.set_disabled(false)
	$Control/VBoxContainer/EC_Level.select(-1)
	$Control/VBoxContainer/EC_Level.set_item_text(-1, 'Error Correction Level')
	
	$Control/VBoxContainer/TextEdit.readonly = false
	$Control/VBoxContainer/TextEdit.text = ''
	
	$Control/VBoxContainer/DrawLength.set_disabled(false)
	
	$Control/VBoxContainer/DrawText.set_disabled(false)
	
	$Control/VBoxContainer/DrawEnd.set_disabled(false)
	
	$Control/VBoxContainer/DrawPadSimbols.set_disabled(false)
	
	$Control/VBoxContainer/DrawECBlocks.set_disabled(false)
	
	$Control/VBoxContainer/Mask.set_disabled(false)
	$Control/VBoxContainer/Mask.select(-1)
	$Control/VBoxContainer/Mask.set_item_text(-1, 'Mask Type')
	
	
	$Control/VBoxContainer/ApplyMask.set_disabled(false)
	
	$Control/VBoxContainer/DrawECFormatBits.set_disabled(false)
	
	$Control/VBoxContainer/MaskFormat.set_disabled(false)

	
