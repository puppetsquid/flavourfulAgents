local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )

local mathutil = include( "modules/mathutil" )
local serverdefs = include( "modules/serverdefs" )
local simability = include( "sim/simability" )

local decker_installer =
{
	name = STRINGS.FLAVORED.ITEMS.AUGMENTS.DECKER_DEAMON_ACTION,
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
	--profile_icon = "gui/icons/Flavour/icon-sniff.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.AUGMENTS.DECKER_DEAMON_ACTION, string.format( STRINGS.FLAVORED.ITEMS.AUGMENTS.DECKER_DEAMON_TOOLTIP, targetUnit:getName() ))
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.SCAN_DEVICE
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return abilityOwner:getUnitData().profile_icon or self.profile_icon
    end,

	acquireTargets = function( self, targets, game, sim, unit )

		local targetUnits = {}
		local userUnit = unit:getUnitOwner()
		
		local maxRange = 10
		local x0, y0 = userUnit:getLocation()
		local units = {}
		for _, targetUnit in pairs(sim:getAllUnits()) do
			local x1, y1 = targetUnit:getLocation()
			if x0 and x1 and self:isValidTarget( sim, userUnit, userUnit, targetUnit ) then
				local range = mathutil.dist2d( x0, y0, x1, y1 )
				if maxRange then
					if range <= maxRange then
						if sim:canPlayerSeeUnit( userUnit:getPlayerOwner(), targetUnit ) then
							table.insert( units, targetUnit )
						else
							for _, cameraUnit in pairs(sim:getAllUnits()) do 
								if cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then
									table.insert( units, targetUnit )
									break
								end
							end
						end
					end
				end
			end
		end
		
		return targets.unitTarget( game, units, self, unit, userUnit )

	end,
	
	isValidTarget = function( self, sim, unit, userUnit, targetUnit )
		
		if (targetUnit:getTraits().mainframe_ice or 0) > 0 and not ( targetUnit:getTraits().mainframe_program ) then
			return true
		end
		
		return false
	end,

		
	canUseAbility = function( self, sim, unit )

		-- Must have a user owner.
		local userUnit = unit:getUnitOwner()

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 

		if not userUnit then
			return false
		end

		--- add has LOS		
	
		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end

		return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local targ = target
		local mainframe = include( "sim/mainframe" )
		local userUnit = unit:getUnitOwner()
		local target = sim:getUnit(target)	

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 		
			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = target:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 

	--	sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = newFacing, sound="SpySociety/Actions/use_scanchip", soundFrame=10} )
		sim:dispatchEvent( simdefs.EV_UNIT_WIRELESS_SCAN, { unitID = userUnit:getID(), targetUnitID = target:getID(), hijack = true } )
		sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )			
		local delay = .5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)

		local daemon = "whistleblow"
		
		for _, unit in pairs( sim:getAllUnits() ) do
				if unit:getTraits().mainframe_program == daemon then
					unit:getTraits().mainframe_program = nil
					target:getTraits().daemon_sniffed = nil
				end
			end
		
	--	sim:getNPC():addMainframeAbility( sim, daemon, targ, 0 )
	--	local ability = simability.create( daemon )
	
	--	table.insert( sim:getNPC()._mainframeAbilities, ability )
	--	ability:spawnAbility( sim:getNPC()._sim, self, targ )
		
		target:getTraits().mainframe_program = daemon
		target:getTraits().daemon_sniffed = true
		sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )		
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
		
	--[==[	
		if target:getTraits().mainframe_program then
			target:getTraits().daemon_sniffed = true	
			sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )		
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
		end

		]==]
		
		inventory.useItem( sim, userUnit, unit )

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
	
}

return decker_installer