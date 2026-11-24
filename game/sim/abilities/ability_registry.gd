## Maps AbilityDef.logic to the script that runs it. The sim never loads
## files, so every ability script is listed here by class name.
## Adding an ability: write game/sim/abilities/<name>.gd with
## `static func cast(world, caster, def, aim)` and add a line below.
class_name AbilityRegistry
extends RefCounted

const KNOWN: Array[StringName] = [
	&"basic_attack",
	&"dust_bath", &"mud_slide", &"rump_bump", &"wall_crush", &"brace", &"burrow_burst",
]


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, aim: Vector2) -> void:
	match def.logic:
		&"basic_attack": BasicAttack.cast(world, caster, def, aim)
		&"dust_bath": DustBath.cast(world, caster, def, aim)
		&"mud_slide": MudSlide.cast(world, caster, def, aim)
		&"rump_bump": RumpBump.cast(world, caster, def, aim)
		&"wall_crush": WallCrush.cast(world, caster, def, aim)
		&"brace": Brace.cast(world, caster, def, aim)
		&"burrow_burst": BurrowBurst.cast(world, caster, def, aim)
		_: push_error("ability '%s' has unknown logic '%s'" % [def.id, def.logic])


## A contact dash (see AbilitySystem) touched an enemy.
static func on_dash_contact(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> void:
	match def.logic:
		&"wall_crush": WallCrush.on_contact(world, caster, def, target)
		_: push_error("ability '%s' has no dash contact" % def.id)
