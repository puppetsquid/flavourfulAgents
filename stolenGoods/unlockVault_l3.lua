local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local inventory = include( "sim/inventory" )

------------------------------------------------------------------
--


local unlockVault_l3 =
	{
		name = "Unlock Tier 3 Draws",

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

				onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
	        section:addLine( "Unlock Tier 3 Draws" )
			section:addAbility( STRINGS.DETAINED.ITEMS.UNLOCK,
						STRINGS.DETAINED.ITEMS.UNLOCK_T3, "gui/items/icon-action_hack-console.png" )
			
			
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		profile_icon = "gui/items/icon-action_open-safe.png",
		proxy = true,
		alwaysShow = true,
		ghostable = true,

		canUseAbility = function( self, sim, unit, userUnit )

			if unit:getTraits().openedLevel3 then
				return false
			end
			
			if unit:getTraits().securityLevel and unit:getTraits().securityLevel < 3 then
				return false
			end
		
			if sim:isVersion("0.17.6") and ( not unit:getTraits().credits or unit:getTraits().credits <= 0 ) then		
				if not sim:getQuery().canSteal( sim, userUnit, unit ) then
					return false
				end
			end

			if not simquery.canUnitReach( sim, userUnit, unit:getLocation() ) then
				return false
			end

			if (unit:getTraits().credits or 0) == 0 and #unit:getChildren() == 0 then
				return false
			end	
			
			if userUnit:getTraits().isDrone then
				return false -- Drones have no hands to loot with
			end
			
			if not simquery.hasKey(userUnit, simdefs.DOOR_KEYS.VAULT) then
				return false, "Requires Vault Card"
			end
			
			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			unit:getTraits().openedLevel3 = true
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), targetID= unit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			
		--	unit:setPlayerOwner( sim:getPC() )					
		--	sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = unit, nosound = true} )	
		unit:getTraits().security_box_locked = false
			
			for i,invItem in ipairs(unit:getChildren())do
				if invItem:getTraits().vaultLocked == "Vault Keycard" then
					invItem:getTraits().vaultLocked = nil
				end
				if invItem:getTraits().vaultLocked == "Guard Keycard" then
					invItem:getTraits().vaultLocked = nil
				end
			end
	
			
			

	
			local originalCard = false
			local originalCardOwner = false
			local copyCard = false
			local copyCardOwner = false
			
			for i,item in ipairs(userUnit:getChildren()) do
				if simquery.isKey(item, simdefs.DOOR_KEYS.VAULT) then
					if item:getTraits().copy_card and not copyCard then 
						copyCard = item
						copyCardOwner = userUnit
						originalCard = item:getTraits().duplicatedCard
						originalCardOwner = originalCard:getUnitOwner()
					elseif not originalCard then
						originalCard = item
						originalCardOwner = userUnit
						if item:getTraits().originalKeyCard then
							copyCard = item:getTraits().originalKeyCard
							copyCardOwner = copyCard:getUnitOwner()
						end
					end
				end
			end
			
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
			
			
			
--[==[				for i,item in ipairs(userUnit:getChildren()) do
				if needClean then
					if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.VAULT) then
						if item:getTraits().copy_card then
							local origCard = item:getTraits().duplicatedCard
							local origOwner = origCard:getUnitOwner()
							inventory.trashItem( sim, origOwner, origCard )
							item:getTraits().active = nil
							item:getTraits().duplicatedCard = nil
							item:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_OLD
							item:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard.png"
							item:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard.png"
							needClean = false
						else
							for _, unit in pairs( sim:getAllUnits() ) do 
								for i,externalItem in ipairs(unit:getChildren())do
									if externalItem:getTraits().duplicatedCard and externalItem:getTraits().duplicatedCard = item then
										externalItem:getTraits().active = nil
										externalItem:getTraits().duplicatedCard = nil
										externalItem:getUnitData().name = STRINGS.FLAVORED.ITEMS.COPYCARD_OLD
										externalItem:getUnitData().profile_icon = "gui/icons/Flavour/icon-item_copycard.png"
										externalItem:getUnitData().profile_icon_100 = "gui/icons/Flavour/icon-item_copycard.png"
									end
								end
							end
							inventory.trashItem( self, userUnit, item )
							needClean = false
						end
					end
				end
			end
			
			
			
			if not originalcard or not copyCard then
				for _, unit2 in pairs( sim:getAllUnits() ) do
					if simquery.hasKey(unit2, simdefs.DOOR_KEYS.VAULT) then
						for i,item in ipairs(userUnit:getChildren()) do
							if simquery.isKey(item, simdefs.DOOR_KEYS.VAULT) then
								if item:getTraits().copy_card and not copyCard then 
									copyCard = item
									originalCardOwner = unit2
								elseif not originalCard then
									originalCard = item
									originalCardOwner = unit2
								end
							end
						end
					end
				end
			end
				
	]==]--		
			
			
			
			
		end,
	}
return unlockVault_l3