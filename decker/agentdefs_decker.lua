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


local DECKARD_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Decker",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Deckard",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,
					
	wallcover = "SpySociety/Movement/foley_trench/wallcover",
	crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
	fall = "SpySociety/Movement/foley_trench/fall",					
	fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
	fall_kneeframe = 9,
	fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
	fall_handframe = 20,
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 35,						
	getup = "SpySociety/Movement/foley_trench/getup",
	grab = "SpySociety/Movement/foley_trench/grab_guard",
	pin = "SpySociety/Movement/foley_trench/pin_guard",
	pinned = "SpySociety/Movement/foley_trench/pinned",	
	peek_fwd = "SpySociety/Movement/foley_trench/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_trench/peek_back",	
	move = "SpySociety/Movement/foley_trench/move",
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
}

local agent_templates =
{
	stealth_1 =
	{
		type = "simunit",
        agentID = 1,
		name = STRINGS.AGENTS.DECKARD.NAME,
		fullname = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		codename = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		file =STRINGS.AGENTS.DECKARD.FILE,
		yearsOfService = STRINGS.AGENTS.DECKARD.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.DECKARD.AGE,
		homeTown =  STRINGS.AGENTS.DECKARD.HOMETOWN,
		gender = "male",
		class = "Stealth",
		toolTip = STRINGS.AGENTS.DECKARD.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/stealth1_64x64.png",
		splash_image = "gui/agents/deckard_1024.png",

		team_select_img = {
			"gui/agents/team_select_1_deckard.png",
		},
		
		profile_anim = "portraits/stealth_guy_face",
		kanim = "kanim_stealth_male",
		hireText = STRINGS.AGENTS.DECKARD.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DECKARD,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { stealth = 2},
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = DECKARD_SOUNDS,
		speech = speechdefs.stealth_1,
		blurb = STRINGS.AGENTS.DECKARD.ALT_1.BIO,
		upgrades = { "augment_deckard", "item_tazer", "item_cloakingrig_deckard"},
	},
	
		stealth_1_a =
	{
		type = "simunit",
        agentID = 1,
		name = STRINGS.AGENTS.DECKARD.NAME,
		codename = STRINGS.AGENTS.DECKARD.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.DECKARD.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		file = STRINGS.AGENTS.DECKARD.FILE,
		yearsOfService = STRINGS.AGENTS.DECKARD.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.DECKARD.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.DECKARD.HOMETOWN,
		gender = "male",
		class = "Stealth",
		toolTip = STRINGS.AGENTS.DECKARD.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/stealth2_64x64.png",
		splash_image = "gui/agents/deckard2_1024.png",

		team_select_img = {
			"gui/agents/team_select_2_deckard.png",
		},
		
		profile_anim = "portraits/stealth_guy_face",
		kanim = "kanim_stealth_male_a",
		hireText = STRINGS.AGENTS.DECKARD.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DECKARD,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8, },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { }, -- stealth = 2
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = DECKARD_SOUNDS,
		speech = speechdefs.stealth_1,
		blurb = STRINGS.AGENTS.DECKARD.ALT_2.BIO,
		upgrades = { "augment_decker_2", "item_tazer_archdeck", "item_revolver_deckard"},
	},
}
	

return agent_templates