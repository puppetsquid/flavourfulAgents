local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local mathutil = include( "modules/mathutil" )
local weighted_list = include( "modules/weighted_list" )
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )
local inventory = include( "sim/inventory" )

local function getLostAgent( agency )
    -- Get the earliest captured agent from the list.
    local minCaptureTime, lostAgent = math.huge, nil
    for i, agentDef in ipairs(agency.unitDefsPotential) do
        if (agentDef.captureTime or math.huge) < minCaptureTime then
            minCaptureTime, lostAgent = agentDef.captureTime, agentDef
        end
    end

    return lostAgent
end

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
			
			local vault = nil
			for i,simunit in pairs (sim:getAllUnits()) do
				if simunit:getTraits().security_box then
			--		simunit:getTraits().security_box_locked = false
					simunit:setPlayerOwner( sim:getPC() )					
					sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = simunit, nosound = true} )	
					vault = simunit
				end
			end
			
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
					local template = hostageUnit:getTraits().template
					
					newUnit = unit:getPlayerOwner():hireUnit( sim, hostageUnit, cell, hostageUnit:getFacing() )		


					if vault and vault:getTraits().securityLevel == 2 then
						self:swapAugs( sim, template, newUnit, vault )
					end

				else
					newUnit = unit:getPlayerOwner():rescueHostage( sim, hostageUnit, cell, hostageUnit:getFacing(), unit )
				end
				if newUnit then
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newUnit } )
					sim:dispatchEvent(simdefs.EV_UNIT_RESCUED, { unit = newUnit } )						
					
					self:lockItems( sim, vault, newUnit )
				end
			end
			
			

			abilityOwner:getTraits().mainframe_status =  "inactive"

		end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			sim:addTrigger( simdefs.TRG_END_TURN, self )
		end,
		
		
		swapAugs = function ( self, sim, template, newUnit, vault )
			local unitDef = unitdefs.lookupTemplate( template )
			local tableSpawnHold = {}
			if unitDef.upgrades then
				local augments = newUnit:getAugments()
				for augment = 1,#augments,1 do
					inventory.trashItem( sim, newUnit, augments[augment] )
				end
				
				for i,invItem in ipairs (newUnit:getChildren()) do
					
					table.insert ( tableSpawnHold, invItem:getUnitData().name )
					inventory.trashItem( sim, newUnit, invItem )
				end  --- now deleting default held items and noting them down
				
				for i,invItem in ipairs (unitDef.upgrades) do
					invItemTemplate = unitdefs.lookupTemplate( invItem )
					if invItemTemplate.traits.augment then
						local newAug = inventory.giftUnit (sim, newUnit, invItem)
						newUnit:doAugmentUpgrade(newAug)
					end
					log:write(invItem)
				end
				vault:getTraits().spawnHoldTable = tableSpawnHold
			end
		end,
		
		
		
		lockItems = function (self, sim, safe, newUnit)
		
		log:write("INFO - transfer items")
		
for i = 1, 8, 1 do
			if #newUnit:getChildren() > 0 then
				for i,invItem in ipairs (newUnit:getChildren()) do
					log:write(invItem:getUnitData().name)
					if invItem:getTraits().installed and invItem:getTraits().installed == true then
			--			log:write("skipped")
					else
						inventory.giveItem( newUnit, safe, invItem )
			--			log:write("transfered")
					end
				end
			end   
