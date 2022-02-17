local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )

------------------------------------------------------------------
--

function processCell (sim, cellx, celly, availableTargets, player, unit)  -- see if player 
--	if unit then
--		log:write("FOUND: %s", unit:getName())
--	end
	if cellx and celly then
		if not player:getLastKnownCell (sim, cellx, celly) then
			table.insert( availableTargets, sim:getCell(cellx, celly) )
		end
	end
end

function isCoreItem( unit )
		if unit:getTraits().largenano or unit:getTraits().bigshopcat or unit:getTraits().vip or unit:getTraits().detention or unit:getTraits().public_term or unit:getTraits().scanner then
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
			elseif unit:getTraits().storeType == "standard" or unit:getTraits().storeType == "miniserver" then
				return true
			elseif unit:getTraits().security_box then
				return true
			elseif unit:getTraits().powerGrid then
				return true
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

	if not sim._showOutline == true then
						sim._showOutline = true
						sim:dispatchEvent( simdefs.EV_WALL_REFRESH )

						local x0,y0 = unit:getLocation()
						local color = {r=1,g=1,b=41/255,a=1}
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.FACILITY_REVEALED,x=x0,y=y0,color=color,alwaysShow=true} )
					end	
end

local function isValidExit(cell, dir)
	return cell.exits[dir] and not cell.exits[dir].closed and not cell.exits[dir].door
end

local function inSameRoom(sim, player, prevCell, testCell)
	local simquery = sim:getQuery()
	local dx, dy = testCell.x - prevCell.x, testCell.y - prevCell.y
	if dx~=0 and dy~=0 then --diagonal, check two directions
		local cell3 = sim:getCell(prevCell.x, testCell.y)
		local cell4 = sim:getCell(testCell.x, prevCell.y)
		if not cell3 or not cell4 then
			return false
		end

		local dir1, dir2 = simquery.getDirectionFromDelta(0, dy), simquery.getDirectionFromDelta(dx, 0)
		local dir3, dir4 = simquery.getDirectionFromDelta(dx, 0), simquery.getDirectionFromDelta(0, dy)

		if isValidExit(prevCell, dir1) and isValidExit(cell3, dir2)
		 and isValidExit(prevCell, dir3) and isValidExit(cell4, dir4) then
			return true
	 	end
	else
		local dir = simquery.getDirectionFromDelta(dx, dy)
		if isValidExit(prevCell, dir) then
			return true
		end
	end
	return false
end

local neural_scan_2 =
	{
		name = STRINGS.DLC1.NEURAL_SCAN,
		usesAction = true,
		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		createToolTip = function( self,sim,abilityOwner,abilityUser,targetID)
			local target = sim:getUnit(targetID)
			if target:isKO() then
				return abilityutil.formatToolTip(STRINGS.DLC1.NEURAL_SCAN, "Reveal an unknown area of map") --STRINGS.DLC1.NEURAL_SCAN_DESC_KO )				
			else
				return abilityutil.formatToolTip(STRINGS.DLC1.NEURAL_SCAN, "Reveal the highest-priority unknown area of map") --STRINGS.DLC1.NEURAL_SCAN_DESC_DEAD )
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
				if ((cellUnit:getTraits().iscorpse and not cellUnit:getTraits().wasDrone) or ((cellUnit:isKO() or cellUnit:isDead()) and cellUnit:getTraits().isGuard and not cellUnit:getTraits().isDrone)) then
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
			
			if userUnit:getAP() < 1 then 
				return false, STRINGS.UI.HUD_ATTACK_USED
			end 
			
			local unknowncells = true
			
			sim:forEachCell(function(cell)
				if not sim:getPC():getLastKnownCell (sim, cell.x, cell.y) then
					local unknowncells = false
				end
			end)
			
			if not unknowncells then
				return false
			end
			
			

