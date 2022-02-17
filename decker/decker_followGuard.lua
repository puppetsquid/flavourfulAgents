local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )

---------------------------------------------------------
-- Local functions

function isCoreItem( unit )
		if unit:getTraits().largenano or unit:getTraits().bigshopcat or unit:getTraits().vip or unit:getTraits().public_term then
			return true
		elseif unit:hasAbility( "open_detention_cells" ) or unit:hasAbility( "hostage_rescuable" )  or unit:hasAbility( "open_security_boxes" ) then
			return true
		elseif unit:hasAbility( "useAugmentMachine" ) and not unit:getTraits().drill then
			return true
		end
	
	--traits().largenano
	--
end


function closestByWalking ( sim, units, userUnit, maxMP, fn )
	--simquery.findPath( sim, unit, startcell, endcell, maxMP, goalFn )
	
	local userLoc = userUnit:getLocation()
	local userLocx, userLocy = userUnit:getLocation()
	local userCell = sim:getCell( userLoc )
	--local nearestEmptyUserCell = simquery.findNearestEmptyCell( sim, userCell.x, userCell.y, userUnit )
	
	
	
--	local startCell = sim:getCell(self.unit:getLocation() )
	--local guardCells = sim:getCells("guard_spawn")

	--to do: reduce the cells we path to down to just the closest ones for each guard elevator

	local astar = include ("modules/astar" )
	local astar_handlers = include("sim/astar_handlers")
	local pather = astar.AStar:new(astar_handlers.aihandler:new(userUnit) ) -- self.unit) )
	local closestCell, closestPathDist, closestUnit
	for i, unit in ipairs(units) do
	--	log:write("checking dist-")
	--	log:write(unit:getUnitData().name)
		local x1, y1 = unit:getLocation()
		local unitCell = sim:getCell( x1, y1 )
		local nearestEmptyCell = simquery.findNearestEmptyCell( sim, x1, y1, userUnit )
		local nearestEmptyUserCell = simquery.findNearestEmptyCell( sim, userLocx, userLocy, unit )
		local canPath, pathCost = simquery.findPath( sim, userUnit, nearestEmptyUserCell, nearestEmptyCell, 99999 )

		if pathCost then
			if not closestCell or pathCost < closestPathDist then
				closestCell = unitCell
				closestUnit = unit
				closestPathDist = pathCost
			end
		end
	end

	if closestUnit then
		log:write("closestIs-")
		log:write(closestUnit:getUnitData().name)
	end
		return closestUnit --{x=closestCell.x, y=closestCell.y}
end

function isUsefulItem( unit )
	if unit:getTraits().mainframe_status ~= "off" and not unit:getTraits().hasBeenPatrolChecked then
		if unit:getTraits().revealUnits == "mainframe_console" or unit:getTraits().revealUnits == "mainframe_camera"  or  unit:getTraits().showOutline or  unit:getTraits().revealDaemons then
			return true
		elseif unit:getTraits().router or unit:getTraits().power_core or unit:getTraits().tinker_anim  then
			return true
	--	elseif unit:getTraits().storeType == "standard" or unit:getTraits().storeType == "miniserver" then
	--		return true
	--	elseif unit:getTraits().powerGrid then
		elseif unit:getTraits().laser_gen or unit:getTraits().multiLockSwitch then
			return true
		end
	end
	
	--traits().largenano
	--
end

function getRelativeDirectionString (target, item)

	local targetFacing = target:getFacing( )
	local x1, y1 = target:getLocation()
	local x2, y2 = item:getLocation()
	local dir = simquery.getDirectionFromDelta(x1 - x2, y1 - y2)
	local x3, y3 = simquery.getDeltaFromDirection(dir)
	
	
	local finalString = "Item is "
	
	if x3 == 1 then
		finalString = finalString .. "Infront "
	elseif x3 == -1 then
		finalString = finalString .. "Behind "
	end
	
	if x3 ~= 0 and y3 ~= 0 then
		finalString = finalString .. "and "
	end
	
	if y3 == 1 then
		finalString = finalString .. "To The Right "
	elseif y3 == -1 then
		finalString = finalString .. "To The Left "
	end
	
	finalString = finalString .. "of Target\n"
	
	return finalString

end


local cloak_tooltip = class( abilityutil.hotkey_tooltip )

function cloak_tooltip:init( hud, unit, range, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
	self._game = hud._game
	self._unit = unit
	self._range = range
    --if range then
    --    local x0, y0 = unit:getLocation() 
    --    self._targets = getTargetUnits( hud._game.simCore, unit, x0, y0, range)
   -- end
end

function cloak_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )
	if self._range then
		self._hiliteID = self._game.boardRig:hiliteCells( self._range, cdefs.HILITE_TARGET_COLOR )
	end
end

function cloak_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
	if self._range then
		self._game.boardRig:unhiliteCells( self._hiliteID )	
		self._hiliteID = nil
	end
end




