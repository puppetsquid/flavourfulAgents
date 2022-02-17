local teamPreview = include( "states/state-team-preview" )
local util = include("modules/util")
local serverdefs = include("modules/serverdefs")
local skilldefs = include("sim/skilldefs")
local unitdefs = include("sim/unitdefs")

local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}
local POSSIBLE_COLOR = {r=0/255,g=184/255,b=0/255, a=1}
local BLANK_COLOR = {r=56/255,g=96/255,b=96/255, a=200/255}

local oldOnLoad = teamPreview.onLoad

local function updateSkills( self, agentIdx, loadoutIdx )
	local agentWidget = self._panel.binder[ "agent" .. agentIdx ]
	local agentID = serverdefs.SELECTABLE_AGENTS[ self._selectedAgents[ agentIdx ] ]
	local loadouts = serverdefs.LOADOUTS[ agentID ]
	local agentDef = unitdefs.lookupTemplate( loadouts[ loadoutIdx ] )
	
	for i, widget in agentWidget.binder:forEach( "skill" ) do			
		if agentDef.skills[i] then 

			skill = skilldefs.lookupSkill(agentDef.skills[i])
			
			widget.binder.costTxt:spoolText(skill.name,15)

			for i, barWidget in widget.binder:forEach( "bar" ) do
				barWidget.binder.meterbarSmall.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)					
			end

			widget.binder.bar1.binder.meterbarSmall.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
			widget:setVisible( true )

			local tooltip = "<c:F4FF78>".. skill.name.. "</>\n"..skill.description
			widget.binder.tooltip:setTooltip(tooltip)
			
		else 
			widget:setVisible(false)
		end
	end
	for i, skillUpgrade in pairs(agentDef.startingSkills) do
		for v, skill in ipairs(agentDef.skills) do
	  		for f=1,skillUpgrade-1 do
				if skill == i then
		     		 agentWidget.binder["skill"..v].binder["bar"..(1+f)].binder.meterbarSmall.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
				end
			end
		end		
	end
end

function teamPreview:onLoad()
	oldOnLoad(self)
	
	local function onClickLoadout( self, agentIdx, loadoutIdx, oldFn )
		oldFn._fn( self, agentIdx, loadoutIdx )
		updateSkills( self, agentIdx, loadoutIdx )
	end
	
	local function randomizeEverything(self,oldFn)
		oldFn._fn( self )
		updateSkills( self, 1, self._selectedLoadouts[ 1 ] )
		updateSkills( self, 2, self._selectedLoadouts[ 2 ] )
	end

	for i, widget in self._panel.binder.agent1.binder:forEach( "loadoutBtn" ) do 
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickLoadout, self, 1, i, widget.binder.btn.onClick ) 
	end 

	for i, widget in self._panel.binder.agent2.binder:forEach( "loadoutBtn" ) do 
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickLoadout, self, 2, i, widget.binder.btn.onClick  ) 
	end
	
	self._panel.binder.randomizeBtn.onClick = util.makeDelegate( nil, randomizeEverything, self, self._panel.binder.randomizeBtn.onClick )
end