local LocalAirdrops = {}
local skyHeight = 100.0

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

function CreateLocalAirdrop(id, data)
    if LocalAirdrops[id] then
        return
    end
    LocalAirdrops[id] = {
        id = id,
        coords = data.coords,
        heading = data.heading,
        items = data.items,
    }
    local dropModel = `sm_prop_smug_crate_01a`
    local parachuteModel = `gr_prop_gr_para_s_01`
    local dropType = "object"
    local planeSpeed = 1.0
    local dropSpeed = 0.2
    LocalAirdrops[id].planeObject = CreateProp(`prop_tennis_ball`, data.coords.x, data.coords.y, data.coords.z + skyHeight, false, false, false)
    SetEntityHeading(LocalAirdrops[id].planeObject, data.heading)
    local forwardVector = GetEntityForwardVector(LocalAirdrops[id].planeObject)
    local planeCoords = data.coords + forwardVector * -(planeSpeed * 100)
    planeCoords = vector3(planeCoords.x, planeCoords.y, planeCoords.z + skyHeight)
    local dropCoords = vector3(data.coords.x, data.coords.y, data.coords.z + skyHeight)
    LocalAirdrops[id].plane = CreateVeh(`jet`, planeCoords.x, planeCoords.y, planeCoords.z, 0.0, false, false)
    FreezeEntityPosition(LocalAirdrops[id].plane, true)
    SetEntityCollision(LocalAirdrops[id].plane, false, false)
    SetEntityInvincible(LocalAirdrops[id].plane, true)
    AttachEntityToEntity(LocalAirdrops[id].plane, LocalAirdrops[id].planeObject, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    CreateThread(function()
        local landed = false
        while LocalAirdrops[id] do
            local airdrop = LocalAirdrops[id]
            if airdrop.planeObject then
                planeCoords = planeCoords + forwardVector * planeSpeed
                SetEntityCoords(LocalAirdrops[id].planeObject, planeCoords.x, planeCoords.y, planeCoords.z)
            end
            if not landed then
                print("RUN")
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
                    end
                elseif #(dropCoords - data.coords) > 1.0 then
                    dropCoords = dropCoords - vector3(0.0, 0.0, dropSpeed)
                    SetEntityCoordsNoOffset(airdrop.dropObject, dropCoords.x, dropCoords.y, dropCoords.z)
                else
                    print("STOP")
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
                end
            end
            Wait(0)
        end
    end)
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
    LocalAirdrops[id] = nil
end

CreateThread(function()
    while not Inventory or not Inventory.Ready do Wait(100) end
    SendNUIMessage({
        type = "setConfig",
        config = {
            items = Inventory.Items,
        }
    })
end)

RegisterNetEvent("pickle_airdrops:startAirdrop", function(id, data)
    CreateLocalAirdrop(id, data)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent("pickle_airdrops:initializePlayer")
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for id, airdrop in pairs(LocalAirdrops) do
            DeleteLocalAirdrop(id)
        end
    end
end)