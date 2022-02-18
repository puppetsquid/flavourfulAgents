local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

-------------------------------------------------------------------------
-- Trigger wireless onselect.

local function toggleCameraSight ( sim, block, unit )
		
		if unit ~= nil then 
			local sight = true
			if block then
				sight = false
			end
			
			
			sim:forEachUnit(
				function( mainframeUnit )
					local x1, y1 = mainframeUnit:getLocation()
					if x1 and y1 and (mainframeUnit:getTraits().mainframe_camera or mainframeUnit:getTraits().mainframe_turret) and (mainframeUnit:getTraits().hasSight or mainframeUnit:getTraits().blocked) then
						if (mainframeUnit:getTraits().mainframe_ice or 0) > 0 then
							mainframeUnit:getTraits().blocked = block
							mainframeUnit:getTraits().hasSight = sight
						end
						if mainframeUnit:getPlayerOwner() == sim:getPC() then
							mainframeUnit:getTraits().hasSight = true
							mainframeUnit:getTraits().blocked = false
						end
						sim:refreshUnitLOS( mainframeUnit )
						sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = mainframeUnit } )
					end
				end )
		end
end

local function refreshCams ( sim )
		sim:forEachUnit(
		    function( mainframeUnit )
			    local x1, y1 = mainframeUnit:getLocation()
			    if x1 and y1 and (mainframeUnit:getTraits().mainframe_camera or mainframeUnit:getTraits().mainframe_turret) and (mainframeUnit:getTraits().hasSight or mainframeUnit:getTraits().blocked) then
					sim:refreshUnitLOS( mainframeUnit )
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = mainframeUnit } )
			    end
		    end )
end

local function triggerCamBlocker( script, sim, selectedUnit, self )
    local level = include( "sim/level" )
    local userUnit = selectedUnit--:getUnitOwner()
    if userUnit == nil then
        return -- Only triggers if carried by somebody.
    end
	self._selectedUnit = selectedUnit

-- local unitID = nil
	
   local unitID =  script:waitFor( { uiEvent = level.EV_UNIT_SELECTED,
        fn = function( sim, unitID )
			if sim:getUnit(unitID) then
				toggleCameraSight ( sim, sim:getUnit(unitID):hasTrait("invisToCams") )
				return sim:getUnit(unitID):isValid()
			else
				return false
			end
        end } )
		refreshCams (sim)
		sim:getLevelScript():addHook( "BLOCKCAMERAS_DRACO", triggerCamBlocker, nil, selectedUnit, self )
end





-------------------------------------------------------------------------
-- Passive wireless scan; scans devices whenever the owning unit warps.

local camBlocker =
{
	name = STRINGS.ABILITIES.WIRELESS_SCAN,
	getName = function( self, sim, unit )
		return self.name
	end,
		
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
        sim:addTrigger( simdefs.TRG_END_TURN, self )
        sim:addTrigger( simdefs.TRG_START_TURN, self )
        self.hook = sim:getLevelScript():addHook( "BLOCKCAMERAS_DRACO", triggerCamBlocker, nil, unit, self )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_END_TURN, self )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        self.abilityOwner = nil
    --    sim:getLevelScript():removeHook( self.hook )
	end,

    canUseAbility = function( self, sim, abilityOwner, abilityUser )
        return abilityutil.checkRequirements( abilityOwner, abilityUser )
    end,

    onTrigger = function( self, sim, evType, evData )
        if self.abilityOwner and evType == simdefs.TRG_END_TURN then
            toggleCameraSight ( sim, false, true )
        end
		if self.abilityOwner and evType == simdefs.TRG_START_TURN then
			local selectedUnit = self._selectedUnit
			if selectedUnit then
				toggleCameraSight ( sim, selectedUnit:hasTrait("invisToCams"), self._selectedUnit )
			end
        end
    end,
	

}

return camBlocker
