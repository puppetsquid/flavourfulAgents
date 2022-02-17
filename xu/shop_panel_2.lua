----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local guiex = include( "guiex" )
local array = include( "modules/array" )
local mui = include( "mui/mui")
local serverdefs = include( "modules/serverdefs" )
local simquery = include( "sim/simquery" )
local modalDialog = include( "states/state-modal-dialog" )
local items_panel = include( "hud/items_panel" )
local inventory = include( "sim/inventory" )
local strings = include( "strings" )
local simdefs = include( "sim/simdefs" )
local level = include( "sim/level" )

--------------------------------------------------------------------
-- In-game item management.  The item panel shows items that can be
-- placed in an agent's inventory, and triggers the appropriate pickup
-- simactions.

local function getOverload(unit)
	
	return math.max(unit:getInventoryCount() - unit:getTraits().inventoryMaxSize,0)
end

local function onClickBuyItem( panel, item, itemType )
	local sim = panel._hud._game.simCore	
	local player = panel._unit
	if not panel._unit._isPlayer then	
	 	player = panel._unit:getPlayerOwner()
	end
	if player ~= sim:getCurrentPlayer() then
		modalDialog.show( STRINGS.UI.TOOLTIP_CANT_PURCHASE )
		return
	end

	if item:getTraits().mainframe_program then

		local maxPrograms = simdefs.MAX_PROGRAMS  + (sim:getParams().agency.extraPrograms or 0)
		if #player:getAbilities() >= maxPrograms then
			modalDialog.show( STRINGS.UI.TOOLTIP_PROGRAMS_FULL )
			return
		end		
		if player:hasMainframeAbility( item:getTraits().mainframe_program ) then
			modalDialog.show( STRINGS.UI.TOOLTIP_ALREADY_OWN )
			return
		end
	elseif panel._unit:getInventoryCount() >= 8 then  
		modalDialog.show( STRINGS.UI.TOOLTIP_INVENTORY_FULL )
		return
	end

	local credits = player:getCredits()
	if credits < (item:getUnitData().value * panel._discount) then 
		modalDialog.show( STRINGS.UI.TOOLTIP_NOT_ENOUGH_CREDIT )
		return
	end

	local itemIndex = nil 

	if panel._buyback then 
		if itemType == "item" then 
			itemIndex = array.find( panel._shopUnit.buyback.items, item )
		elseif itemType == "weapon" then 
			itemIndex = array.find( panel._shopUnit.buyback.weapons, item )
		elseif itemType == "augment" then 
			itemIndex = array.find( panel._shopUnit.buyback.augments, item )
		end
	else 
		if itemType == "item" then 
			itemIndex = array.find( panel._shopUnit.items, item )
		elseif itemType == "weapon" then 
			itemIndex = array.find( panel._shopUnit.weapons, item )
		elseif itemType == "augment" then 
			itemIndex = array.find( panel._shopUnit.augments, item )
		end
	end 

	MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_BUY)

	panel._hud._game:doAction( "buyItem", panel._unit:getID(), panel._shopUnit:getID(), itemIndex, panel._discount, itemType, panel._buyback )
	panel.last_action = panel._buyback and "buyback" or "buy"
	panel:refresh()
end

local function calculateDiscount( unit, tag )
	local discount = 1.00
	local shopperUnit = unit
	if tag == "shop" then
		for _, child in pairs( shopperUnit:getChildren() ) do
			if child:getTraits().shopDiscount then 
				discount = discount - child:getTraits().shopDiscount
			end 
		end  
	end 

	return discount
end 

local function onClickBuyBack( panel )
	panel._buyback = not panel._buyback
	if panel._buyback then 
		panel._discount = 0.50 
		panel._screen.binder.shop_bg.binder.buybackBtn:setText( STRINGS.UI.SHOP_NANOFAB )
	else
		if panel._unit then 
			panel._discount = calculateDiscount(panel._unit, panel._tag)
		else 
			panel._discount = 1.00
		end
		panel._screen.binder.shop_bg.binder.buybackBtn:setText( STRINGS.UI.SHOP_BUYBACK )
	end 

	if panel._shopUnit then 
		if #panel._shopUnit.buyback.items == 0  and #panel._shopUnit.buyback.weapons == 0 and #panel._shopUnit.buyback.augments == 0 then  
			if not panel._buyback then 
				panel._screen.binder.shop_bg.binder.buybackBtn:setVisible( false )
			end 
		end 
	end 

	panel.last_action = "buyback"
	panel:refresh()
