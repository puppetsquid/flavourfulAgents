local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )

------------------------------------------------------------------
--



local unlockVault_l1 =
	{
		name = "Unlock Tier 1 Draws",

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
	        section:addLine( "Unlock Tier 1 Draws" )
			section:addAbility( STRINGS.DETAINED.ITEMS.UNLOCK,
						STRINGS.DETAINED.ITEMS.UNLOCK_T1, "gui/items/icon-action_hack-console.png" )
			
			
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

			if unit:getTraits().openedLevel1 or unit:getTraits().openedLevel2 or unit:getTraits().openedLevel3 then
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

			if not simquery.hasKey(userUnit, simdefs.DOOR_KEYS.SECURITY) then
				return false, "Requires Security Card"
			end
			
		--[==[	for i,item in ipairs(userUnit:getChildren()) do
				if (item:getTraits().keybits and item:getTraits().keybits == simdefs.DOOR_KEYS.SECURITY) then -- item:getTraits().copy_card
					return true
				elseif not (userUnit:getTraits().keybits and userUnit:getTraits().keybits == simdefs.DOOR_KEYS.SECURITY) then
					return false, "Requires Security Card"
				end
			end
		]==]
			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			unit:getTraits().openedLevel1 = true
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
	
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), targetID= unit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			
		--	unit:setPlayerOwner( sim:getPC() )					
		--	sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = unit, nosound = true} )	
			unit:getTraits().security_box_locked = false
		end,
	}
return unlockVault_l1