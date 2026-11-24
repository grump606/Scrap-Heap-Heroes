## Autoload "Settings": this machine's video/audio/input preferences.
## Holds no gameplay data and nothing per-player, and the sim never reads it.
extends Node

const PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.003
var master_volume_db: float = 0.0
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	master_volume_db = cfg.get_value("audio", "master_volume_db", master_volume_db)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("audio", "master_volume_db", master_volume_db)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	AudioServer.set_bus_volume_db(0, master_volume_db)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
