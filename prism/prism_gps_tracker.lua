local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

	local prism_gps_tracker =
{
	name = STRINGS.RESEARCH.MAINFRAME_ATTUNEMENT.NAME, 
	buffDesc = STRINGS.RESEARCH.MAINFRAME_ATTUNEMENT.UNIT_DESC, 
	
	getName = function( self, sim, unit )
		return self.name
	end,
		
	createToolTip = function( self,sim,unit,targetUnit)
		return formatToolTip( self.name, string.format("PASSIVE\n%s", buffDesc ) )
	end,

	canUseAbility = function( self, sim, unit )
		return false -- Passives are never 'used'
	end,
	
			
		

		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_START_TURN, self, unit )
		--	sim:addTrigger( simdefs.TRG_UNIT_CHILDED, self, unit )
		end,

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
		--	sim:removeTrigger( simdefs.TRG_UNIT_CHILDED, self ) -- does not seem to be a thing?
		end,

		onTrigger = function( self, sim, evType, evData, userUnit )
			if evType == simdefs.TRG_START_TURN then 
		--		if userUnit then
				local ownerUnit = userUnit:getUnitOwner()
					if ownerUnit then
						if not ownerUnit:getTraits().patrolObserved and ownerUnit:getBrain() and not ownerUnit:getTraits().isDrone then
							ownerUnit:getTraits().patrolObserved = true
						--	sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, ownerUnit )
						end
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = ownerUnit } )
					end
				end
		
		end, 

	executeAbility = nil, -- Passives by definition have no execute.
}
return prism_gps_tracker