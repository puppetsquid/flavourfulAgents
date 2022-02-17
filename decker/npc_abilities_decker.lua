local simquery = include("sim/simquery")
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local serverdefs = include( "modules/serverdefs" )
local mainframe_common = include("sim/abilities/mainframe_common")

-------------------------------------------------------------------------------
-- These are NPC abilities.

local function shouldNoticeInterests( unit )
    return unit:getBrain() ~= nil and not unit:isKO() and not unit:getTraits().camera_drone
end


local createDaemon = mainframe_common.createDaemon
local createReverseDaemon = mainframe_common.createReverseDaemon
local createCountermeasureInterest = mainframe_common.createCountermeasureInterest

local npc_abilities =
{



--whistleblow = util.extend( createDaemon( STRINGS.DAEMONS.AUTHORITY ) )
whistleblow = util.extend( createDaemon( STRINGS.FLAVORED.ITEMS.AUGMENTS.WHISTLEBLOW ) )
    {
		icon = "gui/icons/daemon_icons/Daemons0003.png",

		REVERSE_DAEMONS = false,
		
		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, 0)
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=false, name = self.name, icon=self.icon, txt = self.activedesc, self.duration } )	
			
			
						
			local mainunit = 0
			
			for _, unit in pairs( sim:getAllUnits() ) do
				if unit:getTraits().mainframe_program == "whistleblow" then
					mainunit = unit
				end
			end
			
			local x0, y0 = mainunit:getLocation()
			local cell = simquery.findNearestEmptyCell( sim, x0, y0, mainunit )
	--		sim:emitSound( { path = simdefs.SOUND_SECURITY_ALERTED, range = 2 }, x0, y0, mainunit )
		--	sim:processReactions(self)		
			sim:getNPC():spawnInterest(x0, y0, simdefs.SENSE_RADIO, simdefs.REASON_ALARMEDSAFE)
			sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.DAEMONS.AUTHORITY.WARNING, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )
			
			local guards = {}
			local player = sim:getPC()
			
			for _, targetUnit in pairs(sim:getAllUnits()) do
				if not (targetUnit:isKO() or targetUnit:isDead())  and targetUnit:getTraits().isGuard then
					table.insert( guards, targetUnit )
				end
			end
			
			local closestUnit = simquery.findClosestUnit( guards, x0, y0, shouldNoticeInterests )
			player:glimpseUnit( sim, closestUnit:getID() )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = closestUnit } )  

			--also raise the alarm
		--	local trackerCount = 1
		--	sim:trackerAdvance( trackerCount )
		
			sim:getNPC():removeAbility(sim, self )
		end,

		standardDaemon = false,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	,
		
		onDespawnAbility = function( self, sim, unit )
		end,
    },

}
return npc_abilities


