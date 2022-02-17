local util = include( "modules/util" )
local simquery = include("sim/simquery")
local abilitydefs = include( "sim/abilitydefs" )

local oldOverwatchMelee = abilitydefs.lookupAbility("overwatchMelee")

local oldCanUseAbility = oldOverwatchMelee.canUseAbility

local overwatchMelee = util.extend(oldOverwatchMelee) {
	getProfileIcon =  function( self, sim, unit )
		if unit:getTraits().isMeleeAiming then
			return "gui/icons/action_icons/Action_icon_Small/actionicon__meleeOW_on.png"
		else
			local tazerUnit = simquery.getEquippedMelee( unit )
			if tazerUnit then
				return tazerUnit:getUnitData().profile_icon
			elseif unit:getTraits().emptyMeleeIcon then
				return unit:getTraits().emptyMeleeIcon
			else
				return "gui/icons/action_icons/Action_icon_Small/actionicon__meleeOW_off.png"
			end
		end
	end,

	canUseAbility = function( self, sim, unit )
		local ok, reason = oldCanUseAbility( self, sim, unit )
		if not ok then
			return false, reason
		end
		
		local tazerUnit = simquery.getEquippedMelee( unit )
		
		if unit:getTraits().pacifist then
			if (tazerUnit:getTraits().baseDamage and tazerUnit:getTraits().baseDamage > 0) or (tazerUnit:getTraits().damage and tazerUnit:getTraits().damage > 0)  then 
				return false, "Inhibited by Pacifism"
			end
		end
		
		return true
	end,
}

return overwatchMelee