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
local DEREK_SOUNDS =
{
    bio = "SpySociety_DLC001/VoiceOver/Central/Bio_Derek",
    escapeVo = "SpySociety_DLC001/VoiceOver/Central/Escape_Derek",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
    wallcover = "SpySociety/Movement/foley_suit/wallcover",
    crouchcover = "SpySociety/Movement/foley_suit/crouchcover",
    fall = "SpySociety/Movement/foley_suit/fall",	
    fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
    fall_kneeframe = 9,
    fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
    fall_handframe = 20,
    land = "SpySociety/Movement/deathfall_agent_hardwood",
    land_frame = 35,						
    getup = "SpySociety/Movement/foley_suit/getup",	
    grab = "SpySociety/Movement/foley_suit/grab_guard",	
    pin = "SpySociety/Movement/foley_suit/pin_guard",
    pinned = "SpySociety/Movement/foley_suit/pinned",
    peek_fwd = "SpySociety/Movement/foley_suit/peek_forward",	
    peek_bwd = "SpySociety/Movement/foley_suit/peek_back",	
    move = "SpySociety/Movement/foley_suit/move",	
    hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
} 
local DRACO_SOUNDS = util.extend(DEREK_SOUNDS)
{
	bio = "SpySociety_DLC001/VoiceOver/Central/Bio_Draco",
	escapeVo = "SpySociety_DLC001/VoiceOver/Central/Escape_Draco",
}


local agent_templates =
{
--[==[	rush = util.extend( unitdefs.lookupTemplate( "rush" ) )
	{
		name = "TEST",
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = {},  --- does not work!?
	} ]==]
	
	
	draco =
	{
		type = "simunit",
        agentID = 1003,
		name = STRINGS.DLC1.AGENTS.DRACO.NAME,
		fullname = STRINGS.DLC1.AGENTS.DRACO.ALT_1.FULLNAME,
		codename = STRINGS.DLC1.AGENTS.DRACO.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		file = STRINGS.DLC1.AGENTS.DRACO.FILE,
		yearsOfService = STRINGS.DLC1.AGENTS.DRACO.YEARS_OF_SERVICE,
		age = STRINGS.DLC1.AGENTS.DRACO.AGE,
		homeTown = STRINGS.DLC1.AGENTS.DRACO.HOMETOWN,
		gender = "male",
		toolTip = STRINGS.DLC1.AGENTS.DRACO.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/draco_36.png",
		profile_icon_64x64= "gui/profile_icons/draco_64x64.png",	
		splash_image = "gui/agents/draco_1024.png",
		profile_anim = "portraits/dracul_build",
		team_select_img = {
			"gui/agents/team_select_1_draco.png",
		},		
		kanim = "kanim_dracul",
		hireText = STRINGS.DLC1.AGENTS.DRACO.RESCUED,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8,  }, -- LOSrange = 7,
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) { }, 
		startingSkills = { },
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {},
		sounds = DRACO_SOUNDS,
		speech = STRINGS.DLC1.AGENTS.DRACO.BANTER,
		blurb = STRINGS.DLC1.AGENTS.DRACO.ALT_1.BIO,
		upgrades = { "augment_neural_mapper_2","item_cloakingrig_draco","item_sedative_draco" },
		logs = {},
	},
	
	
}
	

return agent_templates