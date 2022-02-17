---------------------------------------------------------------------
--
-- The function is responsible for initializing the mod and doing whatever
-- the mod needs to do up front.
--

local function initStrings( modApi )
	local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()
    local MOD_STRINGS = include( scriptPath .. "/strings" )
    modApi:addStrings( dataPath, "FLAVORED", MOD_STRINGS )  
    local MOD_STRINGS = include( scriptPath .. "/stolenGoods/detained_strings" )
    modApi:addStrings( dataPath, "DETAINED", MOD_STRINGS )  
	
end

-- init will be called once

local function init( modApi )

    log:write("inside flavAgents")
		
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()
	rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})
        SCRIPT_PATHS.FA_prefabs = scriptPath
		
		
	modApi.requirements = { "Contingency Plan", "New Items And Augments", "Function Library" }
	
	include(scriptPath .."/newCombat/agent_actions")
	include(scriptPath .."/newCombat/inventory")
	include(scriptPath .."/newCombat/items_panel")
	include(scriptPath .."/newCombat/simquery")
	include(scriptPath .."/newCombat/simunit")
	include(scriptPath .."/newCombat/simengine")
	include(scriptPath .."/newCombat/boardrig")
	--include(scriptPath .."/newCombat/hud")
	--include(scriptPath .."/newCombat/state-team-preview")
    
    -- Mount data.
	KLEIResourceMgr.MountPackage( dataPath .. "/gui.kwad", "data" )

	--modApi:addGenerationOption("Activate", "Activate Mod" , "Use Flavorful Agents")
	modApi:addGenerationOption("decker", STRINGS.FLAVORED.OPTIONS.ENABLE_DECKER , STRINGS.FLAVORED.OPTIONS.ENABLE_DECKER_TIP, {noUpdate = true})
	modApi:addGenerationOption("shalem", STRINGS.FLAVORED.OPTIONS.ENABLE_SHALEM , STRINGS.FLAVORED.OPTIONS.ENABLE_SHALEM_TIP, {noUpdate = true})
	modApi:addGenerationOption("prism", STRINGS.FLAVORED.OPTIONS.ENABLE_PRISM , STRINGS.FLAVORED.OPTIONS.ENABLE_PRISM_TIP, {noUpdate = true})
	modApi:addGenerationOption("internationale", STRINGS.FLAVORED.OPTIONS.ENABLE_INTERNATIONALE , STRINGS.FLAVORED.OPTIONS.ENABLE_INTERNATIONALE_TIP, {noUpdate = true})
	modApi:addGenerationOption("banks", STRINGS.FLAVORED.OPTIONS.ENABLE_BANKS , STRINGS.FLAVORED.OPTIONS.ENABLE_BANKS_TIP, {noUpdate = true})
	modApi:addGenerationOption("xu", STRINGS.FLAVORED.OPTIONS.ENABLE_XU , STRINGS.FLAVORED.OPTIONS.ENABLE_XU_TIP, {noUpdate = true})
	modApi:addGenerationOption("rush", STRINGS.FLAVORED.OPTIONS.ENABLE_RUSH , STRINGS.FLAVORED.OPTIONS.ENABLE_RUSH_TIP, {noUpdate = true})
	modApi:addGenerationOption("draco", STRINGS.FLAVORED.OPTIONS.ENABLE_DRACO , STRINGS.FLAVORED.OPTIONS.ENABLE_DRACO_TIP, {noUpdate = true})
	modApi:addGenerationOption("sharp", STRINGS.FLAVORED.OPTIONS.ENABLE_DRACO , STRINGS.FLAVORED.OPTIONS.ENABLE_DRACO_TIP, {noUpdate = true})
	modApi:addGenerationOption("cent_monst", STRINGS.FLAVORED.OPTIONS.ENABLE_CENTMONST , STRINGS.FLAVORED.OPTIONS.ENABLE_CENTMONST_TIP, {noUpdate = true})
	modApi:addGenerationOption("skills", STRINGS.FLAVORED.OPTIONS.ENABLE_SKILLS , STRINGS.FLAVORED.OPTIONS.ENABLE_SKILLS_TIP, {noUpdate = true})
	modApi:addGenerationOption("equip", STRINGS.FLAVORED.OPTIONS.ENABLE_EQUIP , STRINGS.FLAVORED.OPTIONS.ENABLE_EQUIP_TIP, {noUpdate = true})
