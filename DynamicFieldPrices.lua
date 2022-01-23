
local directory = g_currentModDirectory
local modName = g_currentModName

local dynamicFieldPrices = nil

DynamicFieldPrices = {}

local DynamicFieldPrices_mt = Class(DynamicFieldPrices)

function DynamicFieldPrices:new(mission, messageCenter, farmlandManager)
	local self = setmetatable({}, DynamicFieldPrices_mt)
	
	self.mission = mission
	self.messageCenter = messageCenter
	self.farmlandManager = farmlandManager
    self.isClient = mission:getIsClient()
    self.isServer = mission:getIsServer()
	
	self.sellExtra = 0.1
	self.npcs = {}
	self.messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	
	return self
end

function DynamicFieldPrices:delete()
	self.messageCenter:unsubscribeAll(self)
end

function DynamicFieldPrices:calcPrice()
	pph = self.farmlandManager.pricePerHa
	fls = self.farmlandManager.farmlands
	for fidx, field in pairs(fls) do
		local newPrice = field.areaInHa * pph * field.priceFactor
		local npcIdx = field.npcIndex
		if self.npcs[npcIdx] == nil then
			self:createRandomNPC(npcIdx)
		end
		newPrice = newPrice * self.npcs[npcIdx].greediness * self.npcs[npcIdx].economicSit
		local sellFactor = 1
		if field.isOwned then
			sellFactor = sellFactor - self.sellExtra
		else
			sellFactor = sellFactor + self.sellExtra
		end
		newPrice = newPrice*sellFactor
		field.price = newPrice
	end
end

function DynamicFieldPrices:createRandomNPC(i)
	npc = {
		greediness = math.random()*0.8 + 0.7,
		economicSit = math.random()*0.8 + 0.7
	}
	self.npcs[i] = npc
end

function DynamicFieldPrices:randomizeNPCs()
	for nidx, fnpc in pairs(self.npcs) do
		fnpc.economicSit = fnpc.economicSit + (math.random()-0.5)*0.1
		fnpc.economicSit = math.max(math.min(fnpc.economicSit, 1.5), 0.7)
	end
end

function DynamicFieldPrices:onDayChanged(day)
	if self.isServer then
		self:randomizeNPCs()
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
            dynamicFieldPrices:onMissionSaveToSavegame(xmlFile)
            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function loadedMission(mission, node)
	if mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml") then
		local xmlFile = XMLFile.load("DynamicFieldPricesXML", mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml")
		if xmlFile ~= nil then
			dynamicFieldPrices:onMissionLoadFromSavegame(xmlFile)
			xmlFile:delete()
		end
	end

    if mission.cancelLoading then
        return
    end
end

function load(mission)
	dynamicFieldPrices = DynamicFieldPrices:new(mission, g_messageCenter, g_farmlandManager)
end

function startMission(mission)
	dynamicFieldPrices:onStartMission(mission)
end

addModEventListener(DynamicFieldPrices)

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, saveToXMLFile)
Mission00.load = Utils.appendedFunction(Mission00.load, load)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)

