local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )


function custUseAP( sim, userUnit )
	local x1,y1 = userUnit:getLocation()
	local apTxt = STRINGS.UI.FLY_TXT.ATTACK_USED

	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=apTxt,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
	sim:dispatchEvent( simdefs.EV_HUD_MPUSED, userUnit )

	--[==[
	if userUnit:getTraits().actionAP then 
		local ADRENAL_BONUS=3
		if userUnit:getPlayerOwner()  ~= sim:getCurrentPlayer() then
			if not userUnit:getTraits().floatTxtQue then
				userUnit:getTraits().floatTxtQue = {}
			end
			table.insert(userUnit:getTraits().floatTxtQue,{txt=util.sformat(STRINGS.UI.FLY_TXT.ADRENAL_REGULATOR,ADRENAL_BONUS),color={r=255/255,g=178/255,b=102/255,a=1}})		
		else
			local x1,y1 = userUnit:getLocation()
			sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = userUnit } )		
			sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = userUnit , txt=util.sformat(STRINGS.UI.FLY_TXT.ADRENAL_REGULATOR,ADRENAL_BONUS), x=x1,y=y1,color={r=255/255,g=178/255,b=102/255,a=1}  } )	-- 
		end
		userUnit:addMP( ADRENAL_BONUS )
	end ]==]

	local apUsed = false	
	for i,unit in ipairs(userUnit:getChildren( )) do
		if unit:getTraits().extraAP and unit:getTraits().extraAP > 0 then
			unit:getTraits().extraAP = unit:getTraits().extraAP -1 
			apUsed = true
			local x1,y1 = userUnit:getLocation()
		--	sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = userUnit , txt=STRINGS.UI.FLY_TXT.EXTRA_ATTACK, sound = "SpySociety/Objects/drone/drone_mainfraimeshutdown", x=x1,y=y1,color={r=255/255,g=178/255,b=102/255,a=1}  } )	-- 
			break
		end
	end	

	if userUnit:getTraits().unlimitedAttacks then
		apUsed = true
	end

	if apUsed == false then
		userUnit:getTraits().ap = userUnit:getTraits().ap - 1
	end

	--[[
	if userUnit:getTraits().data_hacking then 
		userUnit:getTraits().data_hacking = nil
		userUnit:getSounds().spot = nil
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit })
	end
	]]

	userUnit:resetAllAiming()
	
	--sim:processReactions( userUnit )
end



local scandevice_ranged =
{
	name = STRINGS.ABILITIES.SCAN_DEVICE,
	--profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
	profile_icon = "gui/icons/Flavour/icon-sniff.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return abilityutil.formatToolTip(STRINGS.ABILITIES.SCAN, string.format( STRINGS.ABILITIES.TOOLTIPS.SCAN, targetUnit:getName() ))
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.SCAN_DEVICE
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return abilityOwner:getUnitData().profile_icon or self.profile_icon
    end,

	acquireTargets = function( self, targets, game, sim, unit )
		local userUnit = unit:getUnitOwner()
		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 
		
		local maxRange = userUnit:getTraits().wireless_range or 0
    --    if simquery.getEquippedGun( userUnit ) then -- does my owner have...
	--		maxRange = maxRange - 2
	--	end
	--	if simquery.getEquippedMelee( userUnit ) then
	--		maxRange = maxRange - 2
	--	end
		
		
        assert( userUnit, tostring(unit and unit:getName())..", "..tostring(unit:getLocation()) )
		
		
		local x0, y0 = userUnit:getLocation()
		local currentCell = sim:getCell( x0, y0 )
		local cells = {currentCell}
		local units = {}
		if maxRange then
			local fillCells = simquery.fillCircle( self._sim, x0, y0, maxRange, 0)			
			for i, cell in ipairs(fillCells) do
				for i, cellUnit in ipairs( cell.units ) do
					if sim:canUnitSeeUnit( userUnit, cellUnit ) and (cellUnit:getTraits().mainframe_ice or 0) > 0 and ( cellUnit:getTraits().mainframe_program or sim:getHideDaemons()) and not cellUnit:getTraits().daemon_sniffed  then
						table.insert( units, cellUnit )
					end
				end
			end
		end
		
		

		return targets.unitTarget( game, units, self, unit, userUnit )
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
		local delay = 0.5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)

		if not target:getTraits().mainframe_program then
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_HUD_INCIDENT_NEGATIVE.path )
        mission_util.showDialog( sim, STRINGS.UI.DIALOGS.NO_DAEMON_TITLE, STRINGS.UI.DIALOGS.NO_DAEMON_BODY )
			target:getTraits().daemon_sniffed = true	
			sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )	
		else
			target:getTraits().daemon_sniffed = true	
			sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = target, ice = target:getTraits().mainframe_ice, delta = 0} )		
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
		end

		inventory.useItem( sim, userUnit, unit )

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
	
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
        sim:addTrigger( simdefs.TRG_START_TURN, self )
        sim:addTrigger( "usedStim", self )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        sim:removeTrigger( "usedStim", self )
        self.abilityOwner = nil
	end,
	
	onTrigger = function( self, sim, evType, evData )
        if self.abilityOwner and evType == simdefs.TRG_START_TURN and not evData:isNPC() then
			local userUnit = self.abilityOwner:getUnitOwner()
			userUnit:getTraits().pacifist = true
        elseif self.abilityOwner and evType == "usedStim" and evData.target == self.abilityOwner:getUnitOwner() then
			local target = evData.target
			target:getTraits().pacifist = nil
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target  } )
		end
    end,
	
}

return scandevice_ranged