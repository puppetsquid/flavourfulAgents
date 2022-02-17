local guiex = include( "guiex" )
local cdefs = include( "client_defs" )

local oldupgrades = include("client/states/state-upgrade-screen")



function findSkillTreeCost (skillDefs, skill)

	local treeVal = skill.treeVal or 0
	local mulitplier = treeVal + 1
	local cost = skillDef[ skill.level + 1 ].cost

end


function skillChanges:learnSkill( agentIdx, skillIdx )
    local agency = self.upgradeScreen._agency
    local agentDef = agency.unitDefs[ agentIdx ]
    local skill = agentDef.skills[ skillIdx ]
	local skillDef = skilldefs.lookupSkill( skill.skillID )
    local cost = skillDef[ skill.level + 1 ].cost

    -- Subtract cost, increase skill.
    if agency.cash >= cost then
        table.insert( self.changes, { skillIdx = skillIdx, agentIdx = agentIdx } )
        skill.level = skill.level + 1
	    agency.cash = agency.cash - cost
        return true

    else
        return false
    end
end

function skillChanges:undoSkill( agentIdx, skillIdx )
    for i, change in ipairs( self.changes ) do
        if change.skillIdx == skillIdx and change.agentIdx == agentIdx then
            local agency = self.upgradeScreen._agency
            local agentDef = agency.unitDefs[ agentIdx ]
            local skill = agentDef.skills[ skillIdx ]
        	local skillDef = skilldefs.lookupSkill( skill.skillID )
            local cost = skillDef[ skill.level ].cost

            -- Return cost, decrease skill
            skill.level = skill.level - 1
        	agency.cash = agency.cash + cost

            table.remove( self.changes, i )
            break
        end
    end
end




upgradeScreen.displaySkill = function(self, skillDef, level)

	self.screen.binder.tipTitle:setText( util.sformat(STRINGS.UI.UPGRADE_SCREEN_UPGRADE_TITLE, util.toupper(skillDef.name)) )

	for i, bar in self.screen.binder:forEach( "metterBar" ) do 
		if i <= level then
			bar.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
		elseif i <= skillDef.levels then
			bar.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
		else
			bar.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)
		end

		if i <= skillDef.levels then
			bar.binder.cost:setVisible(true)
			bar.binder.level:setVisible(true)
			bar.binder.txt:setVisible(true)

			bar.binder.cost:setText( util.sformat( STRINGS.FORMATS.CREDS, skillDef[i].cost ))
			bar.binder.level:setText( util.sformat( STRINGS.FORMATS.LEVEL, i ))
			bar.binder.txt:setText(skillDef[i].tooltip)	

			if i <= level then
				bar.binder.cost:setColor(0,0,0,1)
			else
				bar.binder.cost:setColor(140/255,1,1,1)
			end
		else
			bar.binder.cost:setVisible(false)
			bar.binder.level:setVisible(false)
			bar.binder.txt:setVisible(false)				
		end		
	end
end


upgradeScreen.refreshSkills = function( self, unitDef, k )

	local skills = unitDef.skills

	for i, skillWidget in self.screen.binder.skillGroup.binder:forEach( "skill" ) do 
		if i <= #skills then
			skillWidget:setVisible(true)
			local skill = skills[i]
			local skillDef = skilldefs.lookupSkill( skill.skillID )

			skillWidget.binder.skillTitle:setText(util.toupper(skillDef.name))
			skillWidget.binder.btnBack.onClick = util.makeDelegate( nil, onClickUndoSkill, self, k, i )	
			skillWidget.binder.btnFwd.onClick = util.makeDelegate( nil, onClickLearnSkill, self, k, i )	
			
			if skill.level < skillDef.levels and not self._lockedSkills[i] then 			
				local currentLevel = skillDef[ skill.level +1 ]
				skillWidget.binder.costTxt:setText( util.sformat( STRINGS.FORMATS.CREDITS, currentLevel.cost ))
				skillWidget.binder.btn:setDisabled(true) 							
				skillWidget.binder.btnFwd:setVisible(true)
							
			else 
				skillWidget.binder.btnFwd:setVisible(false)
				skillWidget.binder.costTxt:setText( STRINGS.UI.UPGRADE_SCREEN_MAX )
				skillWidget.binder.btn:setDisabled(true) 				
			end

            skillWidget.binder.btnBack:setVisible( self.changes:hasChanges( k, i ) )

			for j,bar in skillWidget.binder:forEach( "bar" ) do
				if j <=  skill.level - self.changes:countChanges( k, i ) then
					if self._lockedSkills[i] then
						bar.binder.bar:setColor(LOCKED_COLOR.r,LOCKED_COLOR.g,LOCKED_COLOR.b,LOCKED_COLOR.a)
					else
						bar.binder.bar:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
					end
				elseif j <= skill.level  then
					bar.binder.bar:setColor(TEST_COLOR.r,TEST_COLOR.g,TEST_COLOR.b,TEST_COLOR.a)
				elseif j <= skillDef.levels then
					if self._lockedSkills[i] then
						bar.binder.bar:setColor(LOCKED_BLANK.r,LOCKED_BLANK.g,LOCKED_BLANK.b,LOCKED_BLANK.a)
					else
						bar.binder.bar:setColor(POSSIBLE_COLOR.r,POSSIBLE_COLOR.g,POSSIBLE_COLOR.b,POSSIBLE_COLOR.a)
					end
				else
					bar.binder.bar:setColor(BLANK_COLOR.r,BLANK_COLOR.g,BLANK_COLOR.b,BLANK_COLOR.a)
				end
			end
			skillWidget.binder.btn:setColor(1,0,0,1)
		
			local toolTip = tooltip(self,skill,skillDef,i, k)
			skillWidget:setTooltip(toolTip) 

			local tooltipBtnPlus = tooltipBtnPlus(self,skill,skillDef,i, k)
			skillWidget.binder.btnFwd:setTooltip(tooltipBtnPlus) 
			local tooltipBtnMinus = tooltipBtnMinus(self,skill,skillDef,i, k)
			skillWidget.binder.btnBack:setTooltip(tooltipBtnMinus) 

		else
			skillWidget:setVisible(false)
			if not self._firstTime then
				for i, widget in self.screen.binder.skillGroup.binder:forEach("num") do 
					local x0, y0 = widget:getPosition()
					widget:setPosition(x0, y0+40)
				end
			end
		end
	end

	self._firstTime = true
end