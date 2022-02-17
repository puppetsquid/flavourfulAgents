local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )
local serverdefs = include( "modules/serverdefs" )
local simfactory = include( "sim/simfactory" )
local itemdefs = include("sim/unitdefs/itemdefs")
local senses = include( "sim/btree/senses" )



local prism_allytagger =
	{
		name = STRINGS.ABILITIES.SHOOT,

		
		profile_icon = "gui/icons/Flavour/icon-item_tag_ally_small.png",		
		usesAction = true,
		proxy = true,

		getName = function( self, sim, ownerUnit, userUnit, targetUnitID )
			
			local txt = STRINGS.ABILITIES.SHOOT

			if targetUnitID then
					local target = sim:getUnit(targetUnitID)

				local x0,y0 = userUnit:getLocation()
				local x1,y1 = target:getLocation()	
				local shotangle =math.atan2( y1 - y0, x1 - x0)

				local viewAngle = target:getFacingRad()

				local viewDiff = math.abs(mathutil.angleDiff( viewAngle, shotangle ))	

				local target = sim:getUnit(targetUnitID)
				if target:isKO() then
					if target:isDead() then
						return txt..string.format(STRINGS.ABILITIES.SHOOT_DYING,target:getTraits().koTimer)
					else
						return txt..string.format(STRINGS.ABILITIES.SHOOT_KO,target:getTraits().koTimer)
					end
				end
				return txt
			end
			return STRINGS.ABILITIES.SHOOT
		end,

		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip( STRINGS.FLAVORED.ITEMS.ALLYTAGGER_INFIELD_TAG,  STRINGS.FLAVORED.ITEMS.ALLYTAGGER_INFIELD_TAG_DESC, 1 )
		end,


		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
						local x1,y1 = targetUnit:getLocation()
							if x1 and targetUnit:getTraits().isAgent == true and targetUnit ~= userUnit and not targetUnit:getTraits().isGuard and not targetUnit:getTraits().isKO then 
								local distance = mathutil.dist2d( x0, y0, x1, y1 )

								if unit:getTraits().xray or sim:canUnitSeeUnit( userUnit, targetUnit )then -- or distance <= 12 
									table.insert( units, targetUnit )
								end
						end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		canUseAbility = function( self, sim, ownerUnit, unit, targetUnitID )
			local weaponUnit = simquery.getEquippedGun( unit )
            if ownerUnit ~= weaponUnit and ownerUnit ~= unit then
				return false
			end

            local ok, reason = abilityutil.canConsumeAmmo( sim, weaponUnit )
            if not ok then
                return false
            end

            if weaponUnit:getTraits().usesCharges and weaponUnit:getTraits().charges < 1 then
            	return false
            end

			if unit:getAP() < 1 and not unit:isNPC() then 
				return false
			end

			local targetUnit = sim:getUnit( targetUnitID )
			if targetUnit and not ownerUnit:getTraits().xray and not sim:canUnitSeeUnit( unit, targetUnit ) then
                return false
            end

			return true
		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
		--	sim:addTrigger( simdefs.TRG_UNIT_WARP, self)
			sim:addTrigger( simdefs.TRG_START_TURN, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
		--	sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			self.abilityOwner = nil
		end,
		
		onTrigger = function( self, sim, evType, evData )
		
			
			if evType == simdefs.TRG_START_TURN then 
				if evData == sim:getCurrentPlayer() and evData:isPC() then
					sim:forEachUnit(
						function ( sleeperUnit )
							local x1, y1 = sleeperUnit:getLocation()
							if x1 and y1 and sleeperUnit:getTraits().isOnlySleeping and sleeperUnit:getTraits().isOnlySleeping then
					--			sleeperUnit:getTraits().isOnlySleeping = sleeperUnit:getTraits().isOnlySleeping - 1
					--			sleeperUnit:getTraits().isAgent = true  --- is only 'agent' on player turns 'cause AI's bugged
								sleeperUnit:getTraits().forceNeutral = true
							end
							if x1 and y1 and sleeperUnit:getTraits().isOnlySleeping and not sleeperUnit:isKO() then  --- just in case
							--	targetUnit:getTraits().invisible = false
							--	sleeperUnit:getTraits().isAgent = true	
								sleeperUnit:getTraits().forceNeutral = nil
								sleeperUnit:getTraits().isOnlySleeping = nil
								sleeperUnit:getTraits().disguiseOn = false
								sim:processReactions( sleeperUnit ) -- in case they wake up in LOS
							end
						end
					)
				else	
					sim:forEachUnit(
						function ( sleeperUnit )
							local x1, y1 = sleeperUnit:getLocation()
							if x1 and y1 and sleeperUnit:getTraits().isOnlySleeping and sleeperUnit:isKO() then
							--	sleeperUnit:getTraits().isAgent = nil								---- so this is horrible but nothing else works?
								sleeperUnit:getTraits().forceNeutral = nil
							end
						end
					)
				end
			end	
			
	   end,
		
		
		
		
		

		executeAbility = function( self, sim, ownerUnit, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
			local x0,y0 = unit:getLocation()
			local x1,y1 = targetUnit:getLocation()

            if ownerUnit:getTraits().slot ~= "gun" then
                -- HACK: Either the agent or the weapon itself is the ability owner, correctly identify which is which.
                ownerUnit = simquery.getEquippedGun( ownerUnit )
				assert( ownerUnit ) -- should fail canUseAbility otherwise
			end

			local weaponUnit = ownerUnit
			if not weaponUnit:getTraits().equipped then
				inventory.equipItem( unit, weaponUnit )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
			end

			local oldFacing = unit:getFacing()
			local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0)

			local pinning, pinnee = simquery.isUnitPinning(unit:getSim(), unit)
			if pinning and pinnee == targetUnit then
				newFacing = pinnee:getFacing()
			else
				pinning = false
			end

			if targetUnit:getPlayerOwner() then
				targetUnit:getPlayerOwner():glimpseUnit( sim, unit:getID() )
			end

			local eventtxt = speechdefs.EVENT_ATTACK_GUN
			if weaponUnit:getTraits().canSleep then
				eventtxt = speechdefs.EVENT_ATTACK_GUN_KO
			end
			sim:emitSpeech( unit, eventtxt )

			simquery.suggestAgentFacing(unit, newFacing)
			if targetUnit ~= unit then 
				sim:dispatchEvent( simdefs.EV_UNIT_START_SHOOTING, { unitID = unit:getID(), newFacing=newFacing, oldFacing=oldFacing,targetUnitID = targetUnit:getID(), pinning=pinning } )
				
				sim:dispatchEvent( simdefs.EV_CLOAK_IN, { unit = targetUnit  } )
				targetUnit:setKO( sim, weaponUnit:getTraits().fakeDamage )	
				targetUnit:getTraits().hasHearing = true
				targetUnit:getTraits().isOnlySleeping = true
				targetUnit:setInvisible(false)
				targetUnit:getTraits().disguiseOn = true
									
				abilityutil.canConsumeAmmo( sim, weaponUnit )
				inventory.useItem( sim, ownerUnit:getUnitOwner(), weaponUnit )

				sim:dispatchEvent( simdefs.EV_UNIT_STOP_SHOOTING, { unitID = unit:getID(), facing=newFacing, pinning=pinning} )			
				
		--		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Agents/Guard_1/Agitated/After_Shooting")
		--		sim:emitSound( simdefs.SOUND_SMALL, x1, y1, targetUnit)
				sim:startTrackerQueue(false)			
			else
			
				sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = unit:getID(), target = unit:getID(), revive = false, facing = newFacing } )
			--	sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 1 * cdefs.SECONDS )   --- useful but not here
				targetUnit:setKO( sim, weaponUnit:getTraits().fakeDamage )		
			--	targetUnit:getTraits().dynamicImpass = true
				targetUnit:getTraits().isOnlySleeping = true
				targetUnit:getTraits().hasHearing = true
				targetUnit:getTraits().interestSource = false
				
				
				abilityutil.canConsumeAmmo( sim, weaponUnit )
				inventory.useItem( sim, ownerUnit:getUnitOwner(), weaponUnit )
			
			end
			
		--		local newUnit = nil
		--		local player = unit:getPlayerOwner()

		--		newUnit = simfactory.createUnit( itemdefs.item_friendTranqWaker, sim )
		--		newUnit:setPlayerOwner( player )
				-- Spawn and warp the new unit
		--		sim:spawnUnit( newUnit )
		--		sim:warpUnit( newUnit, sim:getCell(x1, y1) )	
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )
			sim:processReactions( unit )
			sim:processReactions( targetUnit )
			


			--unit:useAP( sim )
		end
	}

return prism_allytagger