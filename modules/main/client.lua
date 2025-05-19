local LocalAirdrops = {}
local skyHeight = 500.0
local CurrentAirdropContainer = nil

function SetEntityScale(entity, scale)
    if not entity or not DoesEntityExist(entity) then return end
    local minVec, maxVec = GetModelDimensions(GetEntityModel(entity))
    local height = maxVec.z - minVec.z
    local forwardVector, rightVector, upVector, position  = GetEntityMatrix(entity)
    local newMatrix = {
        forward = forwardVector * scale,
        right = rightVector * scale,
        up = upVector * scale,
    }
    SetEntityMatrix(entity, 
        newMatrix.forward.x, newMatrix.forward.y, newMatrix.forward.z,
        newMatrix.right.x, newMatrix.right.y, newMatrix.right.z,
        newMatrix.up.x, newMatrix.up.y, newMatrix.up.z, 
        position.x, position.y, position.z + height * (scale - 1.0) / 2.0
    )
end

function CreateScriptedBlip(obj, blipType)
    local blipCfg = Config.Blips[blipType]
    if not blipCfg then return end
    local blip = type(obj) == "number" and AddBlipForEntity(obj) or AddBlipForCoord(obj.x, obj.y, obj.z)
    SetBlipSprite(blip, blipCfg.sprite or 1)
    SetBlipColour(blip, blipCfg.color or 1)
    SetBlipScale(blip, blipCfg.scale or 0.8)
    SetBlipCategory(blip, blipCfg.category or 0)
    SetBlipDisplay(blip, blipCfg.display or 4)
    if type(obj) == "number" then
        SetBlipRotation(blip, math.ceil(GetEntityHeading(obj)))
    end
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_L(blipType))
    EndTextCommandSetBlipName(blip)
    local radiusBlip = nil
    if blipCfg.radius then
        radiusBlip = AddBlipForRadius(obj.x, obj.y, obj.z, blipCfg.radius.size or 10.0)
        SetBlipAlpha(radiusBlip, 128)
        SetBlipColour(radiusBlip, blipCfg.radius.color or 1)
    end
    return {blip = blip, radiusBlip = radiusBlip}
end

