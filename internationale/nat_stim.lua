local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )

local banks_paralyze =
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
			local userCell = sim:getCell( userUnit:getLocation() )
			local x0, y0 = userUnit:getLocation()

			local units = {}
			local maxRange = 4 + ((userUnit:getSkillLevel("inventory")) * 1.5)
			
			local cells = {userCell}
			if maxRange then
				local coords = simquery.rasterCircle( self._sim, x0, y0, maxRange )

				for i=1,#coords-1,2 do
					local cell = self._sim:getCell(coords[i],coords[i+1])
					if cell then
					local raycastX, raycastY = self._sim:getLOS():raycast(x0, y0, cell.x, cell.y)			
						if raycastX == cell.x and raycastY == cell.y then
							table.insert(cells, cell)
							for i,cellUnit in ipairs(cell.units) do
								if (simquery.isAgent(cellUnit) and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then
									table.insert( units, cellUnit )
								end
							end
						end			
					end
				end
			end
				
	--[==[		for i,cellUnit in ipairs(cell.units) do
			--	if (cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then
				if (not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and not cellUnit:getTraits().isDrone then
					table.insert( units, cellUnit )
				end
			end]==]

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

	--[==[	for i,cellUnit in ipairs(cell.units) do
			--	if (cellUnit:isKO() and not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and cellUnit:getTraits().canKO then
				if (not cellUnit:isDead()) and cellUnit:getPlayerOwner() ~= userUnit:getPlayerOwner() and cellUnit:getTraits().canKO then
					table.insert( units, cellUnit )
				end
			end					

			if #units < 1 then
				return false, STRINGS.UI.REASON.NO_VIABLE_TARGET
			end]==]	

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
				sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = target, target = target, revive = false, facing = target:getFacing() } )	
			else
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = userUnit:getFacing() } )	
			end
			
			self:doInjection( sim, unit, userUnit, target )
			
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )

			if unit:getTraits().disposable then 
				inventory.trashItem( sim, userUnit, unit )
			else
				inventory.useItem( sim, userUnit, unit )
			end
			
			if distance > 1 then
				inventory.giveItem( userUnit, target, unit )  -- ( unit, targetUnit, item )
			end

			if userUnit:isValid() then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
			end

			sim:triggerEvent( simdefs.TRG_UNIT_PARALYZED )
		end,
	
		doInjection = function( self, sim, unit, userUnit, target )
			local x1,y1 = target:getLocation()
			if target:isKO() then
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.REVIVED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )

				target:setKO( sim, nil )

				sim:emitSpeech( target, speechdefs.EVENT_REVIVED )
			end
 			
			if unit:getTraits().combatRestored then 
				target:getTraits().ap = target:getTraits().apMax	
			end 

			if unit:getTraits().unlimitedAttacks then
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.AMPED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} ) 
				target:getTraits().ap = target:getTraits().apMax
				target:getTraits().unlimitedAttacks = true
			end 

			target:getTraits().mp =target:getTraits().mp + unit:getTraits().mpRestored

			sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = userUnit } )
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.MOVEMENT_BOOSTED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
			
			if not sim:isVersion("0.17.5") then
				inventory.useItem( sim, userUnit, unit )
			end

			local cnt, augments = target:countAugments( "augment_subdermal_cloak" )
			if cnt > 0 then
				local pwrCost = augments[1]:getTraits().pwrCost
				if target:getPlayerOwner():getCpus() >= pwrCost then
					target:setInvisible(true, 1)	
		    		target:getPlayerOwner():addCPUs( -pwrCost, sim, x1, y1)	
		    	end
			end

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )
		end,
	}
return banks_paralyze