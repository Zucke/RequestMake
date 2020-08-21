extends Node
onready var url = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer/Url
onready var method = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer/Method
onready var json_body = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/JsonBody
onready var header = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/Header
onready var authorization = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/Authorization
onready var request_info = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/RequestInfo
onready var send_socket_button = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/JsonBody/SendToSockeyButton
onready var use_websockets = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer/Websocket
onready var connection_message = $UI/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/RequestInfo/ConectingMessage

var last_body_text = ""
var saved_request_info = {
    url="",
    method=0,
    json_body="",
    header="",
    autorization="",
   }

var websocket: WebSocketClient

func get_legible_result(value):
    var legible_var ="\n\t{"
    for key in value:
        if typeof(value[key]) == TYPE_DICTIONARY:
            legible_var += get_legible_result(value[key])    
        
        else:
            legible_var += "\n[color=#40bd06]{key}[/color]: [color=#bcb622]{value}[/color],".format({"key":key, "value":value[key]})

    legible_var +="\n}"
    return legible_var
    
    
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
    connection_message.hide()
    request_info.bbcode_text = ""
    
    if response_code == 0:
        request_info.bbcode_text = "[color=#aa0110]\nError Resolving Host[/color]"
        return
    
    var json_result = JSON.parse(body.get_string_from_utf8())
    
    if json_result.error == OK and typeof(json_result.result) == TYPE_DICTIONARY:
        last_body_text = get_legible_result(json_result.result)
    
    else:
         last_body_text = "[color=#40bd06]%s[/color]"%body.get_string_from_utf8()
        

    request_info.bbcode_text = """
[color=#a16022]{response_code}:{response_info}[/color]

[color=#ffaa11]headers: {headers}[/color]

[color=#00eeaa]result: {result}[/color]

[color=#aaaa37]body:[/color]
{body}

""".format({
    "response_code":response_code,
    "response_info":Response.response_codes[str(response_code)],
    "headers":headers,
    "result":result,
    "body":last_body_text
    })
    
func _ready():
    set_process(false)
    load_last_request()

func save_last_request():
    var file = File.new()
    if file.open("user://las_request.dat", File.WRITE) == OK:
        file.store_var(saved_request_info)
        file.close()

func load_last_request():
    var file = File.new()
    if file.open("user://las_request.dat", File.READ) == OK:
        var contend = file.get_var()
        if not typeof(contend) == TYPE_DICTIONARY:
            return
        saved_request_info = contend
        url.text = saved_request_info.url
        method.select(saved_request_info.method)
        json_body.text = saved_request_info.json_body.c_unescape()
        header.text = saved_request_info.header
        authorization.text = saved_request_info.autorization
        file.close()

func _on_SendButton_pressed():
    $HTTPRequest.cancel_request()
    connection_message.show()
    saved_request_info.json_body = json_body.text

    saved_request_info.method = method.get_selected_id()
    saved_request_info.header =  header.text
    saved_request_info.url = url.text
    saved_request_info.autorization = authorization.text
    save_last_request()
    var header_p = get_headers()
    header_p.append("authorization:"+authorization.text)
    if use_websockets.pressed:
        new_websocket()
        return
        
    $HTTPRequest.request(url.text, header_p, true, saved_request_info.method, clean_and_to_json(saved_request_info.json_body))
    
func get_headers():
    var custom_header = PoolStringArray()
    if header.text:
        var raw_header = (header.text).split(",")
        
        for header_field in raw_header:
            if ":" in header_field:
                custom_header.append(header_field)
                
    
    return custom_header

func save_html():
    var file = File.new()
    if file.open("user://temp_view.html", File.WRITE) == OK:
        file.store_string(last_body_text)
        file.close()
    

func _on_OpenInBrowser_pressed():
    OS.shell_open(url.text)


func _on_DisplayBrowser_pressed():
    save_html()
    OS.shell_open(ProjectSettings.globalize_path("user://temp_view.html"))

func new_websocket():
    websocket = WebSocketClient.new()
    request_info.bbcode_text = ""
    websocket.connect("connection_established", self,"_on_connection_established")
    websocket.connect("data_received", self, "_on_websocket_data_received")
    websocket.connect("connection_closed", self, "_on_websocket_connection_closed") 
    websocket.connect("connection_error", self, "_on_websocket_connection_error")
    if websocket.connect_to_url(url.text) == OK:
        set_process(true)
    
    else:
        request_info.bbcode_text = "[color=#aa0110]Error Connecting[/color]"
    
    connection_message.hide()
    


func _on_websocket_data_received():
     request_info.bbcode_text += "\n[color=#01aa11]{info}[/color]".format({"info":websocket.get_peer(1).get_packet().get_string_from_utf8()})
    
func _on_connection_established(protocol):
    request_info.bbcode_text += "\n[color=#01aa11]Connected seccess, protocol{info}[/color]".format({"info":protocol})
    send_socket_button.show()
    
func _on_websocket_connection_closed(was_clean_close):
    var color = "#aa0110" if not was_clean_close else "#1088aa"
    request_info.bbcode_text += "\n[color={color}]Closed, was clean: {info}[/color]".format({"info":was_clean_close, "color":color})
    send_socket_button.hide()
    set_process(false)
    
func _on_websocket_connection_error():
    print(websocket.get_peer(1).get_packet_error())
    
func _process(delta):
    websocket.poll()

func _on_SendToSockeyButton_pressed():
    websocket.get_peer(1).put_packet(clean_and_to_json(json_body.text).to_utf8())

func clean_and_to_json(string:String):
    var result = JSON.parse(json_body.text)
    result.result
    return JSON.print(result.result)
    
