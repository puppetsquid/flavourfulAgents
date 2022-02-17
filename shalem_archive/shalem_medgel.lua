local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local use_injection = include( "sim/abilities/use_injection" )
local inventory = include("sim/inventory")

local shalem_medgel = util.extend( use_injection )
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
			local pinning, pinnee = simquery.isUnitCellFull(sim, targetUnit)			
		--	return (targetUnit:isKO() and isSameTeam) or (targetUnit:getTraits().iscorpse and not isSameTeam and not targetUnit:getTraits().cleancorpse) and not simquery.isUnitDragged( sim, targetUnit ) 
			return (targetUnit:isKO() and isSameTeam) and (pinnee == userUnit) and not simquery.isUnitDragged( sim, targetUnit ) 
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
			
			if userUnit:getTraits().mp < userUnit:getTraits().mpMax then
				return false, STRINGS.UI.REASON.MUST_TOGGLE_BEFORE_MP
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

		doInjection = function( self, sim, unit, userUnit, target )
			local x1,y1 = target:getLocation()
		--	if target:isKO() then
				local isSameTeam = userUnit:getPlayerOwner() == target:getPlayerOwner()	
				
				if isSameTeam then
					if target:isDead() then
						assert( target:getWounds() >= target:getTraits().woundsMax ) -- Cause they're dead, should have more wounds than max
						target:getTraits().dead = nil
						target:addWounds( target:getTraits().woundsMax - target:getWounds() - 1 )			
					end
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt="Reviving...",x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
					target:setKO( sim, 1 ) 
					target:getTraits().koTimer = 1
					target:getTraits().mp = math.max( 0, target:getMPMax() - (target:getTraits().overloadCount or 0) )
					self.medGelUsed = true
					self.targetUnit = target
				else
					if sim:getCleaningKills() >= 1 then  ---- safe to assume that target requires cleanup but just in case
						sim:addCleaningKills( -1 ) 
						target:getTraits().cleancorpse = true
						target:setKO( sim, 99 )
					end
				end
				sim:emitSpeech( target, speechdefs.EVENT_REVIVED )
		--	end
			userUnit:getTraits().mp = 0
			userUnit:useAP( sim )
		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			self.medGelUsed = nil
			self.targetUnit = nil
			sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
			self.abilityOwner = nil
			self.medGelUsed = nil
			self.targetUnit = nil
		end,
		
		onTrigger = function( self, sim, evType, evData )
			if self.medGelUsed and self.targetUnit  and self.abilityOwner and evData.unit == self.abilityOwner:getUnitOwner() and evData.unit:getPlayerOwner() and evData.to_cell then
				local target = self.targetUnit 
				self.medGelUsed = nil
				self.targetUnit = nil
				self.abilityOwner:getUnitOwner():interruptMove( sim, self.abilityOwner:getUnitOwner() )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.abilityOwner:getUnitOwner()  } )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target  } )
				target:setKO( sim, nil )
			end
		end,
	}
return shalem_medgel
