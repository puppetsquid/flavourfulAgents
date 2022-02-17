----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui_defs = include( "mui/mui_defs")
local world_hud = include( "hud/hud-inworld" )
local simquery = include( "sim/simquery" )
local mathutil = include( "modules/mathutil" )
local geo_util = include( "geo_util" )

------------------------------------------------------------------------------
-- Local functions
------------------------------------------------------------------------------

local areaTargetBase = class()

function areaTargetBase:init( game, range, sim )
	self._game = game
	self.sim = sim 
	self._hiliteClr = { 0.5, 0.5, 0.5, 0.5 }
	self.mx = nil
	self.my = nil
	self.range = range
    self.unitTargets = {}
end

function areaTargetBase:setUnitPredicate( unitTargetFn )
    self.unitTargetFn = unitTargetFn
end

function areaTargetBase:setHiliteColor( clr )
    self._hiliteClr = clr
end

function areaTargetBase:hasTargets()
	return true
end

function areaTargetBase:setTargetCell( cellx, celly )
    self.mx, self.my = cellx, celly

	if self:isValidTargetLoc( cellx, celly ) then
		self.cells = simquery.rasterCircle( self.sim, cellx, celly, self.range )
    else
        self.cells = nil
    end

     if self.unitTargetFn then
        local count = #self.unitTargets
        if self.cells then
		    for i = 1, #self.cells, 2 do
                local cell = self.sim:getCell( self.cells[i], self.cells[i+1] )
                if cell then
                    for j, cellUnit in ipairs(cell.units) do
                        if self.unitTargetFn( cellUnit ) then
                            -- Hey: does this already exist in the list?
                            local idx = array.find( self.unitTargets, cellUnit:getID() )
                            if idx then
                                table.insert( self.unitTargets, table.remove( self.unitTargets, idx ))
                                count = count - 1
                            else
                                table.insert( self.unitTargets, cellUnit:getID() )
                                self._game.boardRig:getUnitRig( cellUnit:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["focus_target"] )
                            end
                        end
                    end
                end
            end
		end

        while count > 0 do
            local unitRig = self._game.boardRig:getUnitRig( table.remove( self.unitTargets, 1 ))
            unitRig:refreshRenderFilter()
            count = count - 1
        end
    end
end

function areaTargetBase:endTargeting()
    self:setTargetCell( nil, nil )
end


function areaTargetBase:onInputEvent( event )
	if event.eventType == mui_defs.EVENT_MouseDown and event.button == mui_defs.MB_Left then
        self.ux, self.uy = event.wx, event.wy

	elseif event.eventType == mui_defs.EVENT_MouseUp and event.button == mui_defs.MB_Left then
        if mathutil.dist2d( self.ux or event.wx, self.uy or event.wy, event.wx, event.wy ) >= 16 then
            return nil
        else
		    local x, y = self._game:wndToSubCell( event.wx, event.wy )	
		    local cellx, celly = math.floor(x), math.floor(y)
		    if self:isValidTargetLoc(cellx, celly) then
			    return {cellx, celly}
		    else
			    return nil
		    end
        end
	elseif event.eventType == mui_defs.EVENT_MouseMove then
		local x, y = self._game:wndToSubCell( event.wx, event.wy )
        x, y = math.floor(x), math.floor(y)
        if x ~= self.mx or y ~= self.my then
            self.tooltip = self:generateTooltip( x, y )
            self:setTargetCell( x, y )
        end
    end
end

function areaTargetBase:onDraw()
	MOAIGfxDevice.setPenColor(unpack(self._hiliteClr))
	if self.cells then
		for i = 1, #self.cells, 2 do
            local x, y = self.cells[i], self.cells[i+1]
			local x0, y0 = self._game:cellToWorld( x + 0.4, y + 0.4 )
			local x1, y1 = self._game:cellToWorld( x - 0.4, y - 0.4 )
			MOAIDraw.fillRect( x0, y0, x1, y1 )
		end
        return true
	end

    return false
end

function areaTargetBase:generateTooltip( x, y )
    return nil
end

function areaTargetBase:getTooltip( x, y )
    return self.tooltip
end

function areaTargetBase:getDefaultTarget()
	return nil
end


---------------------------------------------------------------------
-- Simple Cell targeting -- can target ANY cell.

local simpleAreaTarget = class( areaTargetBase )

