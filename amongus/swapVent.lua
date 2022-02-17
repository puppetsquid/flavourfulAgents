
local function isValidExit(cell, dir)
	return cell.exits[dir] and true --not cell.exits[dir].closed and not cell.exits[dir].door
end

local function isIsolatedCell (cell)

	local area = {}
	area = simquery.floodFill(sim, nil, cell, 1.5, nil)
	local space = {}
	for i, cell in ipairs( area ) do
		if simquery.canPath( sim, userUnit, nil, cell ) then
			table.insert( space, cell )
		end
	end
	if #space > 2 then
		return false
	end
			
end

		


local swapVent = 
	{
		name = "Swap Vent",
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
		
			-- get the linked vent list of units and add each to the table
				
			for i,cellUnit in ipairs(cell.units) do
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
			
			-- check to see if currently in a vent (enter/exit vent ability trait)


			return true
		end,
		
		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_START_TURN, self )
			self.abilityOwner = unit
			
			-- get any cells that could hold a vent
			
			local potentialCells = {}
			sim:forEachCell(
				function( c )
					if not c.exitID and not c.isSolid and isIsolatedCell(c) and not simquery.cellHasTag( sim, c, "interruptNonCentral" ) and not simquery.cellHasTag( sim, c, "guard_spawn" ) then
						if isIsolatedCell(c) then
						table.insert(potentialCells, c)
						end
					end
				end )
			
			-- 	filter this list to be one vent per room
			
			-- spawn a unit for every vent
			
			-- for each vent, add the nearest vent to your 'linked' list, and vice versa
			
			--profit
			
		end,

		executeAbility = function( self, sim, unit, userUnit, target )
		
			local userUnit = unit:getUnitOwner()
			local targetUnit = sim:getUnit(target)	
			local targID = targetUnit:getID()
			
			-- move to the target's cell
			
			-- pan the camera to the target cell

		end,

	}
return swapVent
