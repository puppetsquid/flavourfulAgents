----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Ability definitions
-- These do NOT get serialized as part of sim state!  They define 'static' information
-- that fully qualifies how an ability affects the simulation state.  The only state
-- modified by the functions contained in the ability definitions below is the simulation
-- and ability instance that are passed in as arguments.
--
-- These ability definition tables are looked up by name when they are needed; references
-- to these from within the sim are therefore simply strings (to avoid serialization connectivity)

local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

-----------------------------------------------------------------
--

function findSkillTreeVal(sim, unit, skill)

	local sk = unit:hasSkill( skill, 2 )
	
	local treeVal = nil
	
	if sk then
		treeVal = sk.treeVal
	end
	
	if not treeVal then
		treeVal = 1 + #unit:getSkills()
	end
	
	return treeVal

end

local lvl2cost = 800
local lvl3cost = 500
local lvl4cost = 600
local lvl5cost = 700

local _skills =
{
	
	
	anySkill = 
	{
		--name = STRINGS.SKILLS.INVENTORY_NAME,
		name = "Any",
		levels = 0, 
		description = "Can be replaced with any standard skill",
	},
	
	inventory = 
	{
		--name = STRINGS.SKILLS.INVENTORY_NAME,
		name = STRINGS.FLAVORED.SKILLS.INVENTORY_NAME,
		levels = 5, 
		description = STRINGS.FLAVORED.SKILLS.INVENTORY_DESC,

		[1] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.INVENTORY1_TOOLTIP,
			cost = 0,
			onLearn = function(sim, unit) 	
				unit:getTraits().maxThrow = 3
				unit:getTraits().skillsEnabled = true
			end,
		},

		[2] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.INVENTORY2_TOOLTIP,
			cost = lvl2cost,
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
    			unit:getTraits().dragCostMod = unit:getTraits().dragCostMod +0.5
				unit:getTraits().maxThrow = unit:getTraits().maxThrow + 1.5 -- CURRENTLY this is actually handled by jackin
				unit:giveAbility("throwInventory") -- ranged trade! Now 1-way!			

				local sk = unit:hasSkill( "inventory" )
				if sk then
					sk._treeVal = findSkillTreeVal(sim, unit, "inventory")
					log:write(unit.name .. " inventory skill added " .. _treeVal)
				end
				
			end,
			onUnLearn =function(sim, unit)
				unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize - 1
    			unit:getTraits().dragCostMod = unit:getTraits().dragCostMod -0.5
				unit:getTraits().maxThrow = unit:getTraits().maxThrow - 1.5
				unit:removeAbility(sim, "throwInventory")
			end
		},

		[3] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.INVENTORY3_TOOLTIP,
			cost = lvl3cost,
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
			--	unit:getTraits().dragCostMod = unit:getTraits().dragCostMod +0.5
				unit:getTraits().maxThrow = unit:getTraits().maxThrow + 1.5
			end,
			onUnLearn =function(sim, unit)
				unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize - 1
				unit:getTraits().maxThrow = unit:getTraits().maxThrow - 1.5
			end
		},

		[4] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.INVENTORY4_TOOLTIP,
			cost = lvl4cost,
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
    			unit:getTraits().dragCostMod = unit:getTraits().dragCostMod +0.5
				unit:getTraits().maxThrow = unit:getTraits().maxThrow + 1.5
			end,
			onUnLearn =function(sim, unit)
				unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize - 1
    			unit:getTraits().dragCostMod = unit:getTraits().dragCostMod -0.5
				unit:getTraits().maxThrow = unit:getTraits().maxThrow - 1.5
			end
		},

		[5] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.INVENTORY5_TOOLTIP,
			cost = lvl5cost,
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
    			unit:getTraits().meleeDamage = unit:getTraits().meleeDamage +1
				unit:getTraits().maxThrow = unit:getTraits().maxThrow + 1.5
			--	unit:getTraits().dragCostMod = unit:getTraits().dragCostMod +0.5
			end,
			onUnLearn =function(sim, unit)
				unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize - 1
    			unit:getTraits().dragCostMod = unit:getTraits().meleeDamage -1
				unit:getTraits().maxThrow = unit:getTraits().maxThrow - 1.5
			end
		},
	},
	
	stealth = 
	{
		name = STRINGS.FLAVORED.SKILLS.STEALTH_NAME,
		levels = 5, 
		description = STRINGS.FLAVORED.SKILLS.STEALTH_DESC,

		[1] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.STEALTH1_TOOLTIP, 
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.STEALTH2_TOOLTIP, 
			cost = lvl2cost,
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
				
	--			local sk = unit:hasSkill( "stealth" )
	--			sk.treeVal = findSkillTreeVal(sim, unit, "stealth")
				
			end,
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.STEALTH3_TOOLTIP, 
			cost = lvl3cost,
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			end, 
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			end, 			
		},

		[4] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.STEALTH3_TOOLTIP, 
			cost = lvl4cost,
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			end,
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			end,			 
		},

		[5] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.STEALTH5_TOOLTIP, 
			cost = lvl5cost,
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			    unit:getTraits().sprintBonus = (unit:getTraits().hacking_bonus or 0) + 1
			end, 
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			    unit:getTraits().sprintBonus = unit:getTraits().sprintBonus -1
			end, 			
		}

	},
	
		hacking = 
	{
		name = STRINGS.FLAVORED.SKILLS.HACKING_NAME,
		levels = 5, 
		description = STRINGS.FLAVORED.SKILLS.HACKING_DESC,

		[1] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.HACKING1_TOOLTIP,
			cost = 0, 
			onLearn = function(sim, unit)
				--unit:giveAbility("console_observePath")
			end,
			
		},

		[2] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.HACKING2_TOOLTIP,
			cost = lvl2cost,
			onLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 1
			--	unit:giveAbility("scandevice") -- decker's old Aug
			--	unit:giveAbility("consoles_scandevice") -- decker's old Aug, but via nearest console, now Nat's only
			--	unit:giveAbility("consoles_emp") -- shut down nearby cams/bugs
				unit:giveAbility("consoles_scan") -- nat's wireless scan from owned consoles
			
	--			unit:getSkills().hacking.treeVal = findSkillTreeVal(sim, unit, "hacking")
			
			end,
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 1
			--	unit:removeAbility(sim, "consoles_emp")
				unit:removeAbility(sim, "consoles_scan")
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.HACKING3_TOOLTIP,
			cost = lvl3cost,
			onLearn = function(sim, unit)
    			unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 1
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 1
			end,			
		},

		[4] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.HACKING4_TOOLTIP,
			cost = lvl4cost,
			onLearn = function(sim, unit)
    			unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 1
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 1
			end,			
		},

		[5] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.HACKING5_TOOLTIP,
			cost = lvl5cost,
			onLearn = function(sim, unit)
    			unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 2
			--	unit:giveAbility("scandevice") -- decker's old Aug
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 2
			end,			
		}		
	},
	
	anarchy = 
	{
		name = STRINGS.FLAVORED.SKILLS.ANARCHY_NAME,
		levels = 5, 
		description = STRINGS.FLAVORED.SKILLS.ANARCHY_DESC,

		[1] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.ANARCHY1_TOOLTIP,
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.ANARCHY2_TOOLTIP,
			cost = lvl2cost,
			onLearn = function(sim, unit) 	
			--	unit._skills.anarchy.treeVal = findSkillTreeVal(sim, unit, "anarchy")
			end, 
		},

		[3] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.ANARCHY3_TOOLTIP,
			cost = lvl3cost,
			onLearn = function(sim, unit) 	
    			unit:getTraits().stealBonus = (unit:getTraits().stealBonus or 0) + 0.15
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().stealBonus = (unit:getTraits().stealBonus or 0) - 0.15
			end,
		},

		[4] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.ANARCHY4_TOOLTIP, 
			cost = lvl4cost,
			onLearn = function(sim, unit) 	
    			unit:getTraits().stealBonus = (unit:getTraits().stealBonus or 0) + 0.20
			--	unit:getTraits().anarchyItemBonus = true
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().stealBonus = (unit:getTraits().stealBonus or 0) - 0.20
			--	unit:getTraits().anarchyItemBonus = false
			end,
		},

		[5] = 
		{
			tooltip = STRINGS.FLAVORED.SKILLS.ANARCHY5_TOOLTIP,
			cost = lvl5cost,
			onLearn = function(sim, unit) 	
			    unit:getTraits().anarchyItemBonus = true
            end, 
			onUnLearn = function(sim, unit)
               unit:getTraits().anarchyItemBonus = nil
			end,
		},		
	
	},
	

}

return _skills