function CreateLocalAirdrop(id, data)
    if LocalAirdrops[id] then
        return
    end
    LocalAirdrops[id] = {
        id = id,
        coords = data.coords,
        heading = data.heading,
        items = data.items,
        maxSlots = data.maxSlots,
    }
    local dropModel = `sm_prop_smug_crate_01a`
    local parachuteModel = `gr_prop_gr_para_s_01`
    local dropType = "object"
    local planeSpeed = 2.0
    local dropSpeed = 0.2
    
    LocalAirdrops[id].planeObject = CreateProp(`prop_tennis_ball`, data.coords.x, data.coords.y, data.coords.z + skyHeight, false, false, false)
    SetEntityHeading(LocalAirdrops[id].planeObject, data.heading)
    local forwardVector = GetEntityForwardVector(LocalAirdrops[id].planeObject)
    local planeCoords = vector3(data.coords.x, data.coords.y, data.coords.z + skyHeight) --+ forwardVector * -(planeSpeed * 1000)
    local planeDespawnCoords = vector3(data.coords.x, data.coords.y, data.coords.z + skyHeight) + forwardVector * (planeSpeed * 1000)
    local dropCoords = vector3(data.coords.x, data.coords.y, data.coords.z + 1)--(skyHeight - 10.0))
    LocalAirdrops[id].plane = CreateVeh(`jet`, planeCoords.x, planeCoords.y, planeCoords.z, 0.0, false, false)
    FreezeEntityPosition(LocalAirdrops[id].plane, true)
    SetEntityCollision(LocalAirdrops[id].plane, false, false)
    SetEntityInvincible(LocalAirdrops[id].plane, true)
    AttachEntityToEntity(LocalAirdrops[id].plane, LocalAirdrops[id].planeObject, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    LocalAirdrops[id].planeBlip = CreateScriptedBlip(LocalAirdrops[id].plane, "airdrop_plane_blip")
    CreateThread(function()
        local landed = false
        while LocalAirdrops[id] do
            local airdrop = LocalAirdrops[id]
            if airdrop.planeObject then
                planeCoords = planeCoords + forwardVector * planeSpeed
                SetEntityCoords(LocalAirdrops[id].planeObject, planeCoords.x, planeCoords.y, planeCoords.z)
                if #(planeCoords - planeDespawnCoords) < 50.0 then
                    DeleteEntity(airdrop.planeObject)
                    DeleteEntity(airdrop.plane)
                    RemoveScriptedBlip(airdrop.planeBlip)
                    LocalAirdrops[id].planeObject = nil
                    LocalAirdrops[id].plane = nil
                    LocalAirdrops[id].planeBlip = nil
                end
            end
            if not landed then
                if not airdrop.dropObject then
                    local target2d = vector3(data.coords.x, data.coords.y, 0.0)
                    local plane2d = vector3(planeCoords.x, planeCoords.y, 0.0)
                    if #(target2d - plane2d) < 10.0 then
                        if (dropType == "vehicle") then
                            airdrop.dropObject = CreateVeh(dropModel, dropCoords.x, dropCoords.y, dropCoords.z, data.heading, false, false)
                        else
                            airdrop.dropObject = CreateProp(dropModel, dropCoords.x, dropCoords.y, dropCoords.z, false, false, false)
                        end
                        SetEntityHeading(airdrop.dropObject, data.heading)
                        FreezeEntityPosition(airdrop.dropObject, true)
                        SetEntityInvincible(airdrop.dropObject, true)
                        local minVec, maxVec = GetModelDimensions(dropModel)
                        local height = maxVec.z - minVec.z
                        local paraMinVec, paraMaxVec = GetModelDimensions(parachuteModel)
                        local paraHeight = paraMaxVec.z - paraMinVec.z
                        airdrop.parachute = CreateProp(parachuteModel, dropCoords.x, dropCoords.y, dropCoords.z, false, false, false)
                        AttachEntityToEntity(airdrop.parachute, airdrop.dropObject, 0, 0.0, 0.0, height + (paraHeight - 2.3), 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        airdrop.dropBlip = CreateScriptedBlip(vector3(data.coords.x, data.coords.y, data.coords.z), "airdrop_container_blip")
                        print(json.encode(airdrop.dropBlip))
                    end
                elseif #(dropCoords - data.coords) > 1.0 then
                    dropCoords = dropCoords - vector3(0.0, 0.0, dropSpeed)
                    SetEntityCoordsNoOffset(airdrop.dropObject, dropCoords.x, dropCoords.y, dropCoords.z)
                else
                    landed = true
                    SetEntityCoords(airdrop.dropObject, data.coords.x, data.coords.y, data.coords.z)
                    if dropType == "vehicle" then
                        SetVehicleOnGroundProperly(airdrop.dropObject)
                    else
                        PlaceObjectOnGroundProperly(airdrop.dropObject)
                    end
                    SetEntityCollision(airdrop.dropObject, true, true)
                    SetEntityInvincible(airdrop.dropObject, false)
                    FreezeEntityPosition(airdrop.dropObject, false)
                    CreateThread(function()
                        DetachEntity(airdrop.parachute, false, false)
                        FreezeEntityPosition(airdrop.parachute, true)
                        local scale = 1.0
                        while scale > 0.0 do
                            scale = scale - 0.01
                            if scale < 0.0 then
                                scale = 0.0
                            end
                            SetEntityScale(airdrop.parachute, scale)
                            Wait(0)
                        end
                        DeleteEntity(airdrop.parachute)
                    end)
                    LocalAirdrops[id].interact = CreateInteraction({
                        label = _L("airdrop_interact"),
                        icon = Config.TargetIcons and Config.TargetIcons["airdrop_container"] or nil,
                        coords = data.coords + vector3(0.0, 0.0, 1.0),
                        heading = data.heading,
                        radius = 1.25
                    }, function(selected)
                        AirdropInteraction(id)
                    end)
                end
            end
            Wait(0)
        end
    end)
end

function RemoveScriptedBlip(obj)
    if type(obj) == "number" then
        RemoveBlip(obj)
    else
        if obj.blip then
            RemoveBlip(obj.blip)
        end
        if obj.radiusBlip then
            RemoveBlip(obj.radiusBlip)
        end
    end
end

function DeleteLocalAirdrop(id)
    if not id or not LocalAirdrops[id] then return end
    local airdrop = LocalAirdrops[id]
    if airdrop.plane then
        DeleteVehicle(airdrop.plane)
    end
    if airdrop.planeObject then
        DeleteEntity(airdrop.planeObject)
    end
    if airdrop.dropObject then
        DeleteEntity(airdrop.dropObject)
    end
    if airdrop.parachute then
        DeleteEntity(airdrop.parachute)
    end
    if airdrop.planeBlip then
        RemoveScriptedBlip(airdrop.planeBlip)
    end
    if airdrop.dropBlip then
        RemoveScriptedBlip(airdrop.dropBlip)
    end
    LocalAirdrops[id] = nil
end

function AirdropInteraction(id)
    if not LocalAirdrops[id] then return end
    CurrentAirdropContainer = {id = id}
    local airdrop = LocalAirdrops[id]
    SendNUIMessage({
        type = "setContainerInfo",
        containerInfo = {
            id = id,
            items = airdrop.items,
            maxSlots = airdrop.maxSlots,
        }
    })
    SetNuiFocus(true, true)
    TransitionToBlurred(250)
end

function ExitAirdropContainer()
    if not CurrentAirdropContainer then return end
    SetNuiFocus(false, false)
    TransitionFromBlurred(250)
    SendNUIMessage({
        type = "setContainerInfo",
    })
    CurrentAirdropContainer = nil
end

CreateThread(function()
    local renderingAirdrop = nil
    while true do 
        local wait = 1500
        local closestAirdrop = nil
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k,v in pairs(LocalAirdrops) do 
            local distance = #(playerCoords - v.coords)
            if distance < (Config.InteractDistance * 4) and (not closestAirdrop or distance < closestAirdrop.distance) then
                closestAirdrop = {id = k, distance = distance}
            end
        end
        if closestAirdrop then
            wait = 0
            local airdrop = LocalAirdrops[closestAirdrop.id]
            local coords = airdrop.coords + vector3(0.0, 0.0, 1.0)
            local playerPed = PlayerPedId()
            local renderDistance = 5.0
            local distance = #(GetEntityCoords(playerPed) - coords)
            if distance > renderDistance then
                distance = renderDistance
            end
            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
            local scalar = 1.0 - (distance / renderDistance)
            local scale = lerp(0.0, 1.5, scalar)
            if scale > 1.0 then
                scale = 1.0
            end
            if onScreen then
                renderingAirdrop = closestAirdrop
                SendNUIMessage({
                    type = "updateAirdropContainerHUD",
                    container = {
                        position = { x = screenX, y = screenY },
                        scale = scale,
                        image = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNVTHQLETxbGkAi69ERatzLAjw24-gM4ERfQ&s",
                        label = "Airdrop Container",
                        description = "Loot the airdrop container",
                    },
                })
            elseif renderingAirdrop then
                renderingAirdrop = nil
                SendNUIMessage({
                    type = "updateAirdropContainerHUD",
                    container = nil,
                })
            end
        elseif renderingAirdrop then
            renderingAirdrop = nil
            SendNUIMessage({
                type = "updateAirdropContainerHUD",
                container = nil,
            })
        end
        Wait(wait)
    end
end)

RegisterNUICallback("pageLoaded", function(data, cb)
    while not Inventory or not Inventory.Ready do Wait(100) end
    SendNUIMessage({
        type = "setConfig",
        config = {
            locale = Language[Config.Language],
            items = Inventory.Items,
            imageDirectory = Config.ImageDirectory,
        }
    })
    cb("ok")
end)

RegisterNUICallback("exitInterface", function(data, cb)
    if not CurrentAirdropContainer then return end
    ExitAirdropContainer()
    cb("ok")
end)

RegisterNUICallback("updateAirdropContainerItemStatus", function(data, cb)
    TriggerServerEvent("pickle_airdrops:updateAirdropContainerItemStatus", CurrentAirdropContainer.id, data.slot, data.status)
    cb("ok")
end)

RegisterNUICallback("takeAirdropContainerItem", function(data, cb)
    TriggerServerEvent("pickle_airdrops:takeAirdropContainerItem", CurrentAirdropContainer.id, data.slot)
    cb("ok")
end)

RegisterNetEvent("pickle_airdrops:startAirdrop", function(id, data)
    CreateLocalAirdrop(id, data)
end)

RegisterNetEvent("pickle_airdrops:removeAirdrop", function(id)
    if CurrentAirdropContainer and CurrentAirdropContainer.id == id then
        ExitAirdropContainer()
    end
    if LocalAirdrops[id] then
        DeleteLocalAirdrop(id)
    end
end)

RegisterNetEvent("pickle_airdrops:updateAirdropContainerItems", function(id, items)
    if not LocalAirdrops[id] then return end
    LocalAirdrops[id].items = items
    if CurrentAirdropContainer and CurrentAirdropContainer.id == id then
        SendNUIMessage({
            type = "updateAirdropContainerItems",
            items = items,
        })
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent("pickle_airdrops:initializePlayer")
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if CurrentAirdropContainer then
            SetNuiFocus(false, false)
            TransitionFromBlurred(0)
        end
        for id, airdrop in pairs(LocalAirdrops) do
            DeleteLocalAirdrop(id)
        end
    end
end)