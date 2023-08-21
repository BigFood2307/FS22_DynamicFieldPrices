DFPPricesChangedEvent = {}
local DFPPricesChangedEvent_mt = Class(DFPPricesChangedEvent, Event)

InitEventClass(DFPPricesChangedEvent, "DFPPricesChangedEvent")

function DFPPricesChangedEvent:emptyNew()
    local self = Event.new(DFPPricesChangedEvent_mt)

	self.prices = {}
	
    return self
end

function DFPPricesChangedEvent:new(dfp, prices)
    local self = DFPPricesChangedEvent:emptyNew()

	self.dfp = dfp
    self.prices = prices

    return self
end

function DFPPricesChangedEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, #self.prices)
	for i, p in pairs(self.prices) do
		streamWriteFloat32(streamId, p)
	end
end

function DFPPricesChangedEvent:readStream(streamId, connection)
    local nPrices = streamReadInt32(streamId)
	for i = 1, nPrices, 1 do
		self.prices[i] = streamReadFloat32(streamId)
	end

    self:run(connection)
end

function DFPPricesChangedEvent:run(connection)
    if connection:getIsServer() then
        g_dynamicFieldPrices:onNewPricesReceived(self.prices)
	end
end