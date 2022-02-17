local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )
local rig_util = include( "gameplay/rig_util" )

local banks_throwParalyze =
	{
		name = STRINGS.ABILITIES.THROW,

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,
	
		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip( STRINGS.ABILITIES.THROW,  STRINGS.ABILITIES.THROW_DESC, 1 )
		end,
	
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png",
		usesAction = true,

		acquireTargets = function( self, targets, game, sim, grenadeUnit, unit)
			if not self:canUseAbility( sim, grenadeUnit, unit ) then
				return nil
			end
--[==[			local units = {}
			local xn, yn = unit:getLocation() 
			local cells = simquery.fillCircle( sim, xn, yn, 10, 0)
			for i, cell in ipairs(cells) do
				for i, cellUnit in ipairs(sim:getCell(cell.x,cell.y).units) do
					if (not cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= unit:getPlayerOwner() and cellUnit:getBrain() and not cellUnit:getTraits().isDrone then
				
					else
						return false
					end
				end
			end	]==]
			return targets.throwTarget( game, 0, sim, unit, unit:getTraits().maxThrow, true ) --grenadeUnit:getTraits().targeting_ignoreLOS)
		end, 


		canUseAbility = function( self, sim, grenadeUnit, unit, targetCell )
            if unit:getTraits().movingBody then
                return false, STRINGS.UI.REASON.DROP_BODY_TO_USE
            end
			
			if unit:getBrain() then
				return false
			end
			

			if grenadeUnit:getTraits().pwrCost and (ownerUnit:getPlayerOwner():isPC() and ownerUnit:getPlayerOwner():getCpus() < grenadeUnit:getTraits().pwrCost) then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if grenadeUnit:getTraits().cooldown and grenadeUnit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,grenadeUnit:getTraits().cooldown)
			end

			if targetCell then
				local targetX,targetY = unpack(targetCell)
				local unitX, unitY = unit:getLocation()
	    		local raycastX, raycastY = sim:getLOS():raycast(unitX, unitY, targetX, targetY)
				if raycastX ~= targetX or raycastY ~= targetY then
					return false
				end
	--[==[			for i, cellUnit in ipairs(sim:getCell(targetX,targetY).units) do
					if (not cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= unit:getPlayerOwner() and cellUnit:getBrain() and not cellUnit:getTraits().isDrone then
				
					else
						return false
					end
				end
				]==]
			end

			return true
		end,

		executeAbility = function( self, sim, grenadeUnit, userUnit, targetCell )
			local sim = grenadeUnit:getSim()
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unpack(targetCell)
			userUnit:getTraits().throwing = true
		
			local facing = simquery.getDirectionFromDelta(x1-x0, y1-y0)
			simquery.suggestAgentFacing(userUnit, facing)
			if userUnit:getBrain() then	
				if grenadeUnit:getTraits().baseDamage then
					sim:emitSpeech(userUnit, speechdefs.HUNT_GRENADE)
				end
				sim:refreshUnitLOS( userUnit )
				sim:processReactions( userUnit )
			end

			if userUnit:isValid() and not userUnit:getTraits().interrupted then
			--	sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
				
			--	if grenadeUnit:getTraits().throwUnit then
			--		inventory.dropItem( sim, userUnit, grenadeUnit )
			--	end
			--	if targetCell and targetCell.units then
				local notarget = false
					for i, cellUnit in ipairs(sim:getCell(x1,y1).units) do
						if cellUnit and (not cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then -- and sim:canPlayerSeeUnit( sim:getPC(), cellUnit ) 
							sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
							if cellUnit:getTraits().koTimer then
								cellUnit:getTraits().koTimer = cellUnit:getTraits().koTimer + grenadeUnit:getTraits().koTime
							else
								cellUnit:setKO(sim, grenadeUnit:getTraits().koTime)
							end
							inventory.useItem( sim, userUnit, grenadeUnit )
							inventory.giveItem( userUnit, cellUnit, grenadeUnit ) 
							userUnit:useAP( sim )
							sim:dispatchEvent( simdefs.EV_UNIT_STOP_THROW, { unitID = userUnit:getID(), x1=x1, y1=y1, facing=facing } )
						else	
							notarget = true
							--inventory.dropItem( sim, userUnit, grenadeUnit )
							--sim:warpUnit( grenadeUnit, sim:getCell(x1,y1) )
						end
					if notarget == true then
				--		inventory.dropItem( sim, userUnit, grenadeUnit )
				--		sim:warpUnit( grenadeUnit, sim:getCell(x1,y1) )
					end
						
					end
			--	end	
				
			--	local template = unitdefs.lookupTemplate( "item_paralyzer_banks" )
			--	local unitData = util.extend( template )( {} )
			--	local fakeunit = simfactory.createUnit( unitData, sim )
			--	local fakerig =  self._hud._game.boardRig:getUnitRig(fakeunit:getID())
			--	sim:spawnUnit( fakeunit )
			--	sim:warpUnit( fakeunit, sim:getCell(x0,y0) )
			--	rig_util.throwToLocation(fakeunit, x1, y1)
	
				if sim:isVersion("0.17.15") and userUnit:getTraits().data_hacking then 
					userUnit:stopHacking(sim)
		        end

		--		if grenadeUnit.throw then
		--			grenadeUnit:throw(userUnit, sim:getCell(x1, y1) )
		--		end

		--		sim:dispatchEvent( simdefs.EV_UNIT_STOP_THROW, { unitID = userUnit:getID(), x1=x1, y1=y1, facing=facing } )
				
				sim:processReactions( userUnit )
			end
			userUnit:getTraits().throwing = nil
			if userUnit:isValid() and not userUnit:getTraits().interrupted then
				simquery.suggestAgentFacing(userUnit, facing)
			end
		end
	}

return banks_throwParalyze