--[==[			if #getSkillList( sim, userUnit ) < 1 and not sim:isVersion("0.17.10") and userUnit:getTraits().isAgent then
				return false
			end
]==]
			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit, target )
			local target = sim:getUnit(target)	
			
			userUnit:useAP( sim )
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/transferData" )
			 local player = sim:getCurrentPlayer()
			 local availableTargets = {}
			
			if target:getTraits().iscorpse then
				for _, testunit in pairs( sim:getAllUnits() ) do
					if isCoreItem(testunit) then
							local cellx, celly = testunit:getLocation()
							processCell (sim, cellx, celly, availableTargets, player, testunit)
					end
				end
				if #availableTargets < 1 then
					for _, testcell in pairs( simquery.findExitCells( sim ) ) do 
								processCell (sim, testcell.x, testcell.y, availableTargets, player)
					end
				end
				if #availableTargets < 1 then
					for _, testunit in pairs( sim:getAllUnits() ) do
						if isUsefulItem(testunit) then
								local cellx, celly = testunit:getLocation()
								processCell (sim, cellx, celly, availableTargets, player, testunit)
						end
					end
				end
			end
			if #availableTargets < 1 then
				for _, testunit in pairs( sim:getAllUnits() ) do 
						if testunit:getPlayerOwner() ~= player and (testunit:getTraits().mainframe_ice or 0) > 0 and testunit:getTraits().mainframe_status ~= "off" then		
							local cellx, celly = testunit:getLocation()
							processCell (sim, cellx, celly, availableTargets, player, testunit)
						end
						if testunit:getPlayerOwner() ~= player and testunit:getTraits().isGuard then		
							local cellx, celly = testunit:getLocation()
							processCell (sim, cellx, celly, availableTargets, player, testunit)
						end
					
				end
			end
			if #availableTargets < 1 then
				sim:forEachCell(function(cell)
					processCell (sim, cell.x, cell.y, availableTargets, player)
				end)
			end
			
			-------
			
			if  #availableTargets > 0 then
				local espcell = availableTargets[ sim:nextRand( 1, #availableTargets ) ]
				if target:getTraits().iscorpse then
					-- addInfo( sim, userUnit)

				--	self:esPeek( unit, target, espcell )

					self:highlight( unit, sim, espcell, true )
				
				elseif target:isKO() then
				
					self:highlight( unit, sim, espcell, false )
					
				end
				
			--	target:getTraits().neural_scanned = true
				
				
				--espunit:getTraits().esPeeked = true
			end
			-- self:removePeek( sim )
			 
			
		end,

		
		
		highlight = function( self, unit, sim, espcell, full )
			
			local cell = espcell
			local x0, y0 = cell.x, cell.y
			
			local range = 1
			local AOE = 2
			local area = {}
			table.insert( area, cell )
			if full then
				range = 6
				AOE = 2
			end
			area = simquery.floodFill(sim, nil, cell, AOE, nil, inSameRoom)
			
			sim:dispatchEvent( simdefs.EV_CAM_PAN, { x0, y0 } )	
			local delay = .5
			sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		
			local eyeball = include( "sim/units/eyeball" )
			local eyeballUnit = eyeball.createEyeball( sim )
			eyeballUnit:setPlayerOwner( unit:getPlayerOwner() )
		--	eyeballUnit:setFacing( simquery.getDirectionFromDelta( dx, dy ) )
            eyeballUnit:getTraits().peekID = unit:getID()

			eyeballUnit:getTraits().LOSarc = math.pi * 2	
			eyeballUnit:getTraits().LOSrange = range	

			sim:spawnUnit( eyeballUnit )
			table.insert( self.eyeballs, eyeballUnit )
			
			for i, loc in pairs(area) do
				sim:warpUnit( eyeballUnit, loc)
				for _, cellUnit in ipairs( loc.units ) do
					cellUnit:getTraits().esPeeked = true
				end
				
				loc.esPeeked = true
			end
			
			self:removePeek( sim )
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
		
	}
return neural_scan_2