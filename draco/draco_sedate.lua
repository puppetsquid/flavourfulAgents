local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )



local function isShootTarget( self, sim, abilityOwner, abilityUser, targetUnit )
	if not simquery.isShootable( abilityUser, targetUnit ) then
        return false
    end
    if not sim:canPlayerSeeUnit( abilityUser:getPlayerOwner(), targetUnit ) then
        return false
    end
	if not targetUnit:getTraits().canKO then
		return false
	end
	
    return true
end


local draco_sedate =
	{
		name = STRINGS.ABILITIES.PARALYZE,
	--[==[	createToolTip = function( self, sim, abilityOwner )
				return abilityutil.formatToolTip(STRINGS.ABILITIES.PARALYZE, util.sformat(STRINGS.ABILITIES.PARALYZE_DESC,abilityOwner:getTraits().koTime), simdefs.DEFAULT_COST)
		end,
	]==]
		createToolTip = function( self,sim,abilityOwner,abilityUser,targetID)
			local target = sim:getUnit(targetID)
			if target:isKO() then
				return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_HINT_KILL, STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_DESC_KILL )				
			else
				return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_HINT_KO, util.sformat(STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_DESC_KO,abilityOwner:getTraits().koTime), simdefs.DEFAULT_COST)
			end
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_prototype_injector_small.png",

		alwaysShow = true,
        proxy = true,
		usesAction = true,

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.PARALYZE
		end,

		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
                if isShootTarget( self, sim, unit, userUnit, targetUnit) then 

					local x1,y1 = targetUnit:getLocation()
					local distance =  mathutil.dist2d( x0, y0, x1, y1 )
					local maxRange = 1 -- 3 + (((userUnit:getSkillLevel("inventory"))-1) * 1.5)

    				if sim:canPlayerSeeUnit( userUnit, targetUnit ) and distance <= 1 then
						table.insert( units, targetUnit )
		--[==[			else 
						for _, cameraUnit in pairs(sim:getAllUnits()) do 
							if cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) and distance <= maxRange then -- peek thru doors
								table.insert( units, targetUnit )
                               break
							end
						end
		]==]
					end
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		canUseAbility = function( self, sim, unit, userUnit, targetUnitID )
		--[==[	local abilitydefs = include( "sim/abilitydefs" )
			local oldMelee = abilitydefs.lookupAbility("melee")

			local oldCanUseAbility = oldMelee.canUseAbility
			
			local ok, reason = oldCanUseAbility( self, sim, userUnit, userUnit, targetUnitID )
				if not ok then
					return false, reason
				end
			]==]
			-- Must have a user owner.
			local userUnit = unit:getUnitOwner()
			if not userUnit or not unit:getTraits().equipped then
				return false
			end
			-- Must have a KO target in range
			local cell = sim:getCell( userUnit:getLocation() )
			local units = {}

			if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
			end
			
			if unit:getTraits().ammo and unit:getTraits().ammo < 1 then
				return false, STRINGS.UI.REASON.CHARGES
			end
			
			local targetUnit = nil
			if targetUnitID then
				targetUnit = sim:getUnit( targetUnitID )
			end
			
			if targetUnit and targetUnit:getTraits().armor then
				return false, "Armor too thick"
			end
			
			
			
			if targetUnit then
				local x0, y0 = userUnit:getLocation()
				local x1, y1 = targetUnit:getLocation()
				local raycastX, raycastY = self._sim:getLOS():raycast(x0, y0, x1, y1)			
				if not (raycastX == x1 and raycastY == y1) then
					return false, "Blocked"
				end
				local distance = mathutil.dist2d( x0, y0, x1, y1 )
				if distance > 1 then
					return false
				end
				if targetUnit:getTraits().koTimer and ((x0 ~= x1) or (y0 ~= y1)) then
					return false
				end
			end
			
			if unit:getTraits().pwrCost then
				if unit:getPlayerOwner():getCpus() < unit:getTraits().pwrCost then
					return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
				end
			end

			if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
		
            local ok, reason = abilityutil.checkRequirements( unit, userUnit )
            if not ok then
                return false, reason
            end
			
			if userUnit:getAP() < 1 then 
				return false, STRINGS.UI.HUD_ATTACK_USED
			end 


			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )

			local userUnit = unit:getUnitOwner()
			local target = sim:getUnit(target)	

			local x0,y0 = userUnit:getLocation()
			local x1, y1 = target:getLocation()
			local distance = mathutil.dist2d( x0, y0, x1, y1 )
			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )	
			
			if distance > 1 then
			--	sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
			--	inventory.giveItem( userUnit, target, unit )  -- ( unit, targetUnit, item )
				
			elseif distance > 0 then
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = facing } )	
			else
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = userUnit:getFacing() } )	
			end
			
		--	target:processEMP( 1 )
			
			if target:getTraits().koTimer then
				target:killUnit(sim)
			else
				target:setKO(sim, unit:getTraits().koTime)
			end
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.PARALYZED,x=x0,y=y0,color={r=1,g=1,b=0,a=1}} )
			
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )

			if unit:getTraits().disposable then 
				inventory.trashItem( sim, userUnit, unit )
			else
				inventory.useItem( sim, userUnit, unit )
			end
			
	--		if distance > 1 then
	--			inventory.giveItem( userUnit, target, unit )  -- ( unit, targetUnit, item )
	--		end

			if userUnit:isValid() then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
			end
			
			userUnit:useAP( sim )

			sim:triggerEvent( simdefs.TRG_UNIT_PARALYZED )
		end,
	}
return draco_sedate