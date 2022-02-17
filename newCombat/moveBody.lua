local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local animmgr = include( "anim-manager" )
local mathutil = include( "modules/mathutil" )


local moveBody = 
	{
		name = STRINGS.ABILITIES.MOVE_BODY,
        canUseWhileDragging = true,

		createToolTip = function( self,sim,abilityOwner,abilityUser,targetID)
			--return abilityutil.formatToolTip(self:getName(sim, abilityOwner) )

			local target = sim:getUnit(targetID)
			if abilityUser:getTraits().movingBody then
				return abilityutil.formatToolTip( util.sformat( STRINGS.ABILITIES.MOVE_BODY_DROP_TIP , target:getName() ),  STRINGS.ABILITIES.MOVE_BODY_DROP_DESC  )
			else
				return abilityutil.formatToolTip( util.sformat( STRINGS.ABILITIES.MOVE_BODY_DRAG_TIP , target:getName() ),  STRINGS.ABILITIES.MOVE_BODY_DRAG_DESC  )
			end
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_drag_small.png",
		getProfileIcon = function(self, sim, abilityOwner, abilityUser, ...)
			if abilityUser:getTraits().movingBody then
				return "gui/icons/action_icons/Action_icon_Small/icon-action_drop_small.png"
			else
				return "gui/icons/action_icons/Action_icon_Small/icon-action_drag_small.png"
			end
		end,
		getName = function( self, sim, unit )
			if unit:getTraits().movingBody then
				return STRINGS.ABILITIES.MOVE_BODY_DROP, STRINGS.ABILITIES.MOVE_BODY_DROP_DESC
			else
				return STRINGS.ABILITIES.MOVE_BODY_DRAG, STRINGS.ABILITIES.MOVE_BODY_DRAG_DESC
			end
		end,

		acquireTargets = function( self, targets, game, sim, unit )
			local targetUnits = {}
			if unit:getTraits().movingBody then
				table.insert(targetUnits, unit:getTraits().movingBody)
			else
				local cell = sim:getCell( unit:getLocation() )
				for i,cellUnit in ipairs(cell.units) do
					if self:isValidTarget( sim, unit, unit, cellUnit ) then
						table.insert( targetUnits,cellUnit )
					end
				end
			end

			return targets.unitTarget( game, targetUnits, self, unit, unit )
		end,

		isValidTarget = function( self, sim, unit, userUnit, targetUnit )
			if targetUnit == nil or targetUnit:isGhost() then
				return false
			end

			if not userUnit:canAct() then
				return false
			end

			local animdef = animmgr.lookupAnimDef( targetUnit:getUnitData().kanim )
			if animdef == nil or animdef.grp_build == nil then
				return false
			end

			if targetUnit:getTraits().notDraggable then 
				return false 
			end 

			if not targetUnit:isKO() and not targetUnit:getTraits().iscorpse then 
				return false
			end

			return true
		end,

		canUseAbility = function( self, sim, unit, userUnit, targetID )
			if targetID then
				if not self:isValidTarget( sim, unit, userUnit, sim:getUnit( targetID ) ) then
					return false, STRINGS.UI.REASON.INVALID_TARGET
				end
				if unit:getTraits().movingBody then
					local cell = sim:getCell( unit:getLocation() )
					if cell then
						if array.findIf( cell.units, function( u ) return u:getID() ~= targetID and (u:isKO() or u:getTraits().iscorpse) end ) ~= nil then
							return false, STRINGS.UI.REASON.CANT_STACK_BODIES
						end
					end
				end
			end

			return true
		end,

		executeAbility = function( self, sim, unit, userUnit, target )
			local targetUnit = sim:getUnit(target)

			if unit:getTraits().movingBody == targetUnit then
				unit:getTraits().movingBody = nil
				targetUnit:setFacing(unit:getFacing() )
				unit:setFacing(simquery.getReverseDirection(unit:getFacing() ) )
				sim:dispatchEvent( simdefs.EV_UNIT_DROP_BODY, { unit = unit, targetUnit = targetUnit} )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, {unit = targetUnit} ) --don't drop the unit, just refresh it
			else
				local x0,y0 = unit:getLocation()
				local x1,y1 = targetUnit:getLocation()
				local distance = mathutil.dist2d( x0, y0, x1, y1 )

				unit:setFacing(targetUnit:getFacing() )
				if not unit:isValid() then
					return
				end
				
				userUnit:getTraits().movingBody = targetUnit
				sim:dispatchEvent( simdefs.EV_UNIT_DRAG_BODY, { unit = unit, targetUnit = targetUnit} )
			end

		end,
	}
return moveBody