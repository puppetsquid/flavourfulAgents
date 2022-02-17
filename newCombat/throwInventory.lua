local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )

local simfactory = include( "sim/simfactory" )
local unitdefs = include("sim/unitdefs")

local throwInventory =
{
	name = "Throw-Transfer",
	proxy = true,

	getName = function( self, sim, unit, userUnit )
		return self.name
	end,

	createToolTip = function( self,sim,unit,targetCell)
		return abilityutil.formatToolTip( "Throw-Transfer",  "Transfer items over a short distance", 1 )
	end,

	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_drop_give_small.png",
	
	isTarget = function( self, abilityOwner, unit, targetUnit )
		local canUse = targetUnit:getPlayerOwner() == abilityOwner:getPlayerOwner()
		canUse = canUse and not targetUnit:isDead()
		canUse = canUse and simquery.isAgent(targetUnit)
		return canUse
	end,

	acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
		local maxRange = abilityOwner:getSkillLevel("inventory")
		local x0, y0 = unit:getLocation()
		local units = {}
		for _, targetUnit in pairs(sim:getAllUnits()) do
			local x1, y1 = targetUnit:getLocation()
			if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
				local range = mathutil.dist2d( x0, y0, x1, y1 )
				if maxRange and range <= maxRange and range > 1 and sim:canUnitSeeUnit( abilityOwner, targetUnit ) then
					table.insert( units, targetUnit )
				end
			end
		end

		return targets.unitTarget( game, units, self, abilityOwner, unit )
	end,

	canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
        -- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
        if abilityOwner ~= unit and abilityOwner:getUnitOwner() ~= unit then
            return false
        end

		local targetUnit = sim:getUnit( targetUnitID )
		if targetUnit then
			if targetUnit:isKO() then
				return false, "Target must be awake"
			end
		end
		
		if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
		end	

		if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end	

		return abilityutil.checkRequirements( abilityOwner, unit )
	end,

	executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )


		local targetUnit = sim:getUnit( targetUnitID )
		assert( targetUnit, "No target : "..tostring(targetUnitID))
		local x1, y1 = targetUnit:getLocation()
		local x0,y0 = unit:getLocation()
		local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )
		local revfacing = simquery.getDirectionFromDelta( x0 - x1, y0 - y1 )
		
		local maxRange = targetUnit:getSkillLevel("inventory")
		local range = mathutil.dist2d( x0, y0, x1, y1 )
		
		if range > maxRange then
			for _,childUnit in pairs(targetUnit:getChildren()) do
				if not childUnit:getTraits().catcherOwned then
					childUnit:getTraits().catcherOwned = true
				end
			end
		end
		
		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { targetUnit = targetUnit, unit = unit } )
		sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = abilityOwner, x1=x1, y1=y1, facing=facing } )
		
		self._target = targetUnit
		self._user = abilityOwner
		sim:getCurrentPlayer():glimpseUnit( sim, targetUnit:getID() )
	end,
	
	
	onSpawnAbility = function( self, sim, unit )
		sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
	end,
	
	onDespawnAbility = function( self, sim, unit )
		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
	end,
	
	onTrigger = function( self, sim, evType, evData, player)
		for _,childUnit in pairs(sim:getAllUnits()) do
			if childUnit:getTraits().catcherOwned then
				childUnit:getTraits().catcherOwned = nil
			end
		end
	end, 
}
return throwInventory