local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )

local scan_securityCard =
{
	name = STRINGS.FLAVORED.ITEMS.COPYCARD,
	profile_icon = "gui/icons/item_icons/icon-item_passcard.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.COPYCARD_FUNC, STRINGS.FLAVORED.ITEMS.COPYCARD_FUNC_SEC )
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.FLAVORED.ITEMS.COPYCARD
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return self.profile_icon -- abilityOwner:getUnitData().profile_icon or 
    end,

	acquireTargets = function( self, targets, game, sim, unit )
		local userUnit = unit:getUnitOwner()
		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 
        assert( userUnit, tostring(unit and unit:getName())..", "..tostring(unit:getLocation()) )
		local cell = sim:getCell( userUnit:getLocation() )
		local units = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
				for i,item in ipairs(cellUnit:getChildren()) do
					if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.SECURITY) then
						table.insert( units, cellUnit )
					end
				end
			--	if (cellUnit:getTraits().mainframe_ice or 0) > 0 and ( cellUnit:getTraits().mainframe_program or sim:getHideDaemons()) and not cellUnit:getTraits().daemon_sniffed  then
			--		table.insert( units, cellUnit )
			--	end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,
		
	canUseAbility = function( self, sim, unit )

		-- Must have a user owner.
		local userUnit = unit:getUnitOwner()

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 
		
		if userUnit:getTraits().passiveKey and userUnit:getTraits().passiveKey == simdefs.DOOR_KEYS.SECURITY then
			return false, "Already Copied"
		end

		if not userUnit then
			return false
		end

		return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local userUnit = unit:getUnitOwner()
		local target = sim:getUnit(target)	

		if simquery.isAgent( unit ) then 
			userUnit = unit
		end 		
			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = target:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 

		userUnit:getTraits().passiveKey = simdefs.DOOR_KEYS.SECURITY
		unit:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_SEC
		unit:getTraits().active = "SecKey"
		unit:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard_1.png"
		unit:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard_1.png"

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
	
	onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
		--	sim:addTrigger( simdefs.TRG_UNIT_USEDOOR_PRE, self )
			sim:addTrigger( "unitParented", self )
			sim:addTrigger( "unitUnparented", self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
		--	sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR_PRE, self )
			sim:removeTrigger( "unitParented", self )
			sim:removeTrigger( "unitUnparented", self )
			self.abilityOwner = nil
		end,
		
		onTrigger = function( self, sim, evType, evData )
			if evType == "unitUnparented" and evData.childUnit == self.abilityOwner and evData.childUnit:getTraits().active == "SecKey" then
				evData.parent:getTraits().passiveKey = nil
			elseif evType == "unitParented" and evData.childUnit == self.abilityOwner and evData.childUnit:getTraits().active == "SecKey" then
				evData.parent:getTraits().passiveKey = simdefs.DOOR_KEYS.SECURITY
			end
		end,
}

return scan_securityCard