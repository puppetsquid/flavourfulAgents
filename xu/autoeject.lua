local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local function getAug(unit)
	local augments = unit:getAugments()
	local augmentNum = math.max(2,#augments)
	local augment = augments[augmentNum]
	local framework = augments[1]
	return augment, framework
end

local function removeAugment( sim, unit, item )
	local x1, y1 = unit:getLocation()
	local y1 = y1 - 0.75 
	local x1 = x1 - 0.75

	if item:getTraits().equipped then
		unequipItem( unit, item )
	end

	if item:getTraits().installed  then
		if item:getTraits().addAbilities then			
			unit:removeAbility(sim, item:getTraits().addAbilities)
		end	
		if item:getTraits().addTrait then
			for i,trait in ipairs(item:getTraits().addTrait)do
				unit:getTraits()[trait[1]] = nil
			end
		end
		if item:getTraits().modTrait then
			for i,trait in ipairs(item:getTraits().modTrait)do
				unit:getTraits()[trait[1]] = unit:getTraits()[trait[1]] - trait[2]
			end
		end	
		if item:getTraits().modSkill then
			local skill = unit:getSkills()[item:getTraits().modSkill]
			if skill then
				while skill._currentLevel > 1 do
					skill:levelDown( sim, unit )
				end
			end
			if item:getTraits().modSkillLock then
				for i,skill in ipairs(item:getTraits().modSkillLock) do
					unit:getTraits().skillLock[skill] = false
				end
			end				
		end
	end

	if item:getTraits().drop_dropdisguise then
		unit:setDisguise(false)
	end

	unit:removeChild( item )
	item:getTraits().installed = false
	unit:addChild( item )
end

function getAugmentCountAndNum( sim, unit, augment )
	local count = 0
	local augmentnum = 0
	for _, childUnit in ipairs(unit:getChildren()) do
		if childUnit:hasAbility( "carryable" ) and childUnit:getTraits().augment and childUnit:getTraits().installed then
			if sim:isVersion("0.17.14") or not childUnit:getTraits().ingnoreAugmentCount17_13 then
				count = count + 1
			end
			if childUnit == augment then
				augmentnum = count
			end
		end
	end
	return count, augmentnum
end



local autoeject = 
	{
		name = STRINGS.FLAVORED.UI.SHARP_EJECT,
        canUseWhileDragging = true,

	--	hotkey = "abilitySprint",



		usesMP = true,

		alwaysShow = true,
		HUDpriority = 4,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_augment.png",

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			local augment = getAug(abilityUser)
				if augment then
					return abilityutil.overwatch_tooltip( hud, self, sim, abilityOwner, util.sformat(STRINGS.FLAVORED.UI.SHARP_EJECT_TT, augment:getUnitData().name) )
				else
					return abilityutil.overwatch_tooltip( hud, self, sim, abilityOwner, STRINGS.FLAVORED.UI.SHARP_EJECT_PLACEHOLDER )
				end
		end,
		
		getProfileIcon =  function( self, sim, unit )
	--		if unit:getTraits().isMeleeAiming then
	--			return "gui/icons/action_icons/Action_icon_Small/icon-action_augment.png"
	--		else
				local augment, framework = getAug(unit)
				if augment then
					return augment:getUnitData().profile_icon
				else
					return framework:getUnitData().profile_icon
				end
	--		end
		end,

		--profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_sneak_small.png",

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.SPRINT_TOGGLE
		end,

		canUseAbility = function( self, sim, unit )
			if unit:getTraits().mp < 1 then
				return false,  STRINGS.FLAVORED.UI.SHARP_EJECT_AP
			end
			
			local augment = getAug(unit)
			if not augment then
				return false, STRINGS.FLAVORED.UI.SHARP_EJECT_NONE 
			end
			
			if unit:getPlayerOwner():getCpus() < 1 then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR, STRINGS.UI.FLY_TXT.NOT_ENOUGH_PWR
			end
			

			return true 
		end,
		
		executeAbility = function( self, sim, unit )
	
			local augment = getAug(unit)
			local x0, y0 = unit:getLocation()
				
			removeAugment( sim, unit, augment )
			sim:dispatchEvent( simdefs.EV_UNIT_INSTALL_AUGMENT, { unit = unit } )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Objects/AugmentInstallMachine", x=x0,y=y0} )
				if unit:isValid() then
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { txt="EJECTED", unit = unit, color=cdefs.AUGMENT_TXT_COLOR })
				end    	
			unit:useMP(1, sim)
			unit:getPlayerOwner():addCPUs( -1, sim, x0,y0)	

		end,
	}

return autoeject