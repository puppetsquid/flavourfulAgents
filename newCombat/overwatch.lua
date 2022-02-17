local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simquery = include("sim/simquery")
local abilitydefs = include( "sim/abilitydefs" )

local oldOverwatch = abilitydefs.lookupAbility("overwatch")

local oldCanUseAbility = oldOverwatch.canUseAbility

local overwatch = util.extend(oldOverwatch) {
	getProfileIcon =  function( self, sim, unit )
		if unit:isAiming() then	
			return "gui/icons/action_icons/Action_icon_Small/actionicon_shootOW_on.png"
		else
			local wepUnit = simquery.getEquippedGun( unit )
			if wepUnit then
				return wepUnit:getUnitData().profile_icon
			elseif unit:getTraits().emptyRangedIcon then
				return unit:getTraits().emptyRangedIcon
			else
				return "gui/icons/action_icons/Action_icon_Small/actionicon_shootOW_off.png"
			end
		end
	end,

	canUseAbility = function( self, sim, unit )
		if unit:countAugments( "LEVER_augment_melee_specialist" ) > 0 then
			return false, STRINGS.ITEMSEXTEND.UI.REASON_MELEE_SPECIALIST
		end
		
		local ok, reason = oldCanUseAbility( self, sim, unit )
		if not ok then
			return false, reason
		end
		
		local weaponUnit = simquery.getEquippedGun( unit )
		
		if weaponUnit:getTraits().noOW then
			return false, "Does not work with this weapon"
		end
		
		if unit:getTraits().pacifist then
			if (weaponUnit:getTraits().baseDamage and weaponUnit:getTraits().baseDamage > 0) or (weaponUnit:getTraits().damage and weaponUnit:getTraits().damage > 0)  then 
				return false, "Inhibited by Pacifism"
			end
		end
		
		if weaponUnit and weaponUnit:getTraits().usesCharges then
			if weaponUnit:getTraits().charges < 1 then
				return false, STRINGS.UI.COMBAT_PANEL_NEED_CHARGES_2
			end
		end
		
		return true
	end,
}

return overwatch
