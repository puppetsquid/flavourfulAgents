local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local paralyze =
	{
		name = STRINGS.ABILITIES.PARALYZE,
		createToolTip = function( self, sim, abilityOwner )
				return abilityutil.formatToolTip(STRINGS.ABILITIES.PARALYZE, util.sformat(STRINGS.ABILITIES.PARALYZE_DESC,abilityOwner:getTraits().koTime), simdefs.DEFAULT_COST)
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_paralyzerdose_small.png",

		alwaysShow = true,
        proxy = true,

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.PARALYZE
		end,

		acquireTargets = function( self, targets, game, sim, unit )
			local userUnit = unit:getUnitOwner()
			local cell = sim:getCell( userUnit:getLocation() )

			local units = {}
		
				
			for i,cellUnit in ipairs(cell.units) do
				if (cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then
					table.insert( units, cellUnit )
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		canUseAbility = function( self, sim, unit )

			-- Must have a user owner.
			local userUnit = unit:getUnitOwner()
			if not userUnit then
				return false
			end
			-- Must have a KO target in range
			local cell = sim:getCell( userUnit:getLocation() )
			local units = {}

			if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
			end

			if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
		
            local ok, reason = abilityutil.checkRequirements( unit, userUnit )
            if not ok then
                return false, reason
            end

			for i,cellUnit in ipairs(cell.units) do
				if (cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and cellUnit:getTraits().canKO then
					table.insert( units, cellUnit )
				end
			end					

			if #units < 1 then
				return false, STRINGS.UI.REASON.NO_VIABLE_TARGET
			end

			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )

			local userUnit = unit:getUnitOwner()
			local target = sim:getUnit(target)	

			local x0,y0 = userUnit:getLocation()
			
			sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = userUnit:getFacing() } )
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.PARALYZED,x=x0,y=y0,color={r=1,g=1,b=0,a=1}} )

			target:getTraits().koTimer = target:getTraits().koTimer + unit:getTraits().koTime
			

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )

			if unit:getTraits().disposable then 
				inventory.trashItem( sim, userUnit, unit )
			else
				inventory.useItem( sim, userUnit, unit )
			end

			if userUnit:isValid() then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
			end

			sim:triggerEvent( simdefs.TRG_UNIT_PARALYZED )
		end,
	}
return paralyze