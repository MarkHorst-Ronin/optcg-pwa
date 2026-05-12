## SteamLobby.gd
## Steam P2P lobby management via GodotSteam
## Agent 12 owns this file.
## Requires GodotSteam extension — see https://godotsteam.com
class_name SteamLobby
extends Node

signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_failed(reason: String)
signal match_ready()
signal peer_disconnected(peer_id: int)

var current_lobby_id: int = 0

func create_lobby() -> void:
	## TODO: Agent 12
	## Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 2)
	pass

func join_lobby(lobby_id: int) -> void:
	## TODO: Agent 12
	## Steam.joinLobby(lobby_id)
	pass

func leave_lobby() -> void:
	if current_lobby_id != 0:
		## TODO: Agent 12 — Steam.leaveLobby(current_lobby_id)
		current_lobby_id = 0

func _on_lobby_created(_connect: int, _lobby_id: int) -> void:
	pass  ## TODO: Agent 12

func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	pass  ## TODO: Agent 12
