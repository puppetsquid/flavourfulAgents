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

--addAbilities = "prism_combatdisguise"
local tool_templates =
{

    augment_sharp_flav = util.extend(commondefs.augment_template)
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHARP_3,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHARP_3_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHARP_3_FLAVOR,
		traits = { 
			installed = true,
		--	modTrait = {{"mpMax",-1}},	
			addAbilities = "sharp_eject",
		--	modTrait = {{"augmentMaxSize", 1}},	
		}, 
		abilities = util.tconcat( commondefs.augment_template.abilities, { "sharp_ferry"} ),
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_augment_sharp_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_augment_sharp.png",		
	},	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















