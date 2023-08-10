local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("DFPPricesChangedEvent.lua", directory .. "events/"))

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
	
	self.npcs = {}
	self.messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	farmlandManager:addStateChangeListener(self)	
	
	return self
end

function DynamicFieldPrices:delete()
	self.messageCenter:unsubscribeAll(self)
	farmlandManager:removeStateChangeListener(self)
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
		local newPrice = 0
		if field.fixedPrice ~= nil then
			newPrice = field.fixedPrice
		else
			newPrice = field.areaInHa * pph * field.priceFactor
		end
		local npcIdx = field.npcIndex
		if self.npcs[npcIdx] == nil then
			self:createRandomNPC(npcIdx)
		end
		newPrice = newPrice * DFPSettings:getValue("Greed", self.npcs[npcIdx].greediness)
		newPrice = newPrice * DFPSettings:getValue("Eco", self.npcs[npcIdx].economicSit)
		local sellFactor = 1
		if field.isOwned then
			sellFactor = sellFactor - DFPSettings:getDiscourage()
		else
			sellFactor = sellFactor + DFPSettings:getDiscourage()
		end
		newPrice = newPrice*sellFactor
		field.price = newPrice
		prices[fidx] = newPrice
	end
	
	g_server:broadcastEvent(DFPPricesChangedEvent:new(self, prices))
end

function DynamicFieldPrices:createRandomNPC(i)
	npc = {
		greediness = math.random(),
		economicSit = math.random()
	}
	self.npcs[i] = npc
end

function DynamicFieldPrices:randomizeNPCs()
	for nidx, fnpc in pairs(self.npcs) do
		fnpc.economicSit = fnpc.economicSit + (math.random()-0.5)*0.2
		fnpc.economicSit = math.max(math.min(fnpc.economicSit, 1), 0)
	end
end

function DynamicFieldPrices:onDayChanged(day)
	if self.isServer then
		if DFPSettings.current.ResetNPCs then
			self.npcs = {}
			
			DFPSettings.current.ResetNPCs = false			
			g_server:broadcastEvent(ChangeDFPCheckSettingsEvent.new("ResetNPCs", false), false)
		end
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

    if self.npcs ~= nil then
        for i, snpc in pairs(self.npcs) do
            local key = ("dynamicFieldPrices.npcs.npc(%d)"):format(i - 1)

            xmlFile:setInt(key .. "#id", i)
            xmlFile:setFloat(key .. "#greediness",snpc.greediness)
            xmlFile:setFloat(key .. "#economicSit",snpc.economicSit)
        end
    end
end

function DynamicFieldPrices:onMissionLoadFromSavegame(xmlFile, xmlVersion)

    xmlFile:iterate("dynamicFieldPrices.npcs.npc", function(_, key)
        local npc = {}
		local id = xmlFile:getInt(key .. "#id")
		if id ~= nil then
			npc.greediness = xmlFile:getFloat(key .. "#greediness")
			npc.economicSit = xmlFile:getFloat(key .. "#economicSit")
			
			-- Add support for older versions -> convert values			
			if xmlVersion == 1 then
				npc.greediness = DFPSettings:getRatio("Greed", npc.greediness)
				npc.economicSit = DFPSettings:getRatio("Eco", npc.economicSit)
			end
			
			self.npcs[id] = npc
		end
    end)
end

function loadedMap(mapNode, failedReason, arguments, callAsyncCallback, ...)
	g_currentMission.inGameMenu.pageMapOverview.ingameMap.onClickMapCallback = g_currentMission.inGameMenu.pageMapOverview.onClickMap
end

function load(mission)
	g_dynamicFieldPrices = DynamicFieldPrices:new(mission, g_messageCenter, g_farmlandManager)
	InGameMenuMapFrame.onClickMap = Utils.appendedFunction(InGameMenuMapFrame.onClickMap, onClickFarmland)
end

function startMission(mission)
	g_dynamicFieldPrices:onStartMission(mission)
end

function readStream(e, streamId, connection)
    g_dynamicFieldPrices:onReadStream(streamId, connection)
end

function writeStream(e, streamId, connection)
    g_dynamicFieldPrices:onWriteStream(streamId, connection)
end


function onClickFarmland(self, elem, X, Z)
	-- appended to InGameMenuMapFrame:onClickMap()

	if self.mode ~= InGameMenuMapFrame.MODE_FARMLANDS then return end 

	local farmland = self.selectedFarmland		
	
	if farmland == nil or not farmland.showOnFarmlandsScreen
		then return 
	end
			
	local bcFactor = 1
	
	if g_modIsLoaded["FS22_BetterContracts"] then
		
		local preText = self.farmlandValueText:getText()
	
		local difStartIndex = string.find(preText, "%( -")
		local difEndIndex = string.find(preText, "%%%)")
		
		if difStartIndex ~= nil and difEndIndex ~= nil then
			local difStr = string.sub(preText, difStartIndex+3, difEndIndex-1)
			bcFactor = (100-tonumber(difStr))/100.0
		end
	end
	
	local baseprice = farmland.areaInHa*g_farmlandManager.pricePerHa*farmland.priceFactor
	local mult = 1
	local finalPrice = farmland.price*bcFactor
	if baseprice ~= 0 then
		mult = finalPrice/baseprice
	end		
	local difference = string.format("%.1f %%", (mult-1)*100)
	if mult >= 1 then
		difference = "+" .. difference
	end
	selectedFarmlandDifference = " ( " .. difference .. ")"
	
	if mult >= 1 then
		self.farmlandValueText:applyProfile(InGameMenuMapFrame.PROFILE.MONEY_VALUE_NEGATIVE)
	else			
		self.farmlandValueText:applyProfile(InGameMenuMapFrame.PROFILE.MONEY_VALUE_NEUTRAL)
	end	
	self.farmlandValueText:setText(g_i18n:formatMoney(finalPrice, 0, true, true)..selectedFarmlandDifference)

	self.farmlandValueBox:invalidateLayout()
end

addModEventListener(DynamicFieldPrices)

Mission00.load = Utils.appendedFunction(Mission00.load, load)
BaseMission.loadMapFinished = Utils.appendedFunction(BaseMission.loadMapFinished, loadedMap)
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)
SavegameSettingsEvent.readStream = Utils.appendedFunction(SavegameSettingsEvent.readStream, readStream)
SavegameSettingsEvent.writeStream = Utils.appendedFunction(SavegameSettingsEvent.writeStream, writeStream)

