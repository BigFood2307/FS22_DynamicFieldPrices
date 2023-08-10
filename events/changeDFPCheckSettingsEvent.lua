--[[
Originally Part of Production Revamp

Copyright (C) braeven & Achimobil 2022

Author: Achimobil, adjusted with permission by BigFood

Version: 1.1.0.0
Date: 22.08.2022
]]

ChangeDFPCheckSettingsEvent = {}
ChangeDFPCheckSettingsEvent_mt = Class(ChangeDFPCheckSettingsEvent, Event);
InitEventClass(ChangeDFPCheckSettingsEvent, "ChangeDFPCheckSettingsEvent");

---Create instance of Event class
function ChangeDFPCheckSettingsEvent.emptyNew()
	local self = Event.new(ChangeDFPCheckSettingsEvent_mt);
	return self;
end

---Create new instance of event
function ChangeDFPCheckSettingsEvent.new(settingsId, state)
	DFPSettings:print("ChangeDFPCheckSettingsEvent.new");
	local self = ChangeDFPCheckSettingsEvent.emptyNew();
	self.settingsId = settingsId;
	self.state = state;
	return self;
end

---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ChangeDFPCheckSettingsEvent:readStream(streamId, connection)
	DFPSettings:print("ChangeDFPCheckSettingsEvent.readStream");
	self.settingsId = streamReadString(streamId);
	self.state = streamReadBool(streamId)

	self:run(connection)
end

---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ChangeDFPCheckSettingsEvent:writeStream(streamId, connection)
	DFPSettings:print("ChangeDFPCheckSettingsEvent.writeStream");
	streamWriteString(streamId, self.settingsId)
	streamWriteBool(streamId, self.state)
end

---Run action on receiving side
-- @param integer connection connection
function ChangeDFPCheckSettingsEvent:run(connection)
	DFPSettings:print("ChangeDFPCheckSettingsEvent.run");
	DFPSettings.current[self.settingsId] = self.state;

	if g_server ~= nil then
			g_server:broadcastEvent(self, false)
	end
end