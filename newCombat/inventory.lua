--------------------------------------------------------------------------
-- Inventory functions

local inventory = include( "sim/inventory" )

local actualEquip = inventory.equipItem

inventory.equipItem = function( userUnit, item, notAuto )
	local sim = userUnit:getSim()
	if userUnit._modifiers == nil or userUnit:getTraits().isGuard or notAuto or (sim and not sim:getParams().difficultyOptions.flav_unequip) then ---  player can ONLY manually equip things
		actualEquip( userUnit, item )
	end
end

local oldEquip = inventory.autoEquip

inventory.autoEquip = function( unit )
	local sim = unit:getSim()
	if unit._modifiers == nil or not sim:getParams().difficultyOptions.flav_unequip then
		oldEquip(unit)
	end
end