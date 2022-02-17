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
		------- altered DLC aug
	
	augment_kinetic_capacitor = util.extend( commondefs.augment_template )
	{
		name = STRINGS.DLC1.KINETIC_CAPACITOR,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_TIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_FLAVOR, 			
		value = 600, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			installed = true,	
			kinetic_capc = true,
			addAbilities = "bullrush",
			kModMP = 3,
			kModSP = -3,
			kRate = 3,
			kChangeIn = 3,
			kChangeAmmnt = 1,
			 maxAmmo = 3, ammo = 3,
		--	addTrait = {{"kinetic_capacitor_alert",STRINGS.DLC1.KINETIC_CAPACITOR_ALERT},{"kinetic_capacitor_bonus",1}},		
		},		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_augment_rush_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_augment_rush.png",				
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_TIRING, STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_TIRING_DESC , "gui/items/icon-action_hack-console.png" )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_BULLRUSH, STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_BULLRUSH_DESC , "gui/items/icon-action_hack-console.png" )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_BULLRUSH_2, STRINGS.FLAVORED.ITEMS.AUGMENTS.RUSH_BULLRUSH_2_DESC , "gui/items/icon-action_hack-console.png" )
        end,
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















