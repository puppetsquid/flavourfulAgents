local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local shalem_stowBody =
{
	name = STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY,
	profile_icon = "gui/icons/Flavour/icon-action_dump_small.png",
	usesAction = true,
	canUseWhileDragging = true,
	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return util.sformat( STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY_DESC, util.toupper( targetUnit:getName() ),1)
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY
	end,

    isTarget = function( self, sim, userUnit, targetUnit )
        if targetUnit:getTraits().safeUnit then
            return true
        end
        return false
    end,

	acquireTargets = function( self, targets, game, sim, unit, userUnit )
		local cell = sim:getCell( userUnit:getLocation() )
		local units = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
                if self:isTarget( sim, userUnit, cellUnit ) then
                    if not sim:isVersion( "0.17.4" ) or simquery.canUnitReach( sim, userUnit, exit.cell.x, exit.cell.y ) then
    					table.insert( units, cellUnit )
                    end
				end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,
		
	canUseAbility = function( self, sim, unit, userUnit, targetUnitID )
		-- has a target in range
		local cell = sim:getCell( userUnit:getLocation() )
		local count = 0
		for dir, exit in pairs(cell.exits) do
			local unit = array.findIf( exit.cell.units, function( u ) return self:isTarget( sim, userUnit, u ) end )
			if unit then
				count = count + 1
			end					
		end

		if userUnit:getAP() < 1 then 
			return false, STRINGS.UI.REASON.ATTACK_USED
		end 

		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end

		if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end	

		if count == 0 then
			return false
		end
		
		if userUnit:getTraits().movingBody then
			local dumpee = userUnit:getTraits().movingBody
			if not dumpee:getTraits().iscorpse then
				return false, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY_REQ_BODY)
			end
		end
		
		if not userUnit:getTraits().movingBody then
			return false, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY_REQ_BODY)
		end
		
		if targetUnitID then
			local target = sim:getUnit( targetUnitID )
			if target:getTraits().open ~= true or target:getTraits().hasBody then
				return false, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY_REQ_OPEN)
			end
			
			------- this next bit checks shalem's in front of the safe
			
			local dir = target:getFacing()
			local x0, y0 = target:getLocation()
			local x1, y1 = simquery.getDeltaFromDirection(dir)
			local doorCell = sim:getCell( x0 + x1, y0 + y1 )
			
			if sim:getCell(userUnit:getLocation()) ~= doorCell then
				return false, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.STOW_BODY_REQ_FRONT)
			end
			
		end
		
	--	return abilityutil.checkRequirements( unit, userUnit)
		return true
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local target = sim:getUnit(target)			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = target:getLocation()
  		local direction = simquery.getDirectionFromDelta(x1-x0,y1-y0) 
		
		if userUnit:getTraits().movingBody then
			local dumpedBody = userUnit:getTraits().movingBody
		
			userUnit:setInvisible(false)
			userUnit:setDisguise(false)
			
			userUnit:getTraits().movingBody = nil
			dumpedBody:setFacing(simquery.getReverseDirection(direction) )
			unit:setFacing(direction)
			sim:dispatchEvent( simdefs.EV_UNIT_DROP_BODY, { unit = unit, targetUnit = dumpedBody} )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, {unit = dumpedBody} ) --don't drop the unit, just refresh it
			
			if not userUnit:getTraits().noDoorAnim then 
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = direction, exitOp=simdefs.EXITOP_BREAK_DOOR } )	
			end
			
			if sim:getCleaningKills() >= 0.5 then  ---- safe to assume that target requires cleanup but just in case
				sim:addCleaningKills( -0.5 ) 
			end
			sim:warpUnit( dumpedBody, nil )	
			sim:despawnUnit( dumpedBody )
			
			target:getTraits().open = nil
			target:getTraits().hasBody = true  -- failsafe to stop extra bodies
			target:getTraits().mainframe_status = "off"  -- should stop any further looting etc plus good for effect
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Movement/bodydrop_hardwood") 
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Objects/safe_open") 
			
		--	target:changeKanim( "kanim_safe2" ) -- doesn't seem to work ...
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target } )
			
			if not userUnit:getTraits().noDoorAnim then
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = direction, exitOp=simdefs.EXITOP_BREAK_DOOR } )
			end
			unit:useAP( sim )
		end
		
	end,
}
return shalem_stowBody