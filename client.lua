local QBCore = exports['qb-core']:GetCoreObject()
local previewProp = nil
local placedProps = {}

RegisterCommand('spawnprop', function(source, args)
    local objectName = table.concat(args, " ")
    if objectName ~= "" then
        TriggerEvent('spawnprop:client:previewProp', objectName)
    else
        QBCore.Functions.Notify("Usage: /spawnprop <propname>", "error")
    end
end, false)

RegisterNetEvent('spawnprop:client:previewProp')
AddEventHandler('spawnprop:client:previewProp', function(objectName)
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnPos = pos + forward * 2.0 -- Adjust distance from player

    local propHash = GetHashKey(objectName)
    if not IsModelInCdimage(propHash) or not IsModelValid(propHash) then
        QBCore.Functions.Notify("Invalid object name.", "error")
        return
    end

    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(1)
    end

    -- Remove previous preview prop if exists
    if previewProp then
        DeleteObject(previewProp)
        previewProp = nil
    end

    -- Create preview prop
    previewProp = CreateObject(propHash, spawnPos.x, spawnPos.y, spawnPos.z, true, true, true)
    PlaceObjectOnGroundProperly(previewProp)
    SetEntityAsMissionEntity(previewProp, true, true)
    SetEntityVisible(previewProp, true) -- Show the preview prop
    FreezeEntityPosition(previewProp, true) -- Ensure prop has collision

    -- Show controls for placing the prop
    DisplayHelpText("Press ~INPUT_CONTEXT~ to place prop, ~INPUT_FRONTEND_LEFT~ to rotate left, ~INPUT_FRONTEND_RIGHT~ to rotate right.")

    -- Wait for user input to place the prop
    while true do
        Wait(0)

        -- Update preview prop position based on player's position and forward vector
        local pos = GetEntityCoords(playerPed)
        local forward = GetEntityForwardVector(playerPed)
        local spawnPos = pos + forward * 2.0 -- Adjust distance from player
        
        SetEntityCoordsNoOffset(previewProp, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)

        -- Handle rotation controls
        if IsControlPressed(0, 175) then -- INPUT_FRONTEND_RIGHT (Right Arrow key)
            -- Rotate the prop to the right
            local heading = GetEntityHeading(previewProp)
            SetEntityHeading(previewProp, heading + 2.0)
        elseif IsControlPressed(0, 174) then -- INPUT_FRONTEND_LEFT (Left Arrow key)
            -- Rotate the prop to the left
            local heading = GetEntityHeading(previewProp)
            SetEntityHeading(previewProp, heading - 2.0)
        end

        -- Check for control inputs
        if IsControlJustReleased(0, 51) then -- INPUT_CONTEXT (E key by default)
            -- Place the prop
            PlaceProp(objectName, spawnPos)
            return
        elseif IsControlJustReleased(0, 177) then -- INPUT_FRONTEND_CANCEL (ESC key by default)
            -- Cancel preview and clean up
            CancelPreview()
            return
        end
    end
end)

RegisterCommand('deleteprop', function(source, args)
    TriggerEvent('spawnprop:client:deleteNearestProp')
end, false)

RegisterNetEvent('spawnprop:client:deleteNearestProp')
AddEventHandler('spawnprop:client:deleteNearestProp', function()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)

    -- Search for the nearest prop within a radius
    local object = nil
    local handle, object = FindFirstObject()
    local success
    repeat
        local posObj = GetEntityCoords(object)
        local distance = #(pos - posObj)
        if distance < 2.0 then
            DeleteEntity(object)
            table.insert(placedProps, object)
            success = true
        end
        success, object = FindNextObject(handle, object)
    until not success

    EndFindObject(handle)
end)

function PlaceProp(objectName, coords)
    if previewProp then
        SetEntityCoordsNoOffset(previewProp, coords.x, coords.y, coords.z, true, true, true)
        FreezeEntityPosition(previewProp, false) -- Allow movement
        
        -- Drop the prop to the ground
        PlaceObjectOnGroundProperly(previewProp)
        FreezeEntityPosition(previewProp, true) -- Ensure prop stays in place
        
        QBCore.Functions.Notify("Prop placed successfully: " .. tostring(objectName))
        
        -- Add the placed prop to the list
        table.insert(placedProps, previewProp)
        
        -- Reset preview prop
        previewProp = nil
    end
end

function CancelPreview()
    if previewProp then
        DeleteObject(previewProp)
        previewProp = nil
    end
end

function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end
