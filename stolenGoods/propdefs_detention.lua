local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local commondefs = include("sim/unitdefs/commondefs")
local tool_templates = include("sim/unitdefs/itemdefs")

-------------------------------------------------------------
--


local MAINFRAME_TRAITS = commondefs.MAINFRAME_TRAITS
local SAFE_TRAITS = commondefs.SAFE_TRAITS
local onMainframeTooltip = commondefs.onMainframeTooltip
local onSoundBugTooltip = commondefs.onSoundBugTooltip
local onBeamTooltip = commondefs.onBeamTooltip
local onConsoleTooltip = commondefs.onConsoleTooltip
local onStoreTooltip = commondefs.onStoreTooltip
local onDeviceTooltip = commondefs.onDeviceTooltip
local onSafeTooltip = commondefs.onSafeTooltip 

local prop_templates =
{

	lab_safe = 
	{ 
		type = "simunit", 
		name =  STRINGS.PROPS.SAFE,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_safe", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS, MAINFRAME_TRAITS ) { moveToDevice=true, tier1Safe = true, },
		abilities = { "stealCredits" },
		lootTable = "lab_safe",
		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive",reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},
	
	vault_safe_detention = 
	{ 
		type = "simunit", 
		name = STRINGS.PROPS.DEPOSIT_BOXES,
		onWorldTooltip = onSafeTooltip,
		kanim = "kanim_vault_safe_1", 
		rig ="corerig",
		traits = util.extend( SAFE_TRAITS  ) {  moveToDevice=true, mainframe_status = "active", security_box=true, security_box_locked=true, mainframe_icon=true, emp_safe=true, inventoryMaxSize = 16},
		abilities = {  "unlockVault_l3", "unlockVault_l2",  "stealVaultGoods", }, --"unlockVault_l1",

		sounds = {appeared="SpySociety/HUD/gameplay/peek_positive", reboot_start="SpySociety/Actions/reboot_initiated_safe",reboot_end="SpySociety/Actions/reboot_complete_safe" }
	},	
	
	detain_vault_passcard =
	{
		type = "simunit",
		name = STRINGS.DETAINED.ITEMS.GUARD_KEY,
		desc = STRINGS.DETAINED.ITEMS.GUARD_KEY_TOOLTIP,
		flavor = STRINGS.DETAINED.ITEMS.GUARD_KEY_FLAVOR,			
		icon = "itemrigs/FloorProp_KeyCard.png",		
		profile_icon = "gui/icons/item_icons/icon-item_passcard.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_passcard.png",
		tooltip = "<ttbody><ttheader2>PASS CARD</> Unlock Mid-level Security Locker.",
    	onWorldTooltip = commondefs.onItemWorldTooltip,
    	onTooltip = commondefs.onItemTooltip,		
		abilities = { "carryable" },
		traits = { keybits = simdefs.DOOR_KEYS.GUARD },  -- noDestroy = true
	},
	
	item_miaFile =
	{
		type = "simunit",
		name = STRINGS.DETAINED.ITEMS.DETFILE_2,
		desc = STRINGS.DETAINED.ITEMS.DETFILE_T3_TOOLTIP,
		flavor = STRINGS.DETAINED.ITEMS.DETFILE_T3_FLAVOR,			
		icon = "itemrigs/FloorProp_AmmoClip.png",		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_accellerator_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_compile_key.png",
		tooltip = "<ttbody><ttheader2>PASS CARD</> Unlock Mid-level Security Locker.",
    	onWorldTooltip = commondefs.onItemWorldTooltip,
    	onTooltip = commondefs.onItemTooltip,		
		abilities = { "carryable", "filePenalty" },
		traits = { isDetFile = true, penalty = 1, oValue = 1 },  -- noDestroy = true
	},
	

}


return prop_templates
