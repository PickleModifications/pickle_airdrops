function GetRandomPointInCircle(center, radius)
    local angle = math.random() * 2 * math.pi
    local r = math.sqrt(math.random()) * radius
    local x = center.x + r * math.cos(angle)
    local y = center.y + r * math.sin(angle)
    return vector3(x, y, center.z)
end

function InitializeAirdrop(data)
    local id
    repeat
        id = math.random(1, 999999) .. "_" .. math.random(1, 999999)
    until not Airdrops[id]
    local airdropContainers = {}
    local radius = data.radius or 10.0
    local spawnRadiusMultiplier = data.spawnRadiusMultiplier or 1.0
    local unlockTime = data.unlockTime or Config.Airdrops.defaultUnlockTime
    for i=1, #data.containers do 
        local container = data.containers[i]
        table.insert(airdropContainers, {
            id = i,
            image = container.image or "",
            label = container.label or _L("airdrop_container"),
            location = {
                coords = #data.containers == 1 and data.coords or GetRandomPointInCircle(data.coords, radius * spawnRadiusMultiplier),
                heading = #data.containers == 1 and data.heading or math.random(0, 360),
            },
            timerStarted = nil,
            unlockTime = unlockTime,
            lootingPlayers = {},
            dropModel = container.dropModel,
            items = container.items,
            maxSlots = #container.items,
        })
    end
    Airdrops[id] = {
        id = id,
        radius = radius,
        coords = data.coords,
        heading = data.heading,
        dropBlipEnabled = data.dropBlipEnabled,
        radiusBlipEnabled = data.radiusBlipEnabled,
        dropModel = data.dropModel or `sm_prop_smug_crate_01a`,
        parachuteModel = data.parachuteModel or  `gr_prop_gr_para_s_01`,
        containers = airdropContainers
    }
    TriggerClientEvent("pickle_airdrops:startAirdrop", -1, id, Airdrops[id])
end

exports("InitializeAirdrop", InitializeAirdrop)

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
    local containers = {}
    for i=1, data.containers or 1 do 
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
        table.insert(containers, {
            image = templateCfg.image,
            label = templateCfg.label,
            dropModel = templateCfg.minidropModel,
            items = items,
        })
    end

    InitializeAirdrop({
        coords = data.coords,
        heading = data.heading,
        dropBlipEnabled = templateCfg.dropBlipEnabled,
        spawnRadiusMultiplier = templateCfg.spawnRadiusMultiplier,
        radiusBlipEnabled = templateCfg.radiusBlipEnabled,
        radius = templateCfg.radius,
        dropModel = templateCfg.dropModel,
        containers = containers
    })
end

exports("StartAirdropTemplate", StartAirdropTemplate)

RegisterNetEvent("pickle_airdrops:startContainerTimer", function(id)
    local source = source
    local airdrop = Airdrops[id]
    if not airdrop then return end
    local airdropContainer = airdrop.containers[1]
    if not airdropContainer or airdropContainer.timerStarted then return end
    local timerStarted = os.time()
    for containerId, container in pairs(airdrop.containers) do
        container.timerStarted = timerStarted
    end
    TriggerClientEvent("pickle_airdrops:startContainerTimer", -1, id, timerStarted)
end)

RegisterNetEvent("pickle_airdrops:takeAirdropContainerItem", function(id, containerId, slot)
    local currentTime = os.time()
    local source = source
    local airdrop = Airdrops[id]
    if not airdrop then return end
    local airdropContainer = airdrop.containers[containerId]
    if not airdropContainer then return end
    local item = airdropContainer.items[slot]
    if not item then return end
    local lootingPlayer = airdropContainer.lootingPlayers[source]
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
    airdropContainer.items[slot] = nil
    local remainingItems = 0
    for index, item in pairs(airdropContainer.items) do
        if item then
            remainingItems = remainingItems + 1
        end
    end
    TriggerClientEvent("pickle_airdrops:updateAirdropContainerItems", -1, id, containerId, airdropContainer.items)
    if remainingItems == 0 then
        Airdrops[id].containers[containerId] = nil
        local remainingContainers = 0
        for _, container in pairs(Airdrops[id].containers) do
            if container then
                remainingContainers = remainingContainers + 1
            end
        end
        SetTimeout(1000, function()
            if remainingContainers == 0 then
                Airdrops[id] = nil
                TriggerClientEvent("pickle_airdrops:removeAirdrop", -1, id)
            else
                TriggerClientEvent("pickle_airdrops:removeAirdropContainer", -1, id, containerId)
            end
        end)
    end
end)

