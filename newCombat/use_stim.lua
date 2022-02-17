local util = include( "modules/util" )
local abilitydefs = include( "sim/abilitydefs" )

local oldUse_stim = abilitydefs.lookupAbility("use_stim")
local oldDoInjection = oldUse_stim.doInjection

local use_stim = util.extend( oldUse_stim ) {
	doInjection = function( self, sim, unit, userUnit, target )
		oldDoInjection( self, sim, unit, userUnit, target )
		sim:triggerEvent( "usedStim", { stim = unit, user = userUnit, target = target } )
	end,
}

return use_stim