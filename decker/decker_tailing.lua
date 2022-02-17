local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )

---------------------------------------------------------
-- Local functions

function getTargets( sim, userUnit )
	local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
                if simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) and targetUnit:getTraits().isGuard and not targetUnit:getTraits().isDrone then

    				if sim:canUnitSeeUnit( userUnit, targetUnit ) then
						table.insert( units, targetUnit )
					else 
						for _, cameraUnit in pairs(sim:getAllUnits()) do 
							if cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then -- peek thru doors
								table.insert( units, targetUnit )
								
                               break
							end
						end
					end
				end
			end
	return units
end

local decker_tailing = 
	{
		getName = function( self, sim, unit )
			return self.name
		end,
			
		createToolTip = function( self,sim,unit,targetUnit)
			return formatToolTip( self.name, string.format("PASSIVE\n%s", self.desc ) )
		end,

		canUseAbility = function( self, sim, unit )
			return false -- Passives are never 'usd'
		end,

		canUseAbility = function( self, sim, unit, userUnit, targetID )
			local targetUnit = sim:getUnit( targetID )
			if targetUnit then 
				local x0, y0 = userUnit:getLocation()
			end
			
			if targetUnit then
				local closestItem, itemLoc, itemType = self:getClosestItem( sim, unit, userUnit, targetUnit )
				if not closestItem then
					return false, "No more items"
				end
			end

			return true 
		end, 
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			self.userUnit = unit:getUnitOwner()
			self.patrollingGuard = nil
			self.targetedCell = nil
			self.targetedUnit = nil
			self.patrolGuardBase = nil
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( simdefs.TRG_START_TURN, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			self.patrollingGuard = nil
			self.abilityOwner = nil
			self.userUnit = nil
			self.targetedCell = nil
			self.targetedUnit = nil
			self.patrolGuardBase = nil
		end,
		
		onTrigger = function ( self, sim, evType, evData )  
		
			local userUnit = self.userUnit
			local observeAbility = userUnit:hasAbility("observePath")
			local player = sim:getPC() -- 
			
			if evType == simdefs.TRG_START_TURN and observeAbility  and not evData:isNPC() then
			
				local targs = getTargets( sim, userUnit )
				for _, targetUnit in pairs(targs) do
					if targetUnit:getTraits().deckerTrailed then
						targetUnit:getTraits().patrolObserved = true
						sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
						targetUnit:getTraits().deckerTrailed = nil
						log:write("renew")
					end
				end
				for _, targetUnit in pairs(sim:getAllUnits()) do
					if targetUnit:getTraits().deckerTrailed then
						player:glimpseUnit( sim, targetUnit:getID() )
						sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )  
						targetUnit:getTraits().deckerTrailed = nil
					end
				end
			
				
			end
			
			
			
			if evType == simdefs.TRG_END_TURN and observeAbility  and not evData:isNPC() then
			
				local targs = getTargets( sim, userUnit )
				for _, targetUnit in pairs(targs) do
					log:write(targetUnit:getName())
					targetUnit:getTraits().deckerTrailed = true
					log:write("is observed")
					targetUnit:getTraits().patrolObserved = true
						sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
				end				
			end
		end,
		

		

		}
return decker_tailing