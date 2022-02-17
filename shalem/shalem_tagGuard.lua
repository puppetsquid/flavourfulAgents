local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )

---------------------------------------------------------
-- Local functions


local shalem_tagGuard = 
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER,

		createToolTip = function( self, sim, abilityOwner, abilityUser, targetID )
			return abilityutil.formatToolTip(STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER, STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER_DESC)
		end,
		
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER )
			if targetUnit then
				if targetUnit:getTraits().improved_heart_monitor then
					section:addLine( util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER_DESC, abilityOwner:getTraits().advPWR ))
				elseif targetUnit:getTraits().heartMonitor == "enabled" then
					section:addLine( util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER_DESC, abilityOwner:getTraits().stdPWR ))
				end
			end
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,
		
		proxy = true,

		profile_icon = "gui/icons/Flavour/icon-heartbreak.png",
		getName = function( self, sim, unit )
			return self.name
		end,

        canUseWhileDragging = true,

		isValidTarget = function( self, sim, userUnit, targetUnit )
			if simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) and targetUnit:getTraits().isAgent and not targetUnit:getTraits().isDrone then
				return true
			end
					
			return false
		end,
		
	acquireTargets = function( self, targets, game, sim, unit )

		local targetUnits = {}
		local userUnit = unit:getUnitOwner()
		
		local maxRange = 10
		local x0, y0 = userUnit:getLocation()
		local units = {}
		for _, targetUnit in pairs(sim:getAllUnits()) do
			local x1, y1 = targetUnit:getLocation()
			if x0 and x1 and self:isValidTarget( sim, userUnit, userUnit, targetUnit ) then
				local range = mathutil.dist2d( x0, y0, x1, y1 )
				if maxRange then
					if range <= maxRange then
						if sim:canPlayerSeeUnit( userUnit:getPlayerOwner(), targetUnit ) then
							table.insert( units, targetUnit )
						else
							for _, cameraUnit in pairs(sim:getAllUnits()) do 
								if cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then
									table.insert( units, targetUnit )
									break
								end
							end
						end
					end
				end
			end
		end
		
		return targets.unitTarget( game, units, self, unit, userUnit )

	end,
		canUseAbility = function( self, sim, unit, userUnit, targetID )
			local targetUnit = sim:getUnit( targetID )
			if targetUnit then 
			
				if targetUnit:getTraits().heartmonTagged == true then
					return false
				end

				if targetUnit:getTraits().heartMonitor == "enabled" then
					if userUnit:getPlayerOwner():getCpus() < unit:getTraits().stdPWR then
						return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
					end
				end
				
				if targetUnit:getTraits().improved_heart_monitor then
					if userUnit:getPlayerOwner():getCpus() < unit:getTraits().advPWR then
						return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
					end
				end

			end

			return true 
		end, 

		executeAbility = function( self, sim, unit, userUnit, target )
			local target = sim:getUnit(target)
			local x0, y0 = userUnit:getLocation()
			local player = sim:getPC()
			
			sim:forEachUnit(   --------------------- lets clear old guards
					function ( heartGuards )
						local x1, y1 = heartGuards:getLocation()
						if x1 and y1 and heartGuards:getTraits().heartmonTagged then
							heartGuards:getTraits().heartmonTagged = nil
						end
					end
				)
			
			if target:getTraits().improved_heart_monitor then
				target:getTraits().heartmonTagged = true
				player:addCPUs( 0 - unit:getTraits().advPWR, sim, x0, y0 )
				local params = {color ={{symbol="inner_line",r=0,g=1,b=1,a=0},{symbol="wall_digital",r=0,g=1,b=1,a=0},{symbol="boxy_tail",r=163/255,g=243/255,b=248/255,a=0.5},{symbol="boxy",r=163/255,g=243/255,b=248/255,a=0.75}} }
				sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = target, kanim = "fx/deamon_ko", symbol = "effect", anim="break", above=true, params=params} )
				sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.MINUS_PWR, unit:getTraits().advPWR), x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
			elseif target:getTraits().heartMonitor == "enabled" then
				target:getTraits().heartmonTagged = true
				player:addCPUs( 0 - unit:getTraits().stdPWR, sim, x0, y0 )
				local params = {color ={{symbol="inner_line",r=0,g=1,b=1,a=0},{symbol="wall_digital",r=0,g=1,b=1,a=0},{symbol="boxy_tail",r=163/255,g=243/255,b=248/255,a=0.5},{symbol="boxy",r=163/255,g=243/255,b=248/255,a=0.75}} }
				sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = target, kanim = "fx/deamon_ko", symbol = "effect", anim="break", above=true, params=params} )
				sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.MINUS_PWR, unit:getTraits().stdPWR), x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
			end
		end
	}
return shalem_tagGuard