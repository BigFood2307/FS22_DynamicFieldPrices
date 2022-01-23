local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("DFPPricesChangedEvent.lua", directory))

g_dynamicFieldPrices = nil

DynamicFieldPrices = {}

local DynamicFieldPrices_mt = Class(DynamicFieldPrices)

function DynamicFieldPrices:new(mission, messageCenter, farmlandManager)
	local self = setmetatable({}, DynamicFieldPrices_mt)
	
	self.mission = mission
	self.messageCenter = messageCenter
	self.farmlandManager = farmlandManager
    self.isClient = mission:getIsClient()
    self.isServer = mission:getIsServer()
	
	self.minGreed = 0.8
	self.maxGreed = 1.2
	self.minEco = 0.6
	self.maxEco = 1.6
	
	self.discourage = 0.1
	self.npcs = {}
	self.messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	farmlandManager:addStateChangeListener(self)	
	
	return self
end

function DynamicFieldPrices:delete()
	self.messageCenter:unsubscribeAll(self)
end

function DynamicFieldPrices:onWriteStream(streamId, connection)
	fls = self.farmlandManager.farmlands
	for fidx, field in pairs(fls) do
		streamWriteFloat32(streamId, field.price)
	end
end

function DynamicFieldPrices:onReadStream(streamId, connection)
	fls = self.farmlandManager.farmlands
	for fidx, field in pairs(fls) do
		field.price = streamReadFloat32(streamId)
	end
end

function DynamicFieldPrices:onNewPricesReceived(prices)
	if not self.isServer then
		fls = self.farmlandManager.farmlands
		for fidx, field in pairs(fls) do
			field.price = prices[fidx]
		end	
	end
end

function DynamicFieldPrices:calcPrice()
	pph = self.farmlandManager.pricePerHa
	fls = self.farmlandManager.farmlands
	local prices = {}
	for fidx, field in pairs(fls) do
		local newPrice = field.areaInHa * pph * field.priceFactor
		local npcIdx = field.npcIndex
		if self.npcs[npcIdx] == nil then
			self:createRandomNPC(npcIdx)
		end
		newPrice = newPrice * self.npcs[npcIdx].greediness * self.npcs[npcIdx].economicSit
		local sellFactor = 1
		if field.isOwned then
			sellFactor = sellFactor - self.discourage
		else
			sellFactor = sellFactor + self.discourage
		end
		newPrice = newPrice*sellFactor
		field.price = newPrice
		prices[fidx] = newPrice
	end
	
	g_server:broadcastEvent(DFPPricesChangedEvent:new(self, prices))
end

function DynamicFieldPrices:createRandomNPC(i)
	npc = {
		greediness = math.random()*(self.maxGreed-self.minGreed) + self.minGreed,
		economicSit = math.random()*(self.maxEco-self.minEco) + self.minEco
	}
	self.npcs[i] = npc
end

function DynamicFieldPrices:randomizeNPCs()
	for nidx, fnpc in pairs(self.npcs) do
		fnpc.economicSit = fnpc.economicSit + (math.random()-0.5)*0.1
		fnpc.economicSit = math.max(math.min(fnpc.economicSit, self.maxEco), self.minEco)
	end
end

function DynamicFieldPrices:onDayChanged(day)
	if self.isServer then
		self:randomizeNPCs()
		self:calcPrice()
	end
end

function DynamicFieldPrices:onFarmlandStateChanged(farmlandId, farmId)
	if self.isServer then
		self:calcPrice()
	end
end

function DynamicFieldPrices:onStartMission(mission)
	if self.isServer then
		self:calcPrice()
	end
end

function DynamicFieldPrices:onMissionSaveToSavegame(xmlFile)
    xmlFile:setInt("dynamicFieldPrices#version", 1)
	
	xmlFile:setFloat("dynamicFieldPrices.greediness#min", self.minGreed)
	xmlFile:setFloat("dynamicFieldPrices.greediness#max", self.maxGreed)
	xmlFile:setFloat("dynamicFieldPrices.economicSit#min", self.minEco)
	xmlFile:setFloat("dynamicFieldPrices.economicSit#max", self.maxEco)
	
	xmlFile:setFloat("dynamicFieldPrices.discourage#value", self.discourage)

    if self.npcs ~= nil then
        for i, snpc in pairs(self.npcs) do
            local key = ("dynamicFieldPrices.npcs.npc(%d)"):format(i - 1)

            xmlFile:setInt(key .. "#id", i)
            xmlFile:setFloat(key .. "#greediness",snpc.greediness)
            xmlFile:setFloat(key .. "#economicSit",snpc.economicSit)
        end
    end
