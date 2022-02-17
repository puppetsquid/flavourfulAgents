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


local unlockVault_l2 =
	{
		name = "Unlock Tier 2 Draws",

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
	        section:addLine( "Unlock Tier 2 Draws" )
			section:addAbility( STRINGS.DETAINED.ITEMS.UNLOCK,
						STRINGS.DETAINED.ITEMS.UNLOCK_T2, "gui/items/icon-action_hack-console.png" )
			
			
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

			if unit:getTraits().openedLevel2 or unit:getTraits().openedLevel3 then
				return false
			end
			
	--		if unit:getTraits().securityLevel and unit:getTraits().securityLevel < 2 then
	--			return false
	--		end
		
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
			
			if not simquery.hasKey(userUnit, simdefs.DOOR_KEYS.GUARD) then
				return false, "Requires Guard Keycard"
			end

	--[==[		for i,item in ipairs(userUnit:getChildren()) do
				if (item:getTraits().keybits and item:getTraits().keybits == "DetainVault") then -- item:getTraits().copy_card
					return true
				else
					return false, "Requires Contraband Keycard"
				end
			end
		]==]
			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			unit:getTraits().openedLevel2 = true
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), targetID= unit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			
			--unit:setPlayerOwner( sim:getPC() )					
			--sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = unit, nosound = true} )	
			unit:getTraits().security_box_locked = false
			
			for i,invItem in ipairs(unit:getChildren())do
				if invItem:getTraits().vaultLocked == "Guard Keycard" then
					invItem:getTraits().vaultLocked = nil
				end
			end
			
			--[==[
			local copyCard = false
			local guardCard = false
			local usedCard = nil
			
			for i,item in ipairs(userUnit:getChildren()) do
				if simquery.isKey(item, simdefs.DOOR_KEYS.GUARD) then
					if item:getTraits().copy_card and not copyCard then 
						copyCard = true
						guardCard = false
						usedCard = item
					elseif not copyCard then
						guardCard = true
						usedCard = item
					end
				end
			end
			
			if copyCard then
					sim:triggerEvent( "trashCard", {targetCard=usedCard,} )
			elseif guardCard then
				inventory.trashItem( sim, usedCard:getUnitOwner(), usedCard )
			end
			]==]
			
		end,
	}
return unlockVault_l2