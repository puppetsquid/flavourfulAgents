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


local INTERNATIONALE_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Internationale",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Internationale",
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
}

local agent_templates =
{
	
		engineer_2 =
	{
		type = "simunit",
        agentID = 5,
		name = STRINGS.AGENTS.INTERNATIONALE.NAME,
		file = STRINGS.AGENTS.INTERNATIONALE.FILE,
		fullname = STRINGS.AGENTS.INTERNATIONALE.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.INTERNATIONALE.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.INTERNATIONALE.AGE,
		homeTown = STRINGS.AGENTS.INTERNATIONALE.HOMETOWN,
		gender = "female",
		class = "Engineer",
		toolTip = STRINGS.AGENTS.INTERNATIONALE.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_tech_36.png",
		profile_icon_64x64= "gui/profile_icons/engineer2_64x64.png",
		splash_image = "gui/agents/red_1024.png",
		team_select_img = {"gui/agents/team_select_1_red.png",},
		profile_anim = "portraits/lady_tech_face",
		kanim = "kanim_female_engineer_2",
		hireText = STRINGS.AGENTS.INTERNATIONALE.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_INTERNATIONALE,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 2 },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = INTERNATIONALE_SOUNDS,
		speech = speechdefs.engineer_2,
		blurb = STRINGS.AGENTS.INTERNATIONALE.ALT_1.BIO,
		upgrades = { "augment_international_v1", "item_stim_nat" },
	},
	
}

	

return agent_templates