local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local icemelt =
{
	name = STRINGS.ABILITIES.ICEBREAK,
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
    proxy = true,

	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		local headerTxt = string.format( STRINGS.ABILITIES.TOOLTIPS.HACK, util.toupper( targetUnit:getName() ) )
		local bodyTxt = util.sformat( STRINGS.PROGRAMS.PARASITE.HUD_DESC, abilityOwner:getTraits().icebreak )
		return abilityutil.formatToolTip( headerTxt, bodyTxt, simdefs.DEFAULT_COST )
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.ICEBREAK
	end,

    getProfileIcon = function( self, sim, abilityOwner )
        return abilityOwner:getUnitData().profile_icon or self.profile_icon
    end,

	acquireTargets = function( self, targets, game, sim, unit )
		local userUnit = unit:getUnitOwner()
        assert( userUnit, tostring(unit and unit:getName())..", "..tostring(unit:getLocation()) )
		local cell = sim:getCell( userUnit:getLocation() )
        local cells = { cell }
		for dir, exit in pairs(cell.exits) do
            if simquery.isOpenExit( exit ) then
                table.insert( cells, exit.cell )
            end
        end

		local units = {}
		for i, cell in pairs(cells) do
			for _, cellUnit in ipairs( cell.units ) do
				if (cellUnit:getTraits().mainframe_ice or 0) > 0 then
					if cellUnit:getTraits().mainframe_status ~= "off" or (cellUnit:getTraits().mainframe_camera and cellUnit:getTraits().mainframe_booting) then
						if not cellUnit:getTraits().isDrone or not cellUnit:isKO() then
							table.insert( units, cellUnit )
						end
					end

				end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,
		
	canUseAbility = function( self, sim, unit, unit2, targetUnitID )

		-- Must have a user owner.
		local userUnit = unit:getUnitOwner()
		if not userUnit then
			return false
		end
		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end
		if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end		
        if (unit:getTraits().icebreak or 0) <= 0 then
            return false
        end
		
		local targetUnit = sim:getUnit( targetUnitID )
		if targetUnit and targetUnit:getTraits().parasite then
			return false, STRINGS.PROGRAMS.PARASITE.ALREADY_HOSTED
		end
		
        return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local userUnit = unit:getUnitOwner()
		local targetUnit = sim:getUnit(target)			
			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = targetUnit:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 

		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = newFacing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			
		
		self.abilityOwner = unit
		self.targetUnit = targetUnit
		self.turns = unit:getTraits().duration

		
		local iceCount = unit:getTraits().icebreak
		--mainframe.breakIce( sim, targetUnit, math.min( targetUnit:getTraits().mainframe_ice, iceCount ) )
		mainframe.breakIce( sim, targetUnit, math.min( targetUnit:getTraits().mainframe_ice, 0 ) )

	--	if userUnit:isValid() then
	--		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
	--	end
	
		if not targetUnit:getTraits().parasite then
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_HOST_PARASITE.path )
			targetUnit:getTraits().parasite = true 
			if self.parasiteV2 then
				targetUnit:getTraits().parasiteV2 = true 
			end
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_parasite_installed")
			table.insert(self.parasite_hosts,targetUnit:getID())
        end
		
		unit:getTraits().disposable = nil
		inventory.useItem( sim, userUnit, unit )
		inventory.giveItem( userUnit, targetUnit, unit )
		unit:getTraits().installed = true
		unit:getTraits().augment = true
	end,
	
	onSpawnAbility = function( self, sim )
		sim:addTrigger( simdefs.TRG_START_TURN, self )	
		self.parasite_hosts = {}		
	end, 

    onDespawnAbility = function( self, sim )
    		-- overide despawn for parasite
    end,

	onTrigger = function( self, sim, evType, evData )
		if evType == simdefs.TRG_START_TURN and evData:isPC() then
			local mainframe = include( "sim/mainframe" )
			local parasiteCount = 0
			local unit = self.abilityOwner
            local hosts = util.tdupe(self.parasite_hosts)
            for i, hostID in ipairs(hosts) do
                local hostUnit = sim:getUnit( hostID )
                if hostUnit and hostUnit:getTraits().parasite and hostUnit:getTraits().mainframe_ice and hostUnit:getTraits().mainframe_ice > 0 then
					mainframe.breakIce( sim, hostUnit, unit:getTraits().icebreak )
					parasiteCount = parasiteCount + 1
                end
            end
			if parasiteCount > 0 then
				sim:dispatchEvent( simdefs.EV_MAINFRAME_PARASITE )
			end
		end
	end,
}

return icemelt