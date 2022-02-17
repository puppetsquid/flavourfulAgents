local boardrig = include("gameplay/boardrig")
local simdefs = include("sim/simdefs")

local oldRefreshLOSCaster = boardrig.refreshLOSCaster


boardrig.refreshLOSCaster = function ( self, seerID )
	local seer = self._game.simCore:getUnit( seerID )
    local localPlayer = self:getLocalPlayer()
	local selectedUnit = false
	if self._game.hud then
		selectedUnit = self._game.hud:getSelectedUnit()
	end
	
	if seer and selectedUnit then
		local isVampire = ( selectedUnit:getTraits().invisToCams and (seer:getTraits().mainframe_camera or seer:getTraits().mainframe_turret))
		--local isBanksPeek = seer:getTraits().peekID and seer:getSim():getUnit( seer:getTraits().peekID ):getTraits().senseRange
		if (not isVampire) then
			oldRefreshLOSCaster( self, seerID )
		else
			self:clearBlindSpots( seerID )
			self._game.shadow_map:removeLOS( seerID )
			self._game.shadow_map:removeLOS( seerID + simdefs.SEERID_PERIPHERAL )
		end
	else
		oldRefreshLOSCaster( self, seerID )
	end
	
end
