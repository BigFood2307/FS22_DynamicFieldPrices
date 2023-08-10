--[[

This is mostly using Achimobil and bravens Revamp mod Settings script.
Thanks for allowing me to use it!

]]

DFPSettings = {}
DFPSettings.name = g_currentModName
DFPSettings.modDir = g_currentModDirectory

DFPSettings.debug = true

source(g_currentModDirectory .. "events/changeDFPCheckSettingsEvent.lua")
source(g_currentModDirectory .. "events/changeDFPDecimalSettingsEvent.lua")
source(g_currentModDirectory .. "events/loadDFPSettingsEvent.lua")

function DFPSettings.init()
	-- init default settings
	DFPSettings.current = {}
	DFPSettings.current.MinGreed = 0.8
	DFPSettings.current.MaxGreed = 1.2
	DFPSettings.current.MinEco = 0.6
	DFPSettings.current.MaxEco = 1.6	
	DFPSettings.current.Discourage = 0.1
	DFPSettings.current.ResetNPCs = false

	-- listen zum speichern der elemente für das wieder füllen bei änderungen von anderen
	DFPSettings.checkElements = {}
	DFPSettings.textElements = {}

	-- Einstellungen speichern und laden
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, DFPSettings.loadSettingsXML)
	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, DFPSettings.saveSettingsXML)

	-- game settings dialog extension
	InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, DFPSettings.GameSettingsFrame_onFrameOpen)
	InGameMenuGameSettingsFrame.updateGameSettings = Utils.appendedFunction(InGameMenuGameSettingsFrame.updateGameSettings, DFPSettings.GameSettingsFrame_updateGameSettings)

	-- damit beim joinen im MP die einstellungen geholt werden senden wir ein event dass die einstellungen dann an alle schickt
	FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, DFPSettings.loadSettingsFromServer)
end

function DFPSettings.GameSettingsFrame_onFrameOpen(self)
	---Darf nur ein mal aufgerufen werden, beim nächsten mal sind die elemente ja schon da
	if self.dfpGameSettings_initialized == nil then
		local target = DFPSettings.current

		DFPSettings:AddTitle(self, "DFP_Settings_Title")

		DFPSettings:AddGameSettingDecimalNonNegativeElement(self, target, "MinGreed", DFPSettings.current.MinGreed)
		DFPSettings:AddGameSettingDecimalNonNegativeElement(self, target, "MaxGreed", DFPSettings.current.MaxGreed)
		DFPSettings:AddGameSettingDecimalNonNegativeElement(self, target, "MinEco", DFPSettings.current.MinEco)
		DFPSettings:AddGameSettingDecimalNonNegativeElement(self, target, "MaxEco", DFPSettings.current.MaxEco)
		DFPSettings:AddGameSettingDecimalNonNegativeElement(self, target, "Discourage", DFPSettings.current.Discourage)
		DFPSettings:AddGameSettingCheckElement(self, target, "ResetNPCs", DFPSettings.current.ResetNPCs)

		self.dfpGameSettings_initialized = true

		self.boxLayout:invalidateLayout()
	end
end

function DFPSettings:GameSettingsFrame_updateGameSettings()
	-- Settings neu in den dialog laden, könnten von anderem Admin ja geändert sein
	for settingId, element in pairs(DFPSettings.checkElements) do
		element:setIsChecked(DFPSettings.current[settingId])
		element:setDisabled(not self.hasMasterRights)
	end
	for settingId, element in pairs(DFPSettings.textElements) do
		element:setText(tostring(DFPSettings.current[settingId]))
		element:setDisabled(not self.hasMasterRights)
	end
end

function DFPSettings:AddGameSettingCheckElement(self, target, settingId, state)
	-- hier kopieren wir ein checkbox feld element
	local newCheckElement = self.checkTraffic:clone()
	newCheckElement.target = target
	newCheckElement.onClickCallback = DFPSettings.onClickGameSettingCheckbox
	newCheckElement.buttonLRChange = DFPSettings.onClickGameSettingCheckbox
	newCheckElement.id = settingId

	local settingTitle = newCheckElement.elements[4]
	settingTitle:setText(DFPSettings:getText("DFP_" .. settingId .. "_Title"))

	local toolTip = newCheckElement.elements[6]
	toolTip:setText(DFPSettings:getText("DFP_" .. settingId .. "_Tooltip"))

	newCheckElement:setIsChecked(state)

	self.boxLayout:addElement(newCheckElement)

	DFPSettings.checkElements[settingId] = newCheckElement
end

function DFPSettings:AddGameSettingDecimalNonNegativeElement(self, target, settingId, state)

	-- wir kopieren aus dem dialog das 2. GuiElement, das ist die eingabestelle für den savegame namen
	local wrappingElement = self.boxLayout.elements[2]:clone()

	-- hier nutzen wir das input das schon kopiert ist
	local newTextElement = wrappingElement.elements[1]

	newTextElement.target = self
	newTextElement.onEnterPressedCallback = DFPSettings.onTextChangedGameSettingDecimalNonNegativeCallback
	newTextElement.id = settingId
	newTextElement.maxCharacters = 5
	newTextElement:setText(tostring(state))

	local settingTitle = wrappingElement.elements[2]
	settingTitle:setText(DFPSettings:getText("DFP_" .. settingId .. "_Title"))

	local toolTip = wrappingElement.elements[3]
	toolTip:setText(DFPSettings:getText("DFP_" .. settingId .. "_Tooltip"))

	self.boxLayout:addElement(wrappingElement)

	DFPSettings.textElements[settingId] = newTextElement
