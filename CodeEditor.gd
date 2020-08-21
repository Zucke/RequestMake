extends TextEdit
export (Color) var strings_color
export (Color) var bool_color
var complete_char = ""
var last_selected_text = ""
func _ready():
    add_color_region("\"", "\"", strings_color)
    add_color_region("'", "'", strings_color)
    add_keyword_color("true", bool_color)
    add_keyword_color("false", bool_color)
    fold_all_lines()


func _input(event):
    if event is InputEventKey:
        if not event.pressed:
            return
            
        complete_char = ""
        match event.unicode:
            34, 39:
                complete_char = "%c"%event.unicode
                last_selected_text = get_selection_text()
                
            40:
                complete_char = "%c"%41
                last_selected_text = get_selection_text()
                
            91:
                complete_char = "%c"%93
                last_selected_text = get_selection_text()

            123:
                complete_char = "%c"%125
                last_selected_text = get_selection_text()

            
                



func _on_CodeEditor_text_changed():
    if complete_char:
        insert_text_at_cursor(last_selected_text+complete_char) 
        
