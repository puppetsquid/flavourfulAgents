local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )

------------------------------------------------------------------
--
function isCoreItem( unit )
		if unit:getTraits().largenano or unit:getTraits().bigshopcat or unit:getTraits().vip or unit:getTraits().public_term or unit:getTraits().scanner then
			return true
		elseif unit:hasAbility( "open_detention_cells" ) or unit:hasAbility( "hostage_rescuable" )  or unit:hasAbility( "open_security_boxes" ) then
			return true
		elseif unit:hasAbility( "useAugmentMachine" ) and not unit:getTraits().drill then
			return true
		end

		return false
	--traits().largenano
	--
end
function isUsefulItem( unit )

		if unit:getTraits().mainframe_status ~= "off" then
			if unit:getTraits().revealUnits == "mainframe_console" or unit:getTraits().revealUnits == "mainframe_camera"  or  unit:getTraits().showOutline or  unit:getTraits().revealDaemons then
				return true
			elseif unit:getTraits().router or unit:getTraits().power_core or unit:getTraits().tinker_anim  then
				return true
		--	elseif unit:getTraits().storeType == "standard" or unit:getTraits().storeType == "miniserver" then
		--		return true
		--	elseif unit:getTraits().powerGrid then
			elseif unit:getTraits().laser_gen or unit:getTraits().multiLockSwitch then
				return true
			end
		end
		
		return false
	--traits().largenano
	--
end



local function addInfo( sim, unit)
	local player = unit:getPlayerOwner()

	local num = math.floor(sim:nextRand()*5)+1
	local body = STRINGS.DLC1.NEURAL_SCAN_MODAL_BONUS
	
	log:write("SCAN")
	log:write(num)

    local bonus = 0
	local x,y = unit:getLocation()
	if num == 1 then -- revealCameras
		local unitlist = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
					if targetUnit:getTraits()[ "mainframe_camera" ] ~= nil then
						table.insert(unitlist,targetUnit:getID())
						sim:getPC():glimpseUnit( sim, targetUnit:getID() )				
					end
			end

		--	sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units=unitlist,reveal = true} )
	elseif num == 2 then -- showOutline
		sim._showOutline = true
			sim:dispatchEvent( simdefs.EV_WALL_REFRESH )

    		local x0,y0 = unit:getLocation()
    		local color = {r=1,g=1,b=41/255,a=1}
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.FACILITY_REVEALED,x=x0,y=y0,color=color,alwaysShow=true} )

	elseif num == 3 then --revealDaemons
		for _, targetUnit in pairs(sim:getAllUnits()) do
					if targetUnit:getTraits().mainframe_program ~= nil then
						targetUnit:getTraits().daemon_sniffed = true 
					end
			end 
	elseif num ==4 then -- revealConsoles
		local unitlist = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
					if targetUnit:getTraits()[ "mainframe_console" ] ~= nil then
						table.insert(unitlist,targetUnit:getID())		
						sim:getPC():glimpseUnit( sim, targetUnit:getID() )				
					end
			end 

			sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units=unitlist,reveal = true} )
	else -- revealKeyItem
		local unitlist = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
					if isCoreItem(unit) then
						table.insert(unitlist,targetUnit:getID())		
						sim:getPC():glimpseUnit( sim, targetUnit:getID() )				
					end
				end 

		--	sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units=unitlist,reveal = true} )
	end

	local dialogParams =
	{

		STRINGS.DLC1.NEURAL_SCAN_MODAL_1,
		STRINGS.DLC1.NEURAL_SCAN_MODAL_2,
		util.sformat(body,bonus),
	    "gui/icons/item_icons/icon-item_generic_arm.png"
	}
--	sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "programDialog", dialogParams = dialogParams } )		

	--sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt = util.sformat(body,bonus), x = x, y = y, color=cdefs.AUGMENT_TXT_COLOR} )

end




