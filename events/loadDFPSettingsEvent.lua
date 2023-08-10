--[[
Originally Part of Production Revamp

Copyright (C) braeven & Achimobil 2022

Author: Achimobil, adjusted with permission by BigFood

Version: 1.1.0.0
Date: 22.08.2022
]]

LoadDFPSettingsEvent = {}
LoadDFPSettingsEvent_mt = Class(LoadDFPSettingsEvent, Event)
InitEventClass(LoadDFPSettingsEvent, "LoadDFPSettingsEvent")

function LoadDFPSettingsEvent.emptyNew()
	local self = Event.new(LoadDFPSettingsEvent_mt)
	return self
end

function LoadDFPSettingsEvent.new(settings)
	DFPSettings:print("LoadDFPSettingsEvent.new")
	local self = LoadDFPSettingsEvent.emptyNew()
	self.settings = settings
	return self
end

function LoadDFPSettingsEvent:readStream(streamId, connection)
	DFPSettings:print("LoadDFPSettingsEvent:readStream")
	if g_server == nil then
		self.settings = {}
		self.settings.MinGreed = streamReadFloat32(streamId)
		self.settings.MaxGreed = streamReadFloat32(streamId)
		self.settings.MinEco = streamReadFloat32(streamId)
		self.settings.MaxEco = streamReadFloat32(streamId)
		self.settings.Discourage = streamReadFloat32(streamId)
		self.settings.ResetNPCs = streamReadBool(streamId)
		
		self:run(connection)
	end
end

function LoadDFPSettingsEvent:writeStream(streamId, connection)

	DFPSettings:print("LoadDFPSettingsEvent:writeStream")
	
	streamWriteFloat32(streamId, self.settings.MinGreed)
	streamWriteFloat32(streamId, self.settings.MaxGreed)
	streamWriteFloat32(streamId, self.settings.MinEco)
	streamWriteFloat32(streamId, self.settings.MaxEco)
	streamWriteFloat32(streamId, self.settings.Discourage)
	streamWriteBool(streamId, self.settings.ResetNPCs)

end

function LoadDFPSettingsEvent:run(connection)
	if g_server ~= nil then
		g_server:broadcastEvent(LoadDFPSettingsEvent.new(DFPSettings.current), false)
		return
	end

	if(self.settings ~= nil) then
		DFPSettings.current = self.settings
	end
end
