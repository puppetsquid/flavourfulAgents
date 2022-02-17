local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local use_injection = include( "sim/abilities/use_injection" )
local inventory = include("sim/inventory")
local animmgr = include( "anim-manager" )
local simfactory = include( "sim/simfactory" )


local function isValidExit(cell, dir)
	return cell.exits[dir] and not cell.exits[dir].closed and not cell.exits[dir].door
end

local function inSameRoom(sim, player, prevCell, testCell)
	local simquery = sim:getQuery()
	local dx, dy = testCell.x - prevCell.x, testCell.y - prevCell.y
	if dx~=0 and dy~=0 then --diagonal, check two directions
		local cell3 = sim:getCell(prevCell.x, testCell.y)
		local cell4 = sim:getCell(testCell.x, prevCell.y)
		if not cell3 or not cell4 then
			return false
		end

		local dir1, dir2 = simquery.getDirectionFromDelta(0, dy), simquery.getDirectionFromDelta(dx, 0)
		local dir3, dir4 = simquery.getDirectionFromDelta(dx, 0), simquery.getDirectionFromDelta(0, dy)

		if isValidExit(prevCell, dir1) and isValidExit(cell3, dir2)
		 and isValidExit(prevCell, dir3) and isValidExit(cell4, dir4) then
			return true
	 	end
	else
		local dir = simquery.getDirectionFromDelta(dx, dy)
		if isValidExit(prevCell, dir) then
			return true
		end
	end
	return false
end


local sharp_ferry = 
	{
		name = "CLEANUP",
		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.PARALYZE
		end,
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_augment.png",
		usesAction = true,
		alwaysShow = true,
        proxy = true,
		createToolTip = function(  self,sim, abilityOwner, abilityUser, targetID )

			local targetUnit = sim:getUnit(targetID)
			return abilityutil.formatToolTip(string.format("CLEANUP",targetUnit:getName()), "Removes this corpse.\n\nSharp is incredibly secretive about both his 'ferryport' augment and its uses.\n\n10 turn cooldown\nUses Attack and ALL AP")
		end,
		
		usesMP = true,

		acquireTargets = function( self, targets, game, sim, unit )
			local userUnit = unit:getUnitOwner()
			local cell = sim:getCell( userUnit:getLocation() )

			local units = {}
		
				
			for i,cellUnit in ipairs(cell.units) do
		--		if (cellUnit:isKO() or cellUnit:getTraits().iscorpse) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then
				if (cellUnit:getTraits().iscorpse) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then
					table.insert( units, cellUnit )
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,
		
		canUseAbility = function( self, sim, unit )
			
			-- Must have a user owner.
			local userUnit = unit:getUnitOwner()
			if not userUnit then
				return false
			end
			-- Must have a KO target in range
			local cell = sim:getCell( userUnit:getLocation() )
			local units = {}
			
			--canUseWhileDragging = true,
			
			if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
				return false
			end
			
			if userUnit:getAP() < 1 then 
				return false
			end 
			
			if userUnit:getTraits().mp < userUnit:getTraits().mpMax then
				return false
			end


			if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
				return false
			end	
		
            local ok, reason = abilityutil.checkRequirements( unit, userUnit )
            if not ok then
                return false
            end

			for i,cellUnit in ipairs(cell.units) do
				if (cellUnit:isKO() or cellUnit:getTraits().iscorpse) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().notDraggable  then
					table.insert( units, cellUnit )
				end
			end	
			if #units < 1 then
				return false
			end			
			
			local area = {}
			area = simquery.floodFill(sim, nil, cell, 1.5, nil, inSameRoom)
			local space = {}
			for i, cell in ipairs( area ) do
				if simquery.canPath( sim, userUnit, nil, cell ) then
					table.insert( space, cell )
				end
			end
			if #space > 2 then
				return false
			end

			

			return true
		end,

		executeAbility = function( self, sim, unit, userUnit, target )
		
				local userUnit = unit:getUnitOwner()
				local targetUnit = sim:getUnit(target)	
				local targID = targetUnit:getID()
				inventory.useItem( sim, userUnit, unit )
	--[==[			local targCell = sim:getCell(targetUnit:getLocation())
				
				if not targetUnit:getTraits().iscorpse then
					targetUnit:killUnit(sim)
					for i,cellUnit in ipairs(targCell.units) do
						if cellUnit:getID() == targID then
							targetUnit = cellUnit
							log:write( "MMMMMM CORPSY" )
						end
					end
				end
				]==]
				
				
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )
				
				--local targetUnit = sim:getUnit(targetUnit)
				local x0,y0 = userUnit:getLocation()
				local x1,y1 = targetUnit:getLocation()
				local distance = mathutil.dist2d( x0, y0, x1, y1 )
				local oldcell = sim:getCell( userUnit:getLocation() )

				userUnit:setFacing(targetUnit:getFacing() )
				if not userUnit:isValid() then
					return
				end
				
		--		userUnit:getTraits().movingBody = targetUnit
				userUnit:getTraits().pinningOverride = true
				
		--		sim:dispatchEvent( simdefs.EV_UNIT_DRAG_BODY, { unit = userUnit, targetUnit = targetUnit} )
			
				
				sim:dispatchEvent( simdefs.EV_TELEPORT, { units={userUnit}, warpOut =true } )
				
	--			userUnit:getTraits().sneaking = false
	--			userUnit:getTraits().pinning = targetUnit
	--			targetUnit:setInvisible(true)
				
		--		sim:warpUnit( userUnit, nil )

				if not targetUnit:getTraits().iscorpse then
					userUnit:getTraits().movingBody = nil
					targetUnit:getTraits().corpseTemplate = nil
					targetUnit:killUnit(sim)
					--sim:despawnUnit( targetUnit )
					
				else
					sim:warpUnit( targetUnit, nil )
					sim:despawnUnit( targetUnit )
				end
				if sim:getCleaningKills() >= 1 then -- and livingUnit:getTraits().cleanup then
					sim:addCleaningKills( -1 )
				end
				userUnit:getTraits().hasSight = false
				sim:refreshUnitLOS( userUnit )
				--sim:despawnUnit( targetUnit )
			--	sim:warpUnit( userUnit, x0,y0 )
			--	sim:dispatchEvent( simdefs.EV_TELEPORT, { units={userUnit}, warpOut = false } )
				userUnit:setFacing(simquery.getReverseDirection(userUnit:getFacing() ) )
			--		
			--	sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )	
				sim:dispatchEvent( simdefs.EV_TELEPORT, { units={userUnit}, warpOut =false } )
				userUnit:getTraits().hasSight = true
				sim:refreshUnitLOS( userUnit )
		--		sim:dispatchEvent( simdefs.EV_UNIT_WARPED, { unit = userUnit, from_cell = oldcell, to_cell = oldcell, facing = unit:getFacing(), reverse=true } )
		--		sim:dispatchEvent( simdefs.EV_UNIT_DROP_BODY, { unit = userUnit, targetUnit = userUnit} )
		--		userUnit:setInvisible(false)
				userUnit:getTraits().pinningOverride = nil
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )	
				
				userUnit:getTraits().mp = 0
				userUnit:useAP( sim )
				unit:getTraits().cooldownMax = 10
				unit:getTraits().cooldown = 10
				
		
				
			
		end,

	}
return sharp_ferry
