local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )
local inventory = include( "sim/inventory" )

local scan_securityCard =
{
	name = STRINGS.FLAVORED.ITEMS.COPYCARD,
	profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_vault_key_small.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.COPYCARD_FUNC, STRINGS.FLAVORED.ITEMS.COPYCARD_FUNC_VAL )
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.FLAVORED.ITEMS.COPYCARD
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return  self.profile_icon -- abilityOwner:getUnitData().profile_icon or
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
					if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.VAULT) then
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
		
		if userUnit:getTraits().passiveKey and userUnit:getTraits().passiveKey == simdefs.DOOR_KEYS.VAULT then
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
		
		for i,item in ipairs(target:getChildren()) do
			if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.VAULT) then
				self.abilityOwner:getTraits().duplicatedCard = item
			end
		end
		
		
		local dupCard = self.abilityOwner:getTraits().duplicatedCard
		dupCard:getTraits().originalKeyCard = self.abilityOwner

		userUnit:getTraits().passiveKey = simdefs.DOOR_KEYS.VAULT
		unit:getTraits().active = "ValKey"
		unit:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_VAL
		dupCard:getUnitData().name = STRINGS.ITEMS.VAULT_PASS .. " - Original"
		unit:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard_2.png"
		unit:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard_2.png"
	--	unit:getUnitData().desc = "Mimic a key held by another unit. Currently mimicing Vault Pass."

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
	
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			self.abilityOwner:getTraits().duplicatedCard = nil
			sim:addTrigger( simdefs.TRG_UNIT_USEDOOR_PRE, self )
			sim:addTrigger( "unitParented", self )
			sim:addTrigger( "unitUnparented", self )
			sim:addTrigger( "trgDoorAction", self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR_PRE, self )
			sim:removeTrigger( "unitParented", self )
			sim:removeTrigger( "unitUnparented", self )
			sim:removeTrigger( "trgDoorAction", self )
			self.abilityOwner = nil
			self.abilityOwner:getTraits().duplicatedCard = nil
		end,
		
		onTrigger = function( self, sim, evType, evData )
			if evType == "unitUnparented" and evData.childUnit == self.abilityOwner and evData.childUnit:getTraits().active == "ValKey" then 
				evData.parent:getTraits().passiveKey = nil
			elseif evType == "unitParented" and evData.childUnit == self.abilityOwner and evData.childUnit:getTraits().active == "ValKey" then
				evData.parent:getTraits().passiveKey = simdefs.DOOR_KEYS.VAULT
			elseif evType == "trgDoorAction" and evData.exitOp == simdefs.EXITOP_UNLOCK and self.abilityOwner:getTraits().duplicatedCard then --  exitOp, unitID, x0, y0, facing 
			
				local x0,y0 = evData.x0, evData.y0
				local cell = sim:getCell(x0,y0)
				local dir = evData.facing
				local exit = cell.exits[dir] -- \/ check if we're unlocking a door that this key works on
				if exit.keybits == (simdefs.DOOR_KEYS.VAULT or simdefs.DOOR_KEYS.SPECIAL_EXIT) and self.abilityOwner:getTraits().duplicatedCard then
					local usedCard = false
					
					local originalCard = false
					local originalCardOwner = false
					local copyCard = false
					local copyCardOwner = false
			
					local openingUnit = sim:getUnit(evData.unitID)
					for i,item in ipairs(openingUnit:getChildren())do
						if item == self.abilityOwner and not usedCard then --self.abilityOwner:getTraits().duplicatedCard or
							usedCard = item
							copyCard = item
							copyCardOwner = copyCard:getUnitOwner()
							originalCard = item:getTraits().duplicatedCard
							originalCardOwner = originalCard:getUnitOwner()
						elseif item == self.abilityOwner:getTraits().duplicatedCard and not usedCard then
							usedCard = item 
							originalCard = item
							originalCardOwner = originalCard:getUnitOwner()
							if item:getTraits().originalKeyCard then
								copyCard = item:getTraits().originalKeyCard
								copyCardOwner = copyCard:getUnitOwner()
							end
						end
					end
					
					if usedCard then
						if copyCard then
								copyCard:getTraits().active = nil
								copyCard:getTraits().duplicatedCard = nil
								copyCard:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_OLD
								copyCard:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard.png"
								copyCard:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard.png"
						end
						if originalCard then
							inventory.trashItem( sim, originalCardOwner, originalCard )
						end
					end
				end
				
				
				
			end
		end,
}

return scan_securityCard