end  -- looping cuz some items break aparanetly? fix later

				
			local NEVER_SOLD = 10000
			
			
			local invValuesTable = {}
			local invItemsTable = {}
			log:write("valueSearch")
			for i,simunit in pairs (safe:getChildren()) do
				log:write(simunit:getUnitData().name)
				local value = 1
				if simunit:getUnitData().value then
					value = simunit:getUnitData().value
				end
				if (simunit:getUnitData().soldAfter and simunit:getUnitData().soldAfter == NEVER_SOLD) or  (simunit:getUnitData().notSoldAfter and simunit:getUnitData().notSoldAfter == NEVER_SOLD)  then
					value = value * 9999
				end
				log:write(value)
				table.insert ( invValuesTable, value )
			end
			
			table.sort(invValuesTable)
			
			log:write("create item list")
				for i = 1, #invValuesTable, 1 do
					local found = false
					local curVal = invValuesTable[i]
					for i,simunit in pairs (safe:getChildren()) do
						local value = 1
						if simunit:getUnitData().value then
							value = simunit:getUnitData().value
						end
						if (simunit:getUnitData().soldAfter and simunit:getUnitData().soldAfter == NEVER_SOLD) or  (simunit:getUnitData().notSoldAfter and simunit:getUnitData().notSoldAfter == NEVER_SOLD)  then
							value = value * 9999
						end
						if not simunit:getUnitData().detLockScanFound and value == curVal then
							log:write(simunit:getUnitData().name)
							table.insert ( invItemsTable, simunit )
							log:write("added: " .. invItemsTable[#invItemsTable]:getUnitData().name)
							simunit:getUnitData().detLockScanFound = true
						end
					end	
				end
				
			log:write("final list")	
			for i = 1, #invItemsTable, 1 do
				local item = invItemsTable[i]
					if item then
					log:write(item:getUnitData().name)
					log:write(i)
				end
			end			
			log:write("begin locking")
			
			if safe:getTraits().securityLevel then 
				local portion = math.ceil( #invItemsTable / 2 )
				log:write("Sec = 3: " .. portion .. " items")
				log:write("Vault locks")
				for i = 1, portion, 1 do
					log:write(#invItemsTable)
					local lockoff = invItemsTable[#invItemsTable]
					log:write(lockoff:getUnitData().name)
					lockoff:getTraits().vaultLocked="Vault Keycard"
					invItemsTable[#invItemsTable] = nil
				end
				log:write("Guard locks")
				for i = 1, #invItemsTable, 1 do -- the rest
					log:write(#invItemsTable)
					local lockoff = invItemsTable[#invItemsTable]
					log:write(lockoff:getUnitData().name)
					lockoff:getTraits().vaultLocked="Guard Keycard"
					invItemsTable[#invItemsTable] = nil
				end
			end
			
			for i,simunit in pairs (safe:getChildren()) do
				if simunit:getTraits().isDetFile then
					simunit:getTraits().vaultLocked= "Guard Keycard"
				end
			end
			
			
			if safe:getTraits().spawnHoldTable then
			for heldName = 1, #spawnHoldTable, 1 do
				for i,simunit in pairs (safe:getChildren()) do
					if simunit:getUnitData().name == heldName then
						simunit:getTraits().vaultLocked= "Guard Keycard"
					end
				end
			end			
				
			
			end
			
			
		end,
		
		
		

		onTrigger = function ( self, sim, evType, evData )  -- On first turn, swap a small safe for a large safe full of hostage's stuff		

			local abilityOwner = self.abilityOwner
			local resuceAgent = nil
			if evType == simdefs.TRG_END_TURN and not abilityOwner:getTraits().haveSwapped then
				
				
				abilityOwner:getTraits().haveSwapped = true -- prevent calling after 1st round
				
				----- find t1 safes, prefer ones near tier 2 safes
				log:write("safe search on")
				local t1SafeList = {} 			
				local t1SafeWList = util.weighted_list({})
				local t2SafeWList = util.weighted_list({})
				
				for i,simunit in pairs (sim:getAllUnits()) do
					if simunit:getTraits().tier1Safe then -- :getUnitData().name == STRINGS.PROPS.SAFE then   -- 
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
						if not sim:canPlayerSeeUnit( sim:getPC(), simunit ) then
							t1SafeWList:addChoice( simunit, distance )
							log:write("new safe logged")
						end
						if t1SafeWList:getCount() > 2 then
							t1SafeWList:removeHighest()
						end
					end
				else
					log:write("no big safes")
					for i,simunit in pairs (t1SafeList) do
						if not sim:canPlayerSeeUnit( sim:getPC(), simunit ) then
							backupSafe = simunit
							t1SafeWList:addChoice( simunit, 1 )
							log:write("new safe logged")
						end
					end
				end
				
				local chosenSafe = t1SafeWList:getChoice( sim:nextRand(1, t1SafeWList:getTotalWeight()))
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HUD/mainframe/node_capture" )
				
				------ swap out safe with vault
				
				local x0, y0 = chosenSafe:getLocation()
				local template = unitdefs.lookupTemplate( "vault_safe_detention" )
				local unitData = util.extend( template )( {} )
				local newSafe = simfactory.createUnit( unitData, sim )
				sim:spawnUnit( newSafe )
				local cell = sim:getCell(x0, y0)
				sim:warpUnit( chosenSafe, nil )
				sim:warpUnit( newSafe, cell )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newSafe, reveal = true } )
				newSafe:setFacing( chosenSafe:getFacing() )
				--newSafe:getTraits().credits = chosenSafe:getTraits().credits
				newSafe:getTraits().securityLevel = 0
				
				if #chosenSafe:getChildren() > 0 then
					inventory.giveAll( chosenSafe, newSafe )
				end
				
				--- do a scan for prisoners, fill out inventory as needed
				--- default prisoner has random items, while MIA retain old ones (currently classified by having items; may need to check for dupes of uniques in world)
				
				local fileValue = 0
				if chosenSafe:getTraits().credits and chosenSafe:getTraits().credits > 0 then
					fileValue = chosenSafe:getTraits().credits
				else
					fileValue = 100
				end
				
				local agency = sim._params.agency
				local miaDef = getLostAgent( agency )
				if miaDef then
					log:write("Lost Agent")
				else
					log:write("No Lost Agents")
				end
				
				log:write("beginScan")
				for i,simunit in pairs (sim:getAllUnits()) do
					if simunit:getTraits().template then -- or simunit:getTraits().isBanks == true
						log:write("INFO- ")
						log:write(simunit:getTraits().template)
						
						resuceAgent = simunit
						local x2, y2 = simunit:getLocation()
						
						local unitDef = unitdefs.lookupTemplate( simunit:getTraits().template )
			--			prisonerName = unitDef.name
							
							
							
							if miaDef and miaDef.template == simunit:getTraits().template then 
								--- was MIA
								newSafe:getTraits().securityLevel = 3
								fileValue = 0
								sim:addCleaningKills( 1 ) -- negated by taking file out of level
							else
							
								local itemList = util.weighted_list({})
								if unitDef.kanim == "kanim_prisoner_male" then -- kanim_courier_male
									itemList:addChoice("item_lockdecoder", 5)
									itemList:addChoice("item_econchip", 4) -- item_paralyzer
									itemList:addChoice("item_laptop", 3) -- item_shocktrap
									itemList:addChoice("item_portabledrive", 2)
									itemList:addChoice("item_stickycam", 1)
									for i = 1,2,1 do
										local Rand = sim:nextRand(1, itemList:getTotalWeight())
										local freeItem = itemList:getChoice( Rand )
										inventory.giftUnit (sim, chosenSafe, freeItem)
										itemList:removeChoice(freeItem)
									end
									newSafe:getTraits().securityLevel = 1
									fileValue = fileValue * 2
								end
								
								if unitDef.upgrades then
									for i,invItem in ipairs (unitDef.upgrades) do
										--local invItem = simfactory.createUnit( unitData, sim )
										local augments = resuceAgent:getAugments()
						--				for augment = 1,#augments,1 do
						--					inventory.trashItem( sim, resuceAgent, augments[augment] )
						--				end
										inventory.giftUnit (sim, newSafe, invItem)
						--				inventory.giveAll( resuceAgent, newSafe )
										log:write(invItem)
									end
									newSafe:getTraits().securityLevel = 2
								end
							end
						
					end


				end
				
				
				if #chosenSafe:getChildren() > 0 then
					inventory.giveAll( chosenSafe, newSafe )
				end
				
				if #newSafe:getChildren() < 8 then
					if newSafe:getTraits().securityLevel == 1 then 
						local infoFile = inventory.giftUnit (sim, newSafe, "item_prisonerFile")
						infoFile:getUnitData().value = fileValue
						infoFile:getTraits().oValue = fileValue
						infoFile:getUnitData().desc = util.sformat("Trade for credit: {1}", fileValue)
					elseif newSafe:getTraits().securityLevel == 2 then 
						local infoFile = inventory.giftUnit (sim, newSafe, "item_agentFile")
						infoFile:getUnitData().value = fileValue
						infoFile:getTraits().oValue = fileValue
						infoFile:getUnitData().desc = util.sformat("Trade for credit: {1}", fileValue) 
					elseif newSafe:getTraits().securityLevel == 3 then 
						inventory.giftUnit (sim, newSafe, "item_miaFile")
					end
				end
				
				
				
				--- turn final inventory into list ordered by value
				
				
			--	self:lockItems( sim, newSafe, resuceAgent )
				
				
				--- lock items based on value (cheaper are easier to get) and security (MIA agents have highest security; default prisoners lowest)
				
				
				
				
				for i,item in ipairs(newSafe:getChildren()) do
					if item:getTraits().isDetFile then
						item:getTraits().oValue= fileValue
					end
				end
				
				--newSafe:setPlayerOwner( abilityOwner:getPlayerOwner())
				sim:despawnUnit( chosenSafe )
				
				
				---- finally, find a guard to give a keycard to
				
				local guardList = {}
				for i,simunit in pairs (sim:getAllUnits()) do -- guardUnit:getArmor())
					if simunit:getTraits().isGuard and not simunit:getTraits().isDrone then
					-- drones don't have hands, apparently 
						table.insert(guardList,simunit)
					end
				end
				
				local chosenGuard = 1
				local chosenGuardArmor = 0
				local chosenGuardDist = 9001
				for i,guardUnit in pairs (guardList) do
					local x0, y0 = resuceAgent:getLocation()
					local x1, y1 = guardUnit:getLocation()
					local distance = mathutil.dist2d( x0, y0, x1, y1 )
					if distance < chosenGuardDist then -- and not guardUnit:getArmor() < chosenGuardArmor then
						chosenGuardDist = distance
						chosenGuardArmor = guardUnit:getArmor()
						chosenGuard = guardUnit
					end
				end		
				
				inventory.giftUnit (sim, chosenGuard, "detain_vault_passcard")
				
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

