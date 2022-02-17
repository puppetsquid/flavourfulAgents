local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include("sim/simquery")

simunit.hasSkill = function ( self, skillID, level, isDirectCheck ) ---- adds 'any skill' 
	if self._skills then
		for i,skill in ipairs(self._skills) do
			if (skill:getID() == skillID or skillID == "anySkill") and (level == nil or skill:getCurrentLevel() >= level) then
				return skill
			elseif (skill:getID() == skillID or skillID == "anySkill") and not isDirectCheck and self:getTraits().addHalfSkill and not self:getTraits().addHalfSkill == skillID and not level == nil then -- 'addHalfSkill', possible Xu ability (adds half hacking toward meeting item reqs), change any 'hasSkills' to add 'isDirectCheck' to avoid this firing incorrectly
				local combiSkill = skill:getCurrentLevel() + ( self:getSkillLevel( self:getTraits().addHalfSkill ) * 0.5 )
				if combiSkill >= level then
					return skill
				end
			end
		end
	end

	return nil
end

local oldCanUseAbility = simunit.canUseAbility

simunit.canUseAbility = function ( self, sim, abilityDef, abilityOwner, ... )  --- adds 'pacifism' on damaging weps
		if (abilityOwner:getTraits().baseDamage and abilityOwner:getTraits().baseDamage > 0) or (abilityOwner:getTraits().damage and abilityOwner:getTraits().damage > 0)  then 
			--local abilname = abilityDef.pacifist
		if not abilityDef.pacifist and self:getTraits().pacifist then
			local unitNums = 0
			for i, u in pairs( self:getPlayerOwner():getUnits() ) do -- if agent is threatened then morals are loose
                if simquery.isUnitUnderOverwatch(u) then
					unitNums = unitNums + 1					
				end
			end
			if unitNums == 0 then
				return false, "Inhibited by Pacifism"
			end
		end
		if self:getTraits().noKill and not (abilityOwner:getTraits().canSleep or (abilityOwner:getTraits().melee and not abilityOwner:getTraits().lethalMelee)) then
			return false, "Agent Won't Kill"
		end
	end
	
	return oldCanUseAbility( self, sim, abilityDef, abilityOwner, ... )
end

local oldRemoveChild = simunit.removeChild

simunit.removeChild = function ( self, childUnit )
	oldRemoveChild( self, childUnit )
	self:getSim():triggerEvent( "unitUnparented", {childUnit=childUnit, parent=self} )
end


local oldAddChild = simunit.addChild

simunit.addChild = function ( self, childUnit, sim )
	oldAddChild( self, childUnit, sim )
	if self:getSim() then
		self:getSim():triggerEvent( "unitParented", {childUnit=childUnit, parent=self} )
	else
	log:write("HIDDED")
	end
end	

--[==[]==]
local oldAddSeenUnit = simunit.addSeenUnit

function simunit:addSeenUnit( unit )
	if not (self:getTraits().banksBlink and not unit:getTraits().bankedVision) then
		unit:getTraits().bankedVision = true
		oldAddSeenUnit ( self, unit)
	end
end