end

local function onClickSellItem( panel, item )
	local result = modalDialog.showYesNo( util.sformat(STRINGS.UI.SHOP_SELL_AREYOUSURE, item:getName(), item:getUnitData().value * 0.5 ), STRINGS.UI.SHOP_SELL_AREYOUSURE_TITLE, nil, STRINGS.UI.SHOP_SELL_CONFIRM, nil, true )
	if result == modalDialog.OK then
		local itemIndex = array.find( panel._unit:getChildren(), item )
		MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_SELL)
		panel._hud._game:doAction( "sellItem", panel._unit:getID(), panel._shopUnit:getID(), itemIndex )
		local buybackBtn = panel._screen.binder.shop_bg.binder.buybackBtn
		buybackBtn:setVisible( true )
		buybackBtn.onClick = util.makeDelegate( nil, onClickBuyBack, panel )
		panel.last_action = "sell"
		panel:refresh()
	end 
end


local function onClickTradeItem( panel, item, itemType )
	local sim = panel._hud._game.simCore	
	local player = panel._unit
	if not panel._unit._isPlayer then	
	 	player = panel._unit:getPlayerOwner()
	end
	if player ~= sim:getCurrentPlayer() then
		modalDialog.show( STRINGS.UI.TOOLTIP_CANT_PURCHASE )
		return
	end

	if item:getTraits().mainframe_program then

		local maxPrograms = simdefs.MAX_PROGRAMS  + (sim:getParams().agency.extraPrograms or 0)
		if #player:getAbilities() >= maxPrograms then
			modalDialog.show( STRINGS.UI.TOOLTIP_PROGRAMS_FULL )
			return
		end		
		if player:hasMainframeAbility( item:getTraits().mainframe_program ) then
			modalDialog.show( STRINGS.UI.TOOLTIP_ALREADY_OWN )
			return
		end
	elseif panel._unit:getInventoryCount() >= 8 then  
		modalDialog.show( STRINGS.UI.TOOLTIP_INVENTORY_FULL )
		return
	end

	local itemIndex = nil 

	if panel._buyback then 
		if itemType == "item" then 
			itemIndex = array.find( panel._shopUnit.buyback.items, item )
		elseif itemType == "weapon" then 
			itemIndex = array.find( panel._shopUnit.buyback.weapons, item )
		elseif itemType == "augment" then 
			itemIndex = array.find( panel._shopUnit.buyback.augments, item )
		end
	else 
		if itemType == "item" then 
			itemIndex = array.find( panel._shopUnit.items, item )
		elseif itemType == "weapon" then 
			itemIndex = array.find( panel._shopUnit.weapons, item )
		elseif itemType == "augment" then 
			itemIndex = array.find( panel._shopUnit.augments, item )
		end
	end 

	MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_BUY)

	panel._hud._game:doAction( "tradeItem", panel._unit:getID(), panel._shopUnit:getID(), itemIndex, panel._discount, itemType, panel._buyback )
	panel.last_action = panel._buyback and "buyback" or "buy"
	panel:refresh()
end

									
local function onClickTradeAbility( panel, player, i,ability, unit)
	MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_SELL)
	panel._hud._game:doAction( "tradeAbility", i, unit:getID() )
	panel.last_action = "sell"
	panel:refresh()	
end

local function onClickSellAbility( panel, player, i, item  )
	local result = modalDialog.showYesNo( util.sformat(STRINGS.UI.SHOP_SELL_AREYOUSURE, item.name, item.value * 0.5 ), STRINGS.UI.SHOP_SELL_AREYOUSURE_TITLE, nil, STRINGS.UI.SHOP_SELL_CONFIRM_ABILITY, nil, true )
	if result == modalDialog.OK then
		MOAIFmodDesigner.playSound(cdefs.SOUND_HUD_SELL)
		panel._hud._game:doAction( "sellAbility", i )
		panel.last_action = "sell"
		panel:refresh()
	end
