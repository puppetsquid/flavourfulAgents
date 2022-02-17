local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local speechdefs = include("sim/speechdefs")
local mathutil = include( "modules/mathutil" )
local inventory = include("sim/inventory")

local oldMelee = include("sim/abilities/melee")

local oldCanUseAbility = oldMelee.canUseAbility
local oldExecuteAbility = oldMelee.executeAbility

local melee = util.extend(oldMelee) {
	canUseAbility = function( self, sim, unit, userUnit, targetID )
		local tazerUnit = simquery.getEquippedMelee( unit )
		local targetUnit = sim:getUnit(targetID)
		if tazerUnit == nil or tazerUnit:getTraits().nonStandardMelee then
			return false
		elseif (tazerUnit:getTraits().baseDamage and tazerUnit:getTraits().baseDamage > 0) or (tazerUnit:getTraits().damage and tazerUnit:getTraits().damage > 0)  then 
			--local abilname = abilityDef.pacifist
			if userUnit:getTraits().pacifist then
				local unitNums = 0
				for i, u in pairs( userUnit:getPlayerOwner():getUnits() ) do -- if agent is threatened then morals are loose
					if simquery.isUnitUnderOverwatch(u) then
						unitNums = unitNums + 1					
					end
				end
				if  unitNums == 0 then
					return false, "Inhibited by Pacifism"
				end
			end
		if userUnit:getTraits().noKill and not (tazerUnit:getTraits().canSleep or (tazerUnit:getTraits().melee and not tazerUnit:getTraits().lethalMelee)) then
			return false, "Agent Won't Kill"
		end
		elseif unit:countAugments( "augment_kpc_pistons" ) > 0 and unit:getMP() < 3 then 
			if tazerUnit:getTraits().lethalMelee then
				--return false, STRINGS.UI.COMBAT_PANEL_KILL, STRINGS.ITEMSEXTEND.UI.COMBAT_PANEL_NO_ATTACK
			else
				return false, STRINGS.UI.COMBAT_PANEL_FAIL_KO, STRINGS.ITEMSEXTEND.UI.COMBAT_PANEL_NO_ATTACK or "3 AP REQUIRED"
			end
		end
		
		if tazerUnit:getTraits().lethalMelee then
			unit:getTraits().ignorePinning = false
			
			if unit:getTraits().pacifist then
				return false, "Inhibited by Pacifism"
			end

		end
		
		local meleeFromFront = sim:getParams().difficultyOptions.meleeFromFront
		if unit:getTraits().alwaysFromFront then
			sim:getParams().difficultyOptions.meleeFromFront = true
		end
		
		local ok, res, res2 = oldCanUseAbility( self, sim, unit, userUnit, targetID )
		unit:getTraits().ignorePinning = false
		sim:getParams().difficultyOptions.meleeFromFront = meleeFromFront
		
		if res == STRINGS.UI.COMBAT_PANEL_FAIL_KO and tazerUnit:getTraits().lethalMelee then
			res = STRINGS.UI.COMBAT_PANEL_KILL
		end
		
		return ok, res, res2
	end,

	executeAbility = function( self, sim, unit, userUnit, target )
		local targetUnit = sim:getUnit(target)
		local tazer = simquery.getEquippedMelee(unit)
		local meleeDamage = simquery.calculateMeleeDamage(sim, tazer, targetUnit)
		local lethal = tazer:getTraits().lethalMelee
		local x0,y0 = unit:getLocation()
						
		if meleeDamage > 0 and not tazer:getTraits().lethalMelee then
			if tazer:getTraits().tagsTarget then
				targetUnit:getTraits().tagged = true
			end
		end
		
		local oldKillUnit = targetUnit.killUnit
		targetUnit.killUnit = function()
			targetUnit.killUnit = oldKillUnit
			local dmgt =
			{
				damage = tazer:getTraits().baseDamage or 1,
				ko = false,
				noTargetAlert = false,
			}
			sim:hitUnit( unit, targetUnit, dmgt )
		end
		oldExecuteAbility( self, sim, unit, userUnit, target )
		targetUnit.killUnit = oldKillUnit
		
		if unit:countAugments( "augment_kpc_pistons" ) > 0 and not lethal then
			local BRAWLING_DRAWBACK = -3
			if unit:getPlayerOwner() ~= sim:getCurrentPlayer() then
				if not unit:getTraits().floatTxtQue then
					unit:getTraits().floatTxtQue = {}
				end
				table.insert(unit:getTraits().floatTxtQue,{txt=util.sformat(STRINGS.ITEMSEXTEND.UI.BRAWLING_DRAWBACK or "PNEUMATIC STRIKE",BRAWLING_DRAWBACK),color={r=216/255,g=37/255,b=19/255,a=1}})
			else
				sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit } )
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=util.sformat(STRINGS.ITEMSEXTEND.UI.BRAWLING_DRAWBACK or "PNEUMATIC STRIKE",BRAWLING_DRAWBACK),x=x0,y=y0,color={r=216/255,g=37/255,b=19/255,a=1}} ) 
			end
			unit:addMP( BRAWLING_DRAWBACK )
		end
		
		if tazer:getTraits().soundRange then
			local soundRange = { path = nil, range = tazer:getTraits().soundRange }
			sim:emitSound( soundRange, x0, y0, unit )
		end
	end,
}

return melee