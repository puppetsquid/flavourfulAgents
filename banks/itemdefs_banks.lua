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
		------- Core Augment -- open doors via consoles
	
		augment_banks = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS_TIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
		--	addTrait = {{"passiveKey",simdefs.DOOR_KEYS.SECURITY}},
			addTrait = {{"senseRange",6},{"activeRange",2}},
			addAbilities = "console_doorOpener",
			installed = true,
		--	modTrait = {{"inventoryMaxSize",-1}},	
			--modTrait = {{"LOSrange",2}},	
			--modTrait = {{"LOSperipheralRange",8},{"LOSperipheralArc",math.pi * 2}},	
		},
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS_AP, STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS_AP_DESC , "gui/items/icon-action_hack-console.png" )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS_VIS, STRINGS.FLAVORED.ITEMS.AUGMENTS.BANKS_VIS_DESC , "gui/items/icon-action_hack-console.png" )
        end,
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_banks_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_banks.png",							
	},
	
	item_paralyzer_banks = util.extend(commondefs.item_template)  ---- change this to a melee wep with throwable componant
	{
		name = STRINGS.FLAVORED.ITEMS.PARALYZER_BANKS,
		desc = STRINGS.FLAVORED.ITEMS.PARALYZER_BANKS_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PARALYZER_BANKS_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-paralyzer.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_prototype_injector_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_prototype_med_gel.png",	
		abilities = { "carryable","recharge","equippable","banks_paralyze","banks_throwParalyze" },
		requirements = {  },
		traits = { slot = "melee", melee = true, nonStandardMelee = "banks_paralyze", cooldown = 0, cooldownMax = 6, koTime = 3, restrictedUse={{agentID=4,name="Banks"}} },
		value = 400,
		floorWeight = 1, 
	},	
	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















