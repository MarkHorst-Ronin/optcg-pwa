## AuthManager.gd
## Firebase Auth integration for player accounts
## Agent 7 owns this file.
class_name AuthManager
extends Node

signal login_complete(uid: String, display_name: String)
signal login_failed(error: String)
signal logout_complete()

const API_BASE: String = "https://api.optcg.vaultautomation.org"
const SETTINGS_PATH: String = "user://auth.cfg"

var _uid: String = ""
var _display_name: String = ""
var _token: String = ""

func _ready() -> void:
	_try_auto_login()

func _try_auto_login() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_token        = cfg.get_value("auth", "token", "")
		_uid          = cfg.get_value("auth", "uid", "")
		_display_name = cfg.get_value("auth", "display_name", "")
		## TODO: Agent 7 — validate token against API

func login(email: String, password: String) -> void:
	## TODO: Agent 7 — POST /api/auth/login
	pass

func register(email: String, password: String, display_name: String) -> void:
	## TODO: Agent 7 — POST /api/auth/register
	pass

func logout() -> void:
	_uid = ""
	_token = ""
	_display_name = ""
	var cfg := ConfigFile.new()
	cfg.save(SETTINGS_PATH)
	logout_complete.emit()

func get_current_uid() -> String:
	return _uid

func is_logged_in() -> bool:
	return _token != "" and _uid != ""

func get_auth_token() -> String:
	return _token
