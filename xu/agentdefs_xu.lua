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


local XU_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/DrXu",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_DrXu",
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

local agent_templates =
{
	
	engineer_1 =
	{
		type = "simunit",
        agentID = 3,
		name = STRINGS.AGENTS.XU.NAME,
		file = STRINGS.AGENTS.XU.FILE,
		fullname = STRINGS.AGENTS.XU.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.XU.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.XU.AGE,
		homeTown = STRINGS.AGENTS.XU.HOMETOWN,
		gender = "male",

		class = "Engineer",
		toolTip = STRINGS.AGENTS.XU.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/tony_36.png",
		profile_icon_64x64= "gui/profile_icons/tony_64x64.png",		
		splash_image = "gui/agents/tony_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_tony.png",
		},		

		profile_anim = "portraits/dr_tony_face",
		kanim = "kanim_hacker_male",
		hireText = STRINGS.AGENTS.XU.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_TONY,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},
		startingSkills = { },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = XU_SOUNDS,
		speech = speechdefs.engineer_1,
		blurb = STRINGS.AGENTS.XU.ALT_1.BIO,
		upgrades = { "augment_tony", },	
	},	
	
	engineer_1_a =
	{
		type = "simunit",
        agentID = 3,
		name = STRINGS.AGENTS.XU.NAME,
		file = STRINGS.AGENTS.XU.FILE,
		codename = STRINGS.AGENTS.XU.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.XU.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService = STRINGS.AGENTS.XU.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.XU.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.XU.HOMETOWN,
		gender = "male",

		class = "Engineer",
		toolTip = STRINGS.AGENTS.XU.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/tony_36.png",
		profile_icon_64x64= "gui/profile_icons/tony2_64x64.png",		
		splash_image = "gui/agents/tony2_1024.png",
		team_select_img = {
			"gui/agents/team_select_2_tony.png",
		},		

		profile_anim = "portraits/dr_tony_face",
		kanim = "kanim_hacker_male_a",
		hireText = STRINGS.AGENTS.XU.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_TONY,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},
		startingSkills = { },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = XU_SOUNDS,
		speech = speechdefs.engineer_1,
		blurb = STRINGS.AGENTS.XU.ALT_2.BIO,
		upgrades = { "augment_tony_2","item_shocktrap_tony","item_emp_pack_tony"},	
	},		
	
}

	

return agent_templates