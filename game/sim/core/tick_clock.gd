## Fixed-timestep accumulator. Converts variable frame time into a whole
## number of sim ticks, plus an interpolation factor for rendering.
## The app layer feeds it frame time; SimWorld itself never sees frame time.
class_name TickClock
extends RefCounted

var tick_rate: int
var tick_dt: float
var max_ticks_per_frame: int
var paused: bool = false
var _accumulator: float = 0.0


func _init(p_tick_rate: int = 60, p_max_ticks_per_frame: int = 5) -> void:
	tick_rate = p_tick_rate
	tick_dt = 1.0 / float(p_tick_rate)
	max_ticks_per_frame = p_max_ticks_per_frame


## Adds frame time and returns how many ticks to run now. Time beyond the
## catch-up cap is dropped, so a long hitch slows the game briefly instead of
## freezing it while it tries to catch up.
func advance(frame_delta: float) -> int:
	if paused:
		return 0
	_accumulator += maxf(frame_delta, 0.0)
	var ticks := int(floor(_accumulator / tick_dt))
	if ticks > max_ticks_per_frame:
		ticks = max_ticks_per_frame
		_accumulator = 0.0
	else:
		_accumulator -= ticks * tick_dt
	return ticks


## 0..1 progress toward the next tick, for render interpolation.
func alpha() -> float:
	return clampf(_accumulator / tick_dt, 0.0, 1.0)
