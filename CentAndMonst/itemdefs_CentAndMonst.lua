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

local unitdefs = include( "sim/unitdefs" )

local tool_templates =
{
	augment_monst3r_FA = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.MONSTERS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.MONSTERS_TIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.MONSTERS_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			installed = true,
			--shopDiscount = 0.15, 
			addAbilities = "hacknanofab",
			addTrait = {{"nanoLocate",true},},
		},		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",	
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















