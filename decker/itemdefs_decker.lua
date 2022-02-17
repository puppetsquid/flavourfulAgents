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
	----------- decker augs -----------------
	
	augment_deckard = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.DECKER_DAEMON,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.DECKER_DAEMON_TIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.DECKER_DAEMON_FLAVOR, 
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			icebreak = 4,
			installed = true,
			cooldown = 0, cooldownMax = 3,
		},		
		abilities = util.tconcat( commondefs.augment_template.abilities, {  "decker_installer" }), --"decker_icebreak",
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
		--	tooltip:addAbility(  STRINGS.FLAVORED.ITEMS.NOTE_ACTION, STRINGS.FLAVORED.ITEMS.NOTE_ACTION_DESC, "gui/icons/arrow_small.png" )	
        end,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_leg_small2.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_leg2.png",	
	},
	
	--ignoreArmor=true
	
	item_revolver_deckard = util.extend( commondefs.weapon_reloadable_template )
	{
		name = STRINGS.FLAVORED.ITEMS.REVOLVER_DECKARD,
		desc = STRINGS.FLAVORED.ITEMS.REVOLVER_DECKARD_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.REVOLVER_DECKARD_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_revolver_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_revolver.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", baseDamage = 1, ammo = 6, maxAmmo = 6, noReload = true, ignoreArmor=true, EMP_bullets = true }, --  hidesBody = true  (need to get visuals working)
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_light_revolver",
		agent_anim = "anims_1h",
		value = 0,
	},
	
	item_tazer_archdeck = util.extend(commondefs.melee_template)
	{
		name = STRINGS.FLAVORED.ITEMS.TAZER_DECK,
		desc = STRINGS.FLAVORED.ITEMS.TAZER_DECK_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.TAZER_DECK_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/Flavour/icon-item_tazer_microchip_small.png",
		profile_icon_100 = "gui/icons/Flavour/icon-item_tazer_microchip.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = -10,  cooldown = 0, cooldownMax = 5, melee = true, level = 1, tagsTarget = true },
		value = 300,
		floorWeight = 1,
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )

			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.CANTAG, string.format(STRINGS.ITEMS.TOOLTIPS.CANTAG_DESC), "gui/icons/arrow_small.png" )

        end,
	},
	
	augment_central = util.extend(commondefs.augment_template)
	{
		name = STRINGS.ITEMS.AUGMENTS.PRISM_2,
		desc = STRINGS.ITEMS.AUGMENTS.PRISM_2_TOOLTIP,
		flavor = STRINGS.ITEMS.AUGMENTS.PRISM_2_FLAVOR,
		traits = { 
			installed = true,
		},
		keyword = "NETWORK", 
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_torso_small.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_torso.png",		
	},
	
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















