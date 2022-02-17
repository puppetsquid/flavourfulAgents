local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )

------------------------------------------------------------------
--

local function checkLootCount( sim, safeUnit )
    local totalSafeCount, totalLooted = 0, 0
    for unitID, unit in pairs(sim:getAllUnits()) do
	    if unit:getTraits().safeUnit then
            totalSafeCount = totalSafeCount + 1
            if unit:getTraits().open then
                totalLooted = totalLooted + 1
            end
	    end
    end

    if totalLooted == totalSafeCount and not sim:getTags().isTutorial then
        -- Technically this only counts safes that were OPENED but not necessarily looted, but who cares?
        savefiles.winAchievement( cdefs.ACHIEVEMENTS.ATTENTION_TO_DETAIL )
    end
end


local inStorePickup =
	{
		name = STRINGS.UI.ACTIONS.SEARCH_SAFE.NAME,

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		onTooltip = abilityutil.onAbilityTooltip,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_loot_small.png",
		proxy = true,
		alwaysShow = true,
		ghostable = true,

		canUseAbility = function( self, sim, unit, userUnit )

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

			if unit:getPlayerOwner() ~= userUnit:getPlayerOwner() and unit:getTraits().mainframe_status == "active" and  not unit:getTraits().open then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			if unit:getPlayerOwner() ~= userUnit:getPlayerOwner() and unit:getTraits().security_box and unit:getTraits().security_box_locked==true  then 
				return false, STRINGS.UI.REASON.UNLOCK_WITH_VAULT_TERMINAL
			end			

			if userUnit:getTraits().isDrone then
				return false -- Drones have no hands to loot with
			end

			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			if not unit:getTraits().noOpenAnim then
				local sound = simdefs.SOUNDPATH_SAFE_OPEN

				if unit:getSounds().open_safe then
					sound = "SpySociety/Objects/securitysafe_open"
				end
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = userUnit:getID(), facing = facing, sound = sound, soundFrame = 1 } )
			else
				sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), targetID= unit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			end
				
            if unit:getTraits().open ~= true then
			    if not unit:getTraits().noOpenAnim then
				    unit:getTraits().open = true
			    end

			    unit:getTraits().mainframe_item = nil
									
			    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )

			    sim:getStats():incStat("safes_looted")
                checkLootCount( sim, unit )
            end
   
			-- Loot items within
			if #unit:getChildren() > 0 and (not sim:isVersion("0.17.6") or sim:getQuery().canSteal( sim, userUnit, unit )) then
				sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { targetUnit = unit, unit = userUnit } )
            else
		        local credits = unit:getTraits().credits
		        unit:getTraits().credits = nil
		        if credits and credits > 0 then
			        sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/gameplay/gain_money")
			        userUnit:getPlayerOwner():addCredits(credits, sim,x1,y1)
			        sim:emitSpeech( unit, speechdefs.EVENT_LOOT )
					sim._resultTable.credits_gained.safes = sim._resultTable.credits_gained.safes and sim._resultTable.credits_gained.safes + credits or credits				        
		        end
			end
            unit:checkOverload( sim )
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )				         
            sim:triggerEvent( simdefs.TRG_SAFE_LOOTED, { unit = userUnit, targetUnit = unit } )
		end,
	}
return inStorePickup