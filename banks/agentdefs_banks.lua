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


local BANKS_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Banks",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Banks",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT, 

	wallcover = "SpySociety/Movement/foley_trench/wallcover",
	crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
	fall = "SpySociety/Movement/foley_trench/fall",
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,						
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
	
	stealth_2 =
	{
		type = "simunit",
        agentID = 4,
		name = STRINGS.AGENTS.BANKS.NAME,
		file =  STRINGS.AGENTS.BANKS.FILE,
		fullname = STRINGS.AGENTS.BANKS.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.BANKS.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.BANKS.AGE,
		homeTown = STRINGS.AGENTS.BANKS.HOMETOWN,
		gender = "female",
		class = "Hacker",
		toolTip = STRINGS.AGENTS.BANKS.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_stealth_36.png",
		profile_icon_64x64= "gui/profile_icons/banks_64x64.png",
		splash_image = "gui/agents/banks_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_banks.png",
		},

		profile_anim = "portraits/lady_stealth_face",
		kanim = "kanim_female_stealth_2",
		hireText = STRINGS.AGENTS.BANKS.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_BANKS,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8 },	--passiveKey = simdefs.DOOR_KEYS.SECURITY
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2 },
		abilities = util.tconcat( { "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ), -- "stealth"
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = BANKS_SOUNDS,
		speech = speechdefs.stealth_2,
		blurb = STRINGS.AGENTS.BANKS.ALT_1.BIO,
		upgrades = { "augment_banks", "item_paralyzer_banks" }, --merrymakers, "item_tazer", 
	},
	
}

	

return agent_templates