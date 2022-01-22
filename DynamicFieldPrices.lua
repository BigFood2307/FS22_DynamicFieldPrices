
local directory = g_currentModDirectory
local modName = g_currentModName

DynamicFieldPrices = {
	sellExtra = 0.1,
	npcs = {}
}

function DynamicFieldPrices:calcPrice()
	pph = g_farmlandManager.pricePerHa
	fls = g_farmlandManager.farmlands
	for fidx, field in pairs(fls) do
		local newPrice = field.areaInHa * pph * field.priceFactor
		local npcIdx = field.npcIndex
		if DynamicFieldPrices.npcs[npcIdx] == nil then
			DynamicFieldPrices.createRandomNPC(npcIdx)
		end
		newPrice = newPrice * DynamicFieldPrices.npcs[npcIdx].greediness * DynamicFieldPrices.npcs[npcIdx].economicSit
		local sellFactor = 1
		if field.isOwned then
			sellFactor = sellFactor - DynamicFieldPrices.sellExtra
		else
			sellFactor = sellFactor + DynamicFieldPrices.sellExtra
		end
		newPrice = newPrice*sellFactor
		field.price = newPrice
	end
end

function DynamicFieldPrices.createRandomNPC(i)
	print("Creating NPC")
	npc = {
		greediness = math.random()*0.8 + 0.7,
		economicSit = math.random()*0.8 + 0.7
	}
	DynamicFieldPrices.npcs[i] = npc
	print_r(npc)
end

function DynamicFieldPrices.randomizeNPCs()
	for nidx, fnpc in pairs(DynamicFieldPrices.npcs) do
		fnpc.economicSit = fnpc.economicSit + (math.random()-0.5)*0.1
		fnpc.economicSit = math.max(math.min(fnpc.economicSit, 1.5), 0.7)
	end
end

function DynamicFieldPrices.onDayChanged(day)
	DynamicFieldPrices.randomizeNPCs()
	DynamicFieldPrices.calcPrice()
end

function DynamicFieldPrices.onStartMission(mission)
	DynamicFieldPrices.calcPrice()
end

function DynamicFieldPrices:onMissionSaveToSavegame(xmlFile)
    xmlFile:setInt("dynamicFieldPrices#version", 1)

    if DynamicFieldPrices.npcs ~= nil then
        for i, snpc in pairs(DynamicFieldPrices.npcs) do
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

        DynamicFieldPrices.npcs[id] = npc
    end)
end

function saveToXMLFile(missionInfo)
    if missionInfo.isValid then
        local xmlFile = XMLFile.create("DynamicFieldPricesXML", missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml", "dynamicFieldPrices")
        if xmlFile ~= nil then
            DynamicFieldPrices:onMissionSaveToSavegame(xmlFile)
            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function loadedMission(mission, node)
	print("Test0")
	if mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml") then
		local xmlFile = XMLFile.load("DynamicFieldPricesXML", mission.missionInfo.savegameDirectory .. "/dynamicFieldPrices.xml")
		if xmlFile ~= nil then
			DynamicFieldPrices:onMissionLoadFromSavegame(xmlFile)
			xmlFile:delete()
		end
	end

    if mission.cancelLoading then
        return
    end
end

addModEventListener(DynamicFieldPrices)
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, saveToXMLFile)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, DynamicFieldPrices.onStartMission)
g_messageCenter:subscribe(MessageType.DAY_CHANGED, DynamicFieldPrices.onDayChanged, DynamicFieldPrices)

