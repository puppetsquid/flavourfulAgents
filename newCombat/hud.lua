local hud = include( "hud/hud" )


local cdefs = include( "client_defs" )
local simquery = include( "sim/simquery" )
local oldCreateHud = hud.createHud
local hud = include( "hud/hud" )
local oldCreateHud = hud.createHud
local simdefs = include( "sim/simdefs" )

local function clearMovementRange( self )
		-- Hide movement range hilites.
		self._game.boardRig:clearMovementTiles()
		self._game.boardRig:clearCloakTiles()

		-- Clear movement cells
		self._revealCells = nil
		self._cloakCells = nil
	end

hud.createHud = function( ... )
    local hudObject = oldCreateHud( ... )
	
	

    function hudObject:showMovementRange( unit )

		clearMovementRange( self )

		-- Show movement range.
		if unit and not unit._isPlayer and unit:hasTrait("mp") and unit:canAct() and unit:getPlayerOwner() == self._game:getLocalPlayer() then
			local sim = self._game.simCore
			local simquery = sim:getQuery()
			local cell = sim:getCell( unit:getLocation() )

			--self._revealCells = simquery.floodFill( sim, unit, cell,unit:getMP() )
			
			--self._revealCells = simquery.floodFill( sim, unit, cell, unit:getMP(), simquery.getMoveCost, simquery.canPath, true )
			
			
			log:write( "STAGGERD" )
			self._revealCells = {}
			local cells = simquery.floodFill( sim, unit, cell,unit:getMP() )
				for testcell in ipairs(cells) do
				local testcellExists = sim:getCellByID(testcell)
					if testcellExists then
						local isCover = false
						
						log:write ("CELL: " .. testcell)
					--	
						for _, dir in ipairs(simdefs.DIR_SIDES) do
							if simquery.checkIsHalfWall(sim, testcellExists, dir ) then
								isCover = true
							end
						end
						if isCover == true then
							table.insert( self._revealCells, testcell )
						end
					end
				end

			if unit:getTraits().sneaking then  
				self._game.boardRig:setMovementTiles( self._revealCells, 0.8 * cdefs.MOVECLR_SNEAK, cdefs.MOVECLR_SNEAK )
			else
				self._game.boardRig:setMovementTiles( self._revealCells, 0.8 * cdefs.MOVECLR_DEFAULT, cdefs.MOVECLR_DEFAULT )
			end

			if unit:getTraits().cloakDistance and unit:getTraits().cloakDistance > 0 then
				local distance = math.min(unit:getTraits().cloakDistance-1,unit:getMP())
				self._cloakCells = nil
				self._cloakCells = simquery.floodFill( sim, unit, cell, distance )
			end

			if self._cloakCells then
				self._game.boardRig:setCloakTiles( self._cloakCells, 0.8 * cdefs.MOVECLR_INVIS, cdefs.MOVECLR_INVIS )
			else 
				self._game.boardRig:clearCloakTiles()
			end
		end
	end

    return hudObject
end
