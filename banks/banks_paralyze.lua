local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )



local function isShootTarget( self, sim, abilityOwner, abilityUser, targetUnit )
	if not simquery.isShootable( abilityUser, targetUnit ) then
        return false
    end
    if not sim:canPlayerSeeUnit( abilityUser:getPlayerOwner(), targetUnit ) then
        return false
    end
	if not targetUnit:getTraits().canKO then
		return false
	end
	
    return true
end


local banks_paralyze =
	{
		name = STRINGS.ABILITIES.PARALYZE,
		createToolTip = function( self, sim, abilityOwner )
				return abilityutil.formatToolTip(STRINGS.ABILITIES.PARALYZE, util.sformat(STRINGS.ABILITIES.PARALYZE_DESC,abilityOwner:getTraits().koTime), simdefs.DEFAULT_COST)
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_paralyzerdose_small.png",

		alwaysShow = true,
        proxy = true,
		usesAction = true,

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.PARALYZE
		end,
--[==[
		acquireTargets = function( self, targets, game, sim, unit )
			local userUnit = unit:getUnitOwner()
			local userCell = sim:getCell( userUnit:getLocation() )
			local x0, y0 = userUnit:getLocation()
			local player = sim:getPC()
			local units = {}
			local maxRange = 3 + (((userUnit:getSkillLevel("inventory"))-1) * 1.5)
			
			local cells = {userCell}
			if maxRange then
				local coords = simquery.rasterCircle( self._sim, x0, y0, maxRange )

				for i=1,#coords-1,2 do
					local cell = self._sim:getCell(coords[i],coords[i+1])
					if cell then
					local raycastX, raycastY = self._sim:getLOS():raycast(x0, y0, cell.x, cell.y)			
						if raycastX == cell.x and raycastY == cell.y then
							table.insert(cells, cell)
							for i,cellUnit in ipairs(cell.units) do
								if (simquery.isAgent(cellUnit) and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone
								and sim:canPlayerSeeUnit(userUnit:getPlayerOwner(), cellUnit) then
									table.insert( units, cellUnit )
								end
							end
						end			
					end
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,
]==]		
		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
                if isShootTarget( self, sim, unit, userUnit, targetUnit) then 

					local x1,y1 = targetUnit:getLocation()
					local distance =  mathutil.dist2d( x0, y0, x1, y1 )
					local maxRange = 1 -- 3 + (((userUnit:getSkillLevel("inventory"))-1) * 1.5)

    				if sim:canPlayerSeeUnit( userUnit, targetUnit ) and distance <= maxRange then
						table.insert( units, targetUnit )
					else 
						for _, cameraUnit in pairs(sim:getAllUnits()) do 
							if cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) and distance <= maxRange then -- peek thru doors
								table.insert( units, targetUnit )
                               break
							end
						end
					end
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		canUseAbility = function( self, sim, unit, userUnit, targetUnitID )

			-- Must have a user owner.
			local userUnit = unit:getUnitOwner()
			if not userUnit or not unit:getTraits().equipped then
				return false
			end
			-- Must have a KO target in range
			local cell = sim:getCell( userUnit:getLocation() )
			local units = {}

			if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
			end
			
			local targetUnit = nil
			if targetUnitID then
				targetUnit = sim:getUnit( targetUnitID )
			end
			
			if targetUnit and targetUnit:getTraits().armor then
				return false, "Armor too thick"
			end
			
			
			
			if targetUnit then
				local x0, y0 = userUnit:getLocation()
				local x1, y1 = targetUnit:getLocation()
				local raycastX, raycastY = self._sim:getLOS():raycast(x0, y0, x1, y1)			
				if not (raycastX == x1 and raycastY == y1) then
					return false, "Blocked"
				end
			end

			if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
		
            local ok, reason = abilityutil.checkRequirements( unit, userUnit )
            if not ok then
                return false, reason
            end
			
			if userUnit:getAP() < 1 then 
				return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_ATTACK
			end 

	--[==[	for i,cellUnit in ipairs(cell.units) do
			--	if (cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and cellUnit:getTraits().canKO then
				if (not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and cellUnit:getTraits().canKO then
					table.insert( units, cellUnit )
				end
			end					

			if #units < 1 then
				return false, STRINGS.UI.REASON.NO_VIABLE_TARGET
			end]==]	

			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )

			local userUnit = unit:getUnitOwner()
			local target = sim:getUnit(target)	

			local x0,y0 = userUnit:getLocation()
			local x1, y1 = target:getLocation()
			local distance = mathutil.dist2d( x0, y0, x1, y1 )
			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )	
			
			if distance > 1 then
				sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
			--	inventory.giveItem( userUnit, target, unit )  -- ( unit, targetUnit, item )
			elseif distance > 0 then
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = facing } )	
			else
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = userUnit:getFacing() } )	
			end
			
			if target:getTraits().koTimer then
				target:getTraits().koTimer = target:getTraits().koTimer + unit:getTraits().koTime
			else
				target:setKO(sim, unit:getTraits().koTime)
			end
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.PARALYZED,x=x0,y=y0,color={r=1,g=1,b=0,a=1}} )
			
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )

			if unit:getTraits().disposable then 
				inventory.trashItem( sim, userUnit, unit )
			else
				inventory.useItem( sim, userUnit, unit )
			end
			
			if distance > 1 then
				inventory.giveItem( userUnit, target, unit )  -- ( unit, targetUnit, item )
			end

			if userUnit:isValid() then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
			end
			
			userUnit:useAP( sim )

			sim:triggerEvent( simdefs.TRG_UNIT_PARALYZED )
		end,
	}
return banks_paralyze