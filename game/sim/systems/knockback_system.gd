## Knockback: forced movement in a direction for a set time. Stateless.
## MovementSystem carries it out and pays any wall slam.
class_name KnockbackSystem
extends RefCounted


## Pushes target along dir. Rooted (planted) and CC_IMMUNE units ignore it. Returns true if
## the push took. slam_damage/slam_stun_ticks are paid if the push hits a wall.
static func push(world: SimWorld, target: UnitState, dir: Vector2, speed: float, ticks: int,
		slam_damage: int = 0, slam_stun_ticks: int = 0, source_id: int = 0) -> bool:
	if target.dead or target.immovable or ticks <= 0 or speed <= 0.0:
		return false
	if Status.active(target, Status.Kind.ROOTED, world.tick) or Status.active(target, Status.Kind.CC_IMMUNE, world.tick):
		return false
	var d := dir.normalized() if dir.length_squared() > 0.000001 else Vector2(0, 1)
	target.forced_velocity = Vector3(d.x, 0.0, d.y) * speed
	target.forced_until = world.tick + ticks
	target.slam_damage = slam_damage
	target.slam_stun_ticks = slam_stun_ticks
	target.slam_source = source_id
	if target is HeroState:
		target.dash_ability = null  # A push cancels the target's own dash...
		target.stop_channel()  # ...and any channel.
	if target is DummyState:
		target.reset_at = world.tick + world.rules.seconds_to_ticks(world.rules.dummy_reset_time)
	return true


## Starts a self-propelled dash. Walls stop it without a slam.
static func dash(world: SimWorld, h: HeroState, dir: Vector2, speed: float, ticks: int) -> void:
	var d := dir.normalized() if dir.length_squared() > 0.000001 else Vector2(0, -1)
	h.forced_velocity = Vector3(d.x, 0.0, d.y) * speed
	h.forced_until = world.tick + ticks
	h.slam_damage = 0
	h.slam_stun_ticks = 0
