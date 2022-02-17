local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")

------------- Jackin is now also handling 'empty' weapon slots; if a unit has 'default' light/heavy equipment it is spawned to them when unequipping an item or at start of level if player owned and nothing else equipped
------------- Jackin functionality moved to laptop item (sits in ranged slot), this ability now adds 'equip laptop' ability

local oldJackin = include("sim/abilities/jackin")

local oldAcquireTargets = oldJackin.acquireTargets
local oldCanUseAbility = oldJackin.canUseAbility
local oldExecuteAbility = oldJackin.executeAbility

local jackin = util.extend(oldJackin) {
	acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
		local maxRange = abilityOwner:getTraits().wireless_range
		if sim:getParams().difficultyOptions.flav_internationale then
			abilityOwner:getTraits().wireless_range = nil
		end
		
		local toReturn = oldAcquireTargets( self, targets, game, sim, abilityOwner, unit )
		
		abilityOwner:getTraits().wireless_range = maxRange
		return toReturn
	end,

	canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
		local ok, reason = oldCanUseAbility( self, sim, abilityOwner, unit, targetUnitID )
		if not ok then
			return false, reason
		end
		
		if sim:getParams().difficultyOptions.flav_equipCosts and simquery.getEquippedGun( abilityOwner ) and sim:getParams().difficultyOptions.flav_unequip then
			return false, "Unequip Ranged Weaponry to use"
		end
		
		return true
	end,

	-- Mainframe system.

	executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
		local maxRange = abilityOwner:getTraits().wireless_range
		if sim:getParams().difficultyOptions.flav_internationale then
			abilityOwner:getTraits().wireless_range = nil
		end
		
		oldExecuteAbility( self, sim, abilityOwner, unit, targetUnitID )
		
		abilityOwner:getTraits().wireless_range = maxRange
		
		if unit:getTraits().nanoLocate then	-- adds laptop on first owned mission
			local nano = false
			local player = unit:getPlayerOwner()
			unit:getTraits().nanoLocate = false
			for i,nanunit in pairs(sim:getAllUnits())do
				if nanunit:getTraits() and nanunit:getTraits().storeType and (nanunit:getTraits().storeType=="standard" or nanunit:getTraits().storeType=="large") 
			--	and player:hasSeen(nanunit) 
					then
					--nano = nanunit
					local x0, y0 = nanunit:getLocation()
					sim:dispatchEvent( simdefs.EV_CAM_PAN, { x0, y0 } )	
				end
			end
	--		if nano then
	--			local x0, y0 = nano:getLocation()
	--			sim:dispatchEvent( simdefs.EV_CAM_PAN, { x0, y0 } )	
	--		end
		end

	end,

	----------------------------------------------newstuff-----------------------------------------------------------

	onSpawnAbility = function( self, sim, unit )
		self.abilityOwner = unit
		if unit:getPlayerOwner() then	-- adds laptop on first owned mission
			unit:getTraits().hasLaptop = true
		end
		if sim:getParams().difficultyOptions.flav_skills then
			unit:getTraits().maxThrow = 2 + unit:getSkillLevel("inventory")
		end
	end,
}
return jackin