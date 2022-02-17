local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )
local inventory = include("sim/inventory")


local SPRINT_BONUS = 3

local dashMode = 
	{
		name = STRINGS.ABILITIES.WIRELESS_SCAN,
	getName = function( self, sim, unit )
		return self.name
	end,
		
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
		sim:addTrigger( simdefs.TRG_START_TURN, self )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        self.abilityOwner = nil
	end,

    canUseAbility = function( self, sim, abilityOwner, abilityUser )
        return abilityutil.checkRequirements( abilityOwner, abilityUser )
    end,

    onTrigger = function( self, sim, evType, evData )
        if self.abilityOwner and evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
            
			local num_turns = math.floor( sim:getTurnCount() / 2 )
			
			abilityOwner:getTraits().mp = abilityOwner:getTraits().mp - SPRINT_BONUS
			local sprintTotal = SPRINT_BONUS
			
			if abilityOwner:hasTrait("sprintBonus") and not abilityOwner:hasTrait("dashDone") then
				sprintTotal = sprintTotal + abilityOwner:getTraits().sprintBonus
				abilityOwner:getTraits().dashDone = true
			end
			
			local turnMod = 0
			for int = 0,10 do
				if num_turns / 4 <= int then
					turnMod = int
				end
			end
			
			sprintTotal = sprintTotal - turnMod
			
			if unit:getTraits().mpMax - sprintTotal < 0 then
				sprintTotal = sprintTotal - (unit:getTraits().mpMax - sprintTotal)
			end
			
			abilityOwner:getTraits().mp = abilityOwner:getTraits().mp + sprintTotal
			abilityOwner:getTraits().sprintBonus = 0 - sprintTotal
			
        end
		
				
    end,
	
    performScan = function( self, sim, abilityOwner, cell )
        local player = abilityOwner:getPlayerOwner()
		sim:forEachUnit(
		    function( mainframeUnit )
			    local x1, y1 = mainframeUnit:getLocation()
			    if x1 and y1 and (mainframeUnit:getTraits().mainframe_item or mainframeUnit:getTraits().mainframe_console) and not mainframeUnit:getTraits().scanned then
				    local distance = mathutil.dist2d( cell.x, cell.y, x1, y1 )
				    if distance < abilityOwner:getTraits().wireless_range then
					    player:glimpseUnit( sim, mainframeUnit:getID() )
					    mainframeUnit:getTraits().scanned = true
					    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = mainframeUnit, reveal = true } )      
                        
                        if mainframeUnit:getTraits().mainframe_program then
                            sim:dispatchEvent( simdefs.EV_DAEMON_TUTORIAL )       
                        end
				    end
			    end
		    end )
	end,
		
	--	findNearestEmptyBackcell = function( self, sim, x, y, targetUnit, userUnit )
		generatePath = function( self, sim, targetUnit, userUnit )

			local startcell =  sim:getCell( userUnit:getLocation() )
			local targetCell = sim:getCell( targetUnit:getLocation() ) 
			local targetFacing = targetUnit:getFacing()
			local targetBack = simquery.getReverseDirection(targetFacing)
			local backFaceX, backFaceY = simquery.getDeltaFromDirection(targetBack)
			local scanMidLocX = (targetCell.x + backFaceX)
			local scanMidLocY = (targetCell.y + backFaceY)
			local ptntlCells = {}
			local maxMP = userUnit:getMP()
			
			log:write("cntrecell = " .. scanMidLocX .. "," .. scanMidLocY )
			
			local pathEndCell = nil
	--		local path = {}
			
	--		local brBonus = 0
			
			-- we're gonna scan all squares around the one behind the target to find valid attack squares
			
			for dx = -1,1 do
			for dy = -1,1 do
			local testCell = sim:getCell( scanMidLocX + dx, scanMidLocY + dy )
				log:write("testing location = " .. scanMidLocX + dx .. "," .. scanMidLocY + dy )
				if testCell then -- and not testCell == targetCell then
				log:write("testing cell = " .. testCell.x .. "," .. testCell.y )
					if simquery.isConnected( sim, targetCell, testCell ) then
					log:write("is Connected")
						local cellValid = true
						for i,cellUnit in ipairs(testCell.units) do
							if cellUnit:getTraits().dynamicImpass then
								cellValid = false
								log:write("impass fail by " .. cellUnit:getName())
							end
						end
						local range = mathutil.dist2d( targetCell.x, targetCell.y, testCell.x, testCell.y )
						if range > 1 then 
							cellValid = false   -- no diagonals!
						end
						if cellValid then
							table.insert( ptntlCells, testCell )
							log:write("valid cell = " .. testCell.x .. "," .. testCell.y )
						end
					end
				end
			end
			end
			
			-- of those cells we find the shortest path
			local bestPathCost = 9001
			for i, testEndcell in ipairs(ptntlCells) do
				local goalFn = simquery.canPath
				local testPath, testPathCost = simquery.findPath( sim, userUnit, startcell, testEndcell, maxMP )
				
				if testPath and testPathCost < bestPathCost then
					pathEndCell = testEndcell
				--	path = testpath
					bestPathCost = testPathCost
				--	brBonus = math.floor((pathCost - 2) * 0.5)
				end
				
			end
			
			
			
			if pathEndCell then
			
				local path, pathCost = simquery.findPath( sim, userUnit, startcell, pathEndCell, maxMP )
				local brBonus = math.floor((pathCost) * 0.5)
				return path, pathCost, pathEndCell, brBonus
				
			else
			
				return nil, nil, nil, nil
			
			end
			
			--return path, pathCost, pathEndCell, brBonus
			
		end,
	}
return dashMode
