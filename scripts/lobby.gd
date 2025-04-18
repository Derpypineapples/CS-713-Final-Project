extends Control

var websocket_url = "ADD WEBSOCKET URL HERE"

var match_button_texture = preload("res://assets/textures/tile.jpg")

const REQUEST_MATCHES = "REQUEST_MATCHES"
const JOIN_MATCH = "JOIN_MATCH"
const PLAYER_JOINED = "PLAYER_JOINED"
const PLAYER_DROPPED = "PLAYER_DROPPED"
const START_MATCH = "START_MATCH"
const MATCH_PLAYERS = "MATCH_PLAYERS"
const CHECK_MATCH_READY = "CHECK_MATCH_READY"
const MATCH_READY = "MATCH_READY"

@onready var _client : WebSocketClient = $WebSocketClient

var mock_user = {}

signal start_client(ip, port)

func _connect_to_matchmaking_server():
	var error = _client.connect_to_url(websocket_url)
	if error != OK:
		print("Error Connecting to WebSocket: %s" % [websocket_url])

func _ready():
	print("Attempting to Connect to Server...")
	
	$LobbyContainer.hide()
	$MatchesContainer/UserInfo/Username.text = "[Center]" + mock_user.username + "[center]"
	
	_connect_to_matchmaking_server()

func _send_message(message_to_send):
	var json_message = JSON.stringify(message_to_send)
	_client.send(json_message)

func _process_received_message(message):
	if typeof(message) == TYPE_STRING:
		var response_msg = str_to_var(message)
		
		if response_msg.op:
			print("Process message op: %s" % response_msg.op)
			
			if response_msg.op == REQUEST_MATCHES:
				print("REQUEST_MATCHES")
				var matches = response_msg.response
				if matches && matches.size() > 0:
					_add_matches_to_ui(matches)
					$MatchmakingStatus.text = "[center]Choose a match[center]"
			
			elif response_msg.op == MATCH_PLAYERS:
				print("MATCH_PLAYERS")
				_enter_match_lobby(response_msg.response)
			
			elif response_msg.op == MATCH_READY:
				print("MATCH_READY")
				print("Connection Info: %s, %s" % [response_msg.response.ip, response_msg.response.port])
				$MatchmakingStatus.text = "[center]Game Full, Entering Match[center]"
				start_client.emit(response_msg.response.ip, response_msg.response.port)
				_client.close(1000, "Game Started, Lobby Session Ended Normally")
			
			elif response_msg.op == PLAYER_JOINED:
				print("PLAYER_JOINED")
				var match_to_join = response_msg.response
				_build_player_lobby_list(match_to_join.users)
			
			elif response_msg.op == PLAYER_DROPPED:
				print("PLAYER_DROPPED")
				var match_to_join = response_msg.response
				print("Dropped Player: %s" % match_to_join.userId)
				_build_player_lobby_list(match_to_join.users)

func _enter_match_lobby(match_to_join):
	print("Enter Match Lobby")
	print(match_to_join)
	
	_build_player_lobby_list(match_to_join.users)
	
	var match_id = match_to_join.matchInfo.matchId
	var check_match_ready = {
		"op": CHECK_MATCH_READY,
		"matchId": match_id
	}
	_send_message(check_match_ready)

func _build_player_lobby_list(match_players):
	for team_child in $LobbyContainer/Teams/Team1.get_children():
		team_child.queue_free()
	for team_child in $LobbyContainer/Teams/Team2.get_children():
		team_child.queue_free()
	
	for player in match_players:
		print(player)
		
		var button_text = " %s | %s " % [player.username, player.rank]
		
		var button_label := RichTextLabel.new()
		button_label.set_text(button_text)
		button_label.set_size(Vector2(800, 100))
		button_label.set_position(Vector2(45, 30))
		button_label.fit_content = true
		button_label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		
		var button := TextureButton.new()
		button.texture_normal = match_button_texture
		button.texture_hover = match_button_texture
		button.texture_pressed = match_button_texture
		button.add_child(button_label)
		button.set_stretch_mode(TextureButton.STRETCH_SCALE)
		
		if player.team == "1":
			$LobbyContainer/Teams/Team1.add_child(button)
		elif player.team == "2":
			$LobbyContainer/Teams/Team2.add_child(button)
		else:
			print("Player Not Assigned a Team")

func _add_matches_to_ui(matches):
	for match_index in range(matches.size()):
		print(matches[match_index])
		
		var button_text = "# %s | %s | %s " % [str(match_index), matches[match_index].teamMakeup, matches[match_index].map]
		
		var button_label := RichTextLabel.new()
		button_label.set_text(button_text)
		button_label.set_size(Vector2(800, 100))
		button_label.set_position(Vector2(45, 30))
		button_label.fit_content = true
		button_label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		
		var button := TextureButton.new()
		button.texture_normal = match_button_texture
		button.texture_hover = match_button_texture
		button.texture_pressed = match_button_texture
		button.add_child(button_label)
		button.set_stretch_mode(TextureButton.STRETCH_SCALE)
		
		button.pressed.connect(self._join_match.bind(matches[match_index]))
		$MatchesContainer/AvailableMatches.add_child(button)

func _join_match(match_to_join: Dictionary):
	$MatchesContainer/AvailableMatches.hide()
	$MatchesContainer/MatchStatus.text = "Entering match lobby: \n" + match_to_join.teamMakeup + " | " + match_to_join.map
	
	var join_match_message = {
		"op": JOIN_MATCH,
		"matchId": match_to_join.matchId,
		"playerId": mock_user.playerId,
		"rank": mock_user.rank,
		"username": mock_user.username
	}
	
	_send_message(join_match_message)

func _on_websocket_message_received(message):
	print("Message received: %s" % message)
	_process_received_message(message)

func _on_websocket_client_connection_closed():
	var ws = _client.get_socket()
	print("Client disconnected with code: %s, reason: %s" % [ws.get_close_code(), ws.get_close_reason()])

func _on_websocket_client_connected_to_server():
	print("Client Connected to Server...")
	$MatchmakingStatus.text = "[center]Looking for Matches...[/center]"
	
	var request_matches = {
		"op": REQUEST_MATCHES
	}
	_send_message(request_matches)

func _on_send_test_message_pressed():
	print("Sending Message...")
	var dict = {
		"id": "1234",
		"op": "op"
	}
	var jsonMessage = JSON.stringify(dict)
	_client.send(jsonMessage)
