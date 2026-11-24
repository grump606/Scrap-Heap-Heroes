## Placeholder for multiplayer. Nothing implements this yet.
##
## When networking arrives, the host keeps running SimWorld exactly as in
## single-player. A remote player becomes a Controller whose commands come
## from receive_commands(), and clients render snapshots from
## receive_snapshot() instead of a local world.
class_name Transport
extends RefCounted


func send_commands(_cmds: Array[Command]) -> void:
	pass


func receive_commands() -> Array[Command]:
	return []


func send_snapshot(_snapshot: Snapshot) -> void:
	pass


func receive_snapshot() -> Snapshot:
	return null
