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
local serverdefs = include( "modules/serverdefs" )
local abilitydefs = include( "sim/abilitydefs" )

local oldShootSingle = abilitydefs.lookupAbility("shootSingle")

local oldCanUseAbility = oldShootSingle.canUseAbility

local oldAcquireTargets = oldShootSingle.acquireTargets


local shootSingle = util.extend(oldShootSingle) {

	canUseAbility = function( self, sim, ownerUnit, unit, targetUnitID )
		local weaponUnit = simquery.getEquippedGun( unit )
		if unit:countAugments( "LEVER_augment_melee_specialist" ) > 0 then
			return false, STRINGS.AGEOFLEVER.UI.REASON_MELEE_SPECIALIST
		end
		local storedAP = unit:getAP()
		if weaponUnit and weaponUnit:getTraits().ignoreNoAP then
			unit:getTraits().ap = 1
		end
		local ok, reason = oldCanUseAbility( self, sim, ownerUnit, unit, targetUnitID )
		unit:getTraits().ap = storedAP
		return ok, reason
	end,
	
	acquireTargets = function( self, targets, game, sim, unit, userUnit )
		self._game = game
		return oldAcquireTargets ( self, targets, game, sim, unit, userUnit )
	end,
	
	onSpawnAbility = function( self, sim, unit )
		self.abilityOwner = unit
		self.userUnit = unit:getUnitOwner()
		sim:addTrigger( simdefs.TRG_UNIT_KILLED, self )
	end,
		
	onDespawnAbility = function( self, sim, unit )
		sim:removeTrigger( simdefs.TRG_UNIT_KILLED, self )
		self.abilityOwner = nil
		self.userUnit = nil
	end,
	
	onTrigger = function ( self, sim, evType, evData )  -- need to get this working

		if evType == simdefs.TRG_UNIT_KILLED then
			if evData.corpse and evData.unit:getTraits().hideBody then
				evData.corpse:setPlayerOwner(self.userUnit:getPlayerOwner())	
				evData.corpse:setInvisible(true)
				local kanim = "kanim_dracul"
				evData.corpse:changeKanim(  kanim )	
		--		self._game.boardRig:getUnitRig( self.abilityOwner:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["cloak"] )
		--		self._game.boardRig:getUnitRig( evData.corpse:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["cloak"] )
			end
		end
	end
}

return shootSingle