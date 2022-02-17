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



local prism_allytagger_wake =
	{
		name = STRINGS.ABILITIES.SHOOT,

		
		profile_icon = "gui/icons/Flavour/icon-item_tag_ally_wake_small.png",	
	--	usesAction = true,
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
			return abilityutil.formatToolTip( STRINGS.FLAVORED.ITEMS.ALLYTAGGER_INFIELD_WAKE,  STRINGS.FLAVORED.ITEMS.ALLYTAGGER_INFIELD_WAKE_DESC, 1 )
		end,


		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
                if targetUnit:getTraits().isOnlySleeping == true and targetUnit ~= userUnit and not targetUnit:getTraits().isGuard then 

					local x1,y1 = targetUnit:getLocation()
					local distance =  mathutil.dist2d( x0, y0, x1, y1 )

    				if distance <= 12 and distance > 0.5 then -- or  unit:getTraits().xray or sim:canUnitSeeUnit( userUnit, targetUnit )
						table.insert( units, targetUnit )
					end
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		canUseAbility = function( self, sim, ownerUnit, unit, targetUnitID )
			
			local targetUnit = sim:getUnit( targetUnitID )
			if targetUnit then
				if simquery.isUnitCellFull( sim, targetUnit ) then
					return false, STRINGS.FLAVORED.ITEMS.ALLYTAGGER_INFIELD_WAKE_NEED_SPACE
				end
			end
			
			return true
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
				
			--	sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, {unit=unit, kanim="gui/hud_fx", symbol="aquire_console", anim="front", params={}} )
				
			--	sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt="<font1_18_r>"..STRINGS.UI.FLY_TXT.REVEALED.."</>", x=x1, y=y1, color={r=1,g=1,b=41/255,a=1}, alwaysShow=true} )
			--	sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, {unit=targetUnit, kanim="gui/hud_fx", symbol="aquire_console", anim="front", params={}} )

				targetUnit:setPlayerOwner(unit:getPlayerOwner())
				sim:emitSound( simdefs.SOUND_CLOAK, x1, y1, nil )
			--	targetUnit:getTraits().invisible = false
				sim:dispatchEvent( simdefs.EV_CLOAK_IN, { unit = targetUnit  } )
				sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 0.5 * cdefs.SECONDS )
				targetUnit:setKO( sim, nil )	
				targetUnit:getTraits().isOnlySleeping = nil
				targetUnit:getTraits().forceNeutral = nil
		--		targetUnit:getTraits().mp = math.max( 0, targetUnit:getMPMax() - (targetUnit:getTraits().overloadCount or 0) )
				targetUnit:getTraits().disguiseOn = false
				sim:emitSpeech( targetUnit, speechdefs.EVENT_REVIVED )

				sim:startTrackerQueue(false)			
			
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

return prism_allytagger_wake