end

local function onClickClose( panel )
	panel:destroy()
end

-----------------------------------------------------------------------
-- Shop UI

local shop_panel = class( items_panel.base )

function shop_panel:init( hud, shopperUnit, shopUnit )
	items_panel.base.init( self, hud, shopperUnit, shopUnit:getTraits().storeType )

	self._tag = "shop"
	self._shopUnit = shopUnit
	self._unit = shopperUnit
	self._discount = calculateDiscount( shopperUnit, "shop" )

    local panelBinder = self._screen.binder
	panelBinder.sell.binder.titleLbl:setText(STRINGS.UI.SHOP_SELL)
	panelBinder.headerTxt:spoolText(STRINGS.UI.SHOP_PRINTER)
    panelBinder.shop_bg.binder.closeBtn.onClick = util.makeDelegate( nil, onClickClose, self )
	panelBinder.shop_bg:setVisible(true)
    panelBinder.shop:setVisible(true)
	panelBinder.inventory_bg:setVisible(false)
	panelBinder.inventory:setVisible(false)
end

function shop_panel:refresh()
    local panelBinder = self._screen.binder
	-- Fill out the dialog options.
	local itemCount = 0
	for i, widget in panelBinder.items.binder:forEach( "item" ) do
		if self:refreshItem( widget, i, "item" ) then
			itemCount = itemCount + 1
		end
	end

	for i, widget in panelBinder.weapons.binder:forEach( "item" ) do 
		if self:refreshItem( widget, i, "weapon" ) then
			itemCount = itemCount + 1
        end
	end

	for i, widget in panelBinder.augments.binder:forEach( "item" ) do 
		if self:refreshItem( widget, i, "augment" ) then
			itemCount = itemCount + 1
        end
	end
 
    -- Fill out the UNIT's inventory.
	local items = {}
	for i,childUnit in ipairs(self._unit:getChildren()) do
		if not childUnit:getTraits().augment or not childUnit:getTraits().installed then
			table.insert(items,childUnit)
		end
	end
	for i, widget in panelBinder.sell.binder:forEach( "item" ) do
		self:refreshUserItem( self._unit, items[i], widget, i )
	end

    self:refreshCredits()

    -- Auto-close
	if (itemCount == 0 and not self._buyback) or not self._unit:canAct() then
		onClickClose( self )
	end
end


function shop_panel:refreshItem( widget, i, itemType )
	local item = nil 
	if self._buyback then 
		if itemType == "item" then 
			item = self._shopUnit.buyback.items[i]
		elseif itemType == "weapon" then 
			item = self._shopUnit.buyback.weapons[i]
		elseif itemType == "augment" then 
			item = self._shopUnit.buyback.augments[i]
		end
	else 
		if itemType == "item" then 
			item = self._shopUnit.items[i]
		elseif itemType == "weapon" then 
			item = self._shopUnit.weapons[i]
		elseif itemType == "augment" then 
			item = self._shopUnit.augments[i]
		end
	end 

	if item == nil then
		widget:setVisible( false )
		return false
	else
        guiex.updateButtonFromItem( self._screen, nil, widget, item, self._unit )
		widget.binder.itemName:setText( util.toupper(item:getName()) )
		widget.binder.cost:setText( util.sformat( STRINGS.FORMATS.CREDITS, math.ceil(item:getUnitData().value * self._discount ) ))
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickBuyItem, self, item, itemType )
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", item:getUnitData().profile_icon, widget.binder.btn.onClick )
		return true
	end
end

function shop_panel:refreshUserItem( unit, item, widget, i )
	if items_panel.base.refreshUserItem( self, unit, item, widget, i ) then
		widget.binder.cost:setVisible(true)
		if item:getUnitData().value then 
			widget.binder.cost:setText( util.sformat( STRINGS.FORMATS.PLUS_CREDS, math.ceil(item:getUnitData().value * 0.5) ))
			widget.binder.btn.onClick = util.makeDelegate( nil, onClickSellItem, self, item )
            widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragSell", item:getUnitData().profile_icon, widget.binder.btn.onClick )
		else
			widget.binder.cost:setText( "" )--STRINGS.UI.SHOP_CANNOT_SELL
			widget.binder.btn:setDisabled( true )
		end
        return true
    end
