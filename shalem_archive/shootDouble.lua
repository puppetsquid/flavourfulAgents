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

local shoot_tooltip = class()

function shoot_tooltip:init( hud, abilityOwner, abilityUser, targetUnitID )
	self._hud = hud
	self._abilityOwner = abilityOwner
	self._abilityUser = abilityUser
	self._targetUnitID = targetUnitID
end

function shoot_tooltip:setPosition( wx, wy )
	self._panel:setPosition( self._hud._screen:wndToUI( wx, wy ))
end

function shoot_tooltip:getScreen()
	return self._hud._screen
end

function shoot_tooltip:activate( screen )
	local combat_panel = include( "hud/combat_panel" )
	local sim = self._hud._game.simCore

	self._panel = combat_panel( self._hud, self._hud._screen )
	self._panel:refreshShoot( self._abilityOwner, self._abilityUser, sim:getUnit( self._targetUnitID ))
	self._hud._game.boardRig:getUnitRig( self._targetUnitID )._prop:setRenderFilter( cdefs.RENDER_FILTERS["focus_highlite"] )
end

function shoot_tooltip:deactivate()
	self._hud._game.boardRig:getUnitRig( self._targetUnitID )._prop:setRenderFilter( nil )
	self._panel:setVisible( false )
end

local function isShootTarget( self, sim, abilityOwner, abilityUser, targetUnit )
	if not simquery.isShootable( abilityUser, targetUnit ) then
        return false
    end
    if not sim:canPlayerSeeUnit( abilityUser:getPlayerOwner(), targetUnit ) then
        return false
    end
    local equippedGun = simquery.getEquippedGun( abilityUser )
    if not equippedGun then
        return false
    end
    if equippedGun:getTraits().canTag then
        if targetUnit:getTraits().tagged or not targetUnit:getBrain() then
            return false
        end
    end
    return true
end



local shootDouble =
	{
		name = STRINGS.ABILITIES.SHOOT,

		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png",		
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

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			return shoot_tooltip( hud, abilityOwner, abilityUser, targetUnitID )
		end,


		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
                if isShootTarget( self, sim, unit, userUnit, targetUnit) then 

					local x1,y1 = targetUnit:getLocation()
					local distance =  mathutil.dist2d( x0, y0, x1, y1 )

    				if unit:getTraits().xray or sim:canUnitSeeUnit( userUnit, targetUnit ) or distance <= 12 then
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

			--------------
			if unit:getAP() < 1 and (weaponUnit:getTraits().energyWeapon == "idle" or weaponUnit:getTraits().energyWeapon == "used")then
					return false
			end

			--------------

			local targetUnit = sim:getUnit( targetUnitID )
			if targetUnit and not ownerUnit:getTraits().xray and not sim:canUnitSeeUnit( unit, targetUnit ) then
                return false
            end

            if targetUnit then
            	local shot =  simquery.calculateShotSuccess( sim, unit, targetUnit, weaponUnit )
				if shot.armorBlocked == true then
	                return false
	            end

	            if shot.ko and not targetUnit:getTraits().canKO then 
					return false
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
			sim:dispatchEvent( simdefs.EV_UNIT_START_SHOOTING, { unitID = unit:getID(), newFacing=newFacing, oldFacing=oldFacing,targetUnitID = targetUnit:getID(), pinning=pinning } )

	        if unit:getTraits().monster_hacking then 
		        unit:getTraits().monster_hacking = false
		        unit:getSounds().spot = nil
            end
        						
			if unit:getTraits().data_hacking then 
				unit:stopHacking(sim)
	        end
        						

			if unit:isValid() then
				sim:startTrackerQueue(true)				
				local dmgt = abilityutil.createShotDamage( weaponUnit, unit )
				sim:tryShootAt( unit, targetUnit, dmgt, weaponUnit )
				                
                abilityutil.canConsumeAmmo( sim, weaponUnit )
                inventory.useItem( sim, ownerUnit:getUnitOwner(), weaponUnit )

				if weaponUnit:getTraits().spawnsDaemon then 
					--sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=STRINGS.ITEMS.DARTGUN_MONST3R, x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
					
					if sim:isVersion("0.17.8") then
						local daemon 
					end

					local programList = nil
					
					if sim:isVersion("0.17.7") then
						programList = sim:handleOverrideAbility(serverdefs.OMNI_PROGRAM_LIST)

						if sim and sim:getParams().difficultyOptions.daemonQuantity == "LESS" then
							programList = sim:handleOverrideAbility(serverdefs.OMNI_PROGRAM_LIST_EASY)
						end

						daemon = programList[sim:nextRand(1, #programList)]

					else
						programList = serverdefs.OMNI_PROGRAM_LIST

						if sim and sim:getParams().difficultyOptions.daemonQuantity == "LESS" then
							programList = serverdefs.OMNI_PROGRAM_LIST_EASY
						end

						local daemon = programList[sim:nextRand(1, #programList)]
					end
					sim:getNPC():addMainframeAbility( sim, daemon, nil, 0 )
				end 

				sim:dispatchEvent( simdefs.EV_UNIT_STOP_SHOOTING, { unitID = unit:getID(), facing=newFacing, pinning=pinning} )			
				sim:startTrackerQueue(false)				
			end
			
		
			unit:useAP( sim )
		end
	}

return shootDouble