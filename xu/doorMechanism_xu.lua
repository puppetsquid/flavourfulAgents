local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local doorMechanism_xu = 
	{
		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip( unit:getName(), unit:getUnitData().desc, simdefs.DEFAULT_COST )
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		
	    getProfileIcon = function( self, sim, abilityOwner )
	        return abilityOwner:getUnitData().profile_icon or self.profile_icon
	    end,

        proxy = true,

		getName = function( self, sim, unit )
			return string.format(STRINGS.ABILITIES.SET_NAME,unit:getName())
		end,
        
		acquireTargets = function( self, targets, game, sim, abilityOwner, abilityUser )
			local exits = {}
			local fromCell = sim:getCell( abilityUser:getLocation() )
			local x0,y0 = fromCell.x, fromCell.y
            local applyFn = abilityOwner:getTraits().applyFn
            if type(applyFn) == "string" then
                applyFn = simquery[ applyFn ] -- Sooo brutal, but due to circular includes, itemdefs cannot directly reference simquery functions
            end

			for dir, exit in pairs( fromCell.exits ) do
				if applyFn( exit ) then
					table.insert( exits, { x = fromCell.x, y = fromCell.y, dir = dir } )
				end
			end

			return targets.exitTarget( game, exits, self, abilityOwner, abilityUser )
		end,

		canUseAbility = function( self, sim, unit, abilityUser, x, y, dir )
			-- Must have a user owner.
			local userUnit = unit:getUnitOwner()
			if not userUnit then
				return false
			end

			if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
			end

			if sim:isVersion("0.17.12") and unit:getTraits().pwrCost and userUnit:getPlayerOwner():getCpus() < unit:getTraits().pwrCost then 
				return false,  STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end	
            if x and y then
                local cell = sim:getCell( x, y )
                if not cell.exits[ dir ] or cell.exits[ dir ].trapped then
                    return false, STRINGS.UI.REASON.ALREADY_TRAPPED
                end
            end
            
			return abilityutil.checkRequirements( unit, userUnit )
		end,
		
		executeAbility = function( self, sim, unit, userUnit, x0, y0, dir )
			local fromCell = sim:getCell( x0, y0 )
            assert( fromCell and dir )

			userUnit:resetAllAiming()
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = userUnit:getID(), facing = dir } )		
		
			local doorDevice = include( string.format( "sim/units/%s", unit:getTraits().doorDevice ))
            doorDevice.applyToDoor( sim, fromCell, dir, unit, userUnit )
            
			local deviceUnit = nil
		
				
			for i,cellUnit in ipairs(fromCell.units) do
				if cellUnit:getTraits().turns == 2 and cellUnit:getPlayerOwner() == userUnit:getPlayerOwner() then
					deviceUnit = cellUnit
				end
			end
			deviceUnit:getTraits().turns = 1
			
			
			inventory.useItem( sim, userUnit, unit )

			sim:emitSound( simdefs.SOUND_PLACE_TRAP, x0, y0, userUnit)	

			sim:processReactions( userUnit )
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = dir } )	
		end,
	}
return doorMechanism_xu