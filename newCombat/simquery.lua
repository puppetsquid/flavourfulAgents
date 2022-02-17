local simquery = include( "sim/simquery" )

--------------------------------------------------------------------------

local old_isEnemyTarget = simquery.isEnemyTarget

function simquery.isEnemyTarget( player, unit, ignoreDisguise )
	if unit and unit:getTraits().forceEnemy then
		return true
	end
	if unit and unit:getTraits().forceNeutral then
		return false
	end
	if not old_isEnemyTarget( player, unit, ignoreDisguise ) then
		return false
	end
	
	return true
end

local old_isUnitPinning = simquery.isUnitPinning

function simquery.isUnitPinning( sim, unit )
	if unit:getTraits().pinningOverride ~= nil and (unit:getTraits().pinningOverride == true or unit:getTraits().pinningOverride == false) then
		return unit:getTraits().pinningOverride
	end
	return old_isUnitPinning( sim, unit )
end

--[==[
local old_couldUnitSee = simquery.couldUnitSee


function simquery.couldUnitSee( sim, unit, targetUnit, ignoreCover, targetCell )
    
	if unit and targetUnit then
	--	if unit:getTraits().camera_drone and targetUnit.agentID == 1003 then
		--	return false
	--	end
	
		if unit:getTraits().banksBlink and not targetUnit == sim:getCell( targetUnit:getLocation() ) then -- and targetUnit.units
			log:write("HIDDED")
			return false
		end
	end
	
	return old_couldUnitSee( sim, unit, targetUnit, ignoreCover, targetCell )
	
end



local old_countFieldAgents = simquery.countFieldAgents

function simquery.countFieldAgents( sim )
	
	local fieldUnits, escapingUnits = old_countFieldAgents( sim )
	
	for _, unit in pairs( fieldUnits ) do
        if unit:hasAbility( "escape" ) then
            local cell = sim:getCell( unit:getLocation() )
            if cell == nil then
                table.insert( escapingUnits, unit )
                table.remove( fieldUnits, unit )
            end
        end
    end
    return fieldUnits, escapingUnits
	
	return true
end


local old_isUnitPinning = simquery.isUnitPinning
function simquery.isUnitPinning( sim, unit )
	if unit:getTraits().pinningOverride then
		return true
	else
		return old_isUnitPinning( sim, unit)
	end
end]==]