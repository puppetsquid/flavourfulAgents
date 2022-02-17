local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local weighted_list = include( "modules/weighted_list" )

local open_detention_cells = 
	{
		name = STRINGS.ABILITIES.OPEN_DETENTION_CELLS,

		createToolTip = function( self, sim, unit )

			local title = STRINGS.ABILITIES.OPEN_DETENTION_CELLS
			local body = STRINGS.ABILITIES.OPEN_DETENTION_CELLS_DESC

			if unit:getTraits().activate_txt_title then
				title = unit:getTraits().activate_txt_title
			end
			if unit:getTraits().activate_txt_body then
				body = unit:getTraits().activate_txt_body
			end			

			return abilityutil.formatToolTip( title,  body )
		end,

		proxy = true,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return self.name
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
            if simquery.canUnitReach( sim, unit, abilityOwner:getLocation() ) then
			    return targets.unitTarget( game, { abilityOwner }, self, abilityOwner, unit )
            end
		end,

		canUseAbility = function( self, sim, abilityOwner, unit )
            if abilityOwner:getTraits().mainframe_status ~= "active" then
                return false
            end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	

			if abilityOwner:getTraits().mainframe_ice > 0 then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

            if not simquery.canUnitReach( sim, unit, abilityOwner:getLocation() ) then
			    return false
            end

            return true
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit )
			local x0,y0 = unit:getLocation()
			local x1, y1 = abilityOwner:getLocation()

			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )

			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= abilityOwner:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )			
			
			for i,simunit in pairs (sim:getAllUnits()) do
				if simunit:getTraits().cell_door then
					sim:dispatchEvent( simdefs.EV_UNIT_PLAY_ANIM, {unit= simunit, anim="open", sound="SpySociety/Objects/detention_door_shutdown" } )			
					sim:warpUnit( simunit, nil )
					sim:despawnUnit( simunit )
				end
			end

			local hostageList = {} 
			for i,simunit in pairs (sim:getAllUnits()) do
				if simunit:getTraits().detention == true then
					table.insert(hostageList,simunit)
				end
			end

			for i,hostageUnit in ipairs (hostageList) do
				local cell = sim:getCell( hostageUnit:getLocation() )
				local newUnit = nil
				if hostageUnit:getTraits().rescueID then
					newUnit = unit:getPlayerOwner():hireUnit( sim, hostageUnit, cell, hostageUnit:getFacing() )					
				else
					newUnit = unit:getPlayerOwner():rescueHostage( sim, hostageUnit, cell, hostageUnit:getFacing(), unit )
				end
				if newUnit then
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newUnit } )
					sim:dispatchEvent(simdefs.EV_UNIT_RESCUED, { unit = newUnit } )						
				end
			end

			abilityOwner:getTraits().mainframe_status =  "inactive"
		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			sim:addTrigger( simdefs.TRG_START_TURN, self )
		end,

		onTrigger = function ( self, sim, evType, evData )  -- On first turn, swap a small safe for a large safe full of hostage's stuff		

			local abilityOwner = self.abilityOwner
			if evType == simdefs.TRG_START_TURN and not abilityOwner:getTraits().safed then
				local mathutil = include( "modules/mathutil" )
				local weighted_list = include( "modules/weighted_list" )
				local unitdefs = include("sim/unitdefs")
				local simfactory = include( "sim/simfactory" )
				local inventory = include( "sim/inventory" )
				
				abilityOwner:getTraits().safed = true
				
				local t1SafeList = {} 			
				local t1SafeWList = util.weighted_list({})
				local t2SafeWList = util.weighted_list({})
				
				for i,simunit in pairs (sim:getAllUnits()) do
					if simunit:getTraits().tier1Safe then
						table.insert(t1SafeList,simunit)
					elseif simunit:getTraits().tier2safe then
						t2SafeWList:addChoice( simunit, 1 )
					end
				end
				
				if t2SafeWList:getTotalWeight() > 0 then
					local bigSafe = t2SafeWList:getChoice( sim:nextRand(1, t2SafeWList:getTotalWeight()))
					for i,simunit in pairs (t1SafeList) do
						local x0, y0 = bigSafe:getLocation()
						local x1, y1 = simunit:getLocation()
						local distance = mathutil.dist2d( x0, y0, x1, y1 )
						t1SafeWList:addChoice( simunit, distance )

						if t1SafeWList:getCount() > 1 then
							t1SafeWList:removeHighest()
						end
					end
				else
					for i,simunit in pairs (t1SafeList) do
						t1SafeWList:addChoice( simunit, 1 )
					end
				end
				
				local chosenSafe = t1SafeWList:getChoice( sim:nextRand(1, t1SafeWList:getTotalWeight()))
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/mainframe/node_capture" )
				
				local x0, y0 = chosenSafe:getLocation()
				local template = unitdefs.lookupTemplate( "vault_safe_1" )
				local unitData = util.extend( template )( {} )
				local newSafe = simfactory.createUnit( unitData, sim )
				sim:spawnUnit( newSafe )
				local cell = sim:getCell(x0, y0)
				sim:warpUnit( chosenSafe, nil )
				sim:warpUnit( newSafe, cell )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newSafe, reveal = true } )
				newSafe:setFacing( chosenSafe:getFacing() )
				newSafe:getTraits().credits = chosenSafe:getTraits().credits
				
				
				for i,simunit in pairs (sim:getAllUnits()) do
					if simunit:getTraits().detention == true then -- or simunit:getTraits().isBanks == true
					log:write("INFO- ")
					log:write(simunit:getTraits().template)
					local x2, y2 = simunit:getLocation()
						
						local unitDef = unitdefs.lookupTemplate( simunit:getTraits().template )
						
						for i,invItem in ipairs (unitDef.upgrades) do
							--local invItem = simfactory.createUnit( unitData, sim )
							inventory.giftUnit (sim, chosenSafe, invItem)
							log:write(invItem)
						
						end
					end


				end
				
				if #chosenSafe:getChildren() > 0 then
					inventory.giveAll( chosenSafe, newSafe )
				end
				
				newSafe:getTraits().security_box_locked = false
				--newSafe:setPlayerOwner( abilityOwner:getPlayerOwner())
				newSafe:getTraits().mainframe_ice = 8
				sim:despawnUnit( chosenSafe )
				
				
			end	
		end,
		
	}
return open_detention_cells



--[==[ on spawn

find small safes

pick one (nearest to large safes if there)

spawn a supersafe, add non-aug inventory of rescue ID and small safe

delete small safe

find guards, pick one

give suersafe access card


    local distance = mathutil.dist2d( cell.x, cell.y, x1, y1 )
				    if distance < abilityOwner:getTraits().wireless_range then
					    player:glimpseUnit( sim, mainframeUnit:getID() )
					    mainframeUnit:getTraits().scanned = true
					    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = mainframeUnit, reveal = true } )      
                        
                        if mainframeUnit:getTraits().mainframe_program then
                            sim:dispatchEvent( simdefs.EV_DAEMON_TUTORIAL )       
                        end
				    end
			    end
		    end )
]==]--

