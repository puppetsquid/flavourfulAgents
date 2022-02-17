local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

	
local strengthTazer =
	{
		getName = function( self, sim, unit )
			return self.name
		end,
			
		createToolTip = function( self,sim,unit,targetUnit)
			return formatToolTip( self.name, string.format("BUFF\n%s", self.desc ) )
		end,
		
		name = STRINGS.RESEARCH.RECON_PROTOCOL.NAME, 
		buffDesc = STRINGS.RESEARCH.RECON_PROTOCOL.UNIT_DESC, 
		
		
		onSpawnAbility = function( self, sim, unit )
			self.abilityOwner = unit
			sim:addTrigger( "agentGotItem", self )
			self:strUpdate( sim, self.abilityOwner )
		end,
			
		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( "agentGotItem", self )
			self.abilityOwner = nil
		end,

		onTrigger = function( self, sim, evType, evData )
			if self.abilityOwner then
					self:strUpdate( sim, self.abilityOwner )
			end
		end,
		
		
		strUpdate = function( self, sim, unit )
			if unit._parent then
				local ownerUnit = unit._parent
				if ownerUnit:hasSkill("inventory") then
					unit:getTraits().armorPiercing = math.floor(ownerUnit:getSkillLevel( "inventory" ) * 0.5)
				--	unit:getTraits().addArmorPiercingRanged = math.floor(ownerUnit:getSkillLevel( "inventory" ) * 0.5)
				end
			end
		end, 

		canUseAbility = function( self, sim, unit )
			return false -- Passives are never 'used'
		end,

		executeAbility = nil, -- Passives by definition have no execute.
	}
return strengthTazer