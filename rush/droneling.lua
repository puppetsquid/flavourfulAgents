











onTrigger = function( self, sim, evType, evData )
	local droneling = self.abilityOwner
	local imprintTarg = droneling:getTraits().imprintTarg
	
	if droneling and imprintTarg and not droneling:isKO() then
		if evType == simdefs.TRG_UNIT_WARP and evData.unit == imprintTarg and imprintTarg:getPlayerOwner() and imprintTarg:getTraits().movePath and evData.to_cell and evData.from_cell then
			local from_cell = evData.from_cell
			if sim:canUnitSee( droneling, from_cell.x, from_cell.y )
				droneling:getTraits().imprintCell = from_cell
			end
			
			if droneling:getTraits().imprintCell and ( imprintTarg:getTraits().movePath and #imprintTarg:getTraits().movePath == 0 ) then
			local targCell = droneling:getTraits().imprintCell
			-- this would make the drone move at the same time as the agent
			-- may cause some weird anim bugs 
			--[==[
				local MAX_PATH = 15
				local startcell = sim:getCell( droneling:getLocation() )
				local endcell = targCell
				local moveTable, pathCost = simquery.findPath( sim, droneling, startcell, endcell, math.max( MAX_PATH, droneling:getMP() ) )
				sim:moveUnit( droneling, moveTable ) 
			]==]
			
			-- This just adds an interest to the drone whever it last saw the imprintTarg
			-- IDK if this functions well gameplay wise
				if droneling:getBrain() ~= nil  then
					droneling:getBrain():getSenses():addInterest( targCell.x, targCell.y, simdefs.SENSE_SIGHT, simdefs.REASON_SCANNED, imprintTarg)
				end
			end
		end
	end
end
	
	
	
	
	
	
