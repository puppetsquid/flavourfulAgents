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


local function shutUpShop( script, sim, abilityOwner, mainframenano )
    script:waitFor( mission_util.UI_SHOP_CLOSED )
	local level = include( "sim/level" )
    local unit = abilityOwner
	local player = unit:getPlayerOwner()
	
	local augments = mainframenano:getAugments()
	inventory.trashItem( sim, mainframenano, augments[1] )
	
	--sim:dispatchEvent( simdefs.EV_UNIT_TINKER_END, { unit = abilityOwner } ) 
	sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = unit:getID(), facing = unit:getFacing() } )	
	
	sim:getLevelScript():removeHook( abilityOwner.storeHook )
end


local oldManualHack = abilitydefs.lookupAbility("manualHack")

local oldCanUseAbility = oldManualHack.canUseAbility

local hacknanofab = {
	
		name = "hacknanofab",
		
		 proxy = true,
		
		getName = function( self, sim, abilityOwner )
			return "use Nanofab"
		end,
        canUseWhileDragging = false,

		--usesMP = true,

		alwaysShow = true,
		HUDpriority = 4,
		
		--profile_icon = "gui/items/icon-action_hack-console.png",
			profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return abilityutil.formatToolTip ( "Remote Access", "Opens this nanofab's store with reduced item costs. Purchased items must be manually collected." )
		end, 

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
            -- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
            if abilityOwner ~= unit and abilityOwner:getUnitOwner() ~= unit then
                return false
            end

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	

			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
			
			if targetUnit and not targetUnit:getTraits().mainframe_status == "active" then 
				return false
			end
			
		--	if targetUnit and unit:getPlayerOwner() ~= targetUnit:getPlayerOwner() then 
		--		return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
		--	end
			
			
			
			local cell = sim:getCell( abilityOwner:getLocation() )
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						local dir = cellUnit:getFacing()
						local x0, y0 = cellUnit:getLocation()
						local x1, y1 = simquery.getDeltaFromDirection(dir)
						local consoleFront = sim:getCell( x0 + x1, y0 + y1 )
											
						if sim:getCell(abilityOwner:getLocation()) ~= consoleFront then
							return false, "must be at front of console"
						end
						
						if cellUnit:getPlayerOwner() ~= abilityOwner:getPlayerOwner() then
								return false, "Must own console to use this ability."
						end
						
					end
				end
			end
			

			return abilityutil.checkRequirements( abilityOwner, unit )
		end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local target = sim:getUnit(target)			
		local x0,y0 = userUnit:getLocation()
		
		userUnit:setInvisible(false)
		userUnit:setDisguise(false)
		
		---- anim
		
		local myConsoleDir = userUnit:getFacing()
			
			local cell = sim:getCell( unit:getLocation() )
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						if simquery.canUnitReach( sim, unit, exit.cell.x, exit.cell.y ) then
						--	self.myConsole = cellUnit
							cellUnit:getTraits().shutDownPlz = true
							myConsoleDir = cellUnit:getFacing()
						end
					end
				end
			end
		local newFacing = simquery.getReverseDirection(myConsoleDir)
		--sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), useTinkerMonst3r=true, facing = newFacing, sound = "SpySociety/Objects/turret/gunturret_arm" , soundFrame = 16 } )	
		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), useTinker=true, facing = newFacing, sound = simdefs.SOUNDPATH_SAFE_OPEN, soundFrame = 1 } )
		--local delay = 0.1
		--sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 60*delay)		
		
		
		------ openshop
		
		local mainframenano = target
			
		
		local overload = nil

		mainframenano:getTraits().inventoryMaxSize = 8
		mainframenano:getTraits().noOpenAnim = true
		
		local augment = inventory.giftUnit( sim, mainframenano, "augment_monst3r", false )
		mainframenano:doAugmentUpgrade(augment)
		
		mainframenano:giveAbility("stealCredits")
		
		local mainframe = include( "sim/mainframe" )
	--	mainframe.breakIce( sim, mainframenano, mainframenano:getTraits().mainframe_ice )
		
		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { shopUnit = mainframenano, shopperUnit = mainframenano, overload = overload } )
		
		 local script = sim:getLevelScript()
	--	script:waitFor( mission_util.UI_SHOP_CLOSED )
		
		userUnit.storeHook = sim:getLevelScript():addHook( "closedStore", shutUpShop, sim, unit, mainframenano )
		

	end,
	
	acquireTargets = function( self, targets, game, sim, abilityOwner, abilityUser )
			local exits = {}
			local fromCell = sim:getCell( abilityUser:getLocation() )
			local cellsWithDoors = {}
			local player = abilityOwner:getPlayerOwner()
			local oneConsole = nil
			local cell = sim:getCell( abilityOwner:getLocation() )
			
			local nearbyConsoles = {}
			for dir, exit in pairs(cell.exits) do
				for _, cellUnit in ipairs( exit.cell.units ) do
					if cellUnit:getTraits().mainframe_console or cellUnit:getTraits().open_secure_boxes then
						if simquery.canUnitReach( sim, abilityUser, exit.cell.x, exit.cell.y ) and cellUnit:getTraits().mainframe_status ~= "off" then
							table.insert( nearbyConsoles, cellUnit )
							oneConsole = true
							self.myConsoleDir = cellUnit:getFacing()
							self.myConsole = cellUnit
						end
					end
				end
			end

			
			local units = {}
			------todo- if abilityOwner next to gettraits mainframe_console or open_secure_boxes or generateAugment then
			if oneConsole then
				
				for i,nanunit in pairs(sim:getAllUnits())do
					if nanunit:getTraits() and nanunit:getTraits().storeType and (nanunit:getTraits().storeType=="standard" or nanunit:getTraits().storeType=="large") 
				--	and player:hasSeen(nanunit) 
						then
						table.insert( units, nanunit )
					end
				end
			end
			return targets.unitTarget( game, units, self, abilityOwner, abilityUser )
		end,
	


}
return hacknanofab






