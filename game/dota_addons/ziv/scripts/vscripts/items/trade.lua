if not Trade then
    Trade = class({})
end

Trade.TRADES = {}

function Trade:Init()
	CustomGameEventManager:RegisterListener("ziv_trade_request", Dynamic_Wrap(Trade, 'TradeRequest'))
	CustomGameEventManager:RegisterListener("ziv_accept_trade", Dynamic_Wrap(Trade, 'AcceptTrade'))
	CustomGameEventManager:RegisterListener("ziv_accept_trade_request", Dynamic_Wrap(Trade, 'AcceptRequest'))

	Convars:RegisterCommand( "tt",  Dynamic_Wrap(Trade, 'TestTrade'), "", FCVAR_CHEAT )
end

function Trade:TestTrade()
	Trade:TradeRequest({PlayerID = 0, target = 1})
end

function Trade:TradeRequest(args)
	local initiator = args.PlayerID
	local target = args.target

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(target), "ziv_transmit_trade_request", {initiator = initiator})
end

function Trade:AcceptRequest(args)
	local initiator = args.initiator
	local accepter = args.PlayerID

	local initiatorContainer = Containers:CreateContainer({
		layout 			= {6,6},
		skins 			= {"Trade"},
		position 		= "0px 0px 0px",
		pids 			= {initiator, accepter},
		cantDragTo      = {accepter},
		cantDragFrom	= {accepter},
		entity 			= PlayerResource:GetPlayer(initiator):GetAssignedHero(),
		closeOnOrder 	= false,
		OnDragWorld 	= false
    })

	local accepterContainer = Containers:CreateContainer({
		layout 			= {6,6},
		skins 			= {"Trade"},
		position 		= "0px 0px 0px",
		pids 			= {accepter, initiator},
		cantDragTo      = {initiator},
		cantDragFrom	= {initiator},
		entity 			= PlayerResource:GetPlayer(accepter):GetAssignedHero(),
		closeOnOrder 	= false,
		OnDragWorld 	= false
    })

    local tradeID = #Trade.TRADES+1
    Trade.TRADES[tradeID] = {}
	Trade.TRADES[tradeID][initiator] = { container = initiatorContainer, status = false }
	Trade.TRADES[tradeID][accepter] = { container = accepterContainer, status = false }

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(tonumber(initiator)), "ziv_open_trade", {items = initiatorContainer.id, offer = accepterContainer.id, tradeID = tradeID})

	if initiator ~= accepter then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(tonumber(accepter)), "ziv_open_trade", {items = accepterContainer.id, offer = initiatorContainer.id, tradeID = tradeID})
	end
end

function Trade:AcceptTrade(args)
	local pID = args.PlayerID
	local tradeID = args.tradeID

	Trade.TRADES[tradeID][pID].status = not Trade.TRADES[tradeID][pID].status

	local pIDs = {}

	CustomGameEventManager:Send_ServerToAllClients("ziv_highlight_trade", {tradeID = tradeID, containerID = Trade.TRADES[tradeID][pID].container.id, highlight = Trade.TRADES[tradeID][pID].status})

	for k,v in pairs(Trade.TRADES[tradeID]) do
		table.insert(pIDs, k)

		if not v.status then
			return
		end
	end 

	local initiatorContainer = Trade.TRADES[tradeID][pIDs[1]].container
	local accepterContainer = Trade.TRADES[tradeID][pIDs[2]].container

	for k,v in pairs(initiatorContainer:GetAllItems()) do
		initiatorContainer:RemoveItem(v)
		Characters:GetInventory(pIDs[2]):AddItem(v)
	end

	for k,v in pairs(accepterContainer:GetAllItems()) do
		accepterContainer:RemoveItem(v)
		Characters:GetInventory(pIDs[1]):AddItem(v)
	end

	initiatorContainer:Delete(true)
	accepterContainer:Delete(true)

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(tonumber(pIDs[1])), "ziv_close_trade", {})

	if pIDs[1] ~= pIDs[2] then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(tonumber(pIDs[2])), "ziv_close_trade", {})
	end
end

function Trade:CancelTrade(args)
	local pID = args.PlayerID
	local tradeID = args.tradeID

	if tradeID then
		local trade = Trade.TRADES[tradeID]

		for k,v in pairs(Trade.TRADES[tradeID][pID].container:GetAllItems()) do
			Trade.TRADES[tradeID][pID].container:RemoveItem(v)
			Characters:GetInventory(pID):AddItem(v)
		end

		for k,v in pairs(Trade.TRADES[tradeID]) do
			if k ~= pID then
				for k1,v1 in pairs(Trade.TRADES[tradeID][k].container:GetAllItems()) do
					Trade.TRADES[tradeID][k].container:RemoveItem(v1)
					Characters:GetInventory(k):AddItem(v1)
				end

				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(k), "ziv_close_trade", {})
			end
		end 
	end
end