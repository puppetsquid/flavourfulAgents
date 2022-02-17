local util = include( "modules/util" )
local simquery = include("sim/simquery")
local abilitydefs = include( "sim/abilitydefs" )

local oldStealCredits = abilitydefs.lookupAbility("stealCredits")

local oldCanUseAbility = oldStealCredits.canUseAbility

local stealCredits = util.extend(oldStealCredits) {
	canUseAbility = function( self, sim, unit, userUnit )
		local ok, reason = oldCanUseAbility( self, sim, unit, userUnit )
		if not ok then
			return ok, reason
		end
		if sim:getParams().difficultyOptions.flav_unequip and simquery.getEquippedMelee( userUnit ) then
			return false, "Unequip Melee Equipment to use"
		end
		return true
	end
}

return stealCredits