local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )
local inventory = include("sim/inventory")


	function generatePath( sim, targetUnit, userUnit )

		local startcell =  sim:getCell( userUnit:getLocation() )
		local targetCell = sim:getCell( targetUnit:getLocation() ) 
		local targetFacing = targetUnit:getFacing()
		local targetBack = simquery.getReverseDirection(targetFacing)
		local backFaceX, backFaceY = simquery.getDeltaFromDirection(targetBack)
		local scanMidLocX = (targetCell.x + backFaceX)
		local scanMidLocY = (targetCell.y + backFaceY)
		local ptntlCells = {}
		local maxMP = userUnit:getMP()
		
		-- log:write("cntrecell = " .. scanMidLocX .. "," .. scanMidLocY )
		
		local pathEndCell = nil
--		local path = {}
		
--		local brBonus = 0
		
		-- we're gonna scan all squares around the one behind the target to find valid attack squares
		
		for dx = -1,1 do
		for dy = -1,1 do
		local testCell = sim:getCell( scanMidLocX + dx, scanMidLocY + dy )
			-- log:write("testing location = " .. scanMidLocX + dx .. "," .. scanMidLocY + dy )
			if testCell then -- and not testCell == targetCell then
			-- log:write("testing cell = " .. testCell.x .. "," .. testCell.y )
				if simquery.isConnected( sim, targetCell, testCell ) then
				-- log:write("is Connected")
					local cellValid = true
					for i,cellUnit in ipairs(testCell.units) do
						if cellUnit:getTraits().dynamicImpass then
							cellValid = false
							-- log:write("impass fail by " .. cellUnit:getName())
						end
					end
					local range = mathutil.dist2d( targetCell.x, targetCell.y, testCell.x, testCell.y )
					if range > 1 then 
						cellValid = false   -- no diagonals!
					end
					if cellValid then
						table.insert( ptntlCells, testCell )
						-- log:write("valid cell = " .. testCell.x .. "," .. testCell.y )
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
			local brBonus = math.min(math.floor((pathCost) * 0.5), 3)
			pathCost = math.floor(pathCost*2)*0.5  -- round to nearest 0.5
			return path, pathCost, pathEndCell, brBonus
		else
			return nil, nil, nil, nil
		end
	end
	



local melee_tooltip = class()

function melee_tooltip:init( hud, abilityOwner, abilityUser, targetUnitID )
	self._hud = hud
	self._game = hud._game
	self._abilityOwner = abilityOwner
	self._abilityUser = abilityUser
	self._targetUnitID = targetUnitID
	local sim = self._hud._game.simCore
	
	local targetUnit = sim:getUnit(targetUnitID)
	local targetCell
	local path, pathcost, pathEndCell
		if targetUnit then	
			targetCell = sim:getCell( targetUnit:getLocation() ) 
			path, pathCost, pathEndCell = generatePath (sim, targetUnit, abilityUser)
			table.insert( path, targetCell )
		end
	self._pathTable = path
	
end

function melee_tooltip:setPosition( wx, wy )
	self._panel:setPosition( self._hud._screen:wndToUI( wx, wy ))
end

function melee_tooltip:getScreen()
	return self._hud._screen
end

function melee_tooltip:activate( screen )
	local combat_panel = include( "hud/combat_panel" )
	local sim = self._hud._game.simCore
	
	if self._pathTable then
		self._hiliteID = self._game.boardRig:hiliteCells( self._pathTable, cdefs.HILITE_TARGET_COLOR )
	end

	self._panel = combat_panel( self._hud, self._hud._screen )
	self._panel:refreshMelee( self._abilityOwner, self._abilityUser, sim:getUnit( self._targetUnitID ))
end

function melee_tooltip:deactivate()
	self._hud._game.boardRig:getUnitRig( self._targetUnitID )._prop:setRenderFilter( nil )
	if self._pathTable then
		self._game.boardRig:unhiliteCells( self._hiliteID )	
		self._hiliteID = nil
	end
	self._panel:setVisible( false )
end