end

function shop_panel:onDragFinished()
    items_panel.base.onDragFinished( self )
    -- Cleanup drag drop -- this happens whether or not the thing was dropped or not.
    local panel = self._screen.binder.shop
   -- panel:findWidget( "augments.bg" ):setColor( 0, 0, 0, 0.666 )
   -- panel:findWidget( "weapons.bg" ):setColor( 0, 0, 0, 0.666 )
    --panel:findWidget( "items.bg" ):setColor( 0, 0, 0, 0.666 )
    panel.binder.drag.onDragDrop = nil
end


function shop_panel:onDragSell( iconImg, onDragDrop )
    local widget = self._screen:startDragDrop( iconImg, "DragItem" )
    widget.binder.img:setImage( iconImg )

    local panel = self._screen.binder.shop
    --panel:findWidget( "augments.bg" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    --panel:findWidget( "weapons.bg" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    --panel:findWidget( "items.bg" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
    panel.binder.drag.onDragDrop = function() util.coDelegate( onDragDrop ) end
    return true
end

function shop_panel:destroy()
    items_panel.base.destroy( self )
	local game = self._hud._game
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPDOWN )
	game:dispatchScriptEvent( level.EV_CLOSE_SHOP_UI, self._shopUnit:getID() )
end

-----------------------------------------------------------------------
-- Server panel

local server_panel = class( items_panel.base )

function server_panel:init( hud, unit, targetUnit, txt, mini )
	items_panel.base.init( self, hud, unit )
	self.mini = mini

	self._tag = "server"
	self._unit = unit:getPlayerOwner()
	self._targetUnit = targetUnit
	self._shopUnit = targetUnit	
	self._discount = calculateDiscount( self._unit, "server" )

    local panelBinder = self._screen.binder

	if txt then 
		panelBinder.headerTxt:spoolText(string.format(txt, util.toupper(targetUnit:getName())))
	else
		panelBinder.headerTxt:spoolText(string.format(STRINGS.UI.SHOP_SERVER, util.toupper(targetUnit:getName())))
	end

	panelBinder.sell.binder.titleLbl:spoolText(string.format(STRINGS.UI.INCOGNITA_NAME))
	panelBinder.sell.binder.profile:setVisible( true )
	
	panelBinder.sell.binder.eq:setVisible( true )

	panelBinder.sell.binder.agentProfileImg:setVisible( false )
	panelBinder.sell.binder.agentProfileAnim:bindAnim( "portraits/incognita_face" )
	panelBinder.sell.binder.agentProfileAnim:bindBuild( "portraits/incognita_face" )
	
	if not self.mini and not self.research then
		panelBinder.inventory.binder.titleLbl:spoolText(STRINGS.UI.CATSHOP_OPEN[#STRINGS.UI.CATSHOP_OPEN])	
	end

	panelBinder.inventory.binder.profile:setVisible( true ) 
	panelBinder.inventory.binder.eq:setVisible( true )

	panelBinder.inventory.binder.agentProfileAnim:setVisible(false)
	
	panelBinder.inventory.binder.agentProfileImg:setVisible( true )

	panelBinder.inventory.binder.agentProfileImg:setImage(mini and "gui/profile_icons/warez_shopCat_mini.png" or "gui/profile_icons/warez_shopCat.png")	


    panelBinder.inventory_bg.binder.closeBtn.onClick = util.makeDelegate( nil, 
    	function(self, panel)
    		onClickClose(self) 
    	end,
    	self )
	panelBinder.inventory_bg:setVisible(true)
	panelBinder.inventory:setVisible(true)
	panelBinder.shop_bg:setVisible(false)
    panelBinder.shop:setVisible(false)

	FMODMixer:pushMix( "nomusic" )
	MOAIFmodDesigner.playSound("SpySociety/Music/music_shopcat","shopcat")

end


function server_panel:refresh()
    -- Shop programs
	local shopWidget = self._screen:findWidget( "inventory" )
	local itemCount = 0
	for i, widget in shopWidget.binder:forEach( "item" ) do
		if self:refreshItem( widget, i, "item" ) then
			itemCount = itemCount + 1
		end
	end

    -- User programs
    local userWidget = self._screen:findWidget( "sell" )
	for i, widget in userWidget.binder:forEach( "item" ) do 
		self:refreshUserPrograms( self._unit, self._unit:getAbilities()[i], widget, i )
	end

    self:refreshCredits()


    local stringset = self.mini and STRINGS.UI.SMALLCATSHOP_OPEN or STRINGS.UI.CATSHOP_OPEN
    if self.last_action == "buy" then
		stringset = self.mini and STRINGS.UI.SMALLCATSHOP_BUY or STRINGS.UI.CATSHOP_BUY
    elseif self.last_action == "sell" then
    	stringset = self.mini and STRINGS.UI.SMALLCATSHOP_SELL or STRINGS.UI.CATSHOP_SELL
    elseif self.last_action == "buyback" then
    	stringset = self.mini and STRINGS.UI.SMALLCATSHOP_BUYBACK  or STRINGS.UI.CATSHOP_BUYBACK
    end


	self._screen.binder.inventory.binder.titleLbl:spoolText(stringset[math.random(#stringset)])

	if itemCount == 0 then
		onClickClose( self )
	end
end

function server_panel:refreshItem( widget, i, itemType )
	local item = self._targetUnit.items[i]
	if item == nil then
		widget:setVisible( false )
		return false
	else
        guiex.updateButtonFromItem( self._screen, nil, widget, item, self._unit )
		widget.binder.itemName:setText( util.toupper(item:getName()) )
		widget.binder.cost:setText( util.sformat( STRINGS.FORMATS.CREDITS, math.ceil(item:getUnitData().value * self._discount ) ))
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickBuyItem, self, item, itemType )
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", item:getUnitData().profile_icon_100, widget.binder.btn.onClick )
		return true
	end
end


function server_panel:refreshUserPrograms( player, ability, widget, i )

	if ability == nil then
		local sim = self._hud._game.simCore
		local maxPrograms = simdefs.MAX_PROGRAMS  + (sim:getParams().agency.extraPrograms or 0)
		if i <= maxPrograms then
            guiex.updateButtonEmptySlot( widget )
			widget.binder.cost:setVisible(false)
			widget.binder.itemName:setVisible(false)
		else
			widget:setVisible( false )
		end
		return false

	else
        guiex.updateButtonFromAbility( self._screen, widget, ability, nil, player )
		widget.binder.itemName:setVisible(true)
		widget.binder.itemName:setText( util.toupper(ability.name) )

		widget.binder.cost:setVisible(true)
		widget.binder.cost:setText( util.sformat( STRINGS.FORMATS.PLUS_CREDS, ability.value * 0.5) )			
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickSellAbility, self, player, i, ability )

        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromTop", ability.icon, widget.binder.btn.onClick )
		return true
	end
end

function server_panel:destroy()
    items_panel.base.destroy( self )
	local game = self._hud._game
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPDOWN )
	game:dispatchScriptEvent( level.EV_CLOSE_SHOP_UI, self._shopUnit:getID() )
	FMODMixer:popMix( "nomusic" )
	MOAIFmodDesigner.stopSound("shopcat")
end

-----------------------------------------------------------------------
-- research panel

local research_panel = class( items_panel.base )

function research_panel:init( hud, unit, targetUnit, txt, mini, research )
	items_panel.base.init( self, hud, unit )
	self.mini = mini
	self.research = research

	self._tag = "server"

	self._unit = unit:getPlayerOwner()
	self._targetUnit = targetUnit
	self._shopUnit = targetUnit	
	self._discount = calculateDiscount( self._unit, "server" )

    local panelBinder = self._screen.binder

	if txt then 
		panelBinder.headerTxt:spoolText(string.format(txt, util.toupper(targetUnit:getName())))
	else
		panelBinder.headerTxt:spoolText(string.format(STRINGS.UI.SHOP_SERVER, util.toupper(targetUnit:getName())))
	end

	panelBinder.sell.binder.titleLbl:spoolText(string.format(STRINGS.UI.INCOGNITA_NAME))
	panelBinder.sell.binder.profile:setVisible( true )

	panelBinder.sell.binder.agentProfileImg:setVisible( false )
	panelBinder.sell.binder.agentProfileAnim:bindAnim( "portraits/incognita_face" )
	panelBinder.sell.binder.agentProfileAnim:bindBuild( "portraits/incognita_face" )
	
	panelBinder.inventory.binder.profile:setVisible( true )

	panelBinder.inventory.binder.agentProfileAnim:setVisible(false)
	
	panelBinder.inventory.binder.agentProfileImg:setVisible( true )

	panelBinder.inventory.binder.agentProfileImg:setVisible(false)


    panelBinder.inventory_bg.binder.closeBtn.onClick = util.makeDelegate( nil, 
    	function(self, panel)
    		onClickClose(self) 
    	end,
    	self )
	panelBinder.inventory_bg:setVisible(true)
	panelBinder.inventory:setVisible(true)
	panelBinder.shop_bg:setVisible(false)
    panelBinder.shop:setVisible(false)

end


function research_panel:refresh()
    -- Shop programs
	local shopWidget = self._screen:findWidget( "inventory" )
	local itemCount = 0
	for i, widget in shopWidget.binder:forEach( "item" ) do
		if self:refreshItem( widget, i, "item" ) then
			itemCount = itemCount + 1
		end
	end

    -- User programs
    local userWidget = self._screen:findWidget( "sell" )
	for i, widget in userWidget.binder:forEach( "item" ) do 
		self:refreshUserPrograms( self._unit, self._unit:getAbilities()[i], widget, i )
	end

    self:refreshCredits()

	stringset = STRINGS.UI.RESEARCH_OPEN

	self._screen.binder.inventory.binder.titleLbl:spoolText(stringset[math.random(#stringset)])

	if itemCount == 0 then
		onClickClose( self )
	end
end

function research_panel:refreshItem( widget, i, itemType )
	local item = self._targetUnit.items[i]
	if item == nil then
		widget:setVisible( false )
		return false
	else
        guiex.updateButtonFromItem( self._screen, nil, widget, item, self._unit )
		widget.binder.itemName:setText( util.toupper(item:getName()) )
		widget.binder.cost:setVisible(false)
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickTradeItem, self, item, itemType )
        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromBottom", item:getUnitData().profile_icon_100, widget.binder.btn.onClick )
		return true
	end
end


function research_panel:refreshUserPrograms( player, ability, widget, i )

	if ability == nil then
		local sim = self._hud._game.simCore
		local maxPrograms = simdefs.MAX_PROGRAMS  + (sim:getParams().agency.extraPrograms or 0)
		if i <= maxPrograms then
            guiex.updateButtonEmptySlot( widget )
			widget.binder.cost:setVisible(false)
			widget.binder.itemName:setVisible(false)
		else
			widget:setVisible( false )
		end
		return false

	else
        guiex.updateButtonFromAbility( self._screen, widget, ability, nil, player )
		widget.binder.itemName:setVisible(true)
		widget.binder.itemName:setText( util.toupper(ability.name) )

		widget.binder.cost:setVisible(false)
		widget.binder.btn.onClick = util.makeDelegate( nil, onClickTradeAbility, self, player, i, ability, self._shopUnit  )

        widget.binder.btn.onDragStart = util.makeDelegate( self, "onDragFromTop", ability.icon, widget.binder.btn.onClick )
		return true
	end
end

function research_panel:destroy()
    items_panel.base.destroy( self )
	local game = self._hud._game
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_POPDOWN )
	game:dispatchScriptEvent( level.EV_CLOSE_SHOP_UI, self._shopUnit:getID() )
end


return
{
	shop = shop_panel,
	server = server_panel,
	research = research_panel,
}


