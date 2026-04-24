local Corex = nil
local isReady = false
local spawnedProps = {}
local containerBlips = {}
local isSearching = false
local openContainerId = nil
local searchCancelled = false

local function Debug(level, msg)
    if not Config.Debug and level ~= 'Error' then return end
    local colors = { Error = '^1', Warn = '^3', Info = '^2', Verbose = '^5' }
    print((colors[level] or '^7') .. '[COREX-LOOT] ' .. msg .. '^0')
end

local function InitCorex()
    local attempts = 0
    while not Corex and attempts < 30 do
        local success, result = pcall(function()
            return exports['corex-core']:GetCoreObject()
        end)
        if success and result then
            Corex = result
            Debug('Info', 'Client core object acquired')
            return true
        end
        attempts = attempts + 1
        Wait(1000)
    end
    Debug('Error', 'Client failed to acquire core object')
    return false
end

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local start = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - start > 5000 then return false end
        Wait(10)
    end
    return true
end

local function DrawProgressBar(progress, text)
    local x, y = 0.5, 0.875
    local width, height = 0.18, 0.018

    DrawRect(x, y, width + 0.004, height + 0.004, 0, 0, 0, 180)
    DrawRect(x, y, width, height, 30, 30, 30, 200)

    local fillWidth = width * progress
    local fillX = x - (width / 2) + (fillWidth / 2)
    DrawRect(fillX, y, fillWidth, height - 0.004, 220, 160, 40, 230)

    if text then
        SetTextFont(4)
        SetTextScale(0.0, 0.3)
        SetTextColour(220, 220, 220, 240)
        SetTextCentre(true)
        SetTextDropshadow(1, 0, 0, 0, 200)
        SetTextEntry('STRING')
        AddTextComponentString(text)
        DrawText(x, y - 0.032)
    end
end

