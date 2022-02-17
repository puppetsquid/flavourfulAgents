local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )
local mathutil = include( "modules/mathutil" )


function getRoomMoveCost( cell1, cell2)
	-- if there is a closed door, this increases the cost.
	-- NOTE: since cell1 or cell2 may be ghosted cells, do NOT use a table compare to see if exit.cell == cell2!
	for k,exit in pairs(cell1.exits) do
		if exit.cell.x == cell2.x and exit.cell.y == cell2.y and not simquery.isDoorExit( exit ) then
			return 1
		end
	end

	return 9
end


local consoles_emp =
{
	name = "DISABLE", --STRINGS.ABILITIES.SCAN_DEVICE,
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
   -- proxy = true,
   usesMP = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		local EMP_NAME = "DISABLE"
		local EMP_TOOLTIP = "Disable %s for 2 turns"
		return abilityutil.formatToolTip(EMP_NAME, string.format( EMP_TOOLTIP, targetUnit:getName() ))
	end,
		
	getName = function( self, sim, unit )
		return "DISABLE"
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return abilityOwner:getUnitData().profile_icon or self.profile_icon
    end,
	
	findConsoles = function( self, sim, abilityOwner, unit, targetUnitID )
		local targetUnit = targetUnitID --sim:getUnit( targetUnitID )
		local network = {}
		local closestConsole, closestDist
		local catchRange = 4
	--	local floodRange = 10
		
		if targetUnit then
			local targetCell = sim:getCell( targetUnit:getLocation() )
			local cells = simquery.floodFill( sim, nil, targetCell, 20, getRoomMoveCost, simquery.canPathBetween )  --- will find everything in same room
			-------- floodFill( unit, start_cell, range, costFn, pathFn , maxRangeOnly, cellquery )
			for _, cell in ipairs(cells) do
				for i, xc, yc in util.xypairs( cells ) do
					local cell = sim:getCell( xc, yc )
					if cell then
						for _, cellUnit in ipairs(cell.units) do
							if cellUnit and cellUnit:getTraits().mainframe_console then
								table.insert( network, cellUnit )
							end
						end
					end
				end
			end
			
			
			for i,console in pairs(sim:getAllUnits()) do  --- will find closest console
				if console:getTraits().mainframe_console
				 and console:getLocation()
				 and targetUnit and targetUnit:getLocation()
									then
					local x0,y0 = console:getLocation()
					local x1,y1 = targetUnit:getLocation()
					local dist = mathutil.dist2d( x0, y0, x1, y1 )
					if not closestDist or dist < closestDist then
						closestDist = dist
						closestConsole = console
					end
				end
			end
				
			table.insert( network, closestConsole )
			
				
			sim:forEachUnit(    ----- will find any within radius
			function( mainframeUnit )
				local cell = sim:getCell( targetUnit:getLocation() )
				local x1, y1 = mainframeUnit:getLocation()
				if x1 and y1 and (mainframeUnit:getTraits().mainframe_console) then
					local distance = mathutil.dist2d( cell.x, cell.y, x1, y1 )
					local raycastX, raycastY = sim:getLOS():raycast(cell.x, cell.y, x1, y1)
					if distance < catchRange then --- or not (raycastX ~= cell.x or raycastY ~= cell.y) 
						table.insert( network, mainframeUnit )
					end
				end
			end )	
		end
		
		---- remove duplicates ----
		
		local hash = {}
		local finalNetwork = {}

		for _,v in ipairs(network) do
		   if (not hash[v]) then
			   finalNetwork[#finalNetwork+1] = v 
			   hash[v] = v --true
		   end
		end
		
		---
		
		return closestConsole, finalNetwork
	end,

	acquireTargets = function( self, targets, game, sim, unit )
		local userUnit = unit:getUnitOwner()
		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 
        assert( userUnit, tostring(unit and unit:getName())..", "..tostring(unit:getLocation()) )
		local cell = sim:getCell( userUnit:getLocation() )
		local userloc = sim:getCell(userUnit:getLocation())
		local units = {}
		local oneConsole = nil
		local player = sim:getPC()
		
		local nearbyConsoles = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
                if cellUnit:getTraits().mainframe_console then
                    if simquery.canUnitReach( sim, userUnit, exit.cell.x, exit.cell.y ) then
    					table.insert( nearbyConsoles, cellUnit )
						oneConsole = true
                    end
				end
			end
		end

		----- find relevent devices, check if we're near their console -- should only do this if next to console
		if oneConsole then
			for i,mainframeitem in pairs(player:getSeenUnits()) do
				if mainframeitem:getTraits().mainframe_item then
					if (mainframeitem:getTraits().mainframe_ice or 0) > 0 and (mainframeitem:getTraits().mainframe_camera or mainframeitem:getTraits().toolTipNote == STRINGS.PROPS.SOUND_BUG_TOOLTIP) and mainframeitem:getTraits().mainframe_status ~= "off" then
						local closestConsole, network = self:findConsoles(sim, userUnit, unit, mainframeitem)
						
						for p,networkConsole in pairs(network) do
							local consoleCell = sim:getCell( networkConsole:getLocation() )
							for dir, exit in pairs(consoleCell.exits) do
								local agent = array.findIf( exit.cell.units, function( u ) return u == userUnit end )
								if agent  then
									table.insert( units, mainframeitem )
								end					
							end
						end
					end
				end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,

	
	canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )

		-- Must have a user owner and target.
		local userUnit = abilityOwner:getUnitOwner()
		local targetUnit = sim:getUnit( targetUnitID )

		if simquery.isAgent( abilityOwner ) then 
			userUnit = abilityOwner
		end 

		if not userUnit then
			return false
		end
		
		if userUnit:getMP() < 1 then
			return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
		end
				
		local closestConsole, network = self:findConsoles(sim, userUnit, unit, targetUnit)
			for p,networkConsole in pairs(network) do
				local consoleCell = sim:getCell( networkConsole:getLocation() )
				for dir, exit in pairs(consoleCell.exits) do
					local agent = array.findIf( exit.cell.units, function( u ) return u == userUnit end )
					if agent then
						
						local dir = networkConsole:getFacing()
						local x0, y0 = networkConsole:getLocation()
						local x1, y1 = simquery.getDeltaFromDirection(dir)
						local consoleFront = sim:getCell( x0 + x1, y0 + y1 )
											
						if sim:getCell(userUnit:getLocation()) ~= consoleFront then
							return false, "must be at front of console"
						end
						
						if networkConsole:getPlayerOwner() ~= userUnit:getPlayerOwner() then
								return false, "Must own console to use this ability."
						end
						
						if networkConsole:getTraits().mainframe_status == "off" then
								return false, "Console must be powered to use"
						end
						
					end					
				end
			end
		
		
		if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
		end

		return abilityutil.checkRequirements( abilityOwner, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local userUnit = unit:getUnitOwner()
		local target = sim:getUnit(target)	

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 		
		
		local myConsoleDir = userUnit:getFacing()
		local cell = sim:getCell( unit:getLocation() )
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						if simquery.canUnitReach( sim, unit, exit.cell.x, exit.cell.y ) then
							myConsoleDir = cellUnit:getFacing()
						end
					end
				end
			end
		local newFacing = simquery.getReverseDirection(myConsoleDir)

	--	sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = newFacing } )		
		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), useTinker=true, facing = newFacing, sound = "SpySociety/Actions/hostage/free_hostage" , soundFrame = 16 } )	
	--	sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), facing = newFacing, sound = "SpySociety/Actions/monst3r_jackin" , soundFrame = 16, useTinkerMonst3r=true } )
		
		local delay = 0.5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)			
		
		target:processEMP( 2 )
		unit:useMP(1, sim)
		
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = newFacing } )	
		inventory.useItem( sim, userUnit, unit )

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
}

return consoles_emp