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


local PRISM_SOUNDS =
{
	bio = "SpySociety/VoiceOver/Missions/Bios/Esther",
    escapeVo = "SpySociety/VoiceOver/Missions/Escape/Operator_Escape_Agent_Prism",    
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
	
	disguise_1 =  ---- Prism is disguise master. Tricks enemies with disguises and ploys, digs team out of holes. Is han solo in a stormtroop suit.
	{
		type = "simunit",
        agentID = 8,
		name =  STRINGS.AGENTS.PRISM.NAME,
		file =  STRINGS.AGENTS.PRISM.FILE,
		fullname =  STRINGS.AGENTS.PRISM.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService =  STRINGS.AGENTS.PRISM.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.PRISM.AGE,
		homeTown = STRINGS.AGENTS.PRISM.HOMETOWN,
		gender = "female",
		class = "Disguise",
		toolTip = STRINGS.AGENTS.PRISM.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/prism_36.png",
		profile_icon_64x64= "gui/profile_icons/prism1_64x64.png",
		splash_image = "gui/agents/prism_1024.png",
		profile_anim = "portraits/prism_face",	
		team_select_img = {
			"gui/agents/team_select_1_prism.png"
		},

		kanim = "kanim_disguise_female",
		hireText = STRINGS.AGENTS.PRISM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_PRISM,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8, augmentMaxSize = 1},
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},		
		startingSkills = {  }, -- inventory = 2
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = PRISM_SOUNDS,
		speech = speechdefs.disguise_1,
		blurb = STRINGS.AGENTS.PRISM.ALT_1.BIO,
		upgrades = { "augment_prism_flav", "item_allytagger", "copy_card" }, -- "item_calmchip"
	},
	
	disguise_1_a =  -- prism gives people a taste of their own medicine, turning their own information against them
	{
		type = "simunit",
        agentID = 8,
		name =  STRINGS.AGENTS.PRISM.NAME,
		file =  STRINGS.AGENTS.PRISM.FILE,
		fullname =  STRINGS.AGENTS.PRISM.ALT_1.FULLNAME,
		codename = STRINGS.AGENTS.PRISM.ALT_2.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService =  STRINGS.AGENTS.PRISM.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.PRISM.ALT_2.AGE,
		homeTown = STRINGS.AGENTS.PRISM.HOMETOWN,
		gender = "female",
		class = "Disguise",
		toolTip = STRINGS.AGENTS.PRISM.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,

		profile_icon_36x36= "gui/profile_icons/prism2_36.png",
		profile_icon_64x64= "gui/profile_icons/prism2_64x64.png",
		splash_image = "gui/agents/prism2_1024.png",
		profile_anim = "portraits/prism_face",	
		team_select_img = {
			"gui/agents/team_select_1_prism2.png"
		},

		kanim = "kanim_disguise_female_a",
		hireText = STRINGS.AGENTS.PRISM.RESCUED,
		centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_PRISM,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { shields = 0, shieldsMax = 0, mp=8, mpMax = 8, augmentMaxSize = 1  },
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {},		
		startingSkills = { anarchy = 2 },
		abilities = util.tconcat( {  "sprint" }, commondefs.DEFAULT_AGENT_ABILITIES ),
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = PRISM_SOUNDS,
		speech = speechdefs.disguise_1,
		blurb = STRINGS.AGENTS.PRISM.ALT_2.BIO,
		upgrades = { "item_prism_1", "augment_prism_handshake" },	
	},	

}

	

return agent_templates