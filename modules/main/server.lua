function InitializeAirdrop(data)
    local id
    repeat
        id = math.random(1, 999999) .. "_" .. math.random(1, 999999)
    until not Airdrops[id]
    Airdrops[id] = {
        id = id,
        coords = data.coords,
        heading = data.heading,
        items = {},
        isActive = true,
    }
    TriggerClientEvent("pickle_airdrops:startAirdrop", -1, id, Airdrops[id])
end

RegisterNetEvent("pickle_airdrops:initializePlayer", function()
    local source = source
    InitializeAirdrop({
        coords = vector3(-1681.7599, -888.7565, 7.4712),
        heading = 49.3722,
    })
    TriggerClientEvent("pickle_airdrops:setupInventory", source, {items = Inventory.Items})
end)