--	modApi:addGenerationOption("close", STRINGS.FLAVORED.OPTIONS.ENABLE_CLOSE , STRINGS.FLAVORED.OPTIONS.ENABLE_CLOSE_TIP, {noUpdate = true}) -- needed for NewSkills
	-- modApi:addGenerationOption("detain", STRINGS.FLAVORED.OPTIONS.ENABLE_DETAIN , STRINGS.FLAVORED.OPTIONS.ENABLE_DETAIN_TIP, {noUpdate = true}) -- detention centre
end

local skilldefs = include( "sim/skilldefs" )
local oldLookupSkill = skilldefs.lookupSkill

local function unload( modApi , mod_options)
    local scriptPath = modApi:getScriptPath()
	
	local skills = include( scriptPath .."/newCombat/skilldefs" )

	skilldefs.lookupSkill = function(skillID)
		return oldLookupSkill(skillID) or skills[skillID]
	end
end

local function removeAgent( agency, agentDef )
	-- Remove all potentials with the same ID (or template)
	for i = #agency.unitDefsPotential, 1, -1 do
		local def2 = agency.unitDefsPotential[ i ]
		if (def2.id == agentDef.id) or (def2.template == agentDef.template) then
			table.remove( agency.unitDefsPotential, i )
		end
	end
end

-- load may be called multiple times with different options enabled
local function load( modApi, options, params )

    local scriptPath = modApi:getScriptPath()
	
	--local corpserig = include( scriptPath .."/newCombat/corpserig" )
	--local oldcorpserig = include( "client/gameplay/corpserig" )
	--oldcorpserig.rig = corpserig.rig
	
	
	if options["skills"] == nil or options["skills"].enabled then
		if params then
			params.flav_skills = true
		end
		local skills = include( scriptPath .."/newCombat/skilldefs" )

		skilldefs.lookupSkill = function(skillID)
			return skills[skillID] or oldLookupSkill(skillID)
		end
	else
		local skills = include( scriptPath .."/newCombat/skilldefs" )

		skilldefs.lookupSkill = function(skillID)
			return oldLookupSkill(skillID) or skills[skillID]
		end
		if params then
			params.flav_equipCosts = true -- default OFF
			params.flav_noAutoClose = true
		end
	end

	if (options["equip"] == nil or options["equip"].enabled) then
		if params then
			params.flav_unequip = false -- default OFF
		end
	else
		if params then
			params.flav_unequip = true
		end
	end
	
	if params and (options["close"] == nil or options["close"].enabled) then
		--params.flav_noAutoClose = true
	end
	
