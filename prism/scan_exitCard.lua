local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )
local inventory = include( "sim/inventory" )

local scan_exitCard =
{
	name = STRINGS.FLAVORED.ITEMS.COPYCARD,
	profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_exit_key_small.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.COPYCARD_FUNC, STRINGS.FLAVORED.ITEMS.COPYCARD_FUNC_EXT )
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
					if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT) then
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
		
		if userUnit:getTraits().passiveKey and userUnit:getTraits().passiveKey == simdefs.DOOR_KEYS.SPECIAL_EXIT then
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
			if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.SPECIAL_EXIT) then
				self.duplicatedCard = item
			end
		end
		local dupCard = self.duplicatedCard
		dupCard:getTraits().originalKeyCard = true

		userUnit:getTraits().passiveKey = simdefs.DOOR_KEYS.SPECIAL_EXIT
		unit:getTraits().active = "ValKey"
		unit:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_VAL
		dupCard:getUnitData().name = STRINGS.ITEMS.EXIT_PASS .. " - Original"
		unit:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard_3.png"
		unit:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard_3.png"
	--	unit:getUnitData().desc = "Mimic a key held by another unit. Currently mimicing Vault Pass."

		if userUnit:isValid() then
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end

	end,
	
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			self.duplicatedCard = nil
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
			self.duplicatedCard = nil
		end,
		
		onTrigger = function( self, sim, evType, evData )
			if evType == "unitUnparented" and evData.childUnit == self.abilityOwner and evData.childUnit:getTraits().active == "ValKey" then 
				evData.parent:getTraits().passiveKey = nil
			elseif evType == "unitParented" and evData.childUnit == self.abilityOwner and evData.childUnit:getTraits().active == "ValKey" then
				evData.parent:getTraits().passiveKey = simdefs.DOOR_KEYS.SPECIAL_EXIT
			elseif evType == "trgDoorAction" and evData.exitOp == simdefs.EXITOP_UNLOCK and self.duplicatedCard then --  exitOp, unitID, x0, y0, facing 
			
				local x0,y0 = evData.x0, evData.y0
				local cell = sim:getCell(x0,y0)
				local dir = evData.facing
				local exit = cell.exits[dir] -- \/ check if we're unlocking a door that this key works on
				if exit.keybits == (simdefs.DOOR_KEYS.SPECIAL_EXIT) and self.duplicatedCard then
					local usedCard = false
					local openingUnit = sim:getUnit(evData.unitID)
					for i,item in ipairs(openingUnit:getChildren())do
						if item == self.abilityOwner then --self.duplicatedCard or
							usedCard = item
						elseif item == self.duplicatedCard then
							usedCard = item 
						end
					end
					if usedCard == self.abilityOwner and self.duplicatedCard:getTraits().keybits then
						for _, unit in pairs( sim:getAllUnits() ) do  --check if fromcell has card or original, then remove/null other			
							for i,item in ipairs(unit:getChildren())do
								if item == self.duplicatedCard then
									inventory.trashItem( sim, unit, item )
									local copycardOwner = self.abilityOwner:getUnitOwner()
									copycardOwner:getTraits().passiveKey = nil
									self.abilityOwner:getTraits().active = nil
									self.duplicatedCard = nil
									self.abilityOwner:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_OLD
									self.abilityOwner:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard.png"
									self.abilityOwner:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard.png"
									if copycardOwner:isValid() then
										sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = copycardOwner  } )
										sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit  } )
									end
								end
							end
						end
					elseif usedCard == self.duplicatedCard then
						local copycardOwner = self.abilityOwner:getUnitOwner()
						copycardOwner:getTraits().passiveKey = nil
						self.abilityOwner:getTraits().active = nil
						self.duplicatedCard = nil
						self.abilityOwner:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_OLD
						self.abilityOwner:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard.png"
						self.abilityOwner:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard.png"
						if copycardOwner:isValid() then
							sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = copycardOwner  } )
						end
					end
				end
			end
		end,
}

return scan_exitCard