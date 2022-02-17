local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local unitdefs = include( "sim/unitdefs" )
local simfactory = include( "sim/simfactory" )
local inventory = include("sim/inventory")


local prism_handshake =
{
	name = STRINGS.ABILITIES.MANUAL_SHUTDOWN,
	profile_icon = "gui/icons/Flavour/icon-action_handshake_small.png",
	usesAction = true,
	--proxy = true,
	createToolTip = function( self,sim, abilityOwner, abilityUser, targetUnitID )
		local targetUnit = sim:getUnit( targetUnitID )
		return util.sformat( STRINGS.ABILITIES.MANUAL_SHUTDOWN_DESC, util.toupper( targetUnit:getName() ),1)
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.MANUAL_SHUTDOWN
	end,

	--[==[
    isTarget = function( self, sim, userUnit, targetUnit )
				if targetUnit == nil or targetUnit:isGhost() then
					return false
				end

				if not simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) then
					return false
				end
				
				if targetUnit:getTraits().isAgent ~= true then
					return false
				end
				
				if not targetUnit:getTraits().canKO then
					return false
				end
				
				if targetUnit:getTraits().isDrone then 
					return false
				end 
				
				if targetUnit:getTraits().tagged and targetUnit:getTraits().alreadyShook then
					return false
				end
        return true
    end, ]==]
	
	isTarget = function( self, sim, userUnit, targetUnit )
		if simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) and targetUnit:getTraits().isAgent and not targetUnit:getTraits().isDrone and not targetUnit:getTraits().alreadyShook then
			return true
		end
				
        return false
    end,


	acquireTargets = function( self, targets, game, sim, unit )
			-- Check adjacent tiles
			local targetUnits = {}
			local cell = sim:getCell( unit:getLocation() )
			--check for pinned guards
			for i,cellUnit in ipairs(cell.units) do
				if self:isTarget( sim, unit, cellUnit ) then
					table.insert( targetUnits,cellUnit )
				end
			end
            for i = 1, #simdefs.OFFSET_NEIGHBOURS, 2 do
    			local dx, dy = simdefs.OFFSET_NEIGHBOURS[i], simdefs.OFFSET_NEIGHBOURS[i+1]
                local targetCell = sim:getCell( cell.x + dx, cell.y + dy )
                if simquery.isConnected( sim, cell, targetCell ) then
					for _,cellUnit in ipairs( targetCell.units ) do
						if self:isTarget( sim, unit, cellUnit ) then
							table.insert( targetUnits,cellUnit )
						end
					end
				end
			end

			return targets.unitTarget( game, targetUnits, self, unit, unit )
		end,
		
	canUseAbility = function( self, sim, unit, userUnit )
		-- has a target in range
		local cell = sim:getCell( userUnit:getLocation() )
		local count = 0
		for dir, exit in pairs(cell.exits) do
			local unit = array.findIf( exit.cell.units, function( u ) return self:isTarget( sim, userUnit, u ) end )
			if unit then
				count = count + 1
			end					
		end

		if unit:getAP() < 1 then 
			return false, STRINGS.UI.REASON.ATTACK_USED
		end 

		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end

		if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end	

		if count == 0 then
			return false, STRINGS.UI.REASON.NO_ICE
		end

		return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, targetUnit )
		local mainframe = include( "sim/mainframe" )
		local targetUnit = sim:getUnit(targetUnit)			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = targetUnit:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 
	--	userUnit:setInvisible(false)
	--	userUnit:setDisguise(false)  -- can always be used
		sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = userUnit:getID(), facing = newFacing } )		
		
		local params = {color ={{symbol="inner_line",r=0,g=1,b=1,a=0.75},{symbol="wall_digital",r=0,g=1,b=1,a=0.75},{symbol="boxy_tail",r=0,g=1,b=1,a=0.75},{symbol="boxy",r=0,g=1,b=1,a=0.75}} }
		sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = targetUnit, kanim = "fx/deamon_ko", symbol = "effect", anim="break", above=true, params=params} )
		sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, targetUnit )
		
		local delay = 0.65
		sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)
		
		local intelList = util.weighted_list({
		--	{ "NOTHING", 5 },  
		--	{ "item_prismGPS", 5 },  -- Tags NPCs it's applied to
			{ "item_prismDirt", 4 },  --  Tradable for cred
			{ "item_prismDirt_med", 5 },  --  Tradable for cred
			{ "item_prismDirt_low", 6 },  --  Tradable for cred
			{ "item_prismPWR", 10 }, -- Gain +2 PWR at consoles
		})
		local intelResult = intelList:getChoice( sim:nextRand(1, intelList:getTotalWeight()))
		
		if not targetUnit:getTraits().alreadyShook then  -- this 'finds' credits/pwr on first use only
			if targetUnit:getTraits().vip then
				local unitDef = unitdefs.lookupTemplate( "item_prismDirt_VIP" ) 
				local credUnit = simfactory.createUnit( unitDef, sim )
				sim:spawnUnit( credUnit )
	            targetUnit:addChild( credUnit )
				if targetUnit:getTraits().PWROnHand then
					targetUnit:getTraits().PWROnHand = targetUnit:getTraits().PWROnHand + 2
				else
					targetUnit:getTraits().PWROnHand = 2
				end
				sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { targetUnit = targetUnit, unit = userUnit } )
			else
				if intelResult ~= "NOTHING" then
					local unitDef = unitdefs.lookupTemplate( intelResult ) 
					local credUnit = simfactory.createUnit( unitDef, sim )
					sim:spawnUnit( credUnit )
					targetUnit:addChild( credUnit )
					sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { targetUnit = targetUnit, unit = userUnit } )
				end
			end
			targetUnit:getTraits().alreadyShook = true
		end
		
		unit:useAP( sim )
		
		sim:processReactions( userUnit )
		sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = newFacing } )	
	end,
}
return prism_handshake