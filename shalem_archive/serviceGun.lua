local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local serviceGun =
	{
		name = "Reset",
		createToolTip = function( self,sim,unit,targetCell)
				return abilityutil.formatToolTip( "Reset Weapon",  "Multi-Shot weapons must be reset between uses", 1 )
		end,

		--profile_icon = "gui/items/icon-item_ammo.png",
	--	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_chargeweapon_small.png",
		profile_icon = "gui/icons/Flavour/icon-item_reset.png",

		alwaysShow = true,

		getName = function( self, sim, unit )
			return "Service" --STRINGS.ABILITIES.RECHARGE
		end,

		canUseAbility = function( self, sim, itemUnit, unit )

		--	if itemUnit:getTraits().energyWeapon then
				if not itemUnit:getTraits().energyWeapon == "used" or itemUnit:getTraits().energyWeapon == "idle" then
					return false, "Not in need of reset"
				end
		--	end
			
			if unit:getAP() < 1 then 
				return false, "Attack used"
			end
			
			if unit:getTraits().serviceOnly then

				local userUnitAgentID = userUnit:getUnitData().agentID
				local canUse = false
				for i,set in pairs(unit:getTraits().serviceOnly )do
					if set.agentID == userUnitAgentID then
						canUse=true
					end
				end


				if not canUse then
					return false,  STRINGS.UI.REASON.RESTRUCTED_USE
				end				
			end

			return true
		end,
		
		executeAbility = function( self, sim, itemUnit, unit )
		
			local x0, y0 = unit:getLocation()
			sim:emitSound( simdefs.SOUND_ITEM_PUTDOWN, x0, y0, unit)
			sim:dispatchEvent( simdefs.EV_UNIT_PICKUP, { unitID = unit:getID() } )	
			
			sim:emitSound( { path = "SpySociety/Weapons/Precise/reload_rifle", range = simdefs.SOUND_RANGE_0 }, x0, y0, unit )
            if itemUnit == simquery.getEquippedGun( unit ) then
		        sim:dispatchEvent( simdefs.EV_UNIT_RELOADED, { unit = unit } )
		    end
		
			itemUnit:getTraits().energyWeapon = "idle"
		
			unit:useAP( sim )
		end
	}
return serviceGun