local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )

local jackin_calmguards =
	{
		name = STRINGS.FLAVORED.ITEMS.HIJACK_CALMGUARDS,
        proxy = true,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )			
			section:addLine( targetUnit:getName() ) 
			if (targetUnit:getTraits().cpus or 0) > 0 then
				local cpus, bonus = self:calculateCPUs( abilityOwner, abilityUser, targetUnit )
				local alarmInc = (cpus)	
				section:addAbility( self:getName(sim, abilityOwner, abilityUser, targetUnitID),
					util.sformat( STRINGS.FLAVORED.ITEMS.HIJACK_CALMGUARDS_DESC, alarmInc ), "gui/items/icon-action_hack-console.png" )
			end
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
            return self.name
		end,
		
		profile_icon = "gui/icons/Flavour/icon-item_chip_calmer_small.png",

        getProfileIcon = function( self, sim, abilityOwner )
            return abilityOwner:getUnitData().profile_icon or self.profile_icon
        end,

		isTarget = function( self, abilityOwner, unit, targetUnit )
			if not targetUnit:getTraits().mainframe_console then
				return false
			end

			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			if (targetUnit:getTraits().cpus or 0) == 0 then
				return false
			end

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
                    local ok = simquery.canReach( sim, x0, y0, x1, y1 )
                    if ok then
						table.insert( units, targetUnit )
					end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		calculateCPUs = function( self, abilityOwner, unit, targetUnit )
			local bonus = unit:getTraits().hacking_bonus or 0
            if unit ~= abilityOwner then
                bonus = bonus + (abilityOwner:getTraits().hacking_bonus or 0)
            end
			return math.ceil( targetUnit:getTraits().cpus ), bonus
		end,
		
		onSpawnAbility = function( self, sim, abilityOwner )
			abilityOwner:getTraits().cooldown = abilityOwner:getTraits().startCooldown
		end,
        
        canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
            -- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
            if abilityOwner ~= unit and abilityOwner:getUnitOwner() ~= unit then
                return false
            end
			
			if unit and not unit:getTraits().disguiseOn then
				return false, util.sformat(STRINGS.FLAVORED.ITEMS.REASON_REQ_DISGUISE)
			end

			local targetUnit = sim:getUnit( targetUnitID )
			if targetUnit then
				assert( self:isTarget( abilityOwner, unit, targetUnit ))
				if targetUnit:getTraits().mainframe_console_lock > 0 then
					return false, STRINGS.UI.REASON.CONSOLE_LOCKED
				end
			end
			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	
			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end				

			return abilityutil.checkRequirements( abilityOwner, unit )
		end,

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			sim:emitSpeech( unit, speechdefs.EVENT_HIJACK )
            
			local targetUnit = sim:getUnit( targetUnitID )
			assert( targetUnit, "No target : "..tostring(targetUnitID))
			local x1, y1 = targetUnit:getLocation()
   			local x0,y0 = unit:getLocation()
			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= targetUnit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )

            local triggerData = sim:triggerEvent(simdefs.TRG_UNIT_HIJACKED, { unit=targetUnit, sourceUnit=unit } )
            if not triggerData.abort then
				targetUnit:getTraits().hijacked = true    
				targetUnit:getTraits().mainframe_suppress_range = nil
				targetUnit:setPlayerOwner(abilityOwner:getPlayerOwner())
			   
				sim:processReactions( targetUnit )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )
				
				local cpus, bonus = self:calculateCPUs( abilityOwner, unit, targetUnit )
				local alarmInc = (cpus)	
				
				targetUnit:getTraits().cpus = 0
				text = STRINGS.UI.ALERT_IMPROVED_HEART
				
		--		if not unit:getTraits().disguiseOn then
		--			unit:getTraits().wasDisguised = true
		--			local kanim = "kanim_guard_male_ftm"
		--			unit:setDisguise(true, kanim)
		--		else
		--			unit:getTraits().wasDisguised = false
		--		end
				
				
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = facing } )	
				sim:trackerDecrement( alarmInc )
				targetUnit:getTraits().mainframe_status = "off"
				
				sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT,
	            { txt = util.sformat( STRINGS.FLAVORED.ITEMS.ALARM_SUB, alarmInc ),
					x=x1,y=y1, color={r=163/255,g=243/255,b=248/255,a=1},
					target="alarm"} )
					
		--		if unit:getTraits().wasDisguised then
		--			unit:getTraits().wasDisguised = nil
		--			unit:setDisguise(false)
		--		end
				
				inventory.useItem( sim, unit, abilityOwner )

				sim:emitSound( simdefs.SOUND_SECURITY_ALERTED, x0, y0, unit)	
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = facing } )
                
            end

            sim:processReactions( abilityOwner )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )
		end,
	}
return jackin_calmguards