local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local use_injection = include( "sim/abilities/use_injection" )
local inventory = include("sim/inventory")
local animmgr = include( "anim-manager" )
local simfactory = include( "sim/simfactory" )

local shalem_healCorpse = util.extend( use_injection )
	{
		name = STRINGS.ABILITIES.REVIVE,
		proxy = 1,
		createToolTip = function(  self,sim, abilityOwner, abilityUser, targetID )

			local targetUnit = sim:getUnit(targetID)
			return abilityutil.formatToolTip(string.format(STRINGS.ABILITIES.REVIVE_NAME,targetUnit:getName()), string.format(STRINGS.ABILITIES.REVIVE_DESC,abilityOwner:getName()), simdefs.DEFAULT_COST)
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_medigel_small.png",
		usesMP = true,

		isTarget = function( self, sim, userUnit, targetUnit )
		--	local isKOed =  --and not simquery.isSameLocation( userUnit, targetUnit ))
			local isSameTeam = userUnit:getPlayerOwner() == targetUnit:getPlayerOwner()			
			
			if targetUnit == nil or targetUnit:isGhost() then
				return false
			end

			if not userUnit:canAct() then
				return false
			end

			local animdef = animmgr.lookupAnimDef( targetUnit:getUnitData().kanim )
			if animdef == nil or animdef.grp_build == nil then
				return false
			end

			if targetUnit:getTraits().notDraggable then 
				return false 
			end 

			if not targetUnit:getTraits().iscorpse then 
				return false
			end
			
			if isSameTeam then
				return false
			end

			return true
		end,
		
		canUseAbility = function( self, sim, abilityOwner, userUnit, targetUnitID )

			if not simquery.isAgent( userUnit ) then
				return false
			end
			if abilityOwner:getUnitOwner() ~= userUnit then
				return false
			end
			if targetUnitID then
				if not self:isTarget( sim, userUnit, sim:getUnit( targetUnitID ) ) then
					return false
				end

			else
				local units = self:findTargets( sim, abilityOwner, userUnit )
				if #units == 0 then
					return false, STRINGS.UI.REASON.NO_INJURED_TARGETS
				end
			end
			
			if userUnit:getTraits().mp < 1 then
				return false, "No MP"
			end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false,  util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end
			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end			

			return abilityutil.checkRequirements( abilityOwner, userUnit )
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )
			local oldFacing = userUnit:getFacing()
			local target = sim:getUnit(target)	
			local newFacing = userUnit:getFacing()
			local revive = false


			if target ~= userUnit then
				local x0,y0 = userUnit:getLocation()
				local x1,y1 = target:getLocation()
				newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 
				if target:isKO() then
					revive = true
				end
			end

			sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = false, facing = newFacing } )
			
			self:doInjection( sim, unit, userUnit, target )

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )

			if unit:getTraits().disposable then 
				inventory.trashItem( sim, userUnit, unit )
			else
				inventory.useItem( sim, userUnit, unit )
			end
		end,

		doInjection = function( self, sim, unit, userUnit, corpseUnit )
			local x1,y1 = corpseUnit:getLocation()
			
			local npc_templates = include("sim/unitdefs/guarddefs")
		
			local livingUnit = nil	
			local corpseTemplate = nil
			
			log:write( "Begin Cropse Bride" )
			
			for _,template in pairs(npc_templates) do
				log:write( "testing " .. template.name )
				local corpseName = string.format(STRINGS.UI.CORPSE_OF, template.name )
				if corpseName == corpseUnit:getName() and template.kanim == corpseUnit:getUnitData().kanim then
				
					log:write( "MATCHED " .. corpseName .. " with kanim " .. template.kanim )
				
					corpseTemplate = util.extend( template )
					{
						name = ( "Revived " .. template.name ),
					}
									
				
				end
			end
			
			if corpseTemplate then
			
				livingUnit = simfactory.createUnit( corpseTemplate, sim )
				
				livingUnit:getTraits().unitID = corpseUnit:getID() -- Track the original unit ID, for scoring.
				livingUnit:getTraits().cashOnHand = corpseUnit:getTraits().cashOnHand
				if corpseUnit:getTraits().PWROnHand then
					livingUnit:getTraits().PWROnHand = corpseUnit:getTraits().PWROnHand
				end
				livingUnit:getTraits().notDraggable = corpseUnit:getTraits().notDraggable
		--		livingUnit:getTraits().mpMax = livingUnit:getTraits().mpMax / 2

				livingUnit:getTraits().neural_scanned = corpseUnit:getTraits().neural_scanned 
				
				if sim:getCleaningKills() >= 1 and livingUnit:getTraits().cleanup then
					sim:addCleaningKills( -1 )
					livingUnit:getTraits().cleancorpse = true
				end
				
				sim:spawnUnit( livingUnit )
				
				livingUnit:getTraits().heartMonitor = "disabled"
				if livingUnit:getTraits().improved_heart_monitor then 
					livingUnit:getTraits().improved_heart_monitor = nil
				end 
				if livingUnit:getTraits().consciousness_monitor then 
					livingUnit:getTraits().consciousness_monitor = nil
				end 
				
				livingUnit:setPlayerOwner( sim:getNPC() )
				
				livingUnit:getTraits().corpseCell = sim:getCell( corpseUnit:getLocation() )
				livingUnit:getTraits().corpseFacing = corpseUnit:getFacing()
				
			
				sim:warpUnit( corpseUnit, nil )
				log:write( "spawned " .. livingUnit:getName() )
				sim:warpUnit( livingUnit, livingUnit:getTraits().corpseCell, livingUnit:getTraits().corpseFacing )
				
				livingUnit:setKO( sim, 20 )
				sim:getPC():glimpseUnit(sim, livingUnit)
				
				inventory.giveAll( corpseUnit, livingUnit )
				
				livingUnit:getTraits().koTimer = 999
				
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = livingUnit  } )
				
				
				
				
				
				if sim._resultTable.guards[livingUnit:getID()] then
					sim._resultTable.guards[livingUnit:getID()].alerted = true
					sim._resultTable.guards[livingUnit:getID()].ko = true
				end
				
				

				-- Final removal.
				sim:despawnUnit( corpseUnit )
			--	sim:emitSpeech( corpseUnit, speechdefs.EVENT_REVIVED )
			
				userUnit:getTraits().mp = userUnit:getTraits().mp - 1
				
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = livingUnit  } )
			end
			
		end,

	}
return shalem_healCorpse
