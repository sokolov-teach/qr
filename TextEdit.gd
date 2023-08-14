extends TextEdit

var length = 0

func _input(event):

	var final_text = text
	
	if final_text.length() > length:
		final_text.erase(final_text.length()-1, 1)

	text = final_text
	cursor_set_column(text.length())
