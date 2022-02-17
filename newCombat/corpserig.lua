----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local animmgr = include( "anim-manager" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local unitrig = include( "gameplay/unitrig" )

-----------------------------------------------------------------------------------
-- Local

local simdefs = nil -- Lazy initialized after the sim is mounted.
local simquery = nil -- Lazy initialized after the sim is mounted.

-------------------------------------------------------------

local corpserig = class( unitrig.rig )

function corpserig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )
	self:setCurrentAnim( "dead" )
	self:setPlayMode( KLEIAnim.ONCE )
	self._prop:setFrame( self._prop:getFrameCount() - 1 )	
end

function corpserig:refreshRenderFilter()
	if self._renderFilterOverride then
		self._prop:setRenderFilter( self._renderFilterOverride )
	else
		local unit = self._boardRig:getLastKnownUnit( self._unitID )
		if unit then
			local gfxOptions = self._boardRig._game:getGfxOptions()
			
				if unit:getTraits().invisible then
					self._prop:setRenderFilter( cdefs.RENDER_FILTERS["cloak"] )
					log:write( "CLOAKED TRY" )
				elseif unit:isPC() then
					self._prop:setRenderFilter( cdefs.RENDER_FILTERS["default"] )
                else
					self._prop:setRenderFilter( cdefs.RENDER_FILTERS["shadowlight"] )
				end
				
		end
	end
end

return
{
	rig = corpserig,
}

