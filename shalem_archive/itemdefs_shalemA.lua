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
		------- Custom Wep - multi-shot war pistol
	
	item_clean_pistol = util.extend( commondefs.weapon_template )
	{
		name = STRINGS.FLAVORED.ITEMS.RIFLE_MALIK,
		desc = STRINGS.FLAVORED.ITEMS.RIFLE_MALIK_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.RIFLE_MALIK_FLAVOR,
		icon = "itemrigs/FloorProp_Precision_SMG.png",		
		--profile_icon = "gui/items/item_pistol_56.png",
		profile_icon = "gui/icons/Flavour/icon-item_gun_smg_shalem_small.png",
		profile_icon_100 = "gui/icons/Flavour/icon-item_gun_smg_shalem.png",			
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", energyWeapon = "idle", baseDamage = 1, ammo = 3, maxAmmo = 3, nopwr_guards = {}, ignoreNoAP = true}, -- serviceOnly={{agentID=2,name=STRINGS.AGENTS.SHALEM.NAME}}
		abilities = { "carryable", "shootSingle", "equippable", "serviceGun", "serviceReload",  },
		sounds = {shoot="SpySociety/Weapons/LowBore/shoot_handgun_silenced", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_precise_smg",
		agent_anim = "anims_2h",
		value = 1250,
		createUpgradeParams = function( self, unit )
			local params = { traits = { autoEquip = (unit:getTraits().equipped == true), ammo = unit:getTraits().ammo } }
			--	params.traits.ammo = unit:getTraits().ammo
			return params
		end,
	},
	
--[==[	item_tazer_shalemA = util.extend(commondefs.melee_template)
	{
		name = STRINGS.ITEMS.TAZER_SHALEM,
		desc = STRINGS.ITEMS.TAZER_SHALEM_TOOLTIP,
		flavor = STRINGS.ITEMS.TAZER_SHALEM_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_tazer.png",		
		--profile_icon = "gui/items/icon-tazer-ftm.png",
		requirements = {  },
		traits = { damage = 2,  cooldown = 0, cooldownMax = 5, melee = true, level = 1, armorPiercing = 0, addArmorPiercingRanged = 0 },
		value = 300,
		abilities = util.tmerge( { "strengthTazer" }, commondefs.melee_template.abilities ),
		floorWeight = 1,
		createUpgradeParams = function( self, unit )
			local params = { traits = { autoEquip = (unit:getTraits().equipped == true), armorPiercing = unit:getTraits().armorPiercing } }
			--	params.traits.ammo = unit:getTraits().ammo
			return params
		end,

	}, ]==]
	
	item_tazer_shalemA = util.extend( commondefs.grenade_template)
	{
        type = "stun_grenade",
		name = STRINGS.FLAVORED.ITEMS.GRENADE_MALIK,
		desc = STRINGS.FLAVORED.ITEMS.GRENADE_MALIK_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.GRENADE_MALIK_FLAVOR,
		--icon = "itemrigs/FloorProp_Bandages.png",
		
		ITEM_LIST = true,
		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_flash_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_flash_grenade.png",		
		kanim = "kanim_flashgrenade",	

		abilities ={"carryable" , "throw_snap",  "reload"},		
		sounds = {activate="SpySociety/Grenades/stickycam_deploy", bounce="SpySociety/Grenades/bounce" },
		traits = { range=1.5, explodes = 0, agent_filter=true, attackNeedsLOS=true, multiUse = true, disposable = false, emp_duration = 1, ammo = 2, maxAmmo = 2, throwUnit="item_shalem_empgrenade_true"},
		floorWeight = 2,
		value = 600,
		locator=true,
		createUpgradeParams = function( self, unit )
		--	local params = { traits = { autoEquip = (unit:getTraits().equipped == true), ammo = math.min(unit:getTraits().ammo + 1, unit:getTraits().maxAmmo) } }
			local params = { traits = { autoEquip = (unit:getTraits().equipped == true), ammo = unit:getTraits().ammo } }
			--	params.traits.ammo = unit:getTraits().ammo
			return params
		end,
	},
	
		item_shalem_empgrenade_true = util.extend(commondefs.item_template)
	{
		type = "simemppack",
		name = "True EMP Nade",
		desc = "From Shirsh's Mod Combo",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_flash_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_flash_grenade.png",	
		kanim = "kanim_flashgrenade",	
		abilities = { "carryable", "prime_emp", },
		traits = { range = 1.5, canSleep = false, baseDamage = 0, agent_filter=true, emp_duration = 1 },
	sounds = {activate="SpySociety/Actions/holocover_activate", deactivate="SpySociety/Actions/holocover_deactivate", activeSpot="SpySociety/Actions/holocover_run_LP", bounce="SpySociety/Grenades/bounce"},
	},
	
	augment_shalemA = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.MALIKS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.MALIKS_TIP, --STRINGS.FLAVORED.ITEMS.AUGMENTS.MALIKS_TIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.MALIKS_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
		--	addAbilities = "shalem_medgel",		
			installed = true,
			cooldown = 0, cooldownMax = 10,
		},	
		abilities = util.tconcat( commondefs.augment_template.abilities, { "shalem_medgel"} ), -- , "shalem_healCorpse"  commondefs.augment_template.abilities,
		profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_tony_small.png",
    	profile_icon_100 = "gui/icons/skills_icons/icon-item_augment_tony.png",		
		createUpgradeParams = function( self, unit ) --- ammo get now handled by escape.lua
			--return { traits = { icebreak = unit:getTraits().icebreak } }
		end,
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















