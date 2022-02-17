local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local guarddefs = include("sim/unitdefs/guarddefs")

local function isKO( unit )
    return unit:isKO()
end

local function isNotKO( unit )
    return not unit:isKO()
end

local function canAbandon( unit )
    return not unit:getTraits().cant_abandon
end

local prism_combatdisguise = 
	{
		name = STRINGS.ABILITIES.DISGUISE,
		
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			local cloakAug = self.cloakAug
			local cost = cloakAug:getTraits().chargeCost
			return abilityutil.formatToolTip ( STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_USE, util.sformat( STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_USE_TIP, cost ) )
		end, 

		profile_icon = "gui/icons/Flavour/icon-item_dermalHolo_small.png",
		alwaysShow = true,
		getName = function( self, sim, abilityOwner )
			if abilityOwner and abilityOwner:getTraits().disguiseOn then
				return STRINGS.ABILITIES.DISGUISE_DEACTIVATE
			--	local name = self.abilityOwner:getName()
			--	return name
			else
				return STRINGS.ABILITIES.DISGUISE
			end
		end,

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnit )
			-- Must have a user owner.
			--local userUnit = unit:getUnitOwner()
			if not abilityOwner then
				return false
			end
			
			if not abilityOwner:getTraits().disguiseOn and abilityOwner:getTraits().mpMax == 0 then
				return false, "Cannot be used at 0MaxAP"
			end
			
	--		local hasAugment = array.findIf( unit:getChildren(), function( u ) return u:getTraits().charges_clip ~= nil end )  ----- check for AUG
	--		if not hasAugment then 
	--			return false, STRINGS.UI.REASON.NO_POWER_PACK
	--		end

	--		if not abilityOwner:getTraits().disguiseOn then
	--		local cloakAug = self.cloakAug
	--			if cloakAug:getTraits().charges < cloakAug:getTraits().chargeCost then
	--				return false,  STRINGS.FLAVORED.ITEMS.AUGMENTS.NOT_ENOUGH_CHARGE
	--			end		
	--		end
					
			return abilityutil.checkRequirements( unit, abilityOwner )
		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			
			local abilityOwner = self.abilityOwner
			for i,childAug in ipairs(abilityOwner:getChildren( )) do
				if childAug:getTraits().isCombatCloak then
					self.cloakAug = childAug
				end
			end
			local cloakAug = self.cloakAug
			cloakAug:getTraits().usesCharges = true
			
			sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
			if sim:isVersion("0.17.7") then
				sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			end
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			sim:addTrigger( simdefs.TRG_ALARM_INCREASE, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
			if sim:isVersion("0.17.7") then
				sim:removeTrigger( simdefs.TRG_END_TURN, self )
			end
			sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:removeTrigger( simdefs.TRG_ALARM_INCREASE, self )
			self.cloakAug = nil
			self.abilityOwner = nil
		end,

		--[==[ old ontrigger
		onTrigger = function ( self, sim, evType, evData )  -- need to get this working

			if evType == simdefs.TRG_UNIT_WARP or evType == simdefs.TRG_UNIT_USEDOOR then
				local abilityOwner = self.abilityOwner

				if abilityOwner and abilityOwner:getTraits().disguiseOn then

					local enemyUnit, range = sim:getQuery().getNearestEnemy( abilityOwner )
				   
					if range <=1.5 then
						abilityOwner:setDisguise(false)	
						abilityOwner:interruptMove( sim ) 		
					end

				end
			elseif evType == simdefs.TRG_START_TURN then
				local abilityOwner = self.abilityOwner
				local player = abilityOwner:getPlayerOwner()
				local cloakAug = self.cloakAug

				if player and sim:getCurrentPlayer() == player and abilityOwner:getTraits().disguiseOn  then
					local x,y abilityOwner:getLocation()
					if cloakAug:getTraits().charges >= cloakAug:getTraits().chargesPerTurn then
						--player:addCPUs( -2, sim, x,y )
						cloakAug:getTraits().charges = (cloakAug:getTraits().charges - cloakAug:getTraits().chargesPerTurn)
						sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat( STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_WARNING,cloakAug:getTraits().chargesPerTurn), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=nil } )
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_MINUS_CHARGE, cloakAug:getTraits().chargesPerTurn), unit = abilityOwner,  color={r=163/255,g=243/255,b=248/255,a=1} })
					else
						abilityOwner:setDisguise(false)
					end
				end
			elseif evType == simdefs.TRG_ALARM_INCREASE then
				local abilityOwner = self.abilityOwner
				local cloakAug = self.cloakAug
				local oldcharges = cloakAug:getTraits().charges
				local lastTrack = cloakAug:getTraits().lastTracker
				local currentTrack = sim:getTracker()
				
				if currentTrack > lastTrack and (cloakAug:getTraits().charges < cloakAug:getTraits().chargesMax) then
					cloakAug:getTraits().charges = math.min(oldcharges + (currentTrack - lastTrack), 10)
					
					local fromCell = sim:getCell( abilityOwner:getLocation() )
					local x0,y0 = fromCell.x, fromCell.y
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_PLUS_CHARGE, (currentTrack - lastTrack)), unit = abilityOwner, color= cdefs.MOVECLR_DEFAULT })
				end
				cloakAug:getTraits().lastTracker = currentTrack
			end
		end,
		]==]
		
		onTrigger = function ( self, sim, evType, evData ) 

			if evType == simdefs.TRG_UNIT_WARP or evType == simdefs.TRG_UNIT_USEDOOR then
				local abilityOwner = self.abilityOwner

				if abilityOwner and abilityOwner:getTraits().disguiseOn then

					local enemyUnit, range = sim:getQuery().getNearestEnemy( abilityOwner )
				   
					if range <=1.5 then
					--	abilityOwner:setDisguise(false)	
					--	abilityOwner:getTraits().mp = abilityOwner:getTraits().mp - 1
					--	sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat( STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_WARNING,1), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=nil } )
					--	abilityOwner:interruptMove( sim ) 		
					--	enemyUnit:interruptMove( sim ) 		
					end

				end
			elseif evType == simdefs.TRG_END_TURN then
				local abilityOwner = self.abilityOwner
				local player = abilityOwner:getPlayerOwner()
				local cloakAug = self.cloakAug

				if player and sim:getCurrentPlayer() == player then
					local x,y abilityOwner:getLocation()
					
					if cloakAug:getTraits().wasUsedThisTurn or abilityOwner:getTraits().disguiseOn == true then
						cloakAug:getTraits().wasUsedThisTurn = false
						cloakAug:getTraits().traitModAmmnt = math.min((cloakAug:getTraits().traitModAmmnt + 2), 7 + abilityOwner:getSkillLevel("stealth") ) -- get lower value
						
					--		cloakAug:getTraits().modTrait = {{ "mpMax", modifier }}
						if abilityOwner:getTraits().mpMax == 0 then
							if abilityOwner:getTraits().disguiseOn then
							--	abilityOwner:setKO(sim, cloakAug:getTraits().charges)
								abilityOwner:setDisguise(false)
							--	cloakAug:getTraits().isActive = false
							end
						else	

							abilityOwner:getTraits().mpMax = abilityOwner:getTraits().mpMax - 2
							if abilityOwner:getTraits().mpMax < 0 then
								abilityOwner:getTraits().mpMax = 0
							end
							abilityOwner:getTraits().mp = abilityOwner:getTraits().mpMax
						
							cloakAug:getTraits().charges = (cloakAug:getTraits().traitModAmmnt)
							cloakAug:getTraits().chargesMax = (7 + abilityOwner:getSkillLevel("stealth"))
							sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat( STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_WARNING,cloakAug:getTraits().traitModAmmnt), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=nil } )
							sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_MINUS_CHARGE, cloakAug:getTraits().traitModAmmnt), unit = abilityOwner,  color={r=163/255,g=243/255,b=248/255,a=1} })
						end
					end
					if not abilityOwner:getTraits().disguiseOn and not cloakAug:getTraits().wasActivatedThisTurn then -- cloakAug:getTraits().wasUsedThisTurn or
						cloakAug:getTraits().traitModAmmnt = math.max((cloakAug:getTraits().traitModAmmnt - 1), 0 ) -- get higher value

							abilityOwner:getTraits().mpMax = abilityOwner:getTraits().mpMax + 1
							cloakAug:getTraits().charges = (cloakAug:getTraits().traitModAmmnt)
							cloakAug:getTraits().chargesMax = (7 + abilityOwner:getSkillLevel("stealth"))
							if abilityOwner:getTraits().mpMax > 7 + abilityOwner:getSkillLevel("stealth") then
								abilityOwner:getTraits().mpMax = 7 + abilityOwner:getSkillLevel("stealth")
							end
							abilityOwner:getTraits().mp = abilityOwner:getTraits().mpMax -- need to set MP now so it takes effect for next turn
					end
					
					cloakAug:getTraits().wasActivatedThisTurn = nil
				end
			end
		end,

		
		
		
		executeAbility = function( self, sim, abilityOwner )
			--local userUnit = unit:getUnitOwner()
			local cloakAug = self.cloakAug
			
			if abilityOwner:getTraits().disguiseOn then
				abilityOwner:setDisguise(false)
			--	cloakAug:getTraits().isActive = false
				cloakAug:getTraits().wasUsedThisTurn = true
			else

				local kanim = "kanim_guard_male_ftm"
				local kanim = "kanim_guard_male_enforcer_2"
				local wt = util.weighted_list( sim._patrolGuard )	

				for i = 2, #wt, 2 do
					local template = guarddefs[wt[i]]
					if not template.traits.isDrone then
					--	kanim = template.kanim							
					end

				end
 				
				abilityOwner:setDisguise(true, kanim)
				cloakAug:getTraits().wasActivatedThisTurn = true
				--abilityOwner:getPlayerOwner():addCPUs( -2 )
				
		--		cloakAug:getTraits().charges = (cloakAug:getTraits().charges - cloakAug:getTraits().chargeCost)
				
		--		cloakAug:getTraits().wasUsedThisTurn = true
		--		cloakAug:getTraits().isActive = true
		--		cloakAug:getTraits().traitModAmmnt = (cloakAug:getTraits().traitModAmmnt - 2)
		--		cloakAug:getTraits().modTrait = {{"mpMax",-1}},	
				
		--		local fromCell = sim:getCell( abilityOwner:getLocation() )
		--		local x0,y0 = fromCell.x, fromCell.y
		--		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_MINUS_CHARGE, cloakAug:getTraits().chargeCost), unit = abilityOwner,  color={r=163/255,g=243/255,b=248/255,a=1} })
			
				if sim:canPlayerSeeUnit( sim:getNPC(), abilityOwner ) then 
					abilityOwner:setDisguise(false)
				end

				abilityOwner:resetAllAiming()
	
				--inventory.useItem( sim, abilityOwner, unit )
			end
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = abilityOwner  } )

		--	sim:processReactions(abilityOwner)			

		end,
		
		confirmAbility = function( self, sim, ownerUnit )
			-- Check to see if escaping would leave anyone behind, and there is nobody remaining in the level.
        --    local fieldUnits, escapingUnits = simquery.countFieldAgents( sim )

            -- A partial escape means someone alive is left on the field.
            if not ownerUnit:getTraits().disguiseOn then
				return "This will reduce this agent's MaxAP by 2 next turn." --STRINGS.UI.HUD_CONFIRM_PARTIAL_ESCAPE			
			end

		end,
	}
return prism_combatdisguise
