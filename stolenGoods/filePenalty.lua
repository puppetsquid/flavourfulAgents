local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )
local inventory = include( "sim/inventory" )


local function isNotKO( unit )
    return not unit:isKO()
end


local filePenalty =

{

	name = STRINGS.ABILITIES.CARRYABLE,
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.CARRYABLE, STRINGS.ABILITIES.CARRYABLE_DESC, 0)
		end,

		ghostable = true,
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_drop_give_small.png",

		--getName = function( self, sim, unit, userUnit )
		getName = function( self, sim, abilityOwner, abilityUser )
			if abilityOwner:getUnitOwner() ~= nil then
				 return STRINGS.ABILITIES.DROP
			else
				return string.format(STRINGS.ABILITIES.PICKUP,abilityOwner:getName())
			end
		end,

		canUseAbility = function( self, sim, abilityOwner, abilityUser )

			return false
		end,
		
		executeAbility = function( self, sim, unit, userUnit )
			local cell = sim:getCell( unit:getLocation() )
		end,

		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_MAP_EVENT, self, unit )		
		end,

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_MAP_EVENT, self )
		end,

		onTrigger = function( self, sim, evType, evData, userUnit )
			if evType == simdefs.TRG_MAP_EVENT and evData.event == simdefs.MAP_EVENTS.TELEPORT then 
				if evData.units then 
					for _, escapee in ipairs( evData.units ) do
						for i,item in ipairs(escapee:getChildren()) do
							if item:getTraits().isDetFile and item:getTraits().penalty then
								item:getTraits().penalty = 0
								sim:addCleaningKills( -1 ) 
							end
						end
					end
				end 
			end
		end, 
}



return filePenalty