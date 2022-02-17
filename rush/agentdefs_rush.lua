---------------------------------------------------------------------
-- Invisible Inc. official DLC.
--

-- NOTE: Each agent needs a completely unique agentID. We used numbers, 
-- but strings may be better as they could have a prefix of your mod name making 
-- it less likely for conflicts. EG: new agent Gary in the CoolMod = "coolMod-Gary"
--

local util = include( "modules/util" )
local commondefs = include( "sim/unitdefs/commondefs" )
local simdefs = include("sim/simdefs")
local speechdefs = include("sim/speechdefs")
local SCRIPTS = include('client/story_scripts')
local DEFAULT_DRONE = commondefs.DEFAULT_DRONE
local SOUNDS = commondefs.SOUNDS

local unitdefs = include( "sim/unitdefs" )
local OLIVIA_SOUNDS =
{
	bio = "SpySociety_DLC001/VoiceOver/Central/Bio_Olivia",
    escapeVo = "SpySociety_DLC001/VoiceOver/Central/Escape_Olivia",    
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT, 

	wallcover = "SpySociety/Movement/foley_suit/wallcover", 
	crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
	fall = "SpySociety/Movement/foley_suit/fall",
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,						
	getup = "SpySociety/Movement/foley_suit/getup",
	grab = "SpySociety/Movement/foley_suit/grab_guard",
	pin = "SpySociety/Movement/foley_suit/pin_guard",
	pinned = "SpySociety/Movement/foley_suit/pinned",
	peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_suit/peek_back",
	move = "SpySociety/Movement/foley_suit/move",		
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",   
}local RUSH_SOUNDS = util.extend(OLIVIA_SOUNDS)
{
	bio = "SpySociety_DLC001/VoiceOver/Central/Bio_Rush",
	escapeVo = "SpySociety_DLC001/VoiceOver/Central/Escape_Rush",
}


local agent_templates =
{
--[==[	rush = util.extend( unitdefs.lookupTemplate( "rush" ) )
	{
		name = "TEST",
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = {},  --- does not work!?
	} ]==]
	
	rush =
	{
		type = "simunit",
        agentID = 1002,
		name = STRINGS.DLC1.AGENTS.RUSH.NAME,
		fullname = STRINGS.DLC1.AGENTS.RUSH.ALT_1.FULLNAME,
		codename = STRINGS.DLC1.AGENTS.RUSH.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		file = STRINGS.DLC1.AGENTS.RUSH.FILE,
		yearsOfService = STRINGS.DLC1.AGENTS.RUSH.YEARS_OF_SERVICE,
		age = STRINGS.DLC1.AGENTS.RUSH.AGE,
		homeTown = STRINGS.DLC1.AGENTS.RUSH.HOMETOWN,
		gender = "female",
		toolTip = STRINGS.DLC1.AGENTS.RUSH.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/rush_36.png",
		profile_icon_64x64= "gui/profile_icons/rush_64x64.png",	
		splash_image = "gui/agents/rush_1024.png",
		profile_anim = "portraits/rush_face",
		team_select_img = {
			"gui/agents/team_select_1_rush.png",
		},
		kanim = "kanim_rush",
		hireText = STRINGS.DLC1.AGENTS.RUSH.RESCUED,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { },
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {},
		sounds = RUSH_SOUNDS,
		speech = STRINGS.DLC1.AGENTS.RUSH.BANTER,
		blurb = STRINGS.DLC1.AGENTS.RUSH.ALT_1.BIO,
		upgrades = { "augment_kinetic_capacitor","item_tazer"}, 
		logs = {},
	},	
}
	

return agent_templates