local util = include( "modules/util" )

local oldCarryable = include("sim/abilities/carryable")

local carryable = util.extend(oldCarryable) {
	pacifist = true,
}
return carryable