local neural_scan =
	{
		name = STRINGS.DLC1.NEURAL_SCAN,

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		createToolTip = function( self,sim,abilityOwner,abilityUser,targetID)
			local target = sim:getUnit(targetID)
			if target:isKO() then
				return abilityutil.formatToolTip(STRINGS.DLC1.NEURAL_SCAN, STRINGS.DLC1.NEURAL_SCAN_DESC_KO )				
			else
				return abilityutil.formatToolTip(STRINGS.DLC1.NEURAL_SCAN, STRINGS.DLC1.NEURAL_SCAN_DESC_DEAD )
			end
		end,

		eyeballs = {},

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_augment_dracul_small.png",
		proxy = true,
		alwaysShow = true,
		ghostable = true,

		acquireTargets = function( self, targets, game, sim, unit )
			local userUnit = unit:getUnitOwner()
			local cell = sim:getCell( userUnit:getLocation() )

			local units = {}
		
				
			for i,cellUnit in ipairs(cell.units) do
				if ((cellUnit:getTraits().iscorpse and not cellUnit:getTraits().wasDrone) or ((cellUnit:isKO() or cellUnit:isDead()) and cellUnit:getTraits().isGuard and not cellUnit:getTraits().isDrone)) and not cellUnit:getTraits().neural_scanned then
					table.insert( units, cellUnit )
				end
			end

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,


		canUseAbility = function( self, sim, unit )

			-- If the agent's skills are full, don't show the icon.			
			local userUnit = unit:getUnitOwner()
			
			if not userUnit then
				return false
			end

--[==[			if #getSkillList( sim, userUnit ) < 1 and not sim:isVersion("0.17.10") and userUnit:getTraits().isAgent then
				return false
			end
]==]
			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )
			target = sim:getUnit(target)	

			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
			 local player = sim:getCurrentPlayer()
			 local availableTargets = {}
			for _, testunit in pairs( sim:getAllUnits() ) do 
				if not sim:canPlayerSeeUnit( player, testunit ) and not testunit:getTraits().esPeeked then
					if isCoreItem(testunit) then
						table.insert( availableTargets, testunit )
					end
				end
			end
			if #availableTargets < 1 then
				for _, testunit in pairs( sim:getAllUnits() ) do 
					if not sim:canPlayerSeeUnit( player, testunit ) and not testunit:getTraits().esPeeked then
						if isUsefulItem(testunit) then					
							table.insert( availableTargets, testunit )
						end
					end
				end
			end
			if #availableTargets < 1 then
				for _, testunit in pairs( sim:getAllUnits() ) do 
					if not sim:canPlayerSeeUnit( player, testunit ) and not testunit:getTraits().esPeeked then
						if testunit:getPlayerOwner() ~= player and testunit:getTraits().isGuard then					
							table.insert( availableTargets, testunit )
						end
					end
				end
			end
			if #availableTargets < 1 then
				for _, testunit in pairs( sim:getAllUnits() ) do 
					if not sim:canPlayerSeeUnit( player, testunit ) and not testunit:getTraits().esPeeked then
						if testunit:getPlayerOwner() ~= player and (testunit:getTraits().mainframe_ice or 0) > 0 then		
							table.insert( availableTargets, testunit )
						end
					end
				end
			end
			if #availableTargets < 1 then
				for _, testunit in pairs( sim:getAllUnits() ) do 
					if testunit:getTraits().isGuard then
						table.insert( availableTargets, testunit )
					end
				end
			end
			 
			local espunit = availableTargets[ sim:nextRand( 1, #availableTargets ) ]
			
			if espunit then
				if target:getTraits().iscorpse then
					-- addInfo( sim, userUnit)
			--[==[		if not sim._showOutline == true then
						sim._showOutline = true
						sim:dispatchEvent( simdefs.EV_WALL_REFRESH )

						local x0,y0 = unit:getLocation()
						local color = {r=1,g=1,b=41/255,a=1}
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.FACILITY_REVEALED,x=x0,y=y0,color=color,alwaysShow=true} )
					end	
				]==]	
					self:esPeek( unit, target, espunit )

				elseif target:isKO() then
					local x0, y0 = espunit:getLocation()
					self:highlight( unit, sim, x0, y0, espunit )
					
				end
				
				target:getTraits().neural_scanned = true
				espunit:getTraits().esPeeked = true
			end
			-- self:removePeek( sim )
			 
			
		end,
		
		esPeek = function( self, unit, espunit )
			 
			 local x0, y0 = espunit:getLocation()
			local fromCell = sim:getCell( x0, y0 )
			
			sim:dispatchEvent( simdefs.EV_CAM_PAN, { espunit:getLocation() } )	
			local delay = .5
			sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)

			local peekInfo = { x0 = x0, y0 = y0, cellvizCount = 0}
			

            for i = 1, #simdefs.ADJACENT_EXITS, 3 do
				local dx, dy, dir = simdefs.ADJACENT_EXITS[i], simdefs.ADJACENT_EXITS[i+1], simdefs.ADJACENT_EXITS[i+2]
				local cell = sim:getCell( fromCell.x + dx, fromCell.y + dy )
				if (dx == 0 and dy == 0) or simquery.isOpenExit( fromCell.exits[ simquery.getDirectionFromDelta( dx, dy ) ] ) then
					local exit = cell and cell.exits[ dir ]
					if exit and exit.door and exit.keybits ~= simdefs.DOOR_KEYS.ELEVATOR and exit.keybits ~= simdefs.DOOR_KEYS.GUARD then
						local peekDx, peekDy = simquery.getDeltaFromDirection( dir )
                        self:doPeek(unit, not exit.closed, sim, cell.x, cell.y, peekInfo, peekDx, peekDy, exit)
					end
				end
			end

			if self:canPeek( sim, fromCell, 1, 1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, 1, 1 )
			end
			if self:canPeek( sim, fromCell, -1, 1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, -1, 1 )
			end
			if self:canPeek( sim, fromCell, 1, -1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, 1, -1 )
			end
			if self:canPeek( sim, fromCell, -1, -1 ) then
				self:doPeek( unit, true, sim, x0,y0, peekInfo, -1, -1 )
			end

			 
			  self:removePeek( sim )

		end,
		
		doPeek = function( self, unit, view360, sim, x0,y0, peekInfo, dx, dy, exit )
			local eyeball = include( "sim/units/eyeball" )
			local eyeballUnit = eyeball.createEyeball( sim )
			eyeballUnit:setPlayerOwner( unit:getPlayerOwner() )
			eyeballUnit:setFacing( simquery.getDirectionFromDelta( dx, dy ) )
            eyeballUnit:getTraits().peekID = unit:getID()

			if view360 or unit:getTraits().doorPeek360 then
				eyeballUnit:getTraits().LOSarc = math.pi * 2	
			end

			local cell = sim:getCell( x0 + dx, y0 + dy )
			sim:spawnUnit( eyeballUnit )
			sim:warpUnit( eyeballUnit, cell)
			table.insert( self.eyeballs, eyeballUnit )

			--prefer to use the targeted exit (or lack of exit)
			if peekInfo.preferredExit and exit ~= peekInfo.preferredExit then
				return
			end

			local shoulder = simquery.getAgentShoulderDir(unit, cell.x, cell.y)
			if not peekInfo.preferredExit then
				--we're leaning on something, prefer to peek behind us, and out of those options prefer the least impass
				if (simquery.getAgentCoverDir(unit) or simquery.getAgentLeanDir(unit)) and not shoulder and peekInfo.shoulder then
					return
				elseif peekInfo.cell and peekInfo.cell.impass < cell.impass then
					return
				end
			end

