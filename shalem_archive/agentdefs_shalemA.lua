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


local SHALEM_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Shalem",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Shalem11",
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
	
	sharpshooter_1_a =
	{
		type = "simunit",
        agentID = 2,
		name =  "Shalem", -- STRINGS.AGENTS.SHALEM.NAME,
		file =  STRINGS.AGENTS.SHALEM.FILE,
		codename = STRINGS.AGENTS.SHALEM.ALT_2.FULLNAME,
		fullname = STRINGS.AGENTS.SHALEM.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService =  STRINGS.AGENTS.SHALEM.YEARS_OF_SERVICE,
		age =  STRINGS.AGENTS.SHALEM.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.SHALEM.HOMETOWN,
		gender = "male",
		class = "Sharpshooter",
		toolTip = STRINGS.AGENTS.SHALEM.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/sharpshooter_36.png",
		profile_icon_64x64= "gui/profile_icons/shalem2_64x64.png",	
		splash_image = "gui/agents/shalem_1024_2.png",
		team_select_img = {
			"gui/agents/team_select_2_shalem.png",
		},

		profile_anim = "portraits/sharpshooter_face",
		kanim = "kanim_sharpshooter_male_a",
		hireText =  STRINGS.AGENTS.SHALEM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_SHALEM11,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax = 8 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { },
		abilities = util.tconcat( { "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = SHALEM_SOUNDS,
		speech = speechdefs.sharpshooter_1,
		blurb =  STRINGS.AGENTS.SHALEM.ALT_2.BIO,
		upgrades = {"item_tazer_shalemA", "item_clean_pistol", "augment_shalemA" },
	},	
	
}

	

return agent_templates