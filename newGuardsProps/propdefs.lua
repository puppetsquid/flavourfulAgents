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
	
	security_camera_1x1 =
	{
		type = "simcamera",
		name = STRINGS.PROPS.SECURITY_CAMERA,
		kanim = "kanim_security_camera",
		onWorldTooltip = onMainframeTooltip,
		profile_anim = "portraits/camera_portrait",		
		facing = simdefs.DIR_N,	
		rig = "camerarig",
        hit_fx = { z = 64 },
		abilities = { "cameraObservePath" },
		traits = util.extend( MAINFRAME_TRAITS )
			{ mainframe_camera = true, mainframe_no_daemon_spawn = true, hasSight = true, canBeShot = true, hit_metal = true, LOSrange = 8, breakIceOffset = 56, hasAttenuationHearing=true },
		sounds = {appeared="SpySociety/HUD/gameplay/peek_negative",reboot_start="SpySociety/Actions/reboot_initiated_camera",reboot_end="SpySociety/Actions/reboot_complete_camera"},		
	},	
	
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

}


return prop_templates
