--[[
Originally Part of Production Revamp

Copyright (C) braeven & Achimobil 2022

Author: Achimobil, adjusted with permission by BigFood

Version: 1.1.0.0
Date: 22.08.2022
]]

ChangeDFPDecimalSettingsEvent = {}
ChangeDFPDecimalSettingsEvent_mt = Class(ChangeDFPDecimalSettingsEvent, Event);
InitEventClass(ChangeDFPDecimalSettingsEvent, "ChangeDFPDecimalSettingsEvent");

---Create instance of Event class
function ChangeDFPDecimalSettingsEvent.emptyNew()
	local self = Event.new(ChangeDFPDecimalSettingsEvent_mt);
	return self;
end

---Create new instance of event
function ChangeDFPDecimalSettingsEvent.new(settingsId, newValue)
	DFPSettings:print("ChangeDFPDecimalSettingsEvent.new");
	local self = ChangeDFPDecimalSettingsEvent.emptyNew();
	self.settingsId = settingsId;
	self.newValue = newValue;
	return self;
end

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ChangeDFPDecimalSettingsEvent:readStream(streamId, connection)
	DFPSettings:print("ChangeDFPDecimalSettingsEvent.readStream");
	self.settingsId = streamReadString(streamId);
	self.newValue = streamReadFloat32(streamId)
	
	self:run(connection)
end

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ChangeDFPDecimalSettingsEvent:writeStream(streamId, connection)
	DFPSettings:print("ChangeDFPDecimalSettingsEvent.writeStream");
	streamWriteString(streamId, self.settingsId)
	streamWriteFloat32(streamId, self.newValue)
end

---Run action on receiving side
-- @param integer connection connection
function ChangeDFPDecimalSettingsEvent:run(connection)
	DFPSettings:print("ChangeDFPDecimalSettingsEvent.run");
	DFPSettings.current[self.settingsId] = self.newValue;
	
	-- recalculate Price with new value
	g_dynamicFieldPrices:calcPrice()
	
	if g_server ~= nil then
		g_server:broadcastEvent(self, false)
	end
end

