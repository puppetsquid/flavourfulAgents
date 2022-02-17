local guiex = include( "guiex" )
local cdefs = include( "client_defs" )

local items_panel = include("hud/items_panel")

local oldDestroy = items_panel.base.destroy

function items_panel.base:destroy()
	if not self.dontDestroy then
		oldDestroy(self)
	end
end

items_panel.loot.destroy = items_panel.base.destroy
items_panel.transfer.destroy = items_panel.base.destroy
items_panel.pickup.destroy = items_panel.base.destroy

local oldRefresh = items_panel.base.refresh

function items_panel.base:refresh()
	local old_sound = cdefs.SOUND_HUD_GAME_POPDOWN
--	if self._unit:getSim():getParams().difficultyOptions.flav_noAutoClose then
		cdefs.SOUND_HUD_GAME_POPDOWN = ""
		self.dontDestroy = true
--	end
	
	oldRefresh(self)
	
	self.dontDestroy = nil
	cdefs.SOUND_HUD_GAME_POPDOWN = old_sound
end

items_panel.loot.refresh = items_panel.base.refresh
items_panel.transfer.refresh = items_panel.base.refresh
items_panel.pickup.refresh = items_panel.base.refresh

local oldRefreshItem = items_panel.loot.refreshItem

function items_panel.loot:refreshItem( widget, i )
	widget._item = nil
	local ok = oldRefreshItem(self, widget, i)
	if widget._item then
		local enabled,reason = true, nil
		
		local sim = widget._item:getSim()
		if widget._item:getTraits().catcherOwned then
			enabled = false
			reason = "Item throwing is one-way" -- util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(item:getTraits().pickupOnly) )
		end
		
		if widget._item:getTraits().vaultLocked then
			enabled = false
			reason = "Drawer locked with " .. widget._item:getTraits().vaultLocked -- util.sformat(STRINGS.UI.TOOLTIPS.PICK_UP_CONDITION_DESC, util.toupper(item:getTraits().pickupOnly) )
		end
		
		if reason then
			widget.binder.btn:setDisabled(not enabled)
			widget.binder.btn:setTooltip(reason)
		end
	end
	return ok
end