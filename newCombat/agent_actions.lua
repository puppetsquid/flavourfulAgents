local agent_actions = include("hud/agent_actions")

local oldPerformDoorAction = agent_actions.performDoorAction

local function performDoorAction( game, exitOp, unit, cell, dir )
	oldPerformDoorAction( game, exitOp, unit, cell, dir )
	unit:getSim():triggerEvent( "trgDoorAction", {exitOp=exitOp, unitID=unit:getID(), x0=cell.x, y0=cell.y, facing=dir} )
end

agent_actions.performDoorAction = performDoorAction


local oldGeneratePotentialActions = agent_actions.generatePotentialActions

local function generatePotentialActions( hud, actions, unit, cellx, celly )
	oldGeneratePotentialActions( hud, actions, unit, cellx, celly )
	for i, action in pairs(actions) do
		if action.exitop then
			action.onClick = function() performDoorAction( hud._game, action.exitop, unit, action.cell, action.dir ) end
		end
	end
end

agent_actions.generatePotentialActions = generatePotentialActions