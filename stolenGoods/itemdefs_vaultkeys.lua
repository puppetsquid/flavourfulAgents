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
	
	
	
	vault_passcard = util.extend(commondefs.item_template)
	{
		name = STRINGS.DETAINED.ITEMS.VAULT_PASS,
		desc = STRINGS.DETAINED.ITEMS.VAULT_PASS_TOOLTIP,
		flavor = STRINGS.DETAINED.ITEMS.VAULT_PASS_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_vault_key_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_vault_key.png",
		abilities = { "carryable" },
		value = 500,
		traits = { keybits = simdefs.DOOR_KEYS.VAULT }, 
	},
	
	item_prisonerFile = util.extend(commondefs.item_template)  --  Compromising Info on this unit
	{
		name = STRINGS.DETAINED.ITEMS.DETFILE,
		desc = STRINGS.DETAINED.ITEMS.DETFILE_TOOLTIP,
		flavor = STRINGS.DETAINED.ITEMS.DETFILE_FLAVOR,	
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_compile_key.png",
		abilities = { "carryable" },
		value = 400,
		traits = { isDetFile = true, oValue = 200 }, 
		createUpgradeParams = function( self, unit )
			return { value = unit:getTraits().oValue }
		end,
	},	
	
	item_agentFile = util.extend(commondefs.item_template)  --  Compromising Info on this unit
	{
		name = STRINGS.DETAINED.ITEMS.DETFILE_2,
		desc = STRINGS.DETAINED.ITEMS.DETFILE_TOOLTIP,
		flavor = STRINGS.DETAINED.ITEMS.DETFILE_T2_FLAVOR,		
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_compile_key.png",
		abilities = { "carryable" },
		value = 200,
		traits = { isDetFile = true, oValue = 200 }, 
		createUpgradeParams = function( self, unit )
			return { value = unit:getTraits().oValue }
		end,
	},
	
	
	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