--			print(string.format("PEEKING x=%d y=%d dx=%d dy=%d, exit=%s", x0, y0, dx, dy, util.debugPrintTable(exit) ) )
			if eyeballUnit:getTraits().cellvizCount > peekInfo.cellvizCount or peekInfo.cellvizCount == 0 then
				peekInfo.cellvizCount = eyeballUnit:getTraits().cellvizCount
			--	local unitX, unitY = unit:getLocation()
				local unitX, unitY = x0,y0
				local eyeballX, eyeballY = eyeballUnit:getLocation()
				peekInfo.dx = eyeballX-unitX
				peekInfo.dy = eyeballY-unitY
				peekInfo.cell = cell
				peekInfo.shoulder = shoulder
				peekInfo.exit = exit
				if x0 == peekInfo.x0 and y0 == peekInfo.y0 then
					if dx == 0 or dy == 0 then
						--peek direction is just the direction of dx, dy
						peekInfo.dir = simquery.getDirectionFromDelta( dx, dy )
					else
						--peek is a corner, but we might be better off picking a cardinal direction to peek in
						local baseCell = sim:getCell(peekInfo.x0, peekInfo.y0)
						local dirX1 = simquery.getDirectionFromDelta(dx, 0)
						local dirX2 = simquery.getDirectionFromDelta(0, dy)
						local clearX = baseCell.exits[dirX1] and not baseCell.exits[dirX1].closed
						 and baseCell.exits[dirX1].cell.exits[dirX2] and not baseCell.exits[dirX1].cell.exits[dirX2].closed
						local dirY1 = simquery.getDirectionFromDelta(0, dy)
						local dirY2 = simquery.getDirectionFromDelta(dx, 0)
						local clearY = baseCell.exits[dirY1] and not baseCell.exits[dirY1].closed
						 and baseCell.exits[dirY1].cell.exits[dirY2] and not baseCell.exits[dirY1].cell.exits[dirY2].closed
						if clearX and clearY then
							--diagonal is open
							peekInfo.dir = simquery.getDirectionFromDelta(dx, dy)
						elseif clearX then
							peekInfo.dir = simquery.getDirectionFromDelta(dx, 0)
						elseif clearY then
							peekInfo.dir = simquery.getDirectionFromDelta(0, dy)
						end
					end
				elseif exit then
					--we're peeking through a door we couldn't 'touch'. Peek in such a way it doesn't matter which side the door is on.
					peekInfo.dir = simquery.getDirectionFromDelta(x0-peekInfo.x0, y0-peekInfo.y0)
				end
			end
		end,

		
		
		
		highlight = function( self, unit, sim, x0,y0,espunit )
			
			sim:dispatchEvent( simdefs.EV_CAM_PAN, { espunit:getLocation() } )	
			local delay = .5
			sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		
			local eyeball = include( "sim/units/eyeball" )
			local eyeballUnit = eyeball.createEyeball( sim )
			eyeballUnit:setPlayerOwner( unit:getPlayerOwner() )
		--	eyeballUnit:setFacing( simquery.getDirectionFromDelta( dx, dy ) )
            eyeballUnit:getTraits().peekID = unit:getID()

			eyeballUnit:getTraits().LOSarc = math.pi * 2	
			eyeballUnit:getTraits().LOSrange = 2	

			local cell = sim:getCell( x0 , y0 )
			sim:spawnUnit( eyeballUnit )
			sim:warpUnit( eyeballUnit, cell)
			table.insert( self.eyeballs, eyeballUnit )

			self:removePeek( sim )
		end,

		
		canPeek = function( self, sim, fromCell, dx, dy )
			if sim:getCell( fromCell.x + dx, fromCell.y + dy ) == nil then
				return false
			end

			if math.abs(dx) ~= 1 or math.abs(dy) ~= 1 then
				return false -- Can only peek to cells on the diagonal
			end

			local e1, e2, e3, e4 = false, false, false, false -- Tracks open exits

			local testCell1 = sim:getCell( fromCell.x + dx, fromCell.y )
			if testCell1 then
				local facing1, facing2 = simquery.getDirectionFromDelta( -dx, 0 ), simquery.getDirectionFromDelta( 0, dy )
				e1 = testCell1.exits[ facing1 ] ~= nil 
				e2 = testCell1.exits[ facing2 ] ~= nil

				if testCell1.exits[ facing1 ] and testCell1.exits[ facing1 ].door and testCell1.exits[ facing1 ].closed then
					e1 = false
				end
				if testCell1.exits[ facing2 ] and testCell1.exits[ facing2 ].door and testCell1.exits[ facing2 ].closed then
					e2 = false
				end

			end
			
			local testCell2 = sim:getCell( fromCell.x, fromCell.y + dy )				
			if testCell2 then
				local facing1, facing2 = simquery.getDirectionFromDelta( 0, -dy ), simquery.getDirectionFromDelta( dx, 0 )
				e3 = testCell2.exits[ facing1 ] ~= nil
				e4 = testCell2.exits[ facing2 ] ~= nil


				if  testCell2.exits[ facing1 ] and  testCell2.exits[ facing1 ].door and testCell2.exits[ facing1 ].closed then
					e3 = false
				end
				if testCell2.exits[ facing2 ] and testCell2.exits[ facing2 ].door and testCell2.exits[ facing2 ].closed then
					e4 = false
				end

			end
				
			return (e3 and e4) or (e1 and e2)
		end,

        removePeek = function( self, sim )
            if #self.eyeballs > 0 then
			    while #self.eyeballs > 0 do
				    local eyeball = table.remove( self.eyeballs )
				    sim:warpUnit( eyeball )
				    sim:despawnUnit( eyeball )
			    end
            end
        end,
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			sim:addTrigger( simdefs.TRG_UNIT_APPEARED, self )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_UNIT_APPEARED, self )
			self.abilityOwner = nil
		end,

		onTrigger = function( self, sim, evType, evData ) -- no double peeking
			if evType == simdefs.TRG_UNIT_APPEARED and evData.unit then
				local targetUnit = evData.unit
				targetUnit:getTraits().esPeeked = true
			end
		end,
	}
return neural_scan