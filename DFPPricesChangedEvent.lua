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
	print_r(prices)

    return self
end

function DFPPricesChangedEvent:writeStream(streamId, connection)
	print(#prices)
	streamWriteInt32(#prices)
	for i, p in pairs(prices) do
		streamWriteFloat32(streamId, p)
	end
end

function DFPPricesChangedEvent:readStream(streamId, connection)
    local nPrices = streamReadInt32(streamId)
	print(nPrices)
	for i = 1, nPrices, 1 do
		self.prices[i] = streamReadFloat32(streamId)
	end

    self:run(connection)
end

function DFPPricesChangedEvent:run(connection)
	print("Test0")
	print(connection:getIsServer())
    if not connection:getIsServer() then
		print("Test")
        g_dynamicFieldPrices:onNewPricesReceived(self.prices)
	end
end