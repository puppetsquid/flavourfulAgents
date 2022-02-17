local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local oldEquippable = include( "sim/abilities/equippable" )

local equippable = util.extend(oldEquippable) {
		createToolTip = function( self, sim, unit )
		local userUnit = unit:getUnitOwner()
		
			if unit:getTraits().equipped and sim:getParams().difficultyOptions.flav_unequip then
				self.usesMP = false
				return abilityutil.formatToolTip( "UNEQUIP",  "Unequip this item", 0)
			elseif userUnit and not unit:getTraits().equipped and sim:getParams().difficultyOptions.flav_equipCosts then
				local apCost = 2 - (math.max (userUnit:getSkillLevel("anarchy") - 2, 0 )*0.5)
				self.usesMP = true
				return abilityutil.formatToolTip( "EQUIP",  "Costs " .. apCost .. "AP", 0)
			end
			self.usesMP = false
			return abilityutil.formatToolTip( STRINGS.ABILITIES.EQUIPPABLE,  STRINGS.ABILITIES.EQUIPPABLE_DESC, 0)
		end,
		
		usesMP = true,
		pacifist = true,
		
		getAPCost = function (self, sim, abilityOwner, abilityUser )
			local userUnit = abilityOwner:getUnitOwner()
			local apCost = 2 - math.max((math.max (userUnit:getSkillLevel("anarchy") - 1, 0 )*0.5), 0 )
			return apCost
		end,

		getName = function( self, sim, abilityOwner, abilityUser )
			if abilityOwner:getTraits().equipped and sim:getParams().difficultyOptions.flav_equipCosts then
				self.usesMP = false
				return "Unequip Item"
			else
				self.usesMP = true
				return self.name
			end
			self.usesMP = false
			return self.name
		end,
		
		canUseAbility = function( self, sim, abilityOwner, abilityUser )
			if abilityOwner:getUnitOwner() == nil then
				return false
			end
			local userUnit = abilityOwner:getUnitOwner()
			if abilityOwner:getTraits().equipped and not sim:getParams().difficultyOptions.flav_unequip then
				return false, STRINGS.UI.REASON.ALREADY_EQUIPPED
			end
			local apCost = 2 - (math.max (userUnit:getSkillLevel("anarchy") - 2, 0 )*0.5)
				if abilityUser:getMP() < apCost and sim:getParams().difficultyOptions.flav_equipCosts and not abilityOwner:getTraits().equipped then --
					return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,apCost)
				end
			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit )
			local x1,y1 = userUnit:getLocation()
			local apCost = 2 - (math.max (userUnit:getSkillLevel("anarchy") - 2, 0 )*0.5)
			if unit:getTraits().equipped and sim:getParams().difficultyOptions.flav_unequip then
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/HUD/gameplay/HUD_ItemStorage_TakeOut", x=x1,y=y1} )
				inventory.unequipItem( userUnit, unit )
				unit:getSim():triggerEvent( "flavUnequip", { x = x1, y = y1, itemOwner = userUnit, itemUnit = unit }  )
				--sim:dispatchEvent( simdefs.EV_UNIT_PICKUP, { unitID = userUnit:getID() } )	
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )	
			else
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/equip", x=x1,y=y1} )
				unit:getSim():triggerEvent( "flavEquip", { x = x1, y = y1, itemOwner = userUnit, itemUnit = unit }  )
				unit:getTraits().wasNotEquipped = nil
				inventory.equipItem( userUnit, unit, true )
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )	
				if sim:getParams().difficultyOptions.flav_equipCosts then
					userUnit:useMP(apCost, sim)
				end
			end
		end,
	}
return equippable