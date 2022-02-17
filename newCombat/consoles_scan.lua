local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )
local mathutil = include( "modules/mathutil" )
local speechdefs = include("sim/speechdefs")


local jackin =
	{
		name = STRINGS.ABILITIES.HIJACK_CONSOLE,
        proxy = true,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, abilityOwner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( targetUnit:getName() )
			if not targetUnit:getTraits().wirelessScanDist then 
				targetUnit:getTraits().wirelessScanDist = 2
			end
                local cpus, bonus = self:calculateCPUs( abilityOwner, abilityUser, targetUnit )
				local range = targetUnit:getTraits().wirelessScanDist * 2
	    		section:addAbility( "Scan Local network",  util.sformat( "1AP, RANGE = {1}", range ) )
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return "Scan Local Network"
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

        getProfileIcon = function( self, sim, abilityOwner )
            return abilityOwner:getUnitData().profile_icon or self.profile_icon
        end,

		calculateCPUs = function( self, abilityOwner, unit, targetUnit )
			local bonus = unit:getTraits().hacking_bonus or 0
            if unit ~= abilityOwner then
                bonus = bonus + (abilityOwner:getTraits().hacking_bonus or 0)
            end
			return math.ceil( targetUnit:getTraits().cpus ), bonus
		end,

		isTarget = function( self, abilityOwner, unit, targetUnit  )
			if not targetUnit:getTraits().mainframe_console then
				return false
			end

			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			if (targetUnit:getTraits().cpus or 0) ~= 0 then
				return false
			end
			
			if (targetUnit:getTraits().wirelessScanDist or 0) > abilityOwner:getSkillLevel("hacking") then
				return false
			end
			

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )

			local x0, y0 = abilityOwner:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
					local range = mathutil.dist2d( x0, y0, x1, y1 )
						if range <= 1 and simquery.isConnected( sim, sim:getCell( x0, y0 ), sim:getCell( x1, y1 ) ) then
							table.insert( units, targetUnit )
						end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
            -- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
            if abilityOwner ~= unit and abilityOwner:getUnitOwner() ~= unit then
                return false
            end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	
			
			if unit:getMP() < 1 then
				return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
			end

			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
			
			local cell = sim:getCell( abilityOwner:getLocation() )
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						local dir = cellUnit:getFacing()
						local x0, y0 = cellUnit:getLocation()
						local x1, y1 = simquery.getDeltaFromDirection(dir)
						local consoleFront = sim:getCell( x0 + x1, y0 + y1 )
											
						if sim:getCell(abilityOwner:getLocation()) ~= consoleFront then
							return false, "must be at front of console"
						end
						
						if cellUnit:getPlayerOwner() ~= abilityOwner:getPlayerOwner() then
								return false, "Must own console to use this ability."
						end
						
					end
				end
			end
			
			------
			local maxScanDist = abilityOwner:getSkillLevel("hacking") * 2
			local player = abilityOwner:getPlayerOwner()
			unit.newAssets = 0
			local cell = sim:getCell( unit:getLocation() )
				sim:forEachUnit(
					function( mainframeUnit )
						local x1, y1 = mainframeUnit:getLocation()
						if x1 and y1 and (mainframeUnit:getTraits().mainframe_item or mainframeUnit:getTraits().mainframe_console) and not mainframeUnit:getTraits().scanned then
							local distance = mathutil.dist2d( cell.x, cell.y, x1, y1 )
							if distance < maxScanDist then
								unit.newAssets = 1
							end
						end
					end )
			if unit.newAssets == 0 then
				return false, "No undiscovered local objects."
			end

			return abilityutil.checkRequirements( abilityOwner, unit )
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			
			local player = abilityOwner:getPlayerOwner()
			
			local targetUnit = sim:getUnit( targetUnitID )
			if not targetUnit:getTraits().wirelessScanDist then
				targetUnit:getTraits().wirelessScanDist = 2
			end

			local myConsoleDir = unit:getFacing()
			local x0,y0 = abilityOwner:getLocation()
			local x1,y1 = unit:getLocation()	
			local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = abilityOwner:getID(), useTinker=true, facing = newFacing, sound = simdefs.SOUNDPATH_SAFE_OPEN, soundFrame = 1 } )
			
			local maxScanDist = targetUnit:getTraits().wirelessScanDist * 2
			local cell = sim:getCell( unit:getLocation() )
				for i = maxScanDist-2,maxScanDist,1 do -- this just makes the scan go out in rings, is a little slower but classier
				local scanDist = i
					sim:forEachUnit(
						function( mainframeUnit )
							local x1, y1 = mainframeUnit:getLocation()
							if x1 and y1 and (mainframeUnit:getTraits().mainframe_item or mainframeUnit:getTraits().mainframe_console) and not mainframeUnit:getTraits().scanned then
								local distance = mathutil.dist2d( cell.x, cell.y, x1, y1 )
								if distance < scanDist then
									player:glimpseUnit( sim, mainframeUnit:getID() )
									mainframeUnit:getTraits().scanned = true
									sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = mainframeUnit, reveal = true } )      
									
									if mainframeUnit:getTraits().mainframe_program then
										sim:dispatchEvent( simdefs.EV_DAEMON_TUTORIAL )       
									end
									
								end
							end
						end )
					local delay = 0.2
					sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)	
				end	
			
			targetUnit:getTraits().wirelessScanDist = targetUnit:getTraits().wirelessScanDist + 1
			
			abilityOwner:useMP(1, sim)
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = abilityOwner:getID(), facing = newFacing } )	
		end,
	}
return jackin