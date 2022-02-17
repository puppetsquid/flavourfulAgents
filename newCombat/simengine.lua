local array = include("modules/array")
local simengine = include("sim/engine")
local simquery = include("sim/simquery")
local simdefs = include("sim/simdefs")

local oldHitUnit = simengine.hitUnit

function simengine:hitUnit( sourceUnit, targetUnit, dmgt )
	--Hack. We assume that guns have noTargetAlert set to either nil or true, and only batons have it set to false (see melee)
	if not sourceUnit:getTraits().isAgent or dmgt.noTargetAlert == false or dmgt.noCheckForEMP then
		return oldHitUnit( self, sourceUnit, targetUnit, dmgt )
	end
	
	local equipped = simquery.getEquippedGun(sourceUnit)
	local hasKeensight = array.findIf( sourceUnit:getChildren(), function( u ) return u:getTraits().hasKeensight ~= nil end ) ---  find if has Shalem Aug
	if (hasKeensight and hasKeensight:getTraits().addArmorPiercingRanged and targetUnit:getTraits().heartmonTagged) or equipped:getTraits().EMP_bullets then 
		local hadMagnetic_reinforcement = targetUnit:getTraits().magnetic_reinforcement
		targetUnit:getTraits().magnetic_reinforcement = nil
		if targetUnit:getTraits().improved_heart_monitor then
			targetUnit:getTraits().improved_heart_monitor = nil
			local x1, y1 = targetUnit:getLocation()
			self:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/HitResponse/hitby_distrupter_flesh", x=x1,y=y1} )
			local pierceString = "Advanced Heart Monitor Disabled"
			self:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=pierceString,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )	
			self:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/hostage/heart_shutoff") 	
		end
		targetUnit:processEMP( 2 )
		targetUnit:getTraits().magnetic_reinforcement = hadMagnetic_reinforcement
	end
	if equipped:getTraits().hidesBody then
		--targetUnit:setPlayerOwner(sourceUnit:getPlayerOwner())
		--targetUnit:setInvisible(true, 9999)
		local targetRig = self._board:getUnitRig( targetUnit:getID() )
		targetRig:setRenderFilter( cdefs.RENDER_FILTERS["cloak"] )
		targetUnit:getTraits().hideBody = true
	end
	return oldHitUnit( self, sourceUnit, targetUnit, dmgt )
end

--[==[]==]
local oldCanUnitSeeUnit = simengine.canUnitSeeUnit


function simengine:canUnitSeeUnit( unit, targetUnit )
    
	if targetUnit and targetUnit:getTraits().invisToCams  then
		if unit and oldCanUnitSeeUnit( self, unit, targetUnit ) and (unit:getTraits().mainframe_camera or unit:getTraits().mainframe_turret) then
			log:write( "CAMBUG" )
			local sim = unit:getSim()
			sim:dispatchEvent( simdefs.EV_UNIT_WIRELESS_SCAN, { unitID = targetUnit:getID(), targetUnitID = unit:getID(), hijack = true } )
			return false, false
			
		end
	end
	return oldCanUnitSeeUnit( self, unit, targetUnit )
	
end


--[[=======================
borrowed with love from Sizzlefrost
=======================]]--

oldRefreshUnitLOS = simengine.refreshUnitLOS
function simengine:refreshUnitLOS( unit )
	--log:write("LOS")
	if unit:getTraits().senseRange and unit:getTraits().activeRange then
		--log:write("LOS BANKS")
		unit:getTraits().LOSrange = unit:getTraits().senseRange
		unit:getTraits().banksBlink = true
		oldRefreshUnitLOS( self, unit )
		unit:getTraits().LOSrange = unit:getTraits().activeRange
		unit:getTraits().banksBlink = nil
	end
	return oldRefreshUnitLOS( self, unit )
end