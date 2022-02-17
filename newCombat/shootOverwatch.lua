local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local inventory = include("sim/inventory")
local serverdefs = include( "modules/serverdefs" )
local abilitydefs = include( "sim/abilitydefs" )

local oldShootOverwatch = abilitydefs.lookupAbility("shootOverwatch")

local oldOnTrigger = oldShootOverwatch.onTrigger

local shootOverwatch = util.extend(oldShootOverwatch) {
	onTrigger = function( self, sim, evType, evData, userUnit )
		local hasKeensight = array.findIf( userUnit:getChildren(), function( u ) return u:getTraits().hasKeensight ~= nil end ) ---  find if has Shalem Aug
		if hasKeensight then 
			hasKeensight:getTraits().addArmorPiercingRanged = 1     ---- giveth ranged pierce
		end
		
		oldOnTrigger( self, sim, evType, evData, userUnit )
		
		if hasKeensight then 
			hasKeensight:getTraits().addArmorPiercingRanged = nil   ---- taketh away again
		end
	end,
}

return shootOverwatch

