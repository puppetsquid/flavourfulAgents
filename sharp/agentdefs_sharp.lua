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

local SHARP_SOUNDS =
{
    bio = "SpySociety/VoiceOver/Missions/Bios/Sharp",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Sharp",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT,

	wallcover = "SpySociety/Movement/foley_cyborg/wallcover", 
	crouchcover = "SpySociety/Movement/foley_cyborg/crouchcover",
	fall = "SpySociety/Movement/foley_cyborg/fall",	
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 35,	
	getup = "SpySociety/Movement/foley_cyborg/getup",
	grab = "SpySociety/Movement/foley_cyborg/grab_guard",
	pin = "SpySociety/Movement/foley_cyborg/pin_guard",
	pinned = "SpySociety/Movement/foley_cyborg/pinned",
	peek_fwd = "SpySociety/Movement/foley_cyborg/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_cyborg/peek_back",
	move = "SpySociety/Movement/foley_cyborg/move",						
	hit = "SpySociety/HitResponse/hitby_ballistic_cyborg",
}

local agent_templates =
{
	
	cyborg_1 =
	{
		type = "simunit",
        agentID = 7,
		name =  STRINGS.AGENTS.SHARP.NAME,
		file =  STRINGS.AGENTS.SHARP.FILE,
		fullname =  STRINGS.AGENTS.SHARP.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService =  STRINGS.AGENTS.SHARP.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.SHARP.AGE,
		homeTown = STRINGS.AGENTS.SHARP.HOMETOWN,
		gender = "male",
		class = "Cyborg",
		toolTip = STRINGS.AGENTS.SHARP.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/sharp_36.png",
		profile_icon_64x64= "gui/profile_icons/sharp_64x64.png",
		splash_image = "gui/agents/sharp_1024.png",
		profile_anim = "portraits/robo_alex_face",	
		team_select_img = {
			"gui/agents/team_select_1_sharp.png"
		},

		kanim = "kanim_cyborg_male",
		hireText = STRINGS.AGENTS.SHARP.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_SHARP,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8, augmentMaxSize = 3 },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = {  stealth = 2 } , --inventory = 2
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = SHARP_SOUNDS,
		speech = speechdefs.cyborg_1,
		blurb = STRINGS.AGENTS.SHARP.ALT_1.BIO,
		upgrades = {  "augment_sharp_flav","item_tazer" },	
	},
	
}

	

return agent_templates