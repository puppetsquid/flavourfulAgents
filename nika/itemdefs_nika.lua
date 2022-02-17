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

	augment_nika_FA = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.NIKAS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.NIKAS_TIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.NIKAS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			installed = true,
			addTrait = {{"superBrawler",true},},			
		},		
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_nika_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_nika.png",		
	},	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















