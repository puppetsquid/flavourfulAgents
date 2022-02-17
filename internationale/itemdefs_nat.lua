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
	
		item_stim_nat = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.STIM_NAT,
		desc = STRINGS.FLAVORED.ITEMS.STIM_NAT_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.STIM_NAT_FLAVOR,
		icon = "itemrigs/FloorProp_Bandages.png",
		--profile_icon = "gui/items/icon-stims.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_stim_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_stim.png",
		traits = { cooldown = 0, cooldownMax = 7, mpRestored = 4, },-- combatRestored = true, },
		requirements = { anySkill = 2 },
		abilities = { "carryable","recharge","use_stim" },
		value = 400,
		floorWeight = 1, 
	},
	
		augment_international_v1 = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.INTERNATIONALS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.INTERNATIONALS_TIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.INTERNATIONALS_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addTrait = {{"wireless_range",4},{"pacifist"},{"noKill"}},		
		--	addAbilities = "scandevice_ranged",			
			installed = true,
			wireless_range = 4,
		--	modTrait = {{"apMax",-1}},		
		},
        abilities = util.tconcat( commondefs.augment_template.abilities, { "wireless_scan", "scandevice_ranged" }),
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_internationale_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_internationale.png",			
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