local decker_followGuard = 
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.FOLLOWPATROL,

		createToolTip = function( self, sim, abilityOwner, abilityUser, targetID )
			
			return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.AUGMENTS.FOLLOWPATROL, STRINGS.FLAVORED.ITEMS.AUGMENTS.FOLLOWPATROL_DESC)
		end,
		
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
			local closestItem, itemLoc, itemType = self:getClosestItem( sim, abilityOwner, abilityUser, targetUnit )
			
			local movetable, cost = nil, nil
			
			if closestItem then
				local startPoint = sim:getCell( targetUnit:getLocation() )
				movetable, cost = simquery.findPath( sim, targetUnit, startPoint, itemLoc )
				
				for i = #movetable, 1, -1 do -- the rest
					if i > 4 then
						movetable [i] = nil
					end
				end
			end
			
		--	local SPRINT_TOOLTIP = util.sformat( "THIS IS A TEST" )
			return cloak_tooltip( hud, abilityUser, movetable, self, sim, abilityOwner, STRINGS.ABILITIES.CLOAK_DESC )
		end,
		
	--[==[	onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
			local closestItem, itemLoc, itemType = self:getClosestItem( sim, abilityOwner, abilityUser, targetUnit )
			local finalString = getRelativeDirectionString(targetUnit, closestItem)
			
			
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( STRINGS.FLAVORED.ITEMS.AUGMENTS.FOLLOWPATROL )
			if targetUnit then
					section:addLine(finalString .. STRINGS.FLAVORED.ITEMS.AUGMENTS.FOLLOWPATROL_DESC, abilityOwner:getTraits().advPWR )
			end
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,
	]==]
		
		proxy = true,

		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_overwatch_small.png",
		getName = function( self, sim, unit )
			return self.name
		end,

        canUseWhileDragging = true,

		isTarget = function( self, sim, userUnit, targetUnit )
			if simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) and targetUnit:getTraits().isAgent and not targetUnit:getTraits().isDrone then
			local x0, y0 = userUnit:getLocation()
				if targetUnit:getBrain():getSituation() == sim:getNPC():getIdleSituation() and not userUnit:getTraits().hasUsedFollowGuard 
				and not ( targetUnit:isKO() or targetUnit:isDead() or  targetUnit:getTraits().noObserve ) and targetUnit:getBrain():getSituation() == sim:getNPC():getIdleSituation() then
					return true
				end
			end
			
			
					
			return false
		end,

		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
                if self:isTarget( sim, userUnit, targetUnit ) then 

    				if sim:canUnitSeeUnit( userUnit, targetUnit ) then
						table.insert( units, targetUnit )
					else 
						for _, cameraUnit in pairs(sim:getAllUnits()) do 
							if cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then -- peek thru doors
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
			local targetUnit = sim:getUnit( targetID )
			if targetUnit then 
				local x0, y0 = userUnit:getLocation()
			end
			
			if targetUnit then
				local closestItem, itemLoc, itemType = self:getClosestItem( sim, unit, userUnit, targetUnit )
				if not closestItem then
					return false, "No more items"
				end
			end

			return true 
		end, 
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			self.userUnit = unit:getUnitOwner()
			self.patrollingGuard = nil
			self.targetedCell = nil
			self.targetedUnit = nil
			self.patrolGuardBase = nil
			sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
			sim:addTrigger( simdefs.TRG_START_TURN, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			self.patrollingGuard = nil
			self.abilityOwner = nil
			self.userUnit = nil
			self.targetedCell = nil
			self.targetedUnit = nil
			self.patrolGuardBase = nil
		end,
		
		-- trigger - on reach patrolLoc, 'patrolReached', maybe play tinker anim
		-- recreate table with fn excluding 'patrolReached'
		-- if 'noted' not 'reached', recreate table
		-- else find objective and make patrol (nearest reachable x3?)
		
		onTrigger = function ( self, sim, evType, evData )  -- need to get this working
			local bonusTrait = false
			
			if evType == simdefs.TRG_UNIT_WARP then
				local patrollingGuard = self.patrollingGuard
				local abilityOwner = self.abilityOwner
				local targetedCell = self.targetedCell
				local targetedUnit = self.targetedUnit
				local patrollingGuardBase = self.patrolGuardBase

				if targetedCell and evData.to_cell and evData.unit == patrollingGuard and evData.to_cell == targetedCell then
					log:write("REACHED!")
					targetedUnit:getTraits().hasBeenPatrolChecked = true
				--	self:doSetPatrol( sim, abilityOwner, abilityOwner, patrollingGuardBase )
				end
				
				if evData.to_cell and evData.unit == self.userUnit then
					local userUnit = self.userUnit
					--	if bonusTrait then 
							for _, targetUnit in pairs(sim:getAllUnits()) do
								if targetUnit:getTraits().patrolObservedTemp == true and not sim:canUnitSeeUnit( userUnit, targetUnit ) then
									targetUnit:getTraits().patrolObserved = nil
									targetUnit:getTraits().patrolObservedTemp = nil
								end	
							end							
					--	end
					local observeAbility = self.userUnit:hasAbility("observePath")
					for _, targetUnit in pairs(sim:getAllUnits()) do
						if observeAbility and self:isTarget( sim, userUnit, targetUnit ) and sim:canUnitSeeUnit( userUnit, targetUnit ) then 
							targetUnit:getTraits().patrolObserved = true
							targetUnit:getTraits().patrolObservedTemp = true
							sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
						end
					end
				end
			elseif evType == simdefs.TRG_START_TURN and bonusTrait then
			
				local observeAbility = self.userUnit:hasAbility("observePath")
				if observeAbility then
					for _, targetUnit in pairs(sim:getAllUnits()) do
						if simquery.isEnemyTarget( self.userUnit:getPlayerOwner(), targetUnit ) and targetUnit:getTraits().isAgent and not targetUnit:getTraits().isDrone and not ( targetUnit:getTraits().noObserve or targetUnit:getTraits().patrolObserved or targetUnit:isKO() or targetUnit:isDead() ) then
							if sim:canUnitSeeUnit( self.userUnit, targetUnit )  then
							--	self.userUnit:hasAbility("observePath"):getDef():executeAbility( sim, 	self.userUnit, self.userUnit, targetUnit:getID() )
								targetUnit:getTraits().patrolObserved = true
								targetUnit:getTraits().patrolObservedTemp = true
								sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
							else
								for _, cameraUnit in pairs(sim:getAllUnits()) do 
									if cameraUnit:getTraits().peekID == self.userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then
									--	self.userUnit:hasAbility("observePath"):getDef():executeAbility( sim, self.userUnit, self.userUnit, targetUnit:getID() )
										targetUnit:getTraits().patrolObserved = true
										targetUnit:getTraits().patrolObservedTemp = true
										sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
										break
									end
								end
							end
						end
					end
				end
			end
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )
			self.patrolGuardBase = target
		--	self:doSetPatrol( sim, unit, userUnit, target )
			self:doAlertTarget( sim, unit, userUnit, target )
		--	userUnit:getTraits().hasUsedFollowGuard = true
			
		end,
		
		getClosestItem = function ( self, sim, unit, userUnit, target )
		--	local target = sim:getUnit(target)
			local x0, y0 = userUnit:getLocation()
			local x1, y1 = target:getLocation()
			local player = sim:getPC()
			self.patrollingGuard = target
			
			local usefulItems = {}
			for _, unit in pairs( sim:getAllUnits() ) do
				if isUsefulItem(unit) then
					if not unit:getTraits().hasBeenPatrolChecked then
						table.insert( usefulItems, unit )
					end
				end
			end
			
			local coreItems = {}
			
			for _, unit in pairs( sim:getAllUnits() ) do
				if isCoreItem(unit) then
					if not unit:getTraits().hasBeenPatrolChecked then
						table.insert( coreItems, unit )
					end
				end
			end
			
			
			local closestItem = nil
			local itemLoc = nil
			local itemType = nil
			local closestCoreItem = nil
			local xA, yA = target:getLocation()
			
			
			if #coreItems > 0 then
			--	closestCoreItem = closestByWalking ( sim, coreItems, target )	
				closestItem = simquery.findClosestUnit (coreItems, xA, yA)
				local x9, y9 = closestItem:getLocation()
				itemLoc = simquery.findNearestEmptyCell( sim, x9, y9, target )
				itemType = "core"
			elseif #usefulItems > 0 then
				closestItem = simquery.findClosestUnit (usefulItems, xA, yA)
				local x9, y9 = closestItem:getLocation()
				itemLoc = simquery.findNearestEmptyCell( sim, x9, y9, target )
				itemType = "useful"
			end
			
			return closestItem, itemLoc, itemType
		end,
		
		
		doAlertTarget = function( self, sim, unit, userUnit, target )
			local targetUnit = sim:getUnit(target)
			local closestItem, itemLoc, itemType = self:getClosestItem( sim, unit, userUnit, targetUnit )
			local x9, y9 = closestItem:getLocation()
			local x8, y8 = itemLoc.x, itemLoc.y
		--	if closestItem then
		--		targetUnit:getBrain():spawnInterest(itemLoc.x,itemLoc.y, simdefs.SENSE_SIGHT, simdefs.REASON_PATROLCHANGED)
			local newFacing = simquery.getDirectionFromDelta(x9-x8,y9-y8)
			targetUnit:getBrain():reset()
			targetUnit:getTraits().patrolPath = { { x = itemLoc.x, y = itemLoc.y, facing = newFacing } }
			sim:getNPC():getIdleSituation():generatePatrolPath( targetUnit, x8, y8 )
			closestItem:getTraits().hasBeenPatrolChecked = true
		--		targetUnit:getTraits().patrolObserved = true
		--		sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
		--	end
		end,

		}
return decker_followGuard