--	modApi:addAbilityDef( "moveBody", scriptPath .."/newCombat/moveBody" )	
	
	modApi:addAbilityDef( "escape", scriptPath .."/newCombat/escape" )  -- adds shalemB escape boost
	modApi:addAbilityDef( "equippable", scriptPath .."/newCombat/equippable" )  -- can now unequip. Equipping costs 1 AP
    modApi:addAbilityDef( "carryable", scriptPath .."/newCombat/carryable" ) -- pickup/drop costs 1AP
    modApi:addAbilityDef( "melee", scriptPath .."/newCombat/melee" ) -- excludes pacifists, non-melee weps
    modApi:addAbilityDef( "meleeOverwatch", scriptPath .."/newCombat/meleeOverwatch" ) -- 
    modApi:addAbilityDef( "overwatchMelee", scriptPath .."/newCombat/overwatchMelee" ) -- 
    modApi:addAbilityDef( "overwatch", scriptPath .."/newCombat/overwatch" ) -- 
	modApi:addAbilityDef( "shootSingle", scriptPath .."/newCombat/shootSingle" )	
	modApi:addAbilityDef( "shootOverwatch", scriptPath .."/newCombat/shootOverwatch" ) 
    modApi:addAbilityDef( "jackin", scriptPath .."/newCombat/jackin" ) -- now requires unequiped gun. Also handles triggers (future content)
    modApi:addAbilityDef( "observePath", scriptPath .."/newCombat/observePath" ) -- to do: own version on selectable cameras (universal 1ap)
    modApi:addAbilityDef( "throwInventory", scriptPath .."/newCombat/throwInventory" ) -- to do: custom UI if poss
    modApi:addAbilityDef( "consoles_emp", scriptPath .."/newCombat/consoles_emp" ) -- console ability: EMP nearby (hacking 2 abil)
    modApi:addAbilityDef( "consoles_scan", scriptPath .."/newCombat/consoles_scan" ) -- console ability: find assets within 8 tiles
   -- modApi:addAbilityDef( "console_observePath", scriptPath .."/newCombat/console_observePath" ) -- console ability: EMP nearby (hacking 2 abil)
    modApi:addAbilityDef( "use_stim", scriptPath .."/newCombat/use_stim" ) -- added usedStim trigger event (stim, user, target)
    modApi:addAbilityDef( "peek", scriptPath .."/newCombat/peek" ) -- adds Peek buff with larceny
	
	modApi:addAbilityDef( "stealCredits", scriptPath .."/newCombat/stealCredits" ) -- added usedStim trigger event (stim, user, target)
	
	
    modApi:addAbilityDef( "prism_combatdisguise", scriptPath .."/prism/prism_combatdisguise" ) 
    modApi:addAbilityDef( "prism_allytagger", scriptPath .."/prism/prism_allytagger" ) 
    modApi:addAbilityDef( "prism_allytagger_wake", scriptPath .."/prism/prism_allytagger_wake" ) 
    modApi:addAbilityDef( "jackin_calmguards", scriptPath .."/prism/jackin_calmguards" ) 
	
    modApi:addAbilityDef( "prism_handshake", scriptPath .."/prism/prism_handshake" ) 
    modApi:addAbilityDef( "prism_gps_tracker", scriptPath .."/prism/prism_gps_tracker" ) 
	
    modApi:addAbilityDef( "micronanofab", scriptPath .."/xu/micronanofab" ) 
   
	--modApi:addAbilityDef( "shalem_shootOverwatch", scriptPath .."/shalem/shalem_shootOverwatch" ) 
	modApi:addAbilityDef( "shalem_stowBody", scriptPath .."/shalem/shalem_stowBody" ) 
	modApi:addAbilityDef( "shalem_tagGuard", scriptPath .."/shalem/shalem_tagGuard" ) 
	modApi:addAbilityDef( "shalem_medgel", scriptPath .."/shalem_archive/shalem_medgel" ) 
	modApi:addAbilityDef( "shalem_healCorpse", scriptPath .."/shalem_archive/shalem_healCorpse" ) 
	--modApi:addAbilityDef( "use_invisigel", scriptPath .."/use_invisigel" )	
	
	modApi:addAbilityDef( "serviceGun", scriptPath .."/shalem_archive/serviceGun" )	
	modApi:addAbilityDef( "serviceReload", scriptPath .."/shalem_archive/serviceReload" )	
	--modApi:addAbilityDef( "shootDouble", scriptPath .."/shalem_archive/shootDouble" )	
	modApi:addAbilityDef( "strengthTazer", scriptPath .."/shalem_archive/strengthTazer" )	
	modApi:addAbilityDef( "throw_snap", scriptPath .."/shalem_archive/throw_snap" )	
	
	modApi:addAbilityDef( "bullrush", scriptPath .."/rush/bullrush" )	
	
	modApi:addAbilityDef( "decker_icebreak", scriptPath .."/decker/decker_icebreak" ) 