function simpleAreaTarget:isValidTargetLoc(x, y)
    return x and y
end

---------------------------------------------------------------------
-- Visible Area Cell targeting -- can target ONLY cells that have been seen.

local areaCellTarget = class( areaTargetBase )

function areaCellTarget:init( game, range, sim, player, unitTargetFn )
    areaTargetBase.init( self, game, range, sim, unitTargetFn )
    self.player = player
end

function areaCellTarget:isValidTargetLoc(x, y)
    return x and y and self.player:getLastKnownCell( self.sim, x, y ) ~= nil
end

function areaCellTarget:generateTooltip( x, y )
    if not self:isValidTargetLoc(x, y) then
        return "<c:ff0000>" .. STRINGS.UI.REASON.BAD_TARGET_VIZ .."</>"
    end
end

---------------------------------------------------------------------
-- Throwing.

local throwTarget = class( areaTargetBase )

function throwTarget:init( game, range, sim, unit, isTargetFn, ignoreLOS )
    areaTargetBase.init( self, game, range, sim, isTargetFn )
	self.unit = unit
	self.unitRange = unit:getTraits().maxThrow
	self._ignoreLOS = ignoreLOS
end

function throwTarget:endTargeting()
    areaTargetBase.endTargeting( self )
	if self.prop then
		self._game.boardRig:getLayer("ceiling"):removeProp(self.prop)
		self.prop = nil
	end
end

function throwTarget:isValidTargetLoc(x, y)
	if not x or not y then
		return false
	end

