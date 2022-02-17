local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local unitdefs = include( "sim/unitdefs" )

-------------------------------------------------------------------
--

local oldPeek = include("sim/abilities/peek")

local oldDoPeek = oldPeek.doPeek
local oldOnTrigger = oldPeek.onTrigger

local peek = util.extend(oldPeek) {
		doPeek = function( self, unit, view360, sim, x0,y0, peekInfo, dx, dy, exit )
			sim:addTrigger( simdefs.TRG_UNIT_WARP, self, unit )
			oldDoPeek( self, unit, view360, sim, x0,y0, peekInfo, dx, dy, exit )
			sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )			
		end,
		onTrigger = function( self, sim, evType, evData, unit )
			
			oldOnTrigger( self, sim, evType, evData, unit )
			
			
			if sim:getParams().difficultyOptions.flav_skills and (evType == simdefs.TRG_UNIT_WARP and evData.unit:getTraits().peekID ) then
				--log:write("New Peek")
				local eyeballUnit = evData.unit
				local ownerUnit = sim:getUnit( eyeballUnit:getTraits().peekID )
				
				if ownerUnit and ownerUnit:hasSkill("anarchy") and not (eyeballUnit:getTraits().LOSarc == math.pi * 2) then
					
					local skillLvl = ownerUnit:getSkillLevel("anarchy")
					local LOSarc = math.pi * 0.388888   ---- sliiight nerf to default arc (~70*)
					
					if skillLvl == 2 then
						LOSarc = math.pi * 0.5 	---- default (90*)
					elseif skillLvl == 3 then
						LOSarc = math.pi * 0.611111  ---- (~110*)
					elseif skillLvl == 4 then
						LOSarc = math.pi * 0.722222  ---- (~130*)
					elseif skillLvl == 5 then
						LOSarc = math.pi * 0.833333  ---- still can't see ajacent squares (~150)
					end
					
					eyeballUnit:getTraits().LOSarc = LOSarc
					sim:refreshUnitLOS(eyeballUnit)
				end
			end
		end,
}

return peek