extends Node

var content
var save_path:String = ""
var passcode = "dqaduqiqbnmn1863841hjb"
@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar


const Player = preload("res://player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	
	upnp_setup()
	$CanvasLayer/MainMenu/save.popup_centered()
	
func _on_join_button_pressed():
	$CanvasLayer/MainMenu/FileDialog.popup_centered()
	#main_menu.hide()
	#hud.show()
	#
	#enet_peer.create_client(address_entry.text, PORT)
	#multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	#print(upnp.query_external_address().to_utf8_buffer().hex_encode())
	print("Success! Join Address: %s" % upnp.query_external_address())
	content = upnp.query_external_address()




func save_file(content):
	pass

func load_file(path):
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ,passcode)
	var content = file.get_as_text()
	return content


func _on_file_dialog_file_selected(path):
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(load_file(path), PORT)
	multiplayer.multiplayer_peer = enet_peer


func password_submitted(new_text):
	if new_text != "":
		passcode = new_text




func _on_save_file_selected(path):
	var save_path = str(path,".txt")
	print("dir ",path)
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE,passcode)
	file.store_string(content)
	add_player(multiplayer.get_unique_id())
	main_menu.hide()
	hud.show()