RegisterNetEvent("pickle_airdrops:updateAirdropContainerItemStatus", function(id, containerId, slot, status)
    local source = source
    local airdrop = Airdrops[id]
    if not airdrop then return end
    local airdropContainer = airdrop.containers[containerId]
    if not airdropContainer or airdropContainer.unlockTime - (os.time() - airdropContainer.timerStarted) > 0 then return end
    airdropContainer.lootingPlayers[source] = status and {
        slot = slot,
        statusTime = os.time(),
        status = status,
    } or nil
end)

RegisterNetEvent("pickle_airdrops:initializePlayer", function()
    local source = source
    StartAirdropTemplate("default", {
        coords = GetEntityCoords(GetPlayerPed(source)),
        heading = GetEntityHeading(GetPlayerPed(source)),
        containers = 5,
    })
    TriggerClientEvent("pickle_airdrops:setupInventory", source, {items = Inventory.Items})
end)

RegisterCommand(Config.RandomDropCommand, function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, "airdrop.command") then
        ShowNotification(source, _L("no_permission"))
        return
    end
    local dropTemplate = args[1] or "default"
    if not Config.AirdropTemplates[dropTemplate] then
        ShowNotification(source, "Invalid drop template: " .. dropTemplate)
        return
    end
    local containers = tonumber(args[2] or "") or 1
    if containers < 1 then
        containers = 1
    end
    local location = Config.RandomDropZones[math.random(1, #Config.RandomDropZones)]
    local coords = GetRandomPointInCircle(location.coords, location.radius)
    local heading = location.heading or math.random(0, 360)
    StartAirdropTemplate(dropTemplate, {
        coords = coords,
        heading = heading,
        containers = containers,
    })
end)

CreateThread(function()
    for k,v in pairs(Config.AirdropTemplates) do 
        RegisterUsableItem(v.item, function(source)
            Inventory.RemoveItem(source, v.item, 1)
            local coords = GetEntityCoords(GetPlayerPed(source)) + vector3(
                math.random(2, 5) * (math.random(1, 2) == 1 and 1 or -1), 
                math.random(2, 5) * (math.random(1, 2) == 1 and 1 or -1), 
                0.0
            )
            local heading = GetEntityHeading(GetPlayerPed(source))
            local dropTemplate = Config.AirdropTemplates[k]
            SetTimeout(4000, function()
                ShowNotification(source, _L("airdrop_incoming"))
                StartAirdropTemplate(k, {
                    coords = coords,
                    heading = heading,
                    containers = dropTemplate.containers or 1,
                })
            end)
            TriggerClientEvent("pickle_airdrops:playAirdropPlacement", source)
        end)
        if v.cronSchedule then 
            lib.cron.new(v.cronSchedule, function()
                local dropTemplate = Config.AirdropTemplates[k]
                local containers = dropTemplate.containers or 1
                if containers < 1 then
                    containers = 1
                end
                local location = Config.RandomDropZones[math.random(1, #Config.RandomDropZones)]
                local coords = GetRandomPointInCircle(location.coords, location.radius)
                local heading = location.heading or math.random(0, 360)
                StartAirdropTemplate(k, {
                    coords = coords,
                    heading = heading,
                    containers = containers,
                })
                if Config.Airdrops.announceScheduledDrops then
                    ShowNotification(-1, _L("airdrop_incoming_announce", dropTemplate.label))
                end
            end)
        end
    end
    if Config.RandomDrops.cronSchedule then 
        lib.cron.new(Config.RandomDrops.cronSchedule, function()
            local templateStack = {}
            for i=1, #Config.RandomDrops.airdropTemplates do 
                local template = Config.RandomDrops.airdropTemplates[i]
                for j=1, template.chance do 
                    table.insert(templateStack, template)
                end
            end
            local templateIndex = math.random(1, #templateStack)
            local templateId = templateStack[templateIndex].id
            local containers = templateStack[templateIndex].containers or 1
            local dropTemplate = Config.AirdropTemplates[templateId]
            local location = Config.RandomDropZones[math.random(1, #Config.RandomDropZones)]
            local coords = GetRandomPointInCircle(location.coords, location.radius)
            local heading = location.heading or math.random(0, 360)
            if Config.RandomDrops.announceScheduledDrops then
                ShowNotification(-1, _L("airdrop_incoming_announce", dropTemplate.label))
            end
            StartAirdropTemplate(templateId, {
                coords = coords,
                heading = heading,
                containers = containers,
            })
        end)
    end
end)