end

function DynamicFieldPrices:onMissionLoadFromSavegame(xmlFile)
	
	self.minGreed = xmlFile:getFloat("dynamicFieldPrices.greediness#min")
	self.maxGreed = xmlFile:getFloat("dynamicFieldPrices.greediness#max")
	self.minEco = xmlFile:getFloat("dynamicFieldPrices.economicSit#min")
	self.maxEco = xmlFile:getFloat("dynamicFieldPrices.economicSit#max")
	
	self.discourage = xmlFile:getFloat("dynamicFieldPrices.discourage#value")

    xmlFile:iterate("dynamicFieldPrices.npcs.npc", function(_, key)
        local npc = {}

		local id = xmlFile:getInt(key .. "#id")
        npc.greediness = xmlFile:getFloat(key .. "#greediness")
        npc.economicSit = xmlFile:getFloat(key .. "#economicSit")

        self.npcs[id] = npc
    end)
end

function saveToXMLFile(missionInfo)
    if missionInfo.isValid then
        local xmlFile = XMLFile.create("DynamicFieldPricesXML", missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml", "dynamicFieldPrices")
        if xmlFile ~= nil then
            g_dynamicFieldPrices:onMissionSaveToSavegame(xmlFile)
            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function loadedMission(mission, node)
	if mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml") then
		local xmlFile = XMLFile.load("DynamicFieldPricesXML", mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml")
		if xmlFile ~= nil then
			g_dynamicFieldPrices:onMissionLoadFromSavegame(xmlFile)
			xmlFile:delete()
		end
	end

    if mission.cancelLoading then
        return
    end
end

function load(mission)
	g_dynamicFieldPrices = DynamicFieldPrices:new(mission, g_messageCenter, g_farmlandManager)
end

function startMission(mission)
	g_dynamicFieldPrices:onStartMission(mission)
end

function DynamicFieldPrices:buildFarmlandsMapOverlay(selectedFarmland)
    if selectedFarmland then
		local mult = selectedFarmland.price/(selectedFarmland.areaInHa*g_farmlandManager.pricePerHa*selectedFarmland.priceFactor)
        local difference = string.format("%.2f %%", (mult-1)*100)
		if mult > 1 then
			difference = "+" .. difference
		end
        self.selectedFarmlandDifference = difference
    end
end

function DynamicFieldPrices:onFarmlandOverlayFinished(a, b, c, d)
    if self.mapOverlayGenerator.selectedFarmlandDifference then
		self.farmlandValueText:setText(self.farmlandValueText:getText() .. " (" .. self.mapOverlayGenerator.selectedFarmlandDifference .. ")")
        --if self.areaText == nil then
        --    local areaLabel = self.farmlandValueText:clone(self)
        --    areaLabel:setPosition(0, 0.04)
        --    self.farmlandValueText.parent:addElement(areaLabel)
        --    areaLabel:setText("Difference")
        --    areaLabel:setTextColor(1, 1, 1, 1)
        --    self.areaLabel = areaLabel
        --    local areaText = self.farmlandValueText:clone(self)
        --    areaText:setPosition(0.09, 0.04)
        --    self.farmlandValueText.parent:addElement(areaText)
        --    areaText:setText(self.mapOverlayGenerator.selectedFarmlandDifference)
        --    self.areaText = areaText
        --else
        --    local areaText = self.areaText
        --    areaText:setText(self.mapOverlayGenerator.selectedFarmlandDifference)
        --end
    --else
    --    if self.areaText then
    --        self:removeElement(self.areaText)
    --    end
    --    if self.areaLabel then
    --        self:removeElement(self.areaLabel)
    --    end
    end
end

addModEventListener(DynamicFieldPrices)

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, saveToXMLFile)
Mission00.load = Utils.appendedFunction(Mission00.load, load)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)
MapOverlayGenerator.buildFarmlandsMapOverlay = Utils.appendedFunction(MapOverlayGenerator.buildFarmlandsMapOverlay, DynamicFieldPrices.buildFarmlandsMapOverlay)
InGameMenuMapFrame.onFarmlandOverlayFinished = Utils.prependedFunction(InGameMenuMapFrame.onFarmlandOverlayFinished, DynamicFieldPrices.onFarmlandOverlayFinished)