local function SearchContainer(entity, data)
    if isSearching then return end
    if not Corex then return end

    local ped = Corex.Functions.GetPed()
    if Corex.Functions.IsDead(ped) then return end

    local containerId = data.containerId
    local containerType = data.containerType
    local typeData = Config.ContainerTypes[containerType]
    if not typeData then return end

    isSearching = true
    searchCancelled = false

    local startCoords = Corex.Functions.GetCoords()
    local searchTime = typeData.searchTime

    if LoadAnimDict(Config.Reveal.searchAnimDict) then
        TaskPlayAnim(ped, Config.Reveal.searchAnimDict, Config.Reveal.searchAnim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    local startTime = GetGameTimer()

    CreateThread(function()
        local lastGuardCheck = 0
        while isSearching and not searchCancelled do
            Wait(0)

            local now = GetGameTimer()
            local elapsed = now - startTime
            local progress = math.min(elapsed / searchTime, 1.0)

            DrawProgressBar(progress, typeData.label .. '...')

            if elapsed >= searchTime then
                break
            end

            -- IsControlJustPressed must be polled every frame; heavier
            -- ped/coord/death checks are throttled to 5 Hz.
            if IsControlJustPressed(0, 200) then
                searchCancelled = true
                break
            end

            if now - lastGuardCheck >= 200 then
                lastGuardCheck = now
                local currentPed = Corex.Functions.GetPed()

                if Corex.Functions.IsDead(currentPed) then
                    searchCancelled = true
                    break
                end

                local currentCoords = Corex.Functions.GetCoords()
                local dx = currentCoords.x - startCoords.x
                local dy = currentCoords.y - startCoords.y
                local dz = currentCoords.z - startCoords.z
                if dx * dx + dy * dy + dz * dz > 4.0 then
                    searchCancelled = true
                    break
                end
            end
        end

        local currentPed = Corex.Functions.GetPed()
        ClearPedTasks(currentPed)

        if searchCancelled then
            isSearching = false
            searchCancelled = false
            Corex.Functions.Notify('Search cancelled', 'warning')
            return
        end

        TriggerServerEvent('corex-loot:server:requestContainer', containerId)

        CreateThread(function()
            Wait(10000)
            if isSearching then
                isSearching = false
                Corex.Functions.Notify('Server timeout - try again', 'error')
            end
        end)
    end)
end

local function SpawnContainers()
    for locIndex, location in ipairs(Config.Locations) do
        local containerType = location.type
        local typeData = Config.ContainerTypes[containerType]
        if not typeData then goto nextLocation end

        if typeData.blip then
            local firstContainer = location.containers[1]
            if firstContainer then
                local blip = AddBlipForCoord(firstContainer.coords.x, firstContainer.coords.y, firstContainer.coords.z)
                SetBlipSprite(blip, typeData.blip.sprite)
                SetBlipColour(blip, typeData.blip.color)
                SetBlipScale(blip, typeData.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(typeData.blip.label)
                EndTextCommandSetBlipName(blip)

                containerBlips[#containerBlips + 1] = blip
            end
        end

        for containerIndex, container in ipairs(location.containers) do
            local containerId = ('loc_%d_c_%d'):format(locIndex, containerIndex)
            local model = typeData.model

            local prop = Corex.Functions.SpawnProp(model, container.coords, {
                placeOnGround = false,
                networked = false,
                freeze = true
            })

            if prop then
                SetEntityHeading(prop, container.heading)

                local ok = pcall(function()
                    exports['corex-core']:AddTarget(prop, {
                        text = typeData.interactLabel,
                        icon = typeData.icon,
                        distance = typeData.interactDistance,
                        event = 'corex-loot:client:searchContainer',
                        data = {
                            containerId = containerId,
                            containerType = containerType
                        }
                    })
                end)

                if not ok then
                    Debug('Error', 'Failed to add target for container ' .. containerId)
                end

                spawnedProps[#spawnedProps + 1] = {
                    prop = prop,
                    containerId = containerId,
                    locData = container
                }

                Debug('Verbose', 'Spawned container ' .. containerId .. ' (' .. typeData.label .. ')')
            else
                Debug('Error', 'Failed to spawn prop for container ' .. containerId)
            end
        end

        ::nextLocation::
    end

    Debug('Info', 'Spawned ' .. #spawnedProps .. ' container props and ' .. #containerBlips .. ' blips')
end

local function CleanupAll()
    for _, entry in ipairs(spawnedProps) do
        if entry.prop and DoesEntityExist(entry.prop) then
            pcall(function()
                exports['corex-core']:RemoveTarget(entry.prop)
            end)
            Corex.Functions.DeleteProp(entry.prop)
        end
    end
    spawnedProps = {}

    for _, blip in ipairs(containerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    containerBlips = {}

    isSearching = false
    searchCancelled = false
    openContainerId = nil

    Debug('Info', 'Cleanup complete')
end

RegisterNetEvent('corex-loot:client:searchContainer', function(entity, data)
    SearchContainer(entity, data)
end)

RegisterNetEvent('corex-loot:client:containerOpened', function(containerId, items, containerLabel)
    isSearching = false
    openContainerId = containerId

    TriggerEvent('corex-inventory:client:openLootContainer', containerId, items, containerLabel, Config.Reveal.itemRevealDelay)

    Debug('Verbose', 'Container opened: ' .. containerId .. ' with ' .. #items .. ' items')
end)

RegisterNetEvent('corex-loot:client:searchFailed', function(reason)
    isSearching = false
    if Corex then
        Corex.Functions.Notify(reason or 'Search failed', 'error')
    end
end)

RegisterNetEvent('corex-loot:client:takeResult', function(success, itemIndex, errorMsg)
    if success then
        TriggerEvent('corex-inventory:client:lootItemTaken', itemIndex)
    else
        if Corex then
            Corex.Functions.Notify(errorMsg or 'Could not take item', 'error')
        end
    end
end)

RegisterNetEvent('corex-loot:client:containerClosed', function(containerId)
    if not containerId then
        containerId = openContainerId
    end

    if containerId then
        TriggerServerEvent('corex-loot:server:closeContainer', containerId)
    end

    openContainerId = nil
    isSearching = false
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupAll()
end)

CreateThread(function()
    Wait(500)
    if not InitCorex() then return end

    Corex.Functions.WaitForPlayerData(15000)
    isReady = true

    SpawnContainers()
    Debug('Info', 'Client initialized')
end)
