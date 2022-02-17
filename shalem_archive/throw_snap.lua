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
local itemdefs = include("sim/unitdefs/itemdefs")

local throw_decoy_2 =
	{
	
	------ Copied from throw-emp from Mods Combo by Shirsh
	
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
			return targets.throwTarget( game, grenadeUnit:getTraits().range or 0, sim, unit, unit:getTraits().maxThrow, grenadeUnit:getTraits().targeting_ignoreLOS)
		end, 


		canUseAbility = function( self, sim, grenadeUnit, unit, targetCell )
            if unit:getTraits().movingBody then
                return false, STRINGS.UI.REASON.DROP_BODY_TO_USE
            end

			if grenadeUnit:getTraits().pwrCost and (ownerUnit:getPlayerOwner():isPC() and ownerUnit:getPlayerOwner():getCpus() < grenadeUnit:getTraits().pwrCost) then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if grenadeUnit:getTraits().cooldown and grenadeUnit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,grenadeUnit:getTraits().cooldown)
			end
			
			if grenadeUnit:getTraits().usesCharges and grenadeUnit:getTraits().charges < 1 then
            	return false
            end
			
			
            if grenadeUnit:getTraits().ammo and grenadeUnit:getTraits().ammo < 1 then
                return false
            end

			if targetCell then
				local targetX,targetY = unpack(targetCell)
				local unitX, unitY = unit:getLocation()
	    		local raycastX, raycastY = sim:getLOS():raycast(unitX, unitY, targetX, targetY)
				if raycastX ~= targetX or raycastY ~= targetY then
					return false
				end
			end

			return true
		end,
		
		getTargets = function( self, sim, grenadeUnit, userUnit, x0, y0 )

			local cells = {}

				cells = simquery.rasterCircle( sim, x0, y0, grenadeUnit:getTraits().range )

			local units = {}
			for i, x, y in util.xypairs( cells ) do
				local cell = sim:getCell( x, y )
				if cell then
					for _, cellUnit in ipairs(cell.units) do
						local player = grenadeUnit:getPlayerOwner()
						if cellUnit ~= grenadeUnit and (cellUnit:getTraits().mainframe_status or cellUnit:getTraits().heartMonitor) and (not grenadeUnit:getTraits().flash_pack or (simquery.isEnemyAgent( player, cellUnit) and not cellUnit:getTraits().isDrone)) then
							table.insert( units, cellUnit )
						end
					end
				end
			end

			return units
		end,

		executeAbility = function( self, sim, grenadeUnit, userUnit, targetCell )
			local sim = grenadeUnit:getSim()
			local x0,y0 = userUnit:getLocation()
			local newUnit = simfactory.createUnit( itemdefs.item_shalem_empgrenade_true, sim )
			local x1,y1 = unpack(targetCell)
			local cell = sim:getCell( userUnit:getLocation() )
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
				sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
				
				sim:spawnUnit( newUnit )
				sim:warpUnit( newUnit, sim:getCell(x1, y1) )
				newUnit:removeAbility(sim, "carryable")

			--	sim:emitSound( simdefs.SOUND_ITEM_PUTDOWN, cell.x, cell.y, userUnit)
		--	sim:emitSound( simdefs.SOUND_PRIME_EMP, cell.x, cell.y, userUnit)
			sim:emitSound( { path = "SpySociety/Actions/EMP_explo", range = 2 }, x1, y1, userUnit)
			sim:emitSound( { path = "SpySociety/HitResponse/hitby_shocktrap", range = 1 }, x1, y1, userUnit)
			
		--	newUnit:getTraits().primed = true
		--	newUnit:detonate( sim )	
		
			local units = self:getTargets( sim, grenadeUnit, userUnit, x1, y1 )

		--	sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = x1, y = y1, units = units, range = 2.5 } )
			
			sim:emitSound( simdefs.SOUND_SMALL, x1, y1, nil )
			
			
			for i, unit in ipairs(units) do
				unit:processEMP( 1, false )
			end
			
			sim:warpUnit(newUnit, nil)
			sim:despawnUnit( newUnit )
		
	--		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newUnit} ) 


				
				userUnit:resetAllAiming()

			inventory.useItem( sim, userUnit, grenadeUnit )
			
						
	
				--if grenadeUnit.throw then
				--	grenadeUnit:throw(userUnit, sim:getCell(x1, y1) )
				--end

				sim:dispatchEvent( simdefs.EV_UNIT_STOP_THROW, { unitID = userUnit:getID(), x1=x1, y1=y1, facing=facing } )


				sim:processReactions( userUnit )
			end
			userUnit:getTraits().throwing = nil
			if userUnit:isValid() and not userUnit:getTraits().interrupted then
				simquery.suggestAgentFacing(userUnit, facing)
			end

			
			
		end,
	}

return throw_decoy_2
