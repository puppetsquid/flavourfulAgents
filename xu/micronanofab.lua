local abilityutil = include( "sim/abilities/abilityutil" )
local mission_util = include( "sim/missions/mission_util" )

local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )

local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local simunit = include( "sim/simunit" )

local unitdefs = include( "sim/unitdefs" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilitydefs = include( "sim/abilitydefs" )


local function clearBuyback( unit)
    buyback = {}
    buyback.items = {}
    buyback.weapons = {}
    buyback.augments = {}
end

local function shutUpShop( script, sim, abilityOwner )
    script:waitFor( mission_util.UI_SHOP_CLOSED )
	local level = include( "sim/level" )
    local unit = abilityOwner
	local player = unit:getPlayerOwner()
	local MNF = unit:getTraits().MNF
	MNF:getTraits().ammo = player:getCredits()
    player:resetCredits()
	player:addCredits(unit.credStore)	
	if not unit:getTraits().wasMeleeAiming then
		local delay = 0.5
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		unit:getTraits().isMeleeAiming = false
		unit:getTraits().wasMeleeAiming = nil
		sim:dispatchEvent( simdefs.EV_UNIT_OVERWATCH_MELEE, { unit = unit, cancel=true})
	end
	
	if #unit.augments == 0 then
		MNF:getTraits().hasSoldAug = true
	end
	
	--if not buyback == {} then
	
		clearBuyback( unit )
	--end
	
	
	sim:getLevelScript():removeHook( abilityOwner.storeHook )
end


		

local function createStoreItems( store, storeUnit, sim, items, weapons, augments )
	
	--local possItems = stockItems
	local sellableItems = {
			unitdefs.tool_templates.item_smokegrenade_xu,
			unitdefs.tool_templates.item_lockdecoder_xu,
			unitdefs.tool_templates.item_portabledrive_xu,
			unitdefs.tool_templates.item_icebreaker_xu,
		}
	local sellableWeapons = {
			unitdefs.tool_templates.item_shocktrap_xu,
			unitdefs.tool_templates.item_emp_pack_xu,
		}
	local sellableAugments = {
		}
	
	local soldItems = storeUnit.items
	local soldWeapons = storeUnit.weapons
	local soldAugments = {}
	local soldAugmentsTest = {}
	

	-- These are the potentially added units
--	local itemsList = util.tdupe( store.itemList )


	
	-- Instantiate actual simunits for the shop items that are unit templates.
	for i, item in ipairs( sellableItems ) do
		local readyItem = simfactory.createUnit( item, sim )
		local exists = array.findIf( soldItems, function( u ) return u:getName() == readyItem:getName() end )
		if not exists then
			--soldItems[i] = simfactory.createUnit( item, sim )
			if storeUnit.firstTime then
				readyItem:getTraits().cooldown = sim:nextRand(0,math.ceil(readyItem:getUnitData().value / 50))
			else
				readyItem:getTraits().cooldown = math.ceil(readyItem:getUnitData().value / 50)
			end
			if readyItem:getTraits().cooldown > 0 then
				readyItem:removeAbility(sim, "carryable")
			end
			
			table.insert (soldItems, readyItem)
		end
	end

	for i, item in ipairs( sellableWeapons ) do
		local readyItem = simfactory.createUnit( item, sim )
		local exists = array.findIf( soldWeapons, function( u ) return u:getName() == readyItem:getName() end )
		if not exists then
			if storeUnit.firstTime then
				readyItem:getTraits().cooldown = sim:nextRand(0,1)
			else
				readyItem:getTraits().cooldown = math.ceil(readyItem:getUnitData().value / 50)
			end
			if readyItem:getTraits().cooldown > 0 then
				readyItem:removeAbility(sim, "carryable")
			end
			table.insert (soldWeapons, readyItem)
		end
	end

	for i, item in ipairs(  soldAugmentsTest ) do
		soldAug = simfactory.createUnit( item, sim )
		local exists = false
		local pc = sim:getPC()
		for i, tstUnit in pairs( pc:getAgents() ) do
			local exists = array.findIf( tstUnit:getChildren(), function( u ) return u:getName() == soldAug:getName() end )
		end
		if exists == false then
			table.insert (soldAugments, soldAug)
		end
	end


	return soldItems, soldWeapons, soldAugments
end




local oldManualHack = abilitydefs.lookupAbility("manualHack")

local oldCanUseAbility = oldManualHack.canUseAbility

local micronanofab = {
	
		name = "Micronanofab",
		
		getName = function( self, sim, abilityOwner )
			return name
		end,
        canUseWhileDragging = true,

		--usesMP = true,

		alwaysShow = true,
		HUDpriority = 4,
		
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_arm_small.png",
		
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return abilityutil.formatToolTip ( "MicroNanofab", "Opens the MicroNanofab store. The player's credits will temporarily be replaced with the MicroNanofab's Ammo." )
		end, 

	canUseAbility = function( self, sim, unit, userUnit )
		if not userUnit then
			return false
		end
		return true
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local target = sim:getUnit(target)			
		local x0,y0 = userUnit:getLocation()
		
		local MNF = unit:getTraits().MNF

	--	userUnit:setInvisible(false)
	--	userUnit:setDisguise(false)
		
		local player = userUnit:getPlayerOwner()
		
		unit.credStore = player:getCredits()
		
		player:resetCredits()
		player:addCredits(MNF:getTraits().ammo)
		
		unit:getTraits().wasMeleeAiming = unit:getTraits().isMeleeAiming
		
		if not unit:getTraits().wasMeleeAiming then
			unit:getTraits().isMeleeAiming = true
			sim:dispatchEvent( simdefs.EV_UNIT_OVERWATCH_MELEE, { unit = unit })
		end
		
		local overload = nil
		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { shopUnit = unit, shopperUnit = userUnit, overload = overload } )
		
		 local script = sim:getLevelScript()
	--	script:waitFor( mission_util.UI_SHOP_CLOSED )
		
		userUnit.storeHook = sim:getLevelScript():addHook( "closedStore", shutUpShop, sim, unit )
		

	end,
	
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
		local abilityOwner = self.abilityOwner
			for i,childAug in ipairs(abilityOwner:getChildren( )) do
				if childAug:getTraits().isMicronanofab then
					unit:getTraits().MNF = childAug
				end
			end
		self.augment = unit
		sim:addTrigger( simdefs.TRG_START_TURN, self )
	end,
        
	onDespawnAbility = function( self, sim, unit )
        self.abilityOwner = nil
		sim:removeTrigger( simdefs.TRG_START_TURN, self )
	end,
	
	onTrigger = function ( self, sim, evType, evData ) 
		if evType == simdefs.TRG_START_TURN and evData:isPC() then
			local abilityOwner = self.abilityOwner
			local unit = abilityOwner
			
				if unit.items == nil then
					unit.buyback = {}
					unit.buyback.items = {}
					unit.buyback.weapons = {}
					unit.buyback.augments = {}
					
					unit.items = {}
					unit.weapons = {}
					unit.augments = {}
					
					unit.firstTime = true
				else
				
					for i, item in ipairs( unit.items ) do
						if item:getTraits().cooldown > 0 then
							item:getTraits().cooldown = item:getTraits().cooldown - 1
						end
						if item:getTraits().cooldown == 0 then
							item:giveAbility("carryable")
						end
					end
					for i, item in ipairs( unit.weapons ) do
						if item:getTraits().cooldown > 0 then
							item:getTraits().cooldown = item:getTraits().cooldown - 1
						end
						if item:getTraits().cooldown == 0 then
							item:giveAbility("carryable")
						end
					end
				
				end
				
				unit.items, unit.weapons, unit.augments = createStoreItems( unit, unit, sim )
				
				unit.firstTime = nil
		end
	end,

}
return micronanofab






