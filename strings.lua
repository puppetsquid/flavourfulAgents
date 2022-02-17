---------------------------------------------------------------------
-- Invisible Inc. official DLC.
--

local MOD_STRINGS =
{	           
	
	OPTIONS =
	{
		ENABLE_PRISM = "Enable Prism Reworks",
		ENABLE_PRISM_TIP = "Alters augments and items for Prism\n\nMaster of disguise Prism confuses the guards in her greatest supporting role yet",  
		
		ENABLE_SHALEM = "Enable Shalem Reworks",
		ENABLE_SHALEM_TIP = "Alters augments and items for Shalem\n\nShalem is a cold and tactical killer\n\nArchived Shalem is a war-hardened battle-medic",  
		
		ENABLE_DECKER = "Enable Decker Reworks",
		ENABLE_DECKER_TIP = "Alters augments and items for Decker\n\nNostalgic Decker studies and evades guards\n\nArchived Decker is a chaotic agent who stirs up the hive",  
		
		ENABLE_INTERNATIONALE = "Enable Internationale Reworks",
		ENABLE_INTERNATIONALE_TIP = "Alters augments and items for Internationale\n\nPacifist Internationale is a fantastic scout but a reluctant fighter",  
		
		ENABLE_BANKS = "Enable Banks Reworks",
		ENABLE_BANKS_TIP = "Alters augments and items for Banks\n\nParanoid Banks uses her hacking skills to open all sorts of doors but is constantly looking over her shoulder",    
		
		ENABLE_XU = "Enable Dr. Xu Reworks",
		ENABLE_XU_TIP = "Alters augments and items for Dr. Xu\n\nBrilliant engineer Tony Xu may be physically hindered but he always has the right items for the job.\n\nArchived Xu has fewer gadgets but is more reliable",  
		
		ENABLE_CENTMONST = "Enable Central and Monst3r Reworks",
		ENABLE_CENTMONST_TIP = "Alters augments and items for Central and Monst3r",		
		
		ENABLE_RUSH = "Enable Rush Reworks",
		ENABLE_RUSH_TIP = "Alters augments and items for Rush\n\nSuper-athlete Rush is fast and strong but becomes less subtle the longer she stays on the field",
		
		ENABLE_DRACO = "Enable Draco Reworks",
		ENABLE_DRACO_TIP = "Alters augments and items for Draco\n\nTechno-Vampire Draco gathers intel from dead guards",
		
		ENABLE_SKILLS = "Enable skill reworks",
		ENABLE_SKILLS_TIP = "Alters agent skills",
		
		ENABLE_EQUIP = "DISABLE equip reworks",
		ENABLE_EQUIP_TIP = "Disabled by default. Makes equipping weapons consume AP and makes some actions impossible with weapons equipped. This will lock your agents into their roles even more.",
		
		ENABLE_CLOSE = "Enable no automatic closing of item screens",
		ENABLE_CLOSE_TIP = "Makes it so that the item transfer screen won't close when you take the last item",
		
		ENABLE_DETAIN = "Enable Detention Centre bonus mission",
		ENABLE_DETAIN_TIP = "Adds vaults of captured items to detention centres",
	},
	
	SKILLS = {
	
		STEALTH_NAME = "TRESPASS", -- stealth -- speed
        STEALTH_DESC = "Agent is skilled at moving around unseen",
        STEALTH1_TOOLTIP = "Standard movement\nCan Peek",
        STEALTH2_TOOLTIP = "Adds +1 AP\nCan Observe guard's path's for 1AP without console",
        STEALTH3_TOOLTIP = "Adds +1 AP",
        STEALTH5_TOOLTIP = "Adds +1 AP\n+1 sprint",

        HACKING_NAME = "HACKING", -- hacking
        HACKING_DESC = "Agent uses computers to their full advantage",
        HACKING1_TOOLTIP = "Hijack consoles\nObserve guards via consoles",
        HACKING2_TOOLTIP = "Adds +1 PWR per Console Hijack\nScan for mainframe devices within 4	tiles", 
		HACKING3_TOOLTIP = "Adds +1 PWR per Console Hijack\n+1 Scan Pulse of 2 tiles", 
		HACKING4_TOOLTIP = "Adds +1 PWR per Console Hijack\n+1 Scan Pulse", 
        HACKING5_TOOLTIP = "Adds +2 PWR per Console Hijack\n+1 Scan Pulse",
		
        INVENTORY_NAME = "SMUGGLERY", --possession
        INVENTORY_DESC = "Agent can move items and bodies efficiently",
        INVENTORY1_TOOLTIP = "Carry 3 items, 3 tile throw range\nTrade with adjacent allies.",
        INVENTORY2_TOOLTIP = "+1 item, +0.5 drag\n+1 throw, trade 2 tiles away",
        INVENTORY3_TOOLTIP = "+1 item\n+1 throw, +1 trade distance",
        INVENTORY4_TOOLTIP = "+1 item, +0.5 drag\n+1 throw, +1 trade distance",
        INVENTORY5_TOOLTIP = "+1 item, +1 melee KO\n+1 throw, +1 trade distance",
		
		ANARCHY_NAME = "LARCENY",
        ANARCHY_DESC = "Agent knows how to find what they're looking for",
        ANARCHY1_TOOLTIP = "STEAL from KO guards, 2AP to equip items",
        ANARCHY2_TOOLTIP = "STEAL from behind",
        ANARCHY3_TOOLTIP = "STEAL +15% more credits from guards\n-0.5AP to equip",
        ANARCHY4_TOOLTIP = "STEAL +20% more credits from guards\n-0.5AP to equip",
        ANARCHY5_TOOLTIP = "STEAL increased chance to find items\n-0.5AP to equip",
	},

	UI = 
	{
		BR_DESC = "Attack from the nearest tile behind or to the side of the target.",
		BR_BONUS = "Travel {1} tiles; +{2} KO +{2} Pierce\n\nKOs target for {3} ({4} + {5}) turns",
		BR_WILLSPRINT = "Loud",
		BR_WILLSPRINT_DESC = "User will enter sprint mode when using this ability",
		COMBAT_PANEL_TOO_CLOSE = "TOO CLOSE",                
        COMBAT_PANEL_NO_PATH = "NO VALID PATH", 
        BR_CHANGE = "NOT IN RANGE", 
        
		
		SHARP_EJECT = "EJECT",
		SHARP_EJECT_TT = "Eject {1}\n-1 AP",
		SHARP_EJECT_PLACEHOLDER = "Ejects most recent augment",
		SHARP_EJECT_NONE = "Cannot eject Framework",
		SHARP_EJECT_AP = "Requires 1 AP",
	
	},

	ITEMS =
	{
		AUGMENTS =
		{
			--------------- Prism Augs -----------------

			HANDSHAKE = "Digital Handshake",
			HANDSHAKE_TOOLTIP = "Melee range. Finds an information packet on guards.",
			HANDSHAKE_FLAVOR = "Augmentation is reviled in holovid circles, but this finger mod can easily pass for an innocuous ring while it scans nearby phones for habits and secrets.",

			HOLO_MESH_AUG = "Subcutaneous Holographic Mesh",
			HOLO_MESH_AUG_TOOLTIP = "Generates a disguise while active.\nSprinting and attacking disables the effect. Reduces MaxAP per turn used, does not work at 0MaxAP.",
			HOLO_MESH_AUG_FLAVOR ="After her 'death', Esther's influx of wealth and reliance on her holorig led her to surgically graft the device's mesh to her skin. It took a toll on her body, but she hasn't aged a day since.",
			
			CUSTOMCHARGE = "Strength Sap",
			CUSTOMCHARGE_DESC = "For each turn the disguise is active the user loses 2 MaxAP on the following turn.",
			COSTCHARGE_ACTIVATE = "Respite",
			COSTCHARGE_ACTIVATE_DESC = "If user starts turn disguised, disabling it reduces the MaxAP loss by 1",
			
			DRAINCHARGE = "Recharge",
			DRAINCHARGE_DESC = "User regains 1 MaxAP for each turn they are not disguised. Penalty displayed under augment as XX/10.",		
			
			HOLO_MESH_AUG_WARNING = "HOLOGRAM ACTIVE -1 MaxAP Next Turn",
			HOLO_MESH_AUG_USE = "Activate Disguise",
			HOLO_MESH_AUG_USE_TIP = "Will reduce MaxAP by 2 from next turn",
			HOLO_MESH_MINUS_CHARGE = "-{1} {1:MaxAP|MaxAP}",
			HOLO_MESH_PLUS_CHARGE = "+{1} {1:MaxAP|MaxAP}",
			NOT_ENOUGH_CHARGE = "Not enough MaxAP",
			
			------------ Shalem Augs --------------------
			
			SHALEMS = "High-Speed Optics",
			SHALEMS_TIP = "+1 armour piercing during ranged overwatch. Tag targets to disable heart monitors with PWR.",
			SHALEMS_FLAVOR = "This high-end eye replacement grants Shalem a slow-motion view of the world, allowing him to pinpoint weak spots that are usually obstructed on stationary targets.",
			
			HEARTBREAKER_BONUS  = "Heartbreaker",
			HEARTBREAKER_BONUS_DESC = "Tag 1 guard to destroy their heart monitor when using overwatch.\nCosts {1} PWR, {2} for advanced models.",
			HEARTBREAKER = "Heartbreak",
			HEARTBREAKER_DESC = "Overwatch ignores heart monitor.\n{1} PWR, one unit at a time.",
			
			SHALEM_DUMP = "Skeletal Gearing",
			SHALEM_DUMP_TIP = "Hide corpses in safes. Halves cleanup cost for corpse when used.",
			SHALEM_DUMP_FLAVOR = "The extra support this gearing provides when lifting heavy and ungainly objects makes this common augment for morticians and greengrocers alike.",
			
			STOW_BODY = "Stow Body",
			STOW_BODY_DESC = "HIDE AND HALVE CLEANUP COST FOR THIS GUARD",
			STOW_BODY_REQ_BODY = "Must be holding body to dispose of it",
			STOW_BODY_REQ_OPEN = "Safe must be opened",
			STOW_BODY_REQ_FRONT = "Must be in front of safe",
			
			MALIKS = "Hypodermatic Field Kit",
			MALIKS_TIP = "Spend a turn to revive a KO'd ally. Requires and uses Attack and full AP. Passive: restores 1 Ammo to all held items between missions.",
			MALIKS_FLAVOR = "Combat Medics are never caught short. Malik keeps an array of medical equipment and spare ammunition in hidden compartments across his body - let's hope he sterilises them.",
			
			----------------- Basic Augs ------------------
			
			DECKER_BOOT = "Server Kick",
			DECKER_BOOT_TIP = "Break 4 firewalls on databases",
			DECKER_BOOT_FLAVOR = "As much as he hates it, Decker admits that all this highly-interlinked technology makes a detective's job much easier - just never refer to his prosthetic legs as augments.",
			
			DECKER_DAEMON = "Personal Daemon",
			DECKER_DAEMON_TIP = "Installs or relocates the daemon 'WHISTLEBLOW' to a mainframe item the agent can see. Prompts nearby guard to inspect when activated.",
			DECKER_DAEMON_FLAVOR = "This primitive daemon went out of fashion after an ill-timed alarm lead to the loss of a lieutenant-general's cloaking device and several terabytes of installation keys.",
			
			DECKER_DEAMON_ACTION = "Invoke Daemon",
			DECKER_DEAMON_TOOLTIP = "Installs WHISTLEBLOW on %s",
			WHISTLEBLOW =
				{
					NAME = "WHISTLEBLOW",
					DESC = "Will alert a nearby guard when captured",
					SHORT_DESC = "THIS ITEM IS ALARMED",
					ACTIVE_DESC = "NEARBY GUARD GIVEN INSPECTION ORDERS",
					WARNING = "WHISTLEBLOW DAEMON\nGUARD ALERTED",
				},

			
			FOLLOWPATROL = "Start Patrol",
			FOLLOWPATROL_DESC = "Send this guard to investigate key items. Will end patrol at objective. One use.",
			
			INTERNATIONALS = "Wireless Scouter",
			INTERNATIONALS_TIP = "Reveals mainframe objects over 6 tiles; can uncover Daemons in line of sight.\nCannot attack unless using stims or an agent is threatened. Can never kill.",
			INTERNATIONALS_FLAVOR = "Using her skin as an antenna, Internationale can identify resources and threats across the mainframe.",
			
			BANKS = "Archway Master",
			BANKS_TIP = "Allows remote control of visible doors via nearby consoles; can open secure/vault doors until end of turn. Vision reduced to 2 tiles.",	
			BANKS_FLAVOR = "The quantum computer implanted in Banks's cranium can brute-force most basic operations without so much as a clearance code. Unfortunately, the botched operation has left her unable to trust her own senses.",
			BANKS_AP = "Uses AP",
			BANKS_AP_DESC = "Remotely operating a door uses 1 AP. Opening a Vault Door uses your remaining AP. EMP's console for 2 turns.",
			BANKS_VIS = "Limited Vision",
			BANKS_VIS_DESC = "Banks's vision is reduced to 2 tiles. She retains full vision when peeking, or while under the effect of Stims.",
			
			RUSH_TIP = "+3 MaxAP, -3 Sprint Bonus. Slowly converts MaxAP to Sprint Bonus. Adds Bullrush",
			RUSH_FLAVOR = "Rush's corporate-sponsored sprint augments grant her effortless speed for a short time. Unfortunately, she has trouble pacing herself.",
			RUSH_TIRING = "Tiring",
			RUSH_TIRING_DESC = "Converts 1 point of MaxAP to Sprint Bonus every 3 Turns (min 4 MaxAP).",
			RUSH_BULLRUSH = "Bullrush",
			RUSH_BULLRUSH_DESC = "Agent sprints up behind or to the side of a target and attacks, ending on their space.",
			RUSH_BULLRUSH_2 = "Bullrush Damage",
			RUSH_BULLRUSH_2_DESC = "Adds 1 KO and 1 Pierce to the attack per 2 tiles traveled (max bonus +3)",
			
			NEURAL_MAPPER = "NEURAL PATTERN GRID",
			NEURAL_MAPPER_TIP = "Scan KO'd targets to reveal unknown areas of the map.\nDead targets reveal larger, prioritized areas.\n+1 drag cost.",
			NEURAL_MAPPER_FLAVOR = "Recent memories can be imaged with unprecedented detail via neural mapping, especially if the subject isn't currently making new ones.",
			
			CLOAK_DRACO = "Reflector Rig",
			CLOAK_DRACO_TOOLTIP = "Renders the agent permanently invisible to cameras and turrets.",
			CLOAK_DRACO_FLAVOR = "Beloved by reclusive celebrities, these rigs automatically intercept the low-end cameras used by simple security systems and paparazzi.",
			
			SHARP_3 = "Modular Cybernetic Frame X8",
			SHARP_3_TOOLTIP ="+1 Augment slot.\nCan eject the agent's most recently installed augment at will.\nUses 1PWR and 1AP per eject.",
			SHARP_3_FLAVOR ="The sight of Sharp's highly-modular body constantly reworking itself can be an unsettling one, especially at the dinner table.",

			XU = "",
			XU_TOOLTIP = "Exchange ammo for single-use gadgets. \n\n'Selling' gadgets provides ammo rather than credits. Templates require turn cooldown between use. Regenerates 100 Ammo between missions. \n\nAgent's AP is reduced by 1",
			XU_FLAVOR =  "Dr. Xu's revolutionary MicroNanofab fits snuggly in a purpose-built cavity in his prosthetic arm. Unfortunately, the large power capacitor needed to charge the EMP impairs Xu's stamina.",
			
			MONSTERS = "Fabricator Multithreading",
			MONSTERS_TIP = "Access Nanofabricators from any captured console. Purchases have a 15% discount, but are stored within the Nanofab and must be manually picked up.",
			MONSTERS_FLAVOR = "Monst3r's unique knowledge of the Nanofabricator network allows him to remotely access and operate them with ease. He also gets a discount for in-store collection.",
		},
		
		
		NOTE_ACTION = "USES ACTION",
		NOTE_ACTION_DESC = "This ability counts as an attack",
		
		-- 1ko pistol + 4KO on allies (drag them through cameras!)
		
		ALLYTAGGER = "L.A.R. Pistol",
		ALLYTAGGER_TOOLTIP = "High velocity tag launcher. Safely KO and Revive allies.",
		ALLYTAGGER_FLAVOR = "Although little more dangerous than a BB gun, the ability to convincingly incapacitate willing subjects makes this an essential part of any grifter's toolkit.",
		ALLYTAGGER_TOOLTIP_SLEEP = "TAG ALLY",
		ALLYTAGGER_TOOLTIP_SLEEP_DESC = "KO an ally for 4 turns. Does not drop disguise. Subject may be pinned, dragged or wirelessly revived.",
		
		ALLYTAGGER_TOOLTIP_ONLYWATCH = "DEFENSIVE",
		ALLYTAGGER_TOOLTIP_ONLYWATCH_DESC = "This weapon can only attack enemies via Overwatch.",
		
		ALLYTAGGER_INFIELD_TAG = "Tag Ally",
		ALLYTAGGER_INFIELD_TAG_DESC = "KO for 4 turns",
		
		ALLYTAGGER_INFIELD_WAKE = "Wake Ally",
		ALLYTAGGER_INFIELD_WAKE_DESC = "Revive this unit. Does not require line of sight",
		ALLYTAGGER_INFIELD_WAKE_NEED_SPACE = "Agent pinned",
		
		---------------------
		
		ALARM_CHIP = "COMLINK CHIP",
		ALARM_CHIP_TOOLTIP = "Hijack consoles to reduce alarm level equal to stored PWR.",
		ALARM_CHIP_FLAVOR = "Often carried by engineers and emergency units to tap into low-clearance communication lines. It really helps calm an operator's fears if you talk to them confidently and ask how they're doing.",

		HIJACK_CALMGUARDS = "Counter Alarm",
		HIJACK_CALMGUARDS_DESC = "Reduce alarm by {1} {1:increment|increments}",
		
		REQ_DISGUISE = "Requires Disguise",
		REQ_DISGUISE_DESC = "Can only be used while user is actively disguised",
		REASON_REQ_DISGUISE = "Requires an active disguise",
		
		STARTS_COOLDOWN = "Starting Cooldown",
		STARTS_COOLDOWN_DESC = "Starts with {1} cooldown",
		
		ALARM_SUB = "ALARM -{1}",
		
		---------------------
		
		PACKET_GPS = "Packet: GPS",
		PACKET_GPS_TOOLTIP = "Tags the guard holding it at start of each turn",
		PACKET_GPS_FLAVOR = "This software, often used to keep tabs on employees, is insanely secure if treated with respect. Luckily, your targets rarely do.",	
		
		PACKET_DIRT = "Packet: Dirt",
		PACKET_DIRT_TOOLTIP = "Trade for credit (unknown amount)",
		PACKET_DIRT_FLAVOR = "You know from first-hand experience that someone out there will be willing to pay for this compromising information.",	
		
		PACKET_PASSWORD = "Packet: Password",
		PACKET_PASSWORD_TOOLTIP = "Use at consoles for 2 extra PWR",
		PACKET_PASSWORD_FLAVOR = "It's amazing how much further official identification will take you, even if it's not technically your own.",	
		
		PACKET_VIP = "Packet: VIP Password",
		PACKET_VIP_TOOLTIP = "Break up to 10 points of firewall",
		PACKET_VIP_FLAVOR = "There are some people in this world with more influence than they know what to do with. Surely you're willing to help them out.",			
		
		COPYCARD = "Copycard",
		COPYCARD_FUNC = "DUPLICATE",
		COPYCARD_FUNC_SEC = "Duplicate Lvl1 Security Passcard",
		COPYCARD_FUNC_VAL = "Duplicate Vault Access Card",
		COPYCARD_FUNC_EXT = "Duplicate Exit Access Card",
		COPYCARD_SEC = "Copycard --- Lvl1 Security",
		COPYCARD_VAL = "Copycard --- Vault Access",
		COPYCARD_EXT = "Copycard --- Exit Access",
		COPYCARD_OLD = "Copycard --- VOID PASSWORD",
		COPYCARD_TOOLTIP = "Scan a target's Keycard to temporarily turn this item into duplicate of it. Passwords on single-use cards are still compromised if the copy is used. Resets between levels.",
		COPYCARD_FLAVOR = "While passwords can be tough to crack, this short-range RFID holocard can perfectly duplicate any security pass it is exposed to, visually and functionally, without the original's owner being any the wiser.",			
		
		----------------------
		
		PARALYZER_BANKS = "Paralyzer Dart",
		PARALYZER_BANKS_TOOLTIP = "KOs or increases KO by 3 turns. Can be used in melee or thrown. Must be collected from target if thrown.",
		PARALYZER_BANKS_FLAVOR = "Banks perfected her dart-based combat over many solo corporate heists. After dozens of successful jobs and no fatalities, she was hailed as a modern Robin Hood.",
		
		STIM_NAT = "Shock Stims",
		STIM_NAT_TOOLTIP = "Restores 4 AP. All Stims override Pacifism.",
		STIM_NAT_FLAVOR = "A favourite amongst those preparing to jump out of airplanes into a warzone full of drones, this addictive chemical cocktail really lowers your inhibitions.",
		
		REVOLVER_DECKARD = "Refurbished Revolver", 
		REVOLVER_DECKARD_TOOLTIP = "Ranged targets. Lethal damage. Ignores Armour, Disables Shields and Heart Monitors. Cannot reload.", -- Guards/Drones detonate as Smoke/EMP bombs.  ?
		REVOLVER_DECKARD_FLAVOR = "An old revolver that has been extensively refurbished into a truly terrifying weapon. Each bullet is an irreplaceable hand-made electro-plasma composite, capable of bypassing any and all defences.",
		
		TAZER_DECK = "Knuckle Disrupters",
		TAZER_DECK_TOOLTIP = "KOs a Guard until end of turn and tags them. KO duration cannot be increased.",
		TAZER_DECK_FLAVOR = "Shortly after his termination, a drunken Decker found himself violently losing a bar-room brawl. His ex-colleagues walked away mostly uninjured and grinning, but Decker had the last laugh...",
		
		RIFLE_MALIK = "Service Rifle",
		RIFLE_MALIK_TOOLTIP = "Can shoot multiple times a round. Requires resetting between uses, which consumes an attack.",
		RIFLE_MALIK_FLAVOR = "While civilians adopted the technology quickly, commanders and soldiers knew better than to take nanofabs for granted - these early service rifles saw use right through the Resource Wars due to the care their owners took with them.",
		
		GRENADE_MALIK = "Snap-Grenade Belt",
		GRENADE_MALIK_TOOLTIP = "Knocks out electronics for one turn. Charges restock between missions.",
		GRENADE_MALIK_FLAVOR = "These palm-sized EMP grenades were mass-produced during the war due to both their ability to disable early robotic soldiers and their popularity with children.",
		
		PARALYZER_DRACO = "Volt Paralyzer", --- 3ko 3 pwr
		PARALYZER_DRACO_TOOLTIP = "Melee range, does not move target",
		PARALYZER_DRACO_FLAVOR = "During his research into neural mapping, Draco developed a powerful noostoxin to aid in sample collecting. Unfortunately, a few subjects did die from accidental overdose.",
		PARALYZER_DRACO_KILLS = "Lethal",
		PARALYZER_DRACO_KILLS_DETAIL = "Kills pinned targets",
		
		PARALYZER_DRACO_HINT_KO = "Volt Paralyzer", --- 3ko 3 pwr
		PARALYZER_DRACO_HINT_KILL = "Overdose", --- 3ko 3 pwr
		PARALYZER_DRACO_DESC_KO = "Inject target with noostoxin. Target will be KO'd for {1} {1:turn|turns}.",
		PARALYZER_DRACO_DESC_KILL = "Inject pinned victim with noostoxin. Target will be killed.",

		
		NEURAL_MAPPER = "NEURAL PATTERN GRID",
		NEURAL_MAPPER_TIP = "Scan KO'd targets to reveal areas of the map. Scanning dead targets reveals high-priority targets first.",
		NEURAL_MAPPER_FLAVOR = "Memories can be imaged with unprecedented detail via neural mapping, especially if the subject isn't currently making new ones.",
		
		CLOAK_DRACO = "Reflector Rig",
		CLOAK_DRACO_TOOLTIP = "Renders the agent permanently invisible to cameras and turrets.",
		CLOAK_DRACO_FLAVOR = "Beloved by reclusive celebrities, these rigs automatically intercept the low-end cameras used by simple security systems and paparazzi.",
		
		
		---xu gadgets
		
		BUG = {
			name =  "Debug Chip",
			desc = "Installs a Parasite on a mainframe object, breaking 1 firewall at the start of each turn",
			flavor = "Some tasks require subtlety, finesse, and a moth on a string.",
			},
		
		SMOKE = {
			name = "Makeshift Smoke Grenade",
			desc = "Throw to create a cloud of smoke that occludes vision in an area after a short delay.",
			flavor = "While just as effective as a standard smoke grenade when fully shaken, it sometimes takes a little while for the coke to react to the mints.",
			},
		
		LOCK = {
			name = "Lock Picker",
			desc = "Place on a locked door to decode and disable the lock at the begining of the next turn.",
			flavor = "Less efficient than a keycard, but more expensive!",
			},
		
		ACCEL = {
			name = "Ignition Bypass",
			desc = "Use at a console to increase the amount of PWR generated by 3.",
			flavor = "The process of hotwiring a console to increase turnover is one enjoyed by many aspiring young engineers, but the amperage output during the process makes it one seldom enjoyed by many older ones.",	
			},

		EMP = {
			name = "Jury-Rigged EMP Pack",
			desc = "Detonates at the end of the turn. Disables all Mainframe devices and drones within 2 tiles.",
			flavor = "Xu has become so used to crafting these packs that he often wakes up to unexpected EMP blasts.",	
			},
			
		TRAP = {
			name = "Jury-Rigged Shock Trap",
			desc = "Place on a door. Triggers when opened. Hilarious.",
			flavor = "Why mess with the classics?",	
			},

	},


}

return MOD_STRINGS
