end

function DFPSettings:AddTitle(self, text)
	local title = TextElement.new()
	title:applyProfile("settingsMenuSubtitle", true)
	title:setText(DFPSettings:getText(text))

	self.boxLayout:addElement(title)
end

function DFPSettings:getText(key)
	local result = g_i18n.modEnvironments[DFPSettings.name].texts[key]
	if result == nil then
		return g_i18n:getText(key)
	end
	return result
end

function DFPSettings:onClickGameSettingCheckbox(state, checkboxElement)
	DFPSettings:print("Change ".. tostring(checkboxElement.id) .. " to " .. tostring(checkboxElement:getIsChecked()))
	g_client:getServerConnection():sendEvent(ChangeDFPCheckSettingsEvent.new(checkboxElement.id, checkboxElement:getIsChecked()))
end

function DFPSettings:onTextChangedGameSettingDecimalNonNegativeCallback(textElement, text)
	local newValue = tonumber(textElement:getText())
	if newValue == nil then
		newValue = 1
	end
	if newValue < 0 then
		newValue = 0
	end
	DFPSettings:print("Change ".. tostring(textElement.id) .. " to " .. tostring(newValue))
	g_client:getServerConnection():sendEvent(ChangeDFPDecimalSettingsEvent.new(textElement.id, newValue))

	-- noch mal explizit setzen sonst setzt er er bei erneutem editieren zurück auf den vorherigen wert und die korrektur auf 1 im fehlerfall ist nicht sichtbar
	textElement:setText(tostring(newValue))
end

function DFPSettings.saveSettingsXML(missionInfo)
	if(DFPSettings.current == nil) then
		return
	end

	local xmlFile = XMLFile.create("DynamicFieldPricesXML", missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml", "dynamicFieldPrices")
	if xmlFile ~= nil then
		xmlFile:setInt("dynamicFieldPrices#version", 2)
	
		xmlFile:setFloat("dynamicFieldPrices.greediness#min", DFPSettings.current.MinGreed)
		xmlFile:setFloat("dynamicFieldPrices.greediness#max", DFPSettings.current.MaxGreed)
		xmlFile:setFloat("dynamicFieldPrices.economicSit#min", DFPSettings.current.MinEco)
		xmlFile:setFloat("dynamicFieldPrices.economicSit#max", DFPSettings.current.MaxEco)

		xmlFile:setFloat("dynamicFieldPrices.discourage#value", DFPSettings.current.Discourage)
		
		g_dynamicFieldPrices:onMissionSaveToSavegame(xmlFile)
		
		xmlFile:save()
	end
end

function DFPSettings.loadSettingsXML(mission, node)
	if mission:getIsServer() then
		if mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml") then
			local xmlFile = XMLFile.load("DynamicFieldPricesXML", mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml")
			if xmlFile ~= nil then
				local version = xmlFile:getInt("dynamicFieldPrices#version")

				DFPSettings.loadSettingsFloat(xmlFile, "greediness#min", "MinGreed")
				DFPSettings.loadSettingsFloat(xmlFile, "greediness#max", "MaxGreed")
				DFPSettings.loadSettingsFloat(xmlFile, "economicSit#min", "MinEco")
				DFPSettings.loadSettingsFloat(xmlFile, "economicSit#max", "MaxEco")
				DFPSettings.loadSettingsFloat(xmlFile, "discourage#value", "Discourage")			
				
				g_dynamicFieldPrices:onMissionLoadFromSavegame(xmlFile, version)
				
				xmlFile:delete()
			end
		end
	end
end

function DFPSettings.loadSettingsFloat(xmlFile, xmlKey, settingsId)
	local value = xmlFile:getFloat("dynamicFieldPrices." .. xmlKey)
	if value == nil then
		return
	end
	DFPSettings.current[settingsId] = value
	DFPSettings:print("Dynamic Field Prices: Loaded '" .. settingsId .. "': " .. tostring(DFPSettings.current[settingsId]))
end

function DFPSettings.loadSettingsFromServer()
	DFPSettings:print("Dynamic Field Prices: Request settings from server")
	g_client:getServerConnection():sendEvent(LoadDFPSettingsEvent.new())
end

function DFPSettings:print(text)
	if DFPSettings.debug then
		print(text)
	end
end

function DFPSettings:getRatio(key, value)	
	local maxVal = DFPSettings.current["Max"..key]
	local minVal = DFPSettings.current["Min"..key]
	
	if maxVal == nil or minVal == nil then
		return 1
	end
	
	local range = maxVal - minVal
	
	return (value - minVal) / range
end

function DFPSettings:getValue(key, ratio)
	local maxVal = DFPSettings.current["Max"..key]
	local minVal = DFPSettings.current["Min"..key]
	
	if maxVal == nil or minVal == nil then
		return 1
	end
	
	local range = maxVal - minVal
	
	return minVal + (ratio * range)
end

function DFPSettings:getDiscourage()
	if DFPSettings.current.Discourage == nil then
		return 0.1
	end
	return DFPSettings.current.Discourage
end

DFPSettings.init()