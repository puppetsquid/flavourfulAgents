local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local unitdefs = include( "sim/unitdefs" )

-------------------------------------------------------------------
--

local oldescape = include("sim/abilities/escape")

local oldExecuteAbility = oldescape.executeAbility

local escape = util.extend(oldescape) {
	executeAbility = function( self, sim, abilityOwner )
		local player = sim:getPC() -- abilityOwner:getPlayerOwner()
		local cell = sim:getCell( abilityOwner:getLocation() )
		local escapedUnits = {}

		if player and cell.exitID then
			for _, unit in pairs( sim:getAllUnits() ) do			
				local c = sim:getCell( unit:getLocation() )
				if c and c.exitID and unit:hasAbility( "escape" ) then
					if unit:countAugments( "augment_shalemA" ) > 0 then
						for i, child in pairs(unit:getChildren()) do
							if child:getTraits().ammo and child:getTraits().maxAmmo and not child:getTraits().noReload then 
								child:getTraits().ammo = math.min(child:getTraits().ammo + 1, child:getTraits().maxAmmo)	
							end
						end
					end						
				end
			end
		end
		
		return oldExecuteAbility( self, sim, abilityOwner )
	end,
}

return escape