--	modApi:addAbilityDef( "decker_followGuard", scriptPath .."/decker/decker_followGuard" ) 
--	modApi:addAbilityDef( "decker_tailing", scriptPath .."/decker/decker_tailing" ) 
	modApi:addAbilityDef( "decker_installer", scriptPath .."/decker/decker_installer" ) 
	
	modApi:addAbilityDef( "console_doorOpener", scriptPath .."/banks/console_doorOpener" ) 
	modApi:addAbilityDef( "banks_paralyze", scriptPath .."/banks/banks_paralyze" ) 
	modApi:addAbilityDef( "banks_throwParalyze", scriptPath .."/banks/banks_throwParalyze" ) 
	
	modApi:addAbilityDef( "scandevice_ranged", scriptPath .."/internationale/scandevice_ranged" ) 
	
	modApi:addAbilityDef( "draco_sedate", scriptPath .."/draco/draco_sedate" ) 
	modApi:addAbilityDef( "neural_scan_2", scriptPath .."/draco/neural_scan_2" ) 
	modApi:addAbilityDef( "camBlocker", scriptPath .."/draco/camBlocker" ) 
	
	modApi:addAbilityDef( "sharp_eject", scriptPath .."/sharp/sharp_eject" ) 
	modApi:addAbilityDef( "sharp_ferry", scriptPath .."/sharp/sharp_ferry" ) 
	
	
	modApi:addAbilityDef( "icemelt", scriptPath .."/xu/icemelt" ) 
	modApi:addAbilityDef( "doorMechanism_xu", scriptPath .."/xu/doorMechanism_xu" ) 
	
	modApi:addAbilityDef( "hacknanofab", scriptPath .."/CentAndMonst/hacknanofab" ) 
	
	
---	modApi:addAbilityDef( "scan_securityCard", scriptPath .."/prism/scan_securityCard" ) 
--	modApi:addAbilityDef( "scan_vaultCard", scriptPath .."/prism/scan_vaultCard" ) 
--	modApi:addAbilityDef( "scan_exitCard", scriptPath .."/prism/scan_exitCard" ) 
--	modApi:addAbilityDef( "scan_guardCard", scriptPath .."/prism/scan_guardCard" ) 
	
--	if options["detain"] == nil or options["detain"].enabled then

	--	modApi:addAbilityDef( "open_detention_cells", scriptPath .."/stolenGoods/open_detention_cells" ) 
--		modApi:addAbilityDef( "stealVaultGoods", scriptPath .."/stolenGoods/stealVaultGoods" ) 
--		modApi:addAbilityDef( "unlockVault_l1", scriptPath .."/stolenGoods/unlockVault_l1" ) 
--		modApi:addAbilityDef( "unlockVault_l2", scriptPath .."/stolenGoods/unlockVault_l2" ) 
--		modApi:addAbilityDef( "unlockVault_l3", scriptPath .."/stolenGoods/unlockVault_l3" ) 
--		modApi:addAbilityDef( "filePenalty", scriptPath .."/stolenGoods/filePenalty" ) 

		local propdefs = include( scriptPath .. "/stolenGoods/propdefs_detention" )
			for name, propdef in pairs(propdefs) do
				modApi:addPropDef( name, propdef, false )
			end
		local itemdefs = include( scriptPath .. "/stolenGoods/itemdefs_vaultkeys" )
			for name, itemDef in pairs(itemdefs) do
				modApi:addItemDef( name, itemDef )
			end
--	end
	----------------------------------------------------
	local serverdefs = include ( scriptPath .. "/serverdefs" )
	
	if options["prism"] == nil or options["prism"].enabled then
		local agentdefs = include( scriptPath .. "/prism/agentdefs_prism" )
		for name, agentDef in pairs(agentdefs) do
			modApi:addAgentDef( name, agentDef )
		end
		
		local itemdefs = include( scriptPath .. "/prism/itemdefs_prism" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
		
	--	removeAgent( serverdefs.ORIGINAL_AGENCY, "disguise_1" )
	--	modApi:addRescueAgent( serverdefs.createAgent( "disguise_1", {"augment_prism_flav"} ))
		
	end

	if options["banks"] == nil or options["banks"].enabled then
		local agentdefs = include( scriptPath .. "/banks/agentdefs_banks" )
		for name, agentDef in pairs(agentdefs) do
			modApi:addAgentDef( name, agentDef )
		end
		
		local itemdefs = include( scriptPath .. "/banks/itemdefs_banks" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
	end
	
	local itemdefs = include("sim/unitdefs/itemdefs")
	local util = include("modules/util")

	if options["internationale"] == nil or options["internationale"].enabled then
		if params then
			params.flav_internationale = true
		end
		local agentdefs = include( scriptPath .. "/internationale/agentdefs_nat" )
		for name, agentDef in pairs(agentdefs) do
			modApi:addAgentDef( name, agentDef )
		end
		
		local itemdefs = include( scriptPath .. "/internationale/itemdefs_nat" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
	end

	if options["shalem"] == nil or options["shalem"].enabled then
		local agentdefs2 = include( scriptPath .. "/shalem/agentdefs_shalem" )
		for name, agentDef in pairs(agentdefs2) do
			modApi:addAgentDef( name, agentDef )
		end
		
		local itemdefs = include( scriptPath .. "/shalem/itemdefs_shalem" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
	end

	if options["shalem"] == nil or options["shalem"].enabled then
		local agentdefs2 = include( scriptPath .. "/shalem_archive/agentdefs_shalemA" )
		for name, agentDef in pairs(agentdefs2) do
			modApi:addAgentDef( name, agentDef )
		end
		
		local itemdefs = include( scriptPath .. "/shalem_archive/itemdefs_shalemA" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end     
	end

	if options["decker"] == nil or options["decker"].enabled then
		local agentdefs3 = include( scriptPath .. "/decker/agentdefs_decker" )
		for name, agentDef in pairs(agentdefs3) do
			modApi:addAgentDef( name, agentDef )
		end
		
		local itemdefs = include( scriptPath .. "/decker/itemdefs_decker" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
		
		local npc_abilities = include( scriptPath .. "/decker/npc_abilities_decker" )
        for name, ability in pairs(npc_abilities) do
            modApi:addDaemonAbility( name, ability )
        end  
	end
	
	if options["xu"] == nil or options["xu"].enabled then
		if params then
			params.flav_xu = true
		end
		local agentdefs5 = include( scriptPath .. "/xu/agentdefs_xu" )
		for name, agentDef in pairs(agentdefs5) do
			modApi:addAgentDef( name, agentDef )
		end
		local itemdefs = include( scriptPath .. "/xu/itemdefs_xu" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
	end

	if options["cent_monst"] == nil or options["cent_monst"].enabled then
		local agentdefs4 = include( scriptPath .. "/CentAndMonst/agentdefs_CentAndMonst" )
		for name, agentDef in pairs(agentdefs4) do
			modApi:addAgentDef( name, agentDef )
		end
		local itemdefs = include( scriptPath .. "/CentAndMonst/itemdefs_CentAndMonst" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
	end

	modApi:addAbilityDef( "cameraObservePath", scriptPath .."/newGuardsProps/cameraObservePath" ) 
	local propdefs = include( scriptPath .. "/newGuardsProps/propdefs" )
	for name, propDef in pairs(propdefs) do
		modApi:addPropDef( name, propDef, false )
	end
	
	if options["rush"] == nil or options["rush"].enabled then
		local itemdefs = include( scriptPath .. "/rush/itemdefs_rush" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
		local agentdefs = include( scriptPath .. "/rush/agentdefs_rush" )
		for name, agentDef in pairs(agentdefs) do
			modApi:addAgentDef( name, agentDef )
		end
	end
	
	if options["draco"] == nil or options["draco"].enabled then
		local itemdefs = include( scriptPath .. "/draco/itemdefs_draco" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
		local agentdefs = include( scriptPath .. "/draco/agentdefs_draco" )
		for name, agentDef in pairs(agentdefs) do
			modApi:addAgentDef( name, agentDef )
		end
	end
	
	if options["sharp"] == nil or options["sharp"].enabled then
		local itemdefs = include( scriptPath .. "/sharp/itemdefs_sharp" )
		for name, itemDef in pairs(itemdefs) do
			modApi:addItemDef( name, itemDef )
		end
		local agentdefs = include( scriptPath .. "/sharp/agentdefs_sharp" )
		for name, agentDef in pairs(agentdefs) do
			modApi:addAgentDef( name, agentDef )
		end
	end
	

end


 
return {
    init = init,
	unload = unload,
    load = load,
    initStrings = initStrings,
}
