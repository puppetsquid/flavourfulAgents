local util = include( "modules/util" )
local commondefs = include("sim/unitdefs/commondefs")
local speechdefs = include( "sim/speechdefs" )
local simdefs = include("sim/simdefs")
local SCRIPTS = include('client/story_scripts')
-----------------------------------------------------
-- Agent templates

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


local CENTRAL_SOUNDS = util.extend(PRISM_SOUNDS)
{
	bio = "SpySociety/VoiceOver/Missions/Bios/Central",
}

local MONST3R_SOUNDS = util.extend(DECKARD_SOUNDS)
{
	bio = "SpySociety/VoiceOver/Missions/Bios/Monst3r",
}

local agent_templates =
{
	
	--starting monst3r, instead of the on given to you at the end of the game
	monst3r_pc =
	{
		type = "simunit",
        agentID = 100,
		name = STRINGS.AGENTS.MONST3R.NAME,
		fullname = STRINGS.AGENTS.MONST3R.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.MONST3R.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.MONST3R.AGE,
		homeTown =STRINGS.AGENTS.MONST3R.HOMETOWN,
		toolTip = STRINGS.AGENTS.MONST3R.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/monst3r_36.png",
		profile_icon_64x64= "gui/profile_icons/monst3r_64x64.png",		
		gender = "male",
		splash_image = "gui/agents/monst3r_1024.png",
		profile_anim = "portraits/monst3r_face",
		team_select_img = {
			"gui/agents/team_select_1_monst3r.png",
		},
		lockedText = STRINGS.UI.TEAM_SELECT.UNLOCK_CENTRAL_MONSTER,
		kanim = "kanim_monst3r",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, monst3rUnit = true, monst3r = true },	
		tags = { "monst3r" },
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2, inventory = 2 },
		sounds = MONST3R_SOUNDS,
		speech = speechdefs.monst3r,
		hireText = STRINGS.AGENTS.MONST3R.RESCUED,
		blurb = STRINGS.AGENTS.MONST3R.ALT_1.BIO,
		upgrades = { "augment_monst3r_FA", "item_monst3r_gun" },	
	},	

	--starting monst3r, instead of the on given to you at the end of the game
	central_pc =
	{
		type = "simunit",
		name = STRINGS.AGENTS.CENTRAL.NAME,
        agentID = 108,
		fullname = STRINGS.AGENTS.CENTRAL.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.CENTRAL.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.CENTRAL.AGE,
		homeTown = STRINGS.AGENTS.CENTRAL.HOMETOWN,
		toolTip = STRINGS.AGENTS.CENTRAL.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/central_36.png",
		profile_icon_64x64= "gui/profile_icons/central_64x64.png",	
		splash_image = "gui/agents/central_1024.png",
		profile_anim = "portraits/central_face",
		gender = "female",
		team_select_img = {
			"gui/agents/team_select_1_central.png",
		},
		kanim = "kanim_central",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, central=true  },	
		tags = { "central" },
		children = {}, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 2, stealth = 2 },
		sounds = CENTRAL_SOUNDS,
		speech = speechdefs.central,
		blurb = STRINGS.AGENTS.CENTRAL.ALT_1.BIO,
		hireText = STRINGS.AGENTS.CENTRAL.RESCUED,
		lockedText = STRINGS.UI.TEAM_SELECT.UNLOCK_CENTRAL_MONSTER,
		upgrades = { "augment_central", "item_tazer" },	
	},	

	monst3r =
	{
		type = "simunit",
        agentID = 99,
		name = STRINGS.AGENTS.MONST3R.NAME,
		fullname = STRINGS.AGENTS.MONST3R.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.MONST3R.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.MONST3R.AGE,
		homeTown =STRINGS.AGENTS.MONST3R.HOMETOWN,
		toolTip = STRINGS.AGENTS.MONST3R.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/monst3r_36.png",
		profile_icon_64x64= "gui/profile_icons/monst3r_64x64.png",		
		gender = "male",
		splash_image = "gui/agents/monst3r_1024.png",
		profile_anim = "portraits/monst3r_face",
		team_select_img = {
			"gui/agents/team_select_1_monst3r.png",
		},
		kanim = "kanim_monst3r",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, monst3rUnit = true, monst3r = true, monst3rNPC = true},	
        tags = { "monst3r" },
		children =  { "augment_monst3r_FA", "item_monst3r_gun" },	
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2, inventory = 3 },
		sounds = MONST3R_SOUNDS,
		speech = speechdefs.monst3r,
		blurb = STRINGS.AGENTS.MONST3R.ALT_1.BIO,
	},	

	central =
	{
		type = "simunit",
		name = STRINGS.AGENTS.CENTRAL.NAME,
        agentID = 107,
		fullname = STRINGS.AGENTS.CENTRAL.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.AGENTS.CENTRAL.YEARS_OF_SERVICE,
		age = STRINGS.AGENTS.CENTRAL.AGE,
		homeTown = STRINGS.AGENTS.CENTRAL.HOMETOWN,
		toolTip = STRINGS.AGENTS.CENTRAL.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/central_36.png",
		profile_icon_64x64= "gui/profile_icons/central_64x64.png",	
		splash_image = "gui/agents/central_1024.png",
		profile_anim = "portraits/central_face",
		gender = "female",
		team_select_img = {
			"gui/agents/team_select_1_central.png",
		},
		kanim = "kanim_central",
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { inventoryMaxSize = 3, mp=8, mpMax=8, noUpgrade = true, central=true  },	
        tags = { "central" },
		children = { "augment_central", "item_tazer" },	
		abilities = util.tconcat( {  "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ),-- "stealth"
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { anarchy = 2, stealth = 3 },
		sounds = CENTRAL_SOUNDS,
		speech = speechdefs.central,
		blurb = STRINGS.AGENTS.CENTRAL.ALT_1.BIO,
	},	


}



return agent_templates
