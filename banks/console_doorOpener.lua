local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

function getRoomMoveCost( cell1, cell2)
	-- if there is a door, this increases the cost.
	-- NOTE: since cell1 or cell2 may be ghosted cells, do NOT use a table compare to see if exit.cell == cell2!
	for k,exit in pairs(cell1.exits) do
		if exit.cell.x == cell2.x and exit.cell.y == cell2.y then
			return 1
		end
	end

	return 9 -- this effectively caps dist at 20 while still scanning door cells
end

function closeAllLockedDoors()
	self:forEachCell(
		function( c )
			for i,exit in pairs(c.exits) do
				if exit.locked and exit.keybits == simdefs.DOOR_KEYS.SECURITY then
					self:modifyExit( c, i, simdefs.EXITOP_UNLOCK)
                    self:getPC():glimpseExit( c.x, c.y, i )
				end
			end
		end )
end



local console_doorOpener = 
	{
		createToolTip = function( self,sim,unit,targetCell,dir)
		
	--[==[		local fromCell = targetCell
            assert( fromCell and dir )
			local exit = fromCell.exits[dir]
			assert( exit )
			
			if not exit.locked then
				return abilityutil.formatToolTip("DOOR", "TOGGLE/nCosts MP and locks terminal for 2 rounds", simdefs.DEFAULT_COST )
			elseif exit.keybits == simdefs.DOOR_KEYS.SECURITY then			
				return abilityutil.formatToolTip("SECURITY DOOR", "TOGGLE/nCosts MP and locks terminal for 2 rounds/nDoor will close at end of turn", simdefs.DEFAULT_COST )
			elseif exit.keybits == simdefs.DOOR_KEYS.VAULT then		
				return abilityutil.formatToolTip("VAULT DOOR", "TOGGLE/nUses remaining AP and locks console for 2 turns/nDoor will close at end of turn", simdefs.DEFAULT_COST )
			end
		]==]---
			return abilityutil.formatToolTip("DOOR", "TOGGLE/nCosts MP and locks terminal for 2 rounds", simdefs.DEFAULT_COST )
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_door_open_small.png",
		
		eyeballs = {},
		
	    getProfileIcon = function( self, sim, abilityOwner )
	        return abilityOwner:getUnitData().profile_icon or self.profile_icon
	    end,

        proxy = true,
		usesMP = true,

		getName = function( self, sim, unit )
			return string.format(STRINGS.ABILITIES.SET_NAME,unit:getName())
		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			
			local abilityOwner = self.abilityOwner
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( "usedStim", self )
			 sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
			sim:removeTrigger( "usedStim", self )
			sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
		end,
        
		acquireTargets = function( self, targets, game, sim, abilityOwner, abilityUser )
			local exits = {}
			local fromCell = sim:getCell( abilityUser:getLocation() )
			local cellsWithDoors = {}
			local player = abilityOwner:getPlayerOwner()
			local oneConsole = nil
			local cell = sim:getCell( abilityOwner:getLocation() )
			
			local nearbyConsoles = {}
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						if simquery.canUnitReach( sim, abilityUser, exit.cell.x, exit.cell.y ) and cellUnit:getTraits().mainframe_status ~= "off" then
							table.insert( nearbyConsoles, cellUnit )
							oneConsole = true
							self.myConsoleDir = cellUnit:getFacing()
							self.myConsole = cellUnit
						end
					end
				end
			end

			

			------todo- if abilityOwner next to gettraits mainframe_console or open_secure_boxes or generateAugment then
			if oneConsole then
				local cells = simquery.floodFill( sim, nil, fromCell, 20, getRoomMoveCost, simquery.canPathBetween )  --- will find everything in same room
				-------- floodFill( unit, start_cell, range, costFn, pathFn , maxRangeOnly, cellquery )
					for i, xc, yc in util.xypairs( cells ) do
						local cell = sim:getCell( xc, yc )
						if cell then
							for dir, exit in pairs( cell.exits ) do
								local rdir = simquery.getReverseDirection( dir )
								local reverseExit = exit.cell.exits[ rdir ]
								local x1, y1 = simquery.getDeltaFromDirection(dir)
								local toCell = sim:getCell( cell.x + x1, cell.y + y1 )
								if sim:canPlayerSee( player, cell.x, cell.y ) or sim:canPlayerSee( player, toCell.x, toCell.y ) then
							
									if simquery.isDoorExit( exit ) and not exit.consoleScanned and (not exit.locked or exit.keybits == simdefs.DOOR_KEYS.SECURITY or exit.keybits == simdefs.DOOR_KEYS.VAULT) 
										and not (exit.keybits == simdefs.DOOR_KEYS.ELEVATOR or exit.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE or exit.keybits == simdefs.DOOR_KEYS.GUARD) then
										table.insert( exits, { x = cell.x, y = cell.y, dir = dir } )
										exit.consoleScanned = true
										reverseExit.consoleScanned = true
									end
								end
							end
						end
					end
				
				sim:forEachCell(
					function( c )
						for i,exit in pairs(c.exits) do
								exit.consoleScanned = nil
						end
					end )
			end
			return targets.exitTarget( game, exits, self, abilityOwner, abilityUser )
		end,

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
            -- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
            if abilityOwner ~= unit and abilityOwner:getUnitOwner() ~= unit then
                return false
            end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	
			
			if unit:getMP() < 1 then
				return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
			end

			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
			
			local cell = sim:getCell( abilityOwner:getLocation() )
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						local dir = cellUnit:getFacing()
						local x0, y0 = cellUnit:getLocation()
						local x1, y1 = simquery.getDeltaFromDirection(dir)
						local consoleFront = sim:getCell( x0 + x1, y0 + y1 )
											
						if sim:getCell(abilityOwner:getLocation()) ~= consoleFront then
							return false, "must be at front of console"
						end
						
						if cellUnit:getPlayerOwner() ~= abilityOwner:getPlayerOwner() then
								return false, "Must own console to use this ability."
						end
						
					end
				end
			end
			

			return abilityutil.checkRequirements( abilityOwner, unit )
		end,
		
		executeAbility = function( self, sim, unit, userUnit, x0, y0, dir )
			local fromCell = sim:getCell( x0, y0 )
            assert( fromCell and dir )
			local exit = fromCell.exits[dir]
			assert( exit )
			
			local myConsoleDir = userUnit:getFacing()
			
			local cell = sim:getCell( unit:getLocation() )
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						if simquery.canUnitReach( sim, unit, exit.cell.x, exit.cell.y ) then
						--	self.myConsole = cellUnit
							cellUnit:getTraits().shutDownPlz = true
							myConsoleDir = cellUnit:getFacing()
						end
					end
				end
			end
			
		--	self.myConsole:getTraits().shutDownPlz = true
			
			local newFacing = simquery.getReverseDirection(myConsoleDir)
	
			userUnit:resetAllAiming()
			--sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = newFacing } )		
		--	sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), facing = newFacing, sound = "SpySociety/Actions/monst3r_jackin" , soundFrame = 16, useTinkerMonst3r=true } )

			if not exit.locked then
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = newFacing } )	
				sim:modifyExit(fromCell, dir, simdefs.EXITOP_TOGGLE_DOOR, unit, false)	
				unit:useMP(1, sim)
			elseif exit.keybits == simdefs.DOOR_KEYS.SECURITY then			
				sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), useTinker=true, facing = newFacing, sound = "SpySociety/Actions/hostage/free_hostage" , soundFrame = 16 } )	
				sim:modifyExit(fromCell, dir, simdefs.EXITOP_TOGGLE_DOOR, unit, false)	
				exit.closeEndTurn = true
				unit:useMP(1, sim)
			elseif exit.keybits == simdefs.DOOR_KEYS.VAULT then		
				sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), useTinkerMonst3r=true, facing = newFacing, sound = "SpySociety/Actions/hostage/free_hostage" , soundFrame = 16 } )	
				local delay = 0.65
				sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)			
				sim:modifyExit(fromCell, dir, simdefs.EXITOP_TOGGLE_DOOR, unit, false)	
				exit.closeEndTurn = true
			--	local x1, y1 = unit:getLocation()
			--	sim:getNPC():spawnInterest(x0,y0, simdefs.SENSE_RADIO, simdefs.REASON_CAMERA )
				unit:getTraits().mp = 0
			end
			--- find nearby human guards
			--- add tolerance counter
			--- break door if too intolerant
				--- no need now due to EMP!
		
			sim:processReactions( userUnit )
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = newFacing } )	
		end,
	
		onTrigger = function ( self, sim, evType, evData )  -- need to get this working

			if evType == simdefs.TRG_END_TURN then
				local abilityOwner = self.abilityOwner
				local player = abilityOwner:getPlayerOwner()

				if player and sim:getCurrentPlayer() == player then
					if abilityOwner:getTraits().roidedUp then
						abilityOwner:getTraits().senseRange = abilityOwner:getTraits().senseRange - 8
						abilityOwner:getTraits().roidedUp = nil
						sim:refreshUnitLOS(abilityOwner)
					end
				
					sim:forEachCell(
						function( c )
							for i,exit in pairs(c.exits) do
								if exit.locked and not exit.closed then
								--	sim:modifyExit( c, i, simdefs.EXITOP_CLOSE)
									--self:getPC():glimpseExit( c.x, c.y, i )
								end
							end
						end )
					for i,console in pairs(sim:getAllUnits()) do  --- will find closest console
						if (console:getTraits().mainframe_console or console:getTraits().open_secure_boxes) and console:getTraits().shutDownPlz then
							console:processEMP( 2 )
							console:getTraits().shutDownPlz = nil
						end
					end
					
				end
			elseif self.abilityOwner and evType == "usedStim" and evData.target == self.abilityOwner then
				local abilityOwner = self.abilityOwner
				abilityOwner:getTraits().roidedUp = true
				abilityOwner:getTraits().senseRange = abilityOwner:getTraits().senseRange + 8
				sim:refreshUnitLOS(abilityOwner)
			
			end	

		end,


	}
return console_doorOpener