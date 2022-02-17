local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local abilitydefs = include( "sim/abilitydefs" )

local oldObservePath = abilitydefs.lookupAbility("observePath")

local oldCanUseAbility = oldObservePath.canUseAbility


local function createObserveTab( unit )
	local subtext = ""
	local brainClassType = unit:getBrain():getSituation().ClassType
	local x0, y0 = unit:getLocation()

	if brainClassType == simdefs.SITUATION_INVESTIGATE then
		if unit:getBrain():getInterest().x == x0 and unit:getBrain():getInterest().y == y0 then
			subtext = STRINGS.GUARD_STATUS.START_INVESTIGATING
		else
			subtext = STRINGS.GUARD_STATUS.INVESTIGATING
		end
	elseif brainClassType == simdefs.SITUATION_HUNT then
		local interest = unit:getBrain():getInterest()
		if interest and interest.reason == simdefs.REASON_KO and interest.x == x0 and interest.y == y0 then
			subtext = STRINGS.GUARD_STATUS.START_HUNTING
		else
			subtext = STRINGS.GUARD_STATUS.HUNTING
		end
	elseif brainClassType == simdefs.SITUATION_FLEE then
		subtext = STRINGS.GUARD_STATUS.FLEEING
	elseif brainClassType == simdefs.SITUATION_COMBAT then
		if unit:getTraits().vip then
			subtext = STRINGS.GUARD_STATUS.FLEEING
		else
			subtext = STRINGS.GUARD_STATUS.COMBAT
		end
	elseif brainClassType == simdefs.SITUATION_IDLE then
		if not unit:getTraits().patrolPath
			or (#unit:getTraits().patrolPath == 1 and unit:getTraits().patrolPath[1].x == x0 and unit:getTraits().patrolPath[1].y == y0) then
			subtext = STRINGS.GUARD_STATUS.IDLE
		else
			subtext = STRINGS.GUARD_STATUS.PATROLLING
		end
	else
		subtext = "UNKNOWN"
	end

    unit:createTab( STRINGS.GUARD_STATUS.STATUS, subtext )
end



local observePath = util.extend(oldObservePath) {
	getProfileIcon =  function( self, sim, unit )
		local player = unit:getPlayerOwner()
		local oneConsole = nil
		local cell = sim:getCell( unit:getLocation() )
		local nearbyConsoles = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
				if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
					if simquery.canUnitReach( sim, unit, exit.cell.x, exit.cell.y ) and cellUnit:getTraits().mainframe_status ~= "off" and cellUnit:getPlayerOwner() == unit:getPlayerOwner() then
						table.insert( nearbyConsoles, cellUnit )
						oneConsole = true
						self.myConsoleDir = cellUnit:getFacing()
						self.myConsole = cellUnit
					end
				end
			end
		end
		if oneConsole then	
			return "gui/icons/Flavour/icon-action_camera_peek.png"
		else
			return "gui/items/icon-action_peek.png"
		end
	end,

	acquireTargets = function( self, targets, game, sim, unit, userUnit )
		if config.RECORD_MODE then
			return nil
		end
		
		local player = userUnit:getPlayerOwner()
		local oneConsole = nil
		local cell = sim:getCell( userUnit:getLocation() )
		local nearbyConsoles = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
				if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
					if simquery.canUnitReach( sim, userUnit, exit.cell.x, exit.cell.y ) and cellUnit:getTraits().mainframe_status ~= "off" and cellUnit:getPlayerOwner() == userUnit:getPlayerOwner() then
						table.insert( nearbyConsoles, cellUnit )
						oneConsole = true
						self.myConsoleDir = cellUnit:getFacing()
						self.myConsole = cellUnit
					end
				end
			end
		end
		
		local units = {}
		local x0, y0 = userUnit:getLocation()
		for _, targetUnit in pairs(sim:getAllUnits()) do
			if self:isTarget( userUnit, targetUnit ) then
				if ( userUnit:countAugments( "LEVER_augment_quantum_communicator" ) > 0 and sim:canPlayerSeeUnit( sim:getCurrentPlayer(), targetUnit ) ) or (sim:canUnitSeeUnit( userUnit, targetUnit ) and ((userUnit:getSkillLevel("stealth") and userUnit:getSkillLevel("stealth") > 1) or not sim:getParams().difficultyOptions.flav_skills)) then
					--or (sim:canPlayerSeeUnit( sim:getPC(), targetUnit ) and oneConsole) then
					table.insert( units, targetUnit )
				else
					for _, cameraUnit in pairs(sim:getAllUnits()) do 
						if (oneConsole or not sim:getParams().difficultyOptions.flav_skills) and (cameraUnit:getTraits().mainframe_camera or cameraUnit:getTraits().isDrone) and cameraUnit:getPlayerOwner() == sim:getCurrentPlayer() then 
							if sim:canUnitSeeUnit(cameraUnit, targetUnit) then 
								table.insert( units, targetUnit )
								break
							end
						elseif cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit )
								and ((userUnit:getSkillLevel("stealth") and userUnit:getSkillLevel("stealth") > 1) or not sim:getParams().difficultyOptions.flav_skill) then -- or oneConsole
							table.insert( units, targetUnit )
							break
						end
					end
				end
			end
		end
		return targets.unitTarget( game, units, self, unit, userUnit )
	end,

	canUseAbility = function( self, sim, unit, userUnit, targetID )
		local ok, reason = oldCanUseAbility( self, sim, unit, userUnit, targetID )
		if not ok then
			return ok, reason
		end
		if targetID then
			if (sim:getParams().difficultyOptions.flav_skills and userUnit:countAugments( "LEVER_augment_quantum_communicator" ) == 0 and unit:getSkillLevel("stealth") and unit:getSkillLevel("stealth") == 1) then
				local cell = sim:getCell( userUnit:getLocation() )
				local reason
				for dir, exit in pairs(cell.exits) do
					for _, cellUnit in ipairs( exit.cell.units ) do
						if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
							local dir = cellUnit:getFacing()
							local x0, y0 = cellUnit:getLocation()
							local x1, y1 = simquery.getDeltaFromDirection(dir)
							local consoleFront = sim:getCell( x0 + x1, y0 + y1 )
												
							if sim:getCell(userUnit:getLocation()) ~= consoleFront then
								reason = "must be at front of console"
							elseif cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() then
								reason = reason or "Must own console to use this ability."
							else
								return true
							end						
						end
					end
				end
				return false, reason
			end
		end
	
		return true 
	end, 
	
	--[==[executeAbility = function( self, sim, unit, userUnit, target )
			local target = sim:getUnit(target)

			unit:useMP(1, sim)
			target:getTraits().patrolObserved = true
			target:getTraits().patrolObservedDecker = true
            createObserveTab( target )
			sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, target )
		end]==]
}
return observePath