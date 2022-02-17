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
	augment_tony = util.extend( commondefs.augment_template )
	{
		name = STRINGS.ITEMS.AUGMENTS.TONYS,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.XU_TOOLTIP, 
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.XU_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "micronanofab",
			modTrait = {{"mpMax",-1}},			
			installed = true,
			isMicronanofab = true,
			ammo = 100, maxAmmo = 0,
			hasSoldAug = false,
		},	
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_arm_small2.png",
    	profile_icon_100 = "gui/icons/item_icons/icon-item_generic_arm2.png",    	
		createUpgradeParams = function( self, unit )
			local params = { traits = { installed = unit:getTraits().installed, augment=true } }
			params.traits.ammo = math.min(999,unit:getTraits().ammo+100)
			params.traits.hasSoldAug = unit:getTraits().hasSoldAug
			return params
		end,
	},

		item_icebreaker_xu = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.BUG.name,
		desc =  STRINGS.FLAVORED.ITEMS.BUG.desc,
		flavor = STRINGS.FLAVORED.ITEMS.BUG.flavor,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_ice_breaker.png",		
		traits = { disposable = true, icebreak = 1, duration = 5, cooldownMax = 0 },
		requirements = { },
		abilities = { "icemelt","carryable" },
		value = 125,
		floorWeight = 1,
		notSoldAfter = 10000, 
	},

	item_smokegrenade_xu = util.extend( commondefs.grenade_template )
	{
        type = "smoke_grenade",
		name = STRINGS.FLAVORED.ITEMS.SMOKE.name,
		desc =  STRINGS.FLAVORED.ITEMS.SMOKE.desc,
		flavor = STRINGS.FLAVORED.ITEMS.SMOKE.flavor,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_smoke_grenade_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_smoke_grenade.png",	
		kanim = "kanim_stickycam",		
		sounds = {explode="SpySociety/Grenades/smokegrenade_explo", bounce="SpySociety/Grenades/bounce_smokegrenade"},
		traits = { on_spawn = "smoke_cloud" , range=3, noghost = true, explodes = 1, cooldownMax = 0 },
		value = 200,
		floorWeight = 10000, 
		locator=true,
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( "DELAYED",
				 "Detonates at the end of the turn", "gui/icons/arrow_small.png" )
        end,
	},
	
	item_lockdecoder_xu = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.LOCK.name,
		desc =  STRINGS.FLAVORED.ITEMS.LOCK.desc,
		flavor = STRINGS.FLAVORED.ITEMS.LOCK.flavor,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_lock_decoder_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_lock_decoder.png",		
		traits = {  cooldownMax = 0, disposable = true, applyFn = "isSecurityExit", doorDevice = "lock_decoder", profile_icon="gui/icons/item_icons/items_icon_small/icon-item_lock_decoder_small.png" },
		requirements = { },
		abilities = { "doorMechanism_xu", "carryable" },
		value = 50,		
		floorWeight = 1,
	},
	item_portabledrive_xu = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.ACCEL.name,
		desc =  STRINGS.FLAVORED.ITEMS.ACCEL.desc,
		flavor = STRINGS.FLAVORED.ITEMS.ACCEL.flavor,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_accellerator.png",	
		traits = { hacking_bonus = 3,  disposable = true,  cooldownMax = 0  },
		requirements = { },
		abilities = { "carryable","recharge","jackin" },
		value = 75,
		floorWeight = 1,
		notSoldAfter = 48, 
	},
	item_emp_pack_xu = util.extend(commondefs.item_template)
	{
		type = "simemppack",
		name = STRINGS.FLAVORED.ITEMS.EMP.name,
		desc =  STRINGS.FLAVORED.ITEMS.EMP.desc,
		flavor = STRINGS.FLAVORED.ITEMS.EMP.flavor,
		icon = "itemrigs/FloorProp_emp.png",
		--profile_icon = "gui/items/icon-emp.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_emp_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_emp.png",	
		abilities = { "carryable","prime_emp", },
		requirements = {},
		traits = { disposable = true, range = 2, emp_duration = 2,  cooldownMax = 0 },
		value = 250,
		floorWeight = 1,
		notSoldAfter = 1000, 
	},
	item_shocktrap_xu = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.TRAP.name,
		desc =  STRINGS.FLAVORED.ITEMS.TRAP.desc,
		flavor = STRINGS.FLAVORED.ITEMS.TRAP.flavor,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-shocktrap-.png",
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_shocktrap_mod_small.png",	
		profile_icon_100 = "gui/icons/item_icons/icon-item_shock trap_mod.png",		
		traits = { disposable = true, damage = 3, stun = 3, applyFn = "isClosedDoor", doorDevice = "simtrap",  cooldownMax = 0 },
		requirements = { },
		abilities = { "doorMechanism", "carryable" },
		value = 100,
		floorWeight = 1,
		notSoldAfter = 1000, 
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( "ARMOR PIERCING",
				 "Ignores Armor", "gui/icons/arrow_small.png" )
        end,
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















