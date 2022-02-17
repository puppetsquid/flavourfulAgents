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
		------- Core Augment -- Pierce bonus only applied to Overwatch, but now has optional heart monitor bypass (costs PWR)
	
	augment_shalem_flavour = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHALEMS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHALEMS_TIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHALEMS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			hasKeensight = true,
			installed = true,
			stdPWR = 3,
			advPWR = 6,
		},
		abilities = util.tconcat( commondefs.augment_template.abilities, { "shalem_tagGuard" }),
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER_BONUS,
				 util.sformat( STRINGS.FLAVORED.ITEMS.AUGMENTS.HEARTBREAKER_BONUS_DESC, unit:getTraits().stdPWR, unit:getTraits().advPWR ), "gui/icons/Flavour/icon-heartbreak.png" )
        end,
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_shalem_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_shalem.png",					
	},
	
	------------ Extra aug -- shalem is great at covering tracks. This also massively helps reduce the multiple costs of killing, AND reinforces his strength stat. win-win!
	
	augment_shalem_flavour_2ndry = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHALEM_DUMP,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHALEM_DUMP_TIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.SHALEM_DUMP_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "shalem_stowBody",	
			installed = true,
		},	
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility(  STRINGS.FLAVORED.ITEMS.NOTE_ACTION, STRINGS.FLAVORED.ITEMS.NOTE_ACTION_DESC, "gui/icons/arrow_small.png" )	
        end,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_arm_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_augment2.png",		
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















