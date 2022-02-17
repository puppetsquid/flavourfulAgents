local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilitydefs = include( "sim/abilitydefs" )
local mathutil = include( "modules/mathutil" )

local oldMeleeOverwatch = abilitydefs.lookupAbility("meleeOverwatch")

local oldCanUseAbility = oldMeleeOverwatch.canUseAbility
local oldAcquireTargets = oldMeleeOverwatch.acquireTargets

local meleeOverwatch = util.extend(oldMeleeOverwatch) {
	executeAbility = function( self, sim, userUnit, targetUnit)
		userUnit:setInvisible(false)
		userUnit:setDisguise(false)

		if targetUnit:getPlayerOwner() then
			targetUnit:getPlayerOwner():glimpseUnit( sim, userUnit:getID() )
		end			
		
		userUnit:resetAllAiming()
		
		local tazerUnit = simquery.getEquippedMelee( userUnit )
		local nsMelee = tazerUnit:getTraits().nonStandardMelee
		
		if tazerUnit and nsMelee ~= nil then
			local nsMeleeAbility, owner = userUnit:ownsAbility(nsMelee)
			nsMeleeAbility:getDef():executeAbility( sim, owner, userUnit, targetUnit:getID() )
			
			
		else
			userUnit:hasAbility("melee"):getDef():executeAbility( sim, userUnit, userUnit, targetUnit:getID() )
		end
		
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
	end,
	
	canUseAbility = function( self, sim, userUnit, targetUnit )
		local tazerUnit = simquery.getEquippedMelee( userUnit )
		local nsMelee = tazerUnit:getTraits().nonStandardMelee
		local nsMeleeAbility, owner = userUnit:ownsAbility(nsMelee)
		if nsMelee ~= nil then
			return nsMeleeAbility:canUseAbility( sim, simquery.getEquippedMelee(userUnit), userUnit, targetUnit:getID() )
		end
		return oldCanUseAbility( self, sim, userUnit, targetUnit )
	end,
	
	acquireTargets = function( self, targets, game, sim, unit, userUnit )
		local tazerUnit = simquery.getEquippedMelee( userUnit )
		local nsMelee = tazerUnit:getTraits().nonStandardMelee
		local nsMeleeAbility, owner = userUnit:ownsAbility(nsMelee)
		if nsMelee ~= nil then
			return nsMeleeAbility:acquireTargets( self, targets, game, sim, unit, userUnit )
		end
		return oldacquireTargets( self, targets, game, sim, unit, userUnit )
	end,
}

return meleeOverwatch