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


local tool_templates =
{
		item_stim = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.STIM_1,
		desc = STRINGS.ITEMS.STIM_1_TOOLTIP,
		flavor = STRINGS.ITEMS.STIM_1_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 9, mpRestored = 4, },
		requirements = { anySkill = 3 },
		abilities = { "carryable","recharge","use_stim" },
		value = 400,
		floorWeight = 1, 
	},

	item_stim_2 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.STIM_2,
		desc = STRINGS.ITEMS.STIM_2_TOOLTIP,
		flavor = STRINGS.ITEMS.STIM_2_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 7, mpRestored = 6, },
		requirements = { anySkill = 4 },
		abilities = { "carryable","recharge","use_stim" },
		value = 800,
		floorWeight = 2, 
	},	

	item_stim_3 = util.extend(commondefs.item_template)
	{
		name = STRINGS.ITEMS.STIM_3,
		desc = STRINGS.ITEMS.STIM_3_TOOLTIP,
		flavor = STRINGS.ITEMS.STIM_3_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 4, mpRestored = 8, combatRestored = true, },
		requirements = { anySkill = 5 },
		abilities = { "carryable","recharge","use_stim" },
		value = 1000,
		floorWeight = 3,
	},	

}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