function returnPWRcostPoints(sim, userUnit, targetUnit)
	
	local path, pathCost, pathEndCell, brBonus = generatePath (sim, targetUnit, userUnit)
	
	brBonus = (brBonus or 0)
	local weapon = simquery.getEquippedMelee( userUnit )
	local weaponDmg = (weapon:getTraits().damage or 0)
	weapon:getTraits().damage = weaponDmg + brBonus
	local weaponAP = (weapon:getTraits().armorPiercing or 0)
	weapon:getTraits().armorPiercing = weaponAP + brBonus

	local meleeDamage,  armorPierce, armor = simquery.calculateDamageAndArmorForMelee(sim, simquery.getEquippedMelee( userUnit ), targetUnit)

	local diff = armorPierce - armor

	local PWRcostPoints = math.max(simquery.getEquippedMelee( userUnit ):getTraits().armorPiercing - diff,0)
	
	weapon:getTraits().damage = weaponDmg
	weapon:getTraits().armorPiercing = weaponAP
	
	return PWRcostPoints
end



					

local bullrush = 
	{
		name = "Bullrush",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_ko.png",
		usesAction = true,
		alwaysShow = true,
		getName = function( self, sim, unit )
			return self.name
		end,

--[==[		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local targetUnit = sim:getUnit(targetUnitID)
			local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, abilityUser)
			return melee_tooltip( hud, abilityOwner, abilityUser, targetUnitID )
		end,	]==]
		
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )

	--[==[		-------------------------------------------------------------
					---- this version shows the path but not the damage... 
			
			
			local targetUnit = sim:getUnit(targetUnitID)
			local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, abilityUser)
	
			local weapon = simquery.getEquippedMelee( abilityUser )
			local weaponDmg = (weapon:getTraits().damage or 0)
			weapon:getTraits().damage = weaponDmg + brBonus
			local weaponAP = (weapon:getTraits().armorPiercing or 0)
			weapon:getTraits().armorPiercing = weaponAP + brBonus
			local startcell =  sim:getCell( abilityUser:getLocation() )

			local tooltip =  melee_tooltip( hud, abilityOwner, abilityUser, targetUnitID ) 
			
			weapon:getTraits().damage = weaponDmg
			weapon:getTraits().armorPiercing = weaponAP
			
		]==]--
			--------------------------------------------------------------
				---- this has more info but I can't find a way to show AND unload the path....
				---- on balance this feels better.
			
		local tooltip = util.tooltip( hud._screen )
			
			
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
			self._hud = hud
			
			local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, abilityUser)
			local dmg = self:calcBullrushDamage (sim, abilityUser, targetUnit, brBonus)
			
			self._hiliteID = hud._game.boardRig:hiliteCells( path, cdefs.HILITE_TARGET_COLOR )
			
			if simquery.getEquippedMelee( abilityUser ):getTraits().lethalMelee then
				dmg = STRINGS.UI.COMBAT_PANEL_KILL
			end
			
	        section:addLine( targetUnit:getName() )
			
			if brBonus then
				section:addAbility( self:getName(sim, abilityOwner),
							 STRINGS.FLAVORED.UI.BR_DESC, "gui/items/icon-action_hack-console.png" )
				section:addAbility( "Melee Bonus",
							util.sformat(STRINGS.FLAVORED.UI.BR_BONUS, pathCost, brBonus, dmg, dmg - brBonus, brBonus), "gui/items/icon-action_hack-console.png" )
			end
			if abilityUser:getTraits().sneaking then
				section:addAbility( STRINGS.FLAVORED.UI.BR_WILLSPRINT,
							STRINGS.FLAVORED.UI.BR_WILLSPRINT_DESC, "gui/items/icon-action_hack-console.png" )
			end

			if reason then
				section:addRequirement( reason )
			end
			
		--	local delay = 1
		--	sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		--	tooltip:deactivate()
				hud._game.boardRig:unhiliteCells( self._hiliteID )	
				self._hiliteID = nil
		--	end
		

			return tooltip
		end,
		
		

		acquireTargets = function( self, targets, game, sim, unit )

			local targetUnits = {}
			
			local maxRange = unit:getMP()
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isValidTarget( sim, unit, unit, targetUnit ) then
					local range = mathutil.dist2d( x0, y0, x1, y1 )
					if maxRange then
						if range <= maxRange and range > 1 then --- the way we work out a path means that a pinned target is regarded as 2 squares away so we ignore them
							targetUnit = unit:getPlayerOwner():getLastKnownUnit( sim, targetUnit:getID() )
							if sim:canPlayerSeeUnit( unit:getPlayerOwner(), targetUnit ) then
								table.insert( units, targetUnit )
							end
						end
					end
				end
			end
			
			return targets.unitTarget( game, units, self, unit, unit )

		end,

		isValidTarget = function( self, sim, unit, userUnit, targetUnit )
		
	--		local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, userUnit)
			
	--		if not path then 
	--			return false, "no valid path"
	--		end
			
			
			if targetUnit == nil or targetUnit:isGhost() then
				return false
			end

			if not simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) then
				return false
			end
			
			if not targetUnit:getTraits().canKO then
				return false
			end

			local pinned, pinner = simquery.isUnitPinned(sim, targetUnit)
			if targetUnit:isKO() and pinner ~= userUnit then
				return false
			end
			
			local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, userUnit)
			
			if not path then 
				return false, "no valid path"
			end

			return true
		end,

		canUseAbility = function( self, sim, unit, userUnit, targetID )
		
			local meleeAbility = userUnit:hasAbility("melee")
			if meleeAbility == nil then
				return false
			end
			
			
			

            local tazerUnit = simquery.getEquippedMelee( unit )
            if tazerUnit == nil then
				if sim:getTags().isTutorial then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_GEAR
				else
					return false
				end

			elseif tazerUnit:getTraits().cooldown and tazerUnit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.COMBAT_PANEL_COOLDOWN,tazerUnit:getTraits().cooldown), STRINGS.UI.COMBAT_PANEL_COOLDOWN_2			
			elseif tazerUnit:getTraits().usesCharges and tazerUnit:getTraits().charges < 1 then
				return false, STRINGS.UI.COMBAT_PANEL_NEED_CHARGES, STRINGS.UI.COMBAT_PANEL_NEED_CHARGES_2			
			end				


			if unit:getAP() < 1 then 
				return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_ATTACK
			end 

			if targetID and sim:getCell( sim:getUnit( targetID ):getLocation() ) then
				local targetUnit = sim:getUnit( targetID )
				
				
				local startcell =  sim:getCell( unit:getLocation() )
				local targetUnitCell =  sim:getCell( targetUnit:getLocation() )  
				
				if not targetUnitCell then
				
					return false, STRINGS.FLAVORED.UI.COMBAT_PANEL_NO_PATH
				
				end
				
				local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, userUnit)
				
				if not pathCost or pathCost > userUnit:getMP() then
					return false, STRINGS.FLAVORED.UI.COMBAT_PANEL_NO_PATH
				elseif pathCost < 2 then
					return false, STRINGS.FLAVORED.UI.COMBAT_PANEL_TOO_CLOSE
				end
				
				local pinning, pinnee = simquery.isUnitPinning(sim, targetUnit)
				if pinning then
					return false, STRINGS.UI.COMBAT_PANEL_PINNING
				end
				
				if not targetUnit:getTraits().modifyingExit and not targetUnit:getTraits().turning and not targetUnit:getTraits().movePath and sim:canUnitSeeUnit( targetUnit, userUnit ) then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_SEEN
				end
				
				
	--[==[		--- All of this is irrelevant but saved for legacy
				if not self:isValidTarget( sim, unit, userUnit, targetUnit ) then
					return false, STRINGS.UI.REASON.INVALID_TARGET 
				end
				
				local pinning, pinnee = simquery.isUnitPinning(sim, userUnit)
				if pinning and pinnee ~= targetUnit then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_PINNING
				end

				
              if not simquery.canUnitReach( sim, userUnit, targetUnit:getLocation() ) then
				    return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_NO_RANGE
			    end

				if not sim:getParams().difficultyOptions.meleeFromFront and not targetUnit:getTraits().modifyingExit and not targetUnit:getTraits().turning and not targetUnit:getTraits().movePath and sim:canUnitSeeUnit( targetUnit, userUnit ) then
					return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.UI.COMBAT_PANEL_SEEN
				end  
				]==]
				
		--		if unit:getTraits().sneaking then
		--			return false, "Must be sprinting to bullrush"
		--		end
				
				
				local dmg = self:calcBullrushDamage (sim, userUnit, targetUnit, brBonus)
				if dmg <= 0 and targetUnit:getArmor() > 0 then
					return false, STRINGS.UI.COMBAT_PANEL_ARMORED
				end	

				if sim:isVersion("0.17.12") then
					if tazerUnit:getTraits().armorPWRcost then

						local PWRcostPoints = returnPWRcostPoints(sim, userUnit, targetUnit)

						if PWRcostPoints and unit:getPlayerOwner():getCpus() < tazerUnit:getTraits().armorPWRcost * PWRcostPoints then
							return false, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
						end					
					end
				else
					if tazerUnit:getTraits().armorPWRcost and  unit:getPlayerOwner():getCpus() < tazerUnit:getTraits().armorPWRcost * targetUnit:getArmor() then
						return false, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
					end				
				end		
				
			end
			
			if tazerUnit:getTraits().pwrCost and  unit:getPlayerOwner():getCpus() < tazerUnit:getTraits().pwrCost then
				return false, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
			end				
			

			return true
		end,
		
		calcBullrushDamage = function( self, sim, userUnit, targetUnit, brBonus)
			
			local weapon = simquery.getEquippedMelee( userUnit )
			
			local weaponDmg = (weapon:getTraits().damage or 0)
			weapon:getTraits().damage = weaponDmg + brBonus
			local weaponAP = (weapon:getTraits().armorPiercing or 0)
			weapon:getTraits().armorPiercing = weaponAP + brBonus
			

			local dmg = simquery.calculateMeleeDamage(sim, weapon, targetUnit)
			
			weapon:getTraits().damage = weaponDmg
			weapon:getTraits().armorPiercing = weaponAP
			
			return dmg
		
		end,

		executeAbility = function( self, sim, unit, userUnit, target )
			local targetUnit = sim:getUnit(target)
			local targetCell = sim:getCell( targetUnit:getLocation() ) 
			if targetUnit then
			
				if userUnit:getTraits().sneaking then
					unit:hasAbility("sprint"):getDef():executeAbility( sim, unit, userUnit, targetUnit:getID() )
				end
			
				local path, pathCost, pathEndCell, brBonus = self:generatePath (sim, targetUnit, userUnit)
				table.insert( path, targetCell )
				
				local weapon = simquery.getEquippedMelee( userUnit )
				local weaponDmg = (weapon:getTraits().damage or 0)
				weapon:getTraits().damage = weaponDmg + brBonus
				local weaponAP = (weapon:getTraits().armorPiercing or 0)
				weapon:getTraits().armorPiercing = weaponAP + brBonus

				self.userUnit = userUnit
				self.targetUnit = targetUnit
				self.pathEndCell = pathEndCell
				self.targetCell = targetCell
				
				local oldSight = targetUnit:getTraits().hasSight
				local oldHearing = targetUnit:getTraits().hasHearing
				targetUnit:getTraits().dynamicImpass = nil
				targetUnit:getTraits().hasSight = false
				targetUnit:getTraits().hasHearing = false
				
				sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
				sim:moveUnit (unit , path)
				sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
		--		sim:warpUnit( unit, targetCell )
		--		sim:warpUnit( targetUnit, pathEndCell )
				
				if sim:getCell( unit:getLocation() ) == targetCell then
					unit:hasAbility("melee"):getDef():executeAbility( sim, unit, userUnit, targetUnit:getID() )
				end
				
				weapon:getTraits().damage = weaponDmg
				weapon:getTraits().armorPiercing = weaponAP
				
				targetUnit:getTraits().hasSight = oldSight
				targetUnit:getTraits().hasHearing = oldHearing
			end
		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			sim:addTrigger( simdefs.TRG_START_TURN, self )
			sim:addTrigger( simdefs.TRG_UI_ACTION, self )
			
			local abilityOwner = self.abilityOwner
			for i,childAug in ipairs(abilityOwner:getChildren( )) do
				if childAug:getTraits().kinetic_capc then
					self.sprintAug = childAug
				end
			end
			local sprintAug = self.sprintAug
			self.kRate = sprintAug:getTraits().kRate
			sprintAug:getTraits().ammo = sprintAug:getTraits().ammo + 1
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			sim:removeTrigger( simdefs.TRG_UI_ACTION, self )
			self.abilityOwner = nil
		end,
		
		onTrigger = function( self, sim, evType, evData ) -- move target out of end cell for takedown
			if self.userUnit and evData.unit == self.userUnit and evData.unit:getPlayerOwner() and evData.from_cell and self.targetUnit then
				
				if evData.from_cell == self.pathEndCell then
					local targetFacing = self.targetUnit:getFacing()
					local targetBack = simquery.getReverseDirection(targetFacing)
					sim:warpUnit( self.targetUnit, self.pathEndCell )
					self.targetUnit:setFacing(targetBack)
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, {unit = self.targetUnit} )
				--	sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = self.pathEndCell.x, y = self.pathEndCell.y, range = 2 } )
				else
					sim:processReactions( self.userUnit )
				end
			end
			

			
			
			--- this bit deals with the fatigue timer for Rush ---
			
			if self.abilityOwner and evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
				local sprintAug = self.sprintAug
				local SPRINT_BONUS = 3
				local kRate = self.kRate
				
				local abilityOwner = self.abilityOwner
				local num_turns = math.floor( sim:getTurnCount() / 2 )
				local sprintTotal = SPRINT_BONUS
				
				if not abilityOwner:hasTrait("sprintBonus") then
						abilityOwner:getTraits().sprintBonus = 0
					else
						sprintTotal = sprintTotal + abilityOwner:getTraits().sprintBonus
				end
				
				if not abilityOwner:hasTrait("dashTurn") then
					abilityOwner:getTraits().mpMax = abilityOwner:getTraits().mpMax + sprintTotal
					abilityOwner:getTraits().mp = abilityOwner:getTraits().mp + sprintTotal
					abilityOwner:getTraits().sprintBonus = 0 - sprintTotal
					abilityOwner:getTraits().dashTurn = 0
				end
				
				local turnMod = 0
				-- log:write("turn " .. num_turns)
				for int = 0,12 do
					if int <= num_turns / kRate then
						turnMod = int
						-- log:write("turnmod = " .. turnMod)
					end
				end
				
				if turnMod > abilityOwner:getTraits().dashTurn and abilityOwner:getTraits().mpMax > 4 then
					abilityOwner:getTraits().mpMax = abilityOwner:getTraits().mpMax - 1
					abilityOwner:getTraits().mp = abilityOwner:getTraits().mp - 1
					abilityOwner:getTraits().sprintBonus = abilityOwner:getTraits().sprintBonus + 1
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.FLAVORED.UI.BR_CHANGE, unit = abilityOwner, color=cdefs.MOVECLR_DEFAULT })
					sprintAug:getTraits().ammo = kRate
				else
					sprintAug:getTraits().ammo = sprintAug:getTraits().ammo - 1
					if sprintAug:getTraits().ammo <= 0 then
						sprintAug:getTraits().ammo = kRate
					end
				end
				
				abilityOwner:getTraits().dashTurn = turnMod
				
			end
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
			
			-- log:write("cntrecell = " .. scanMidLocX .. "," .. scanMidLocY )
			
			local pathEndCell = nil
	--		local path = {}
			
	--		local brBonus = 0
			
			-- we're gonna scan all squares around the one behind the target to find valid attack squares
			
			for dx = -1,1 do
			for dy = -1,1 do
			local testCell = sim:getCell( scanMidLocX + dx, scanMidLocY + dy )
				-- log:write("testing location = " .. scanMidLocX + dx .. "," .. scanMidLocY + dy )
				if testCell then -- and not testCell == targetCell then
				-- log:write("testing cell = " .. testCell.x .. "," .. testCell.y )
					if simquery.isConnected( sim, targetCell, testCell ) then
					-- log:write("is Connected")
						local cellValid = true
						for i,cellUnit in ipairs(testCell.units) do
							if cellUnit:getTraits().dynamicImpass then
								cellValid = false
								-- log:write("impass fail by " .. cellUnit:getName())
							end
						end
						local range = mathutil.dist2d( targetCell.x, targetCell.y, testCell.x, testCell.y )
						if range > 1 then 
							cellValid = false   -- no diagonals!
						end
						if cellValid then
							table.insert( ptntlCells, testCell )
							-- log:write("valid cell = " .. testCell.x .. "," .. testCell.y )
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
				local brBonus = math.min(math.floor((pathCost) * 0.5), 3)
				pathCost = math.floor(pathCost*2)*0.5  -- round to nearest 0.5
				return path, pathCost, pathEndCell, brBonus
				
			else
			
				return nil, nil, nil, nil
			
			end
			
			--return path, pathCost, pathEndCell, brBonus
			
		end,
	
	}
return bullrush
