local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local geo_util = include( "geo_util" )

---------------------------------------------------------
-- Local functions

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

local function createAltObserveTab( self, unit ) ----- if not stealthy
	local subtext = ""
	local brainClassType = unit:getBrain():getSituation().ClassType
	local x0, y0 = unit:getLocation()
	local x1 = nil
	local y1 = nil

	if brainClassType == simdefs.SITUATION_INVESTIGATE then
		if unit:getBrain():getInterest().x == x0 and unit:getBrain():getInterest().y == y0 then
			subtext = STRINGS.GUARD_STATUS.START_INVESTIGATING
		else
			subtext = STRINGS.GUARD_STATUS.INVESTIGATING
			x1 = unit:getBrain():getInterest().x
			y1 = unit:getBrain():getInterest().y
		end
	elseif brainClassType == simdefs.SITUATION_HUNT then
		local interest = unit:getBrain():getInterest()
		if interest and interest.reason == simdefs.REASON_KO and interest.x == x0 and interest.y == y0 then
			subtext = STRINGS.GUARD_STATUS.START_HUNTING
		else
			subtext = STRINGS.GUARD_STATUS.HUNTING
			x1 = interest.x 
			y1 = interest.y
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
			x1 = unit:getTraits().patrolPath[1].x
			y1 = unit:getTraits().patrolPath[1].y
		end
	else
		subtext = "UNKNOWN"
	end
	
	if x1 and y1 then
	--[==[	if not self.prop then
			self.prop = MOAIProp.new()
		end		
		
		local msh = geo_util.generateArcMesh(self._game.boardRig, x0, y0, 0, x1, y1, 0, 30, 10)
		self.prop:setDeck(msh)
		self.prop:setLoc(x0, y0)
		_game.boardRig:getLayer("ceiling"):insertProp(self.prop)
		]==]
	--	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { txt="hi", x=x1,y=y1, color={r=1,g=1,b=41/255,a=1}, skipQue=true } )
	end
	
    unit:createTab( STRINGS.GUARD_STATUS.STATUS, subtext )
end


local observePath = 
	{
		name = "OBSERVE - INCOGNITA", 

		createToolTip = function( self, sim, abilityOwner, abilityUser, targetID )
			return abilityutil.formatToolTip("OBSERVE - INCOGNITA", "Predict this guard's movements\nCosts 0.5Ap from all agents")
		end,

	--	profile_icon = "gui/items/icon-action_peek.png",
		profile_icon = "gui/icons/Flavour/icon-action_camera_peek.png",
		getName = function( self, sim, unit )
			return self.name
		end,

        canUseWhileDragging = true,

        isTarget = function( self, userUnit, targetUnit )
		
        	if targetUnit:getTraits().noObserve then
				return false
			end 
			if not targetUnit:getPather() then
				return false
			end 
			if targetUnit:getTraits().patrolObserved then 
				return false
			end 
			if not simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) then 
				return false 
			end
			if targetUnit:isKO() or targetUnit:isDead() then
				return false
			end

            return true
        end,

		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			if config.RECORD_MODE then
				return nil
			end
			
			if not sim:getParams().difficultyOptions.flav_skills then
				return nil
			end
			
			self._game = game
			_game = game
			
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
				if self:isTarget( userUnit, targetUnit ) then
					if sim:canUnitSeeUnit( userUnit, targetUnit ) then
						table.insert( units, targetUnit )
					elseif userUnit:getTraits().camObserve then --- if has inconitos (now central only)
						for _, cameraUnit in pairs(sim:getAllUnits()) do 
							if (cameraUnit:getTraits().mainframe_camera or cameraUnit:getTraits().isDrone) and cameraUnit:getPlayerOwner() == sim:getCurrentPlayer() then 
								if sim:canUnitSeeUnit(cameraUnit, targetUnit) then 
									table.insert( units, targetUnit )
                                    break
								end
                            elseif cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then
								table.insert( units, targetUnit )
                                break
							end
						end
					end
				end
			end 

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		usesMP = true,

		canUseAbility = function( self, sim, unit, userUnit, targetID )
			if targetID then 
				local targetUnit = sim:getUnit( targetID )
                if not self:isTarget( userUnit, targetUnit ) then
                    return false
                end
				
				local player = sim:getPC()
				if not userUnit:getPlayerOwner() == player then
					return false
				end
				
				for _, unit in pairs(sim:getAllUnits()) do
					if unit:getPlayerOwner() == player and simquery.isAgent( unit ) and unit:getMP() < 0.5 then
						return false, "All agents must have at least 0.5 AP"
					end
				end
				
	--			if unit:getMP() < 1 then
	--				return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
	--			end
			end

			return true 
		end, 

		executeAbility = function( self, sim, unit, userUnit, target )
			local target = sim:getUnit(target)
			local player = sim:getPC()
			
			target:getTraits().patrolObserved = true
			createObserveTab( target )
			sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, target )
			
			for _, unit in pairs(sim:getAllUnits()) do
				if unit:getPlayerOwner() == player and simquery.isAgent( unit ) then
					unit:getTraits().mp = unit:getTraits().mp - 0.5
					local x0,y0 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat("-{1} AP",0.5),x=x0,y=y0,color={r=1,g=1,b=1,a=1}} )		

					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )

					local x1, y1 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit } )
				--	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = STRINGS.PROGRAMS.WINGS.NAME, x = x1, y = y1,color={r=255/255,g=255/255,b=51/255,a=1}} )	
				end
			end
		end
	}
return observePath