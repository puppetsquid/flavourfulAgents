---------------------------------------------------------------------
-- Invisible Inc. official DLC.
--
local util = include( "modules/util" )
local commondefs = include( "sim/unitdefs/commondefs" )
local simdefs = include( "sim/simdefs" )

local HOTKEY_COLOUR = "<c:ffffff>"
local FLAVOUR_COLOUR = "<c:61AAAA>"
local ITEM_HEADER_COLOUR = "<ttheader>"
local DESC_COLOUR = "<c:ffffff>"
local EQUIPPED_COLOUR = "<c:FF8411>"
local NOTINSTALLED_COLOUR = "<c:FF8411>"
--local SPECIAL_INFO_COLOUR = "<c:F4FF78>"
local SPECIAL_INFO_COLOUR = "<c:ffffff>"

local NEVER_SOLD = 10000

local tool_templates =
{
	
	item_sedative_draco = util.extend(commondefs.item_template) 
	{
		name = STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO,
		desc = STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-paralyzer.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_prototype_injector_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_prototype_med_gel.png",	
		abilities = { "carryable","recharge","equippable","draco_sedate" },
		requirements = {  },
		traits = { slot = "melee", melee = true, nonStandardMelee = "draco_sedate", pwrCost = 3, koTime = 2, usesCharges=true, charges=3, chargesMax=3 },
		value = 400,
		floorWeight = 1, 
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_KILLS, STRINGS.FLAVORED.ITEMS.PARALYZER_DRACO_KILLS_DETAIL , "gui/icons/item_icons/items_icon_small/icon-item_heart_monitor_small.png" )
        end,
	},	
	
	augment_neural_mapper_2 = util.extend( commondefs.augment_template )
	{
       -- id = "augment_subdermal_pda",
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.NEURAL_MAPPER,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.NEURAL_MAPPER_TIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.NEURAL_MAPPER_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS )
        {
        --	modSkillLock = {1,2,3,4},
			installed = true,
			ingnoreAugmentCount17_13 = true, -- this is for a bug where the augment was missing the 'carryable' ability. When it was added, there needed to be a way to have early save games still load.	
		modTrait = {{"dragCostMod", (-1.5)}},			
		},
		value = 400, 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_augment_dracul_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_augment_dracul.png",
    	abilities = {"carryable", "installAugment","neural_scan_2"},
	},	
	
	item_cloakingrig_draco = util.extend(commondefs.augment_template)
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.CLOAK_DRACO,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.CLOAK_DRACO_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.CLOAK_DRACO_FLAVOR,
		icon = "itemrigs/FloorProp_InvisiCloakTimed.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_cloaking_rigr_small.png",			
		profile_icon_100 = "gui/icons/item_icons/icon-item_cloaking_rig.png",
		traits = { disposable = false,
			--restrictedUse={{agentID=1003,name=STRINGS.AGENTS.PRISM.NAME}},
				addTrait = {{"invisToCams", true}},installed = true,	},
		requirements = { },
		abilities = util.tconcat( commondefs.augment_template.abilities, { "camBlocker" }),
		value = 400,
		floorWeight = 1,
		notSoldAfter = NEVER_SOLD, 
	},
	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















