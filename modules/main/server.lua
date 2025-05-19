function InitializeAirdrop(data)
    local id
    repeat
        id = math.random(1, 999999) .. "_" .. math.random(1, 999999)
    until not Airdrops[id]
    Airdrops[id] = {
        id = id,
        coords = data.coords,
        heading = data.heading,
        lootingPlayers = {},
        items = data.items,
        maxSlots = #data.items,
        isActive = true,
    }
    TriggerClientEvent("pickle_airdrops:startAirdrop", -1, id, Airdrops[id])
end

function GenerateRange(range)
    if not range or type(range) ~= "table" or #range ~= 2 then
        return 1
    end
    if type(range) == "number" then
        return range
    end
    local min = range[1] or 1
    local max = range[2] or 1
    if min >= max then
        return min
    end
    return math.random(min, max)
end

function StartAirdropTemplate(templateId, data)
    local templateCfg = Config.AirdropTemplates[templateId]
    if not templateCfg then
        print("^1ERROR:^0 Invalid airdrop template: ", templateId)
        return
    end
    local itemRange = GenerateRange(templateCfg.itemRange)
    local items = {}
    local itemStack = {}
    for i=1, #templateCfg.items do 
        local item = templateCfg.items[i]
        for j=1, item.chance do 
            table.insert(itemStack, i)
        end
    end
    for i=1, itemRange do 
        local itemIndex = itemStack[math.random(1, #itemStack)]
        local item = templateCfg.items[itemIndex]
        local itemCount = GenerateRange(item.range)
        table.insert(items, {
            name = item.name or Config.CurrencyItems[item.itemType],
            itemType = item.itemType or "item",
            count = itemCount,
            captureTime = item.captureTime or Config.Airdrops.defaultItemCaptureTime,
        })
        local newItemStack = {}
        for i=1, #itemStack do 
            if itemStack[i] ~= itemIndex then
                table.insert(newItemStack, itemStack[i])
            end
        end
        itemStack = newItemStack
    end
    InitializeAirdrop({
        coords = data.coords,
        heading = data.heading,
        items = items,
    })
end

RegisterNetEvent("pickle_airdrops:takeAirdropContainerItem", function(id, slot)
    local currentTime = os.time()
    local source = source
    local airdrop = Airdrops[id]
    if not airdrop then return end
    local item = airdrop.items[slot]
    if not item then return end
    local lootingPlayer = airdrop.lootingPlayers[source]
    if not lootingPlayer or lootingPlayer.slot ~= slot or currentTime - lootingPlayer.statusTime < (item.captureTime - 2) then
        ShowNotification(source, "nice try bud, get banned")
        return
    end
    if item.itemType == "money" or item.itemType == "dirty_money" then
        AddMoney(source, item.count, item.itemType == "money" and "money" or "dirty")
    elseif item.itemType == "weapon" then
        Inventory.AddWeapon(source, item.name, item.count)
    else
        Inventory.AddItem(source, item.name, item.count)
    end
    airdrop.items[slot] = nil
    local remainingItems = 0
    for index, item in pairs(airdrop.items) do
        if item then
            remainingItems = remainingItems + 1
        end
    end
    TriggerClientEvent("pickle_airdrops:updateAirdropContainerItems", -1, id, airdrop.items)
    if remainingItems == 0 then
        Airdrops[id] = nil
        SetTimeout(1000, function()
            TriggerClientEvent("pickle_airdrops:removeAirdrop", -1, id)
        end)
    end
end)

RegisterNetEvent("pickle_airdrops:updateAirdropContainerItemStatus", function(id, slot, status)
    local source = source
    local airdrop = Airdrops[id]
    if not airdrop then return end
    airdrop.lootingPlayers[source] = status and {
        slot = slot,
        statusTime = os.time(),
        status = status,
    } or nil
end)

RegisterNetEvent("pickle_airdrops:initializePlayer", function()
    local source = source
    StartAirdropTemplate("default", {
        coords = vector3(-1681.7599, -888.7565, 7.4712),
        heading = 49.3722,
    })
    TriggerClientEvent("pickle_airdrops:setupInventory", source, {items = Inventory.Items})
end)

RegisterCommand(Config.RandomDropCommand, function(source, args, rawCommand)
    local dropTemplate = args[1] or "default"
end)