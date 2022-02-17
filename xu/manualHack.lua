local abilityutil = include( "sim/abilities/abilityutil" )

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


local function createStoreItems( store, storeUnit, sim )
	local soldItems = {
			unitdefs.tool_templates.item_icebreaker_xu,
			unitdefs.tool_templates.item_hologrenade_xu,
			unitdefs.tool_templates.item_lockdecoder_xu,
			unitdefs.tool_templates.item_portabledrive_xu,
		}
	local soldWeapons = {
		unitdefs.tool_templates.item_shocktrap_xu,
		unitdefs.tool_templates.item_shocktrap_xu,
		unitdefs.tool_templates.item_shocktrap_xu,
	}
	local soldAugments = {
		unitdefs.tool_templates.item_emp_pack_xu,
		unitdefs.tool_templates.item_emp_pack_xu,
		unitdefs.tool_templates.item_emp_pack_xu,
	}

	-- These are the potentially added units
--	local itemsList = util.tdupe( store.itemList )


	
	-- Instantiate actual simunits for the shop items that are unit templates.
	for i, item in ipairs( soldItems ) do
		soldItems[i] = simfactory.createUnit( item, sim )
	end

	for i, item in ipairs( soldWeapons ) do
		soldWeapons[i] = simfactory.createUnit( item, sim )
	end

	for i, item in ipairs( soldAugments ) do
		soldAugments[i] = simfactory.createUnit( item, sim )
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
			return abilityutil.formatToolTip ( "MICRONANOFAB", "DO THE NANOFAB" )
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
		--local x1,y1 = target:getLocation()
  	--	local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 
	--	userUnit:setInvisible(false)
	--	userUnit:setDisguise(false)
		
		
		if unit.items == nil then
		unit.buyback = {}
		unit.buyback.items = {}
		unit.buyback.weapons = {}
		unit.buyback.augments = {}
		
			unit.items, unit.weapons, unit.augments = createStoreItems( unit, unit, sim )
			clearBuyback( unit )
		end
		
		local overload = nil
		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { shopUnit = unit, shopperUnit = userUnit, overload = overload } )
		--[==[
		if sim:getParams().difficultyOptions.flav_xu then
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = unit:getID(), facing = newFacing, sound="SpySociety/Actions/use_scanchip", soundFrame=2 } )		
	--		target:processEMP( 1 )
			if target:getTraits().heartMonitor then
				target:processEMP( 1 )
			else
				target:setPlayerOwner(userUnit:getPlayerOwner())	
			end
			self.myTarg = target
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = newFacing } )	
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target, fx = "emp" } )
		else
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), facing = newFacing, sound="SpySociety/Actions/use_scanchip", soundFrame=10 } )
					
			target:processEMP( 1 )
			--target:setPlayerOwner(userUnit:getPlayerOwner())	
			self.myTarg = target
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target, fx = "emp" } )
		end
		
		if unit:getTraits().disposable then
			inventory.trashItem( sim, userUnit, unit )
		else
			inventory.useItem( sim, userUnit, unit )
		end

		unit:useAP( sim )
		]==]--
	end,
	
	onSpawnAbility = function( self, sim, unit )
        self.abilityOwner = unit
		sim:addTrigger( simdefs.TRG_START_TURN, self )
		self.myTarg = nil
	end,
        
	onDespawnAbility = function( self, sim, unit )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        self.abilityOwner = nil
	end,
	
	onTrigger = function( self, sim, evType, evData )
        if self.abilityOwner and evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
            
			if self.myTarg then
			
				target = self.myTarg
				target:setPlayerOwner(sim:getNPC())
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target, fx = "emp" } )
				self.myTarg = nil
			
			end
			
        end
		
				
    end,
}
return micronanofab