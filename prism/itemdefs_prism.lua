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
		------- Holomesh Aug - reduces inventory to make original slightly better. Encourages +str which reinforces dragging.
		------- Revised; Now has own charge so little control over charge rate. Make chip Prism Only for STR boost.
		------- Based on alert = pseudo replacement of Olivia's aug. Is plugged into defense system so makes sense
		
		augment_prism_backup = util.extend(commondefs.augment_template)
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
		
    	augment_prism_flav = util.extend(commondefs.augment_template)  -- possibly run on ammo; +1 ammo per alert / protochip?
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.HOLO_MESH_AUG_FLAVOR,
		traits = { 
			installed = true, scan_vulnerable=true, -- CPUperTurn=2, pwrCost=2, 
			warning=STRINGS.ITEMS.AUGMENTS.HOLO_MESH_AUG_WARNING, drop_dropdisguise=true,
			addAbilities = "prism_combatdisguise", --addInventory = -1,	
			charges = 0, chargesMax = 10, --usesCharges = true,
			isCombatCloak = true, lastTracker = 0, traitModAmmnt = 0, modTrait = {{ "mpMax", 0 }},
			chargeCost=4, chargesPerTurn=3, startCharge=4, isFirstCharge = true,
		},
		--keyword = "NETWORK", 
		--abilities = { "disguise_augmented" },
		--abilities = util.tconcat( commondefs.augment_template.abilities, { "disguise_augmented" }),
		profile_icon = "gui/icons/Flavour/icon-item_dermalHolo_small.png",
		profile_icon_100 = "gui/icons/Flavour/icon-item_dermalHolo.png",	
		onTooltip = function( tooltip, unit, userUnit )
		local simquery = include( "sim/simquery" )
		local name = util.toupper( unit:getName() )
		tooltip:addLine( ITEM_HEADER_COLOUR..name.."</>" )
		
		if unit:getUnitData().flavor then
			tooltip:addDesc(  FLAVOUR_COLOUR..unit:getUnitData().flavor.."</>" )
		end	
		
		if unit:getTraits().augment and unit:getTraits().installed == false then		
			tooltip:addLine( NOTINSTALLED_COLOUR.. STRINGS.UI.TOOLTIPS.NOT_INSTALLED .."</c>" )
		end
		
		if unit:getUnitData().desc then
			tooltip:addDesc( unit:getUnitData().desc )
		end

		if unit:getTraits().equipped then
			tooltip:addLine( EQUIPPED_COLOUR.. STRINGS.UI.TOOLTIPS.EQUIPPED .."</c>") 
		end
		
		-------------------- add stuff here ----------------------
		
		------ charge system
			tooltip:addAbility(  STRINGS.FLAVORED.ITEMS.AUGMENTS.CUSTOMCHARGE, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.CUSTOMCHARGE_DESC, unit:getTraits().startCharge), "gui/icons/arrow_small.png" )	
		------ charge cost
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.COSTCHARGE_ACTIVATE, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.COSTCHARGE_ACTIVATE_DESC, unit:getTraits().chargeCost), "gui/icons/arrow_small.png" )	
		------ charge per turn
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.AUGMENTS.DRAINCHARGE, util.sformat(STRINGS.FLAVORED.ITEMS.AUGMENTS.DRAINCHARGE_DESC, unit:getTraits().chargesPerTurn), "gui/icons/arrow_small.png" )	
			
			-------- also need to change float text in comdisg, chip needs disguise req and all text/images
		
		-------------------- end add stuff -----------------------
		
		if unit:getTraits().scan_vulnerable then
			tooltip:addAbility( STRINGS.UI.TOOLTIPS.SCAN_VULNERABLE, util.sformat(STRINGS.UI.TOOLTIPS.SCAN_VULNERABLE_DESC ), "gui/icons/arrow_small.png" )
		end	    
		
		if unit:getTraits().augment then
			if unit:getTraits().stackable then
				tooltip:addDesc( SPECIAL_INFO_COLOUR.. STRINGS.UI.TOOLTIPS.STACKABLE .."</>")
			else
				tooltip:addDesc( SPECIAL_INFO_COLOUR.. STRINGS.UI.TOOLTIPS.NOT_STACKABLE .."</>")
			end
		end
		
		local canUseAnyItem = false

		if userUnit and userUnit:getTraits() and userUnit:getTraits().useAnyItem then 
			canUseAnyItem= true
		end


		if unit:getRequirements() and userUnit then
			for skill,level in pairs( unit:getRequirements() ) do
				if not userUnit:hasSkill( skill, level ) and not canUseAnyItem then
					local skilldefs = include( "sim/skilldefs" )
					local skillDef = skilldefs.lookupSkill( skill )            	
					tooltip:addRequirement( string.format( STRINGS.UI.TOOLTIP_REQUIRES_SKILL_LVL, util.toupper(skillDef.name), level ))
				else
					local skilldefs = include( "sim/skilldefs" )
					local skillDef = skilldefs.lookupSkill( skill )            	
					tooltip:addLine( string.format( STRINGS.UI.TOOLTIP_REQUIRES_SKILL_LVL, util.toupper(skillDef.name), level ))             	
				end
			end
		end
		
		if unit:getTraits().installed and unit:getTraits().installed == false then		
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.INSTALL, STRINGS.ITEMS.TOOLTIPS.INSTALL_DESC, "gui/icons/arrow_small.png" )
		end

		if unit:getTraits().mp_penalty then
			tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.HEAVY_EQUIPMENT, util.sformat(STRINGS.ITEMS.TOOLTIPS.HEAVY_EQUIPMENT_DESC, unit:getTraits().mp_penalty ), "gui/icons/arrow_small.png" )
		end

		for i,tooltipFunction in ipairs(mod_manager:getTooltipDefs().onItemTooltips)do
			tooltipFunction(tooltip, unit, userUnit )
		end     

		
		end,
	},
	
	-------- PROP GUN - enough force to sell a shot / tumble an unsuspecting victim, but with little lasting damage. Includes a buzzer chip to let target know when to wake up
	------- weak attack, not sure if utility is great - should be more forced with combat holo
	
	item_allytagger = util.extend( commondefs.weapon_template )   --- plants camera which can reawaken unit? maybe later.
	{
		name =  STRINGS.FLAVORED.ITEMS.ALLYTAGGER,
		desc =  STRINGS.FLAVORED.ITEMS.ALLYTAGGER_TIP,
		flavor = STRINGS.FLAVORED.ITEMS.ALLYTAGGER_FLAVOR,
		icon = "itemrigs/FloorProp_Pistol.png",	
		profile_icon = "gui/icons/Flavour/icon-item_gun_allytagger_small.png",
		profile_icon_100 = "gui/icons/Flavour/icon-item_gun_allytagger.png",				
		equipped_icon = "gui/items/equipped_pistol.png",
		traits = { weaponType="pistol", fakeDamage = 4, canSleep = true, cooldown = 0, cooldownMax = 10, noOW = true},
		sounds = {shoot="SpySociety/Weapons/Precise/shoot_dart", reload="SpySociety/Weapons/LowBore/reload_handgun", use="SpySociety/Actions/item_pickup"},
		weapon_anim = "kanim_precise_revolver",
		agent_anim = "anims_1h",
		abilities = { "recharge", "prism_allytagger", "prism_allytagger_wake", "carryable", "equippable", }, -- "shootSingle", 
		value = 300,
		onTooltip = function( tooltip, unit, userUnit )
        commondefs.onItemTooltip( tooltip, unit, userUnit )
		
			local sim = unit._sim 
			local armorPiercing = unit:getTraits().armorPiercing or 0
			local damage = unit:getTraits().baseDamage or 0
			
--			tooltip:addAbility(  STRINGS.FLAVORED.ITEMS.ALLYTAGGER_TOOLTIP_ONLYWATCH, STRINGS.FLAVORED.ITEMS.ALLYTAGGER_TOOLTIP_ONLYWATCH_DESC, "gui/icons/arrow_small.png" )

			tooltip:addAbility(  STRINGS.FLAVORED.ITEMS.ALLYTAGGER_TOOLTIP_SLEEP, STRINGS.FLAVORED.ITEMS.ALLYTAGGER_TOOLTIP_SLEEP_DESC, "gui/icons/arrow_small.png" )

			
		end,
	},	

		-------- so this basically lets you be han solo

	item_calmchip = util.extend(commondefs.item_template)  -- only usable if disguised (i.e. only prism)
	{
		name = STRINGS.FLAVORED.ITEMS.ALARM_CHIP,
		desc = STRINGS.FLAVORED.ITEMS.ALARM_CHIP_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.ALARM_CHIP_FLAVOR,
		icon = "itemrigs/FloorProp_AmmoClip.png",
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/Flavour/icon-item_chip_calmer_small.png",
		profile_icon_100 = "gui/icons/Flavour/icon-item_chip_calmer.png",	
		traits = { cooldown = 0, cooldownMax = 7, startCooldown = 5 },  --- first point of cooldown is used before level starts
		requirements = { },
		abilities = { "carryable","recharge","jackin_calmguards" },
		value = 100,
		floorWeight = 1,
		onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.REQ_DISGUISE,
				util.sformat( STRINGS.FLAVORED.ITEMS.REQ_DISGUISE_DESC ), "gui/items/icon-action_hack-console.png" )
			tooltip:addAbility( STRINGS.FLAVORED.ITEMS.STARTS_COOLDOWN,
				util.sformat( STRINGS.FLAVORED.ITEMS.STARTS_COOLDOWN_DESC, (unit:getTraits().startCooldown - 1) ), "gui/items/icon-action_hack-console.png" )
        end,
	},
	
	copy_card = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.COPYCARD,
		desc = STRINGS.FLAVORED.ITEMS.COPYCARD_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.COPYCARD_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/Flavour/icon-item_copycard.png",
		profile_icon_100 = "gui/icons/Flavour/icon-item_copycard.png",
		abilities = { "carryable", "scan_securityCard", "scan_guardCard", "scan_vaultCard", "scan_exitCard" },
		value = 0,
		traits = { copy_card = true, }, -- keybits = simdefs.DOOR_KEYS.VAULT }, 
	},

	
	------------- archive augment! -------------------	
	----------- this is like a pick-pocketing bonus. prism is more of a wildcard and has more 'interaction' with guards


	augment_prism_handshake = util.extend( commondefs.augment_template )
	{
		name = STRINGS.FLAVORED.ITEMS.AUGMENTS.HANDSHAKE,
		desc = STRINGS.FLAVORED.ITEMS.AUGMENTS.HANDSHAKE_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.AUGMENTS.HANDSHAKE_FLAVOR,
		traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){
			addAbilities = "prism_handshake",	
			installed = true,
		},	
		profile_icon = "gui/icons/Flavour/icon-item_handshake_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_handshake.png",		
	},
	
	item_prismGPS = util.extend(commondefs.item_template)
	{
		name = STRINGS.FLAVORED.ITEMS.PACKET_GPS,
		desc = STRINGS.FLAVORED.ITEMS.PACKET_GPS_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PACKET_GPS_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/Flavour/icon-item_disk_GPS_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_disk_GPS.png",	
		abilities = { "carryable", "prism_gps_tracker" },
		value = 10,
		traits = { }, 
	},
	
	item_prismDirt_VIP = util.extend(commondefs.item_template)  --- Admin password (icebreak almost any single unit)
	{
		name = STRINGS.FLAVORED.ITEMS.PACKET_VIP,
		desc = STRINGS.FLAVORED.ITEMS.PACKET_VIP_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PACKET_VIP_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",	
		--profile_icon = "gui/items/icon-action_crack-safe.png",		
		profile_icon = "gui/icons/Flavour/icon-item_disk_ICEBREAK_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_disk_ICEBREAK.png",			
		traits = { icebreak = 10, disposable = true },
		requirements = { anarchy = 2, },
		abilities = { "icebreak","recharge","carryable" },
		value = 20,
	},
	
	item_prismDirt = util.extend(commondefs.item_template)  --  Compromising Info on this unit
	{
		name = STRINGS.FLAVORED.ITEMS.PACKET_DIRT,
		desc = STRINGS.FLAVORED.ITEMS.PACKET_DIRT_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PACKET_DIRT_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/Flavour/icon-item_disk_CREDIT_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_disk_CREDIT.png",	
		abilities = { "carryable" },
		value = 270,
		traits = { }, 
	},
	
	item_prismDirt_med = util.extend(commondefs.item_template)  --  Compromising Info on this unit
	{
		name = STRINGS.FLAVORED.ITEMS.PACKET_DIRT,
		desc = STRINGS.FLAVORED.ITEMS.PACKET_DIRT_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PACKET_DIRT_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/Flavour/icon-item_disk_CREDIT_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_disk_CREDIT.png",	
		abilities = { "carryable" },
		value = 180,
		traits = { }, 
	},
	
	item_prismDirt_low = util.extend(commondefs.item_template)  --  Compromising Info on this unit
	{
		name = STRINGS.FLAVORED.ITEMS.PACKET_DIRT,
		desc = STRINGS.FLAVORED.ITEMS.PACKET_DIRT_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PACKET_DIRT_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/Flavour/icon-item_disk_CREDIT_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_disk_CREDIT.png",	
		abilities = { "carryable" },
		value = 90,
		traits = { }, 
	},
	
	item_prismPWR = util.extend(commondefs.item_template) -- User password (gain 2 PWR from consoles)
	{
		name = STRINGS.FLAVORED.ITEMS.PACKET_PASSWORD,
		desc = STRINGS.FLAVORED.ITEMS.PACKET_PASSWORD_TOOLTIP,
		flavor = STRINGS.FLAVORED.ITEMS.PACKET_PASSWORD_FLAVOR,
		icon = "itemrigs/FloorProp_KeyCard.png",	
		--profile_icon = "gui/items/icon-action_crack-safe.png",
		profile_icon = "gui/icons/Flavour/icon-item_disk_PWR_small.png",
    	profile_icon_100 = "gui/icons/Flavour/icon-item_disk_PWR.png",	
		traits = { hacking_bonus = 2, disposable = true },
		requirements = { anarchy = 2, },
		abilities = { "carryable","recharge","jackin" },
		value = 10,
	},
}

-- Reassign key name to value table.
for id, template in pairs(tool_templates) do
	template.id = id
end

return tool_templates


