--	if not self.sim:getQuery().is360viewClear( self.sim, self.unit, self.unitRange,x,y) then
--		return false
--	end	
--	_M.is360viewClear(sim,unit,unitRange,x,y) --- this is the original is360ViewClear, edited with values above
	assert( self.unit and self.unitRange )
	local ux, uy = self.unit:getLocation()
	local dist = mathutil.dist2d(ux, uy, x, y)
	if dist > self.unitRange then
		return false
	end
	
	
	local possThrow = nil
	
	local raycastX, raycastY = self.sim:getLOS():raycast(ux, uy, x, y) --- attempt raycast
	if not (raycastX ~= x or raycastY ~= y) then-	
		possThrow = true --return false
	end
	
	local cell = sim:getCell( userUnit:getLocation() ) --- attempt raycast from adjacent squares (basically you can 'lean' a little and reach targets shooting wouldn't)
	local units = {}
	for dir, exit in pairs(cell.exits) do
		local raycastX, raycastY = self.sim:getLOS():raycast(ux, uy, x, y) 
		if not (raycastX ~= x or raycastY ~= y) then-	
			possThrow = true --return false
		end
	end	
	
	if not possThrow then
		return false
	end
--	return true --- continue with original code from here
		

	if not self.unit:getTraits().explodes then
		local cell = self.sim:getCell(x, y)
		if cell and cell.impass > 0 then
			return false
		end
	end

	local targetCell = self.sim:getCell(x,y)
	if self.sim:isVersion("0.17.9") and targetCell and self.sim:getQuery().cellHasTag( self.sim, targetCell, "interruptNonCentral" ) then		
		return false
	end

	--LOS passes through cell door
	if self.sim:isVersion("0.17.9") and targetCell and self.sim:getQuery().cellHasTag( self.sim, targetCell, "interruptNonCentral" ) then
		return false
	end

	return true
end

function throwTarget:onInputEvent( event )
	local x, y = self.mx, self.my
	local result = areaTargetBase.onInputEvent(self, event)
	if result then
		return result
	end
	if self.mx ~= x or self.my ~= y then
		if self:isValidTargetLoc(self.mx, self.my) then
			if not self.prop then
				self.prop = MOAIProp.new()
			end
		    local x0, y0 = self._game:cellToWorld(self.unit:getLocation() )
		    local x1, y1 = self._game:cellToWorld(self.mx, self.my)

			local msh = geo_util.generateArcMesh(self._game.boardRig, x0, y0, 0, x1, y1, 0, 30, 10)
			self.prop:setDeck(msh)
			self.prop:setLoc(x0, y0)
			self._game.boardRig:getLayer("ceiling"):insertProp(self.prop)
		else
			if self.prop then
				self._game.boardRig:getLayer("ceiling"):removeProp(self.prop)
				self.prop = nil
			end
		end
	end
end

function throwTarget:generateTooltip( x, y )
    if not self:isValidTargetLoc(x, y) then
        return "<c:ff0000>" .. STRINGS.UI.REASON.BAD_TARGET_RANGE .. "</>"
    end
end


function throwTarget:onDraw()
	MOAIGfxDevice.setPenColor(unpack(self._hiliteClr))
	if self.mx and self.my and self:isValidTargetLoc(self.mx, self.my) then
		local cells = simquery.rasterCircle( self.sim, self.mx, self.my, self.range )
		for i = 1, #cells, 2 do
            local x, y = cells[i], cells[i+1]
			local player = self.unit:getPlayerOwner()
			local raycastX, raycastY = self.sim:getLOS():raycast(self.mx, self.my, x, y)
			if ((raycastX == x and raycastY == y) or self._ignoreLOS ) and player:getLastKnownCell (self.sim, x, y) then --self.sim:canPlayerSee(self.unit:getPlayerOwner(), x, y) then
				local x0, y0 = self._game:cellToWorld( x + 0.4, y + 0.4 )
				local x1, y1 = self._game:cellToWorld( x - 0.4, y - 0.4 )
				MOAIDraw.fillRect( x0, y0, x1, y1 )
			end
		end
        return true
	end

    return false
end

---------------------------------------------------------------------
-- Cell targeting.

local cellTarget = class()

function cellTarget:init( game, cells, ability, abilityOwner, abilityUser )
	self._game = game
	self._hiliteClr = { 10/255, 70/255, 10/255, 0.05 }
	self._cells = cells
	self._ability = ability
	self._abilityOwner = abilityOwner
	self._abilityUser = abilityUser
end

function cellTarget:hasTargets()
	return #self._cells > 0
end

function cellTarget:getDefaultTarget()
	if #self._cells == 1 then
		return { self._cells[1].x, self._cells[1].y }
	end

	return nil
end

function cellTarget:onInputEvent( event )
end

function cellTarget:startTargeting( cellTargets )
	local agent_panel = include( "hud/agent_panel" )
	local sim = self._game.simCore
	for i, cell in ipairs( self._cells ) do
		local wx, wy = self._game:cellToWorld( cell.x, cell.y )
		wx, wy = cellTargets:findLocation( wx, wy )

		local wz = 0

		local widget = self._game.hud._world_hud:createWidget( world_hud.HUD, "Target", {  worldx = wx, worldy = wy, worldz = wz } )
		agent_panel.updateButtonFromAbilityTarget( self._game.hud._agent_panel, widget, self._ability, self._abilityOwner, self._abilityUser, { cell.x, cell.y } )
	end
end

function cellTarget:endTargeting( hud )
	hud._world_hud:destroyWidgets( world_hud.HUD )
end

function cellTarget:onDraw()
	MOAIGfxDevice.setPenColor(unpack(self._hiliteClr))

	for i,cell in ipairs(self._cells) do 
		local x0, y0 = self._game:cellToWorld( cell.x + 0.4, cell.y + 0.4 )
		local x1, y1 = self._game:cellToWorld( cell.x - 0.4, cell.y - 0.4 )
		MOAIDraw.fillRect( x0, y0, x1, y1 )
	end
end


---------------------------------------------------------------------
-- Exit targeting.

local exitTarget = class()

function exitTarget:init( game, exits, ability, abilityOwner, abilityUser )
	self._game = game
	self._exits = exits
	self._ability = ability
	self._abilityOwner = abilityOwner
	self._abilityUser = abilityUser
end

function exitTarget:hasTargets()
	return #self._exits > 0
end

function exitTarget:getDefaultTarget()
	return nil
end

function exitTarget:onInputEvent( event )
end

function exitTarget:startTargeting( cellTargets )
	local agent_panel = include( "hud/agent_panel" )
	local sim = self._game.simCore
	for i, exit in ipairs( self._exits ) do
		local dx, dy = simquery.getDeltaFromDirection( exit.dir )
		local x1, y1 = exit.x + dx, exit.y + dy
		local wx, wy = self._game:cellToWorld( (exit.x + x1)/2, (exit.y + y1)/2 )
		wx, wy = cellTargets:findLocation( wx, wy )
		local widget = self._game.hud._world_hud:createWidget( world_hud.HUD, "Target", {  worldx = wx, worldy = wy, worldz = 36, layoutID = string.format( "%d,%d-%d", exit.x, exit.y, exit.dir ) } )
		agent_panel.updateButtonFromAbilityTarget( self._game.hud._agent_panel, widget, self._ability, self._abilityOwner, self._abilityUser, exit.x, exit.y, exit.dir  )
	end
end

function exitTarget:endTargeting( hud )
	hud._world_hud:destroyWidgets( world_hud.HUD )
end

---------------------------------------------------------------------
-- Direction targeting.

local directionTarget = class()

function directionTarget:init( game, x0, y0 )
	self._game = game
	self._x0, self._y0 = x0, y0
end

function directionTarget:hasTargets()
	return true
end

function directionTarget:getDefaultTarget()
	return nil
end

function directionTarget:onInputEvent( event )
	if (event.eventType == mui_defs.EVENT_MouseDown and event.button == mui_defs.MB_Left) or event.eventType == mui_defs.EVENT_MouseMove then
		local cellx, celly = self._game:wndToCell( event.wx, event.wy )
		if cellx and celly then
			local dx, dy = cellx - self._x0, celly - self._y0
			if dx ~= 0 or dy ~= 0 then
				local simquery = self._game.simCore:getQuery()
				self._target = simquery.getDirectionFromDelta( dx, dy )
				if event.eventType == mui_defs.EVENT_MouseDown then
					return self._target
				end
			end
		end
	end
end

function directionTarget:onDraw()
	if self._target then
		MOAIGfxDevice.setPenColor( 0, 1, 0 )

		local simquery = self._game.simCore:getQuery()
		local dx, dy = simquery.getDeltaFromDirection( self._target )
		local x0, y0 = self._game:cellToWorld( self._x0, self._y0 )
		local x1, y1 = self._game:cellToWorld( self._x0 + dx, self._y0 + dy )

		MOAIDraw.drawLine( x0, y0, x1, y1 )
	end
end

---------------------------------------------------------------------
-- Unit targeting.

local unitTarget = class()

function unitTarget:init( game, units, ability, abilityOwner, abilityUser, noDefault )
	self._game = game
	self._units = units
	self._noDefault = noDefault
	self._ability = ability
	self._abilityOwner = abilityOwner
	self._abilityUser = abilityUser
end

function unitTarget:hasTargets()
	return #self._units > 0
end

function unitTarget:getDefaultTarget()
	if not self._noDefault and #self._units == 1 then
		return self._units[1]:getID()
	end
	return nil
end


function unitTarget:startTargeting( cellTargets )
	local agent_panel = include( "hud/agent_panel" )
	local sim = self._game.simCore
	for i, unit in ipairs( self._units ) do
		local cell = sim:getCell( unit:getLocation() )

		-- If targetting self in item-target mode, then the option shoudl go into the popup menu (eg. STIM)
		if unit == self._abilityUser and self._game.hud._state == self._game.hud.STATE_ITEM_TARGET then
			local realAgentPanel = self._game.hud._agent_panel
			table.insert(realAgentPanel._popUps,{ ability = self._ability, abilityOwner = self._abilityOwner, abilityUser = self._abilityUser, unitID = unit:getID() })
		else
			local wx, wy, wz = self._game:cellToWorld( cell.x, cell.y )
			wx, wy, wz = cellTargets:findLocation( wx, wy )

			wz = 0
			if unit:getTraits().breakIceOffset then
				wz = unit:getTraits().breakIceOffset
			end

			local widget = self._game.hud._world_hud:createWidget( world_hud.HUD, "Target", {  worldx = wx, worldy = wy, worldz = wz, layoutID = unit:getID() } )
			agent_panel.updateButtonFromAbilityTarget( self._game.hud._agent_panel, widget, self._ability, self._abilityOwner, self._abilityUser, unit:getID() )
		end
	end
end

function unitTarget:endTargeting( hud )
	hud._world_hud:destroyWidgets( world_hud.HUD )
end

function unitTarget:onInputEvent( event )
end

function unitTarget:onDraw()
end

return
{
    simpleAreaTarget = simpleAreaTarget,
	areaCellTarget = areaCellTarget, 
    throwTarget = throwTarget,
	cellTarget = cellTarget,
	exitTarget = exitTarget,
	directionTarget = directionTarget,
	unitTarget = unitTarget,
}
