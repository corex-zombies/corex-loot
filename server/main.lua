local Corex = nil
local ContainerStates = {}
local PlayerSearching = {}

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
            Debug('Info', 'Core object acquired')
            return true
        end
        attempts = attempts + 1
        Wait(1000)
    end
    Debug('Error', 'Failed to acquire core object after 30 attempts')
    return false
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, state in pairs(ContainerStates) do
        if state.dynamic and state.searchedBy then
            TriggerClientEvent('corex-loot:client:searchFailed', state.searchedBy, 'Resource stopping')
        end
    end
    ContainerStates = {}
    PlayerSearching = {}
end)

local function GetItemData(itemName)
    local ok, data = pcall(function()
        return exports['corex-inventory']:GetItemData(itemName)
    end)
    if ok and data then return data end
    local lo, up = string.lower(itemName), string.upper(itemName)
    return Items[lo] or Items[up]
        or Weapons[lo] or Weapons[up]
        or Ammo[lo] or Ammo[up]
end

local function GenerateContainerId(locIndex, containerIndex)
    return ('loc_%d_c_%d'):format(locIndex, containerIndex)
end

local function ToVec3(value)
    if not value or value.x == nil or value.y == nil or value.z == nil then
        return nil
    end

    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end
    return vector3(x, y, z)
end

local function GetContainerCoords(state)
    if not state then return nil end
    if state.coords then return ToVec3(state.coords) end

    if state.locIndex and state.containerIndex then
        local location = Config.Locations[state.locIndex]
        local container = location and location.containers and location.containers[state.containerIndex]
        return container and ToVec3(container.coords) or nil
    end

    return nil
end

local function IsPlayerNearContainer(src, state)
    local coords = GetContainerCoords(state)
    if not coords then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    if not playerCoords then return false end

    local typeData = Config.ContainerTypes[state.type] or {}
    local baseDistance = tonumber(state.interactDistance) or tonumber(typeData.interactDistance) or 2.0
    local maxDistance = baseDistance + 2.0

    return #(playerCoords - coords) <= maxDistance
end

local function RollLootTable(containerType)
    local table = Config.LootTables[containerType]
    if not table or #table == 0 then return nil end

    local roll = math.random()
    local cumulative = 0.0

    for _, tier in ipairs(table) do
        cumulative = cumulative + tier.chance
        if roll <= cumulative then
            return tier.items
        end
    end

    return table[1].items
end

local function GenerateLoot(containerType)
    local itemCount = math.random(Config.ItemsPerContainer.min, Config.ItemsPerContainer.max)
    local loot = {}

    for _ = 1, itemCount do
        local tierItems = RollLootTable(containerType)
        if tierItems and #tierItems > 0 then
            local pick = tierItems[math.random(1, #tierItems)]
            local data = GetItemData(pick.name)

            if data then
                local count = math.random(pick.min, pick.max)
                loot[#loot + 1] = {
                    name = pick.name,
                    count = count,
                    label = data.label or pick.name,
                    image = data.image or 'default.png',
                    rarity = data.rarity or 'common',
                    taken = false
                }
            else
                Debug('Warn', 'Item data not found for: ' .. pick.name)
            end
        end
    end

    if #loot == 0 then
        local fallback = GetItemData('cloth')
        loot[1] = {
            name = 'cloth',
            count = 1,
            label = fallback and fallback.label or 'Cloth',
            image = fallback and fallback.image or 'default.png',
            rarity = 'common',
            taken = false
        }
    end

    return loot
end

local function InitializeContainers()
    local total = 0
    for locIndex, location in ipairs(Config.Locations) do
        local containerType = location.type
        if not Config.ContainerTypes[containerType] then
            Debug('Warn', 'Unknown container type: ' .. tostring(containerType) .. ' at location: ' .. (location.name or '?'))
            goto continue
        end

        for containerIndex, container in ipairs(location.containers) do
            local containerId = GenerateContainerId(locIndex, containerIndex)
            ContainerStates[containerId] = {
                items = GenerateLoot(containerType),
                lootedAt = nil,
                lootedBy = nil,
                respawnAt = nil,
                type = containerType,
                locIndex = locIndex,
                containerIndex = containerIndex,
                coords = container.coords,
                interactDistance = Config.ContainerTypes[containerType].interactDistance,
                searchedBy = nil
            }
            total = total + 1
        end

        ::continue::
    end
    Debug('Info', 'Initialized ' .. total .. ' containers')
end

local function IsContainerAvailable(containerId)
    local state = ContainerStates[containerId]
    if not state then return false end
    if not state.lootedAt then return true end
    if state.respawnAt and os.time() >= state.respawnAt then return true end
    return false
end

local function RespawnContainer(containerId)
    local state = ContainerStates[containerId]
    if not state then return end

    state.items = GenerateLoot(state.type)
    state.lootedAt = nil
    state.lootedBy = nil
    state.respawnAt = nil
    state.searchedBy = nil
    state.depleted = false
end

local function GetContainerData(containerId)
    local state = ContainerStates[containerId]
    if not state then return nil end

    if state.lootedAt and state.respawnAt and os.time() >= state.respawnAt then
        RespawnContainer(containerId)
    end

    return state
end

local function MarkContainerLooted(containerId, source)
    local state = ContainerStates[containerId]
    if not state or state.depleted then return end

    if state.dynamic then
        state.searchedBy = nil
        if source then PlayerSearching[source] = nil end
        local anyLeft = false
        for _, it in ipairs(state.items) do
            if not it.taken then anyLeft = true break end
        end
        if anyLeft and not state.consumeOnClose then return end

        state.depleted = true
        state.lootedAt = os.time()
        state.lootedBy = source
        if state.onDepleted then
            local ok, err = pcall(state.onDepleted, containerId, source)
            if not ok then Debug('Error', 'onDepleted callback failed: ' .. tostring(err)) end
        end
        return
    end

    state.depleted = true
    state.lootedAt = os.time()
    state.lootedBy = source
    state.respawnAt = os.time() + math.random(Config.Respawn.minTime, Config.Respawn.maxTime)
    state.searchedBy = nil
end

local function GetContainerLabel(containerId)
    local state = ContainerStates[containerId]
    if not state then return 'Container' end
    -- Dynamic containers carry their label directly on the state
    if state.label then return state.label end
    local typeData = Config.ContainerTypes[state.type]
    return typeData and typeData.label or 'Container'
end

local function BuildClientItems(state)
    local gridCols = 8
    local gridRows = 10
    local occupied = {}

    local function isSpotFree(x, y, w, h)
        for dy = 0, h - 1 do
            for dx = 0, w - 1 do
                local key = (y + dy) .. '_' .. (x + dx)
                if occupied[key] then return false end
                if (x + dx) > gridCols or (y + dy) > gridRows then return false end
            end
        end
        return true
    end

    local function markOccupied(x, y, w, h)
        for dy = 0, h - 1 do
            for dx = 0, w - 1 do
                occupied[(y + dy) .. '_' .. (x + dx)] = true
            end
        end
    end

    local function findFreeSpot(w, h)
        for row = 1, gridRows do
            for col = 1, gridCols do
                if isSpotFree(col, row, w, h) then
                    return col, row
                end
            end
        end
        return nil, nil
    end

    local clientItems = {}
    for i, item in ipairs(state.items) do
        if not item.taken then
            local data = GetItemData(item.name)
            local w = data and data.size and data.size.w or 1
            local h = data and data.size and data.size.h or 1

            local x, y = findFreeSpot(w, h)
            if x and y then
                markOccupied(x, y, w, h)
                clientItems[#clientItems + 1] = {
                    index = i,
                    name = item.name,
                    count = item.count,
                    label = item.label,
                    image = item.image,
                    rarity = item.rarity,
                    x = x,
                    y = y
                }
            end
        end
    end
    return clientItems
end

RegisterNetEvent('corex-loot:server:requestContainer', function(containerId)
    local src = source

    if not containerId or type(containerId) ~= 'string' then
        Debug('Warn', 'Invalid containerId from source ' .. src)
        return
    end

    local state = GetContainerData(containerId)
    if not state then
        Debug('Warn', 'Container not found: ' .. containerId)
        TriggerClientEvent('corex-loot:client:searchFailed', src, 'Container not found')
        return
    end

    if not IsPlayerNearContainer(src, state) then
        Debug('Warn', ('Open rejected: player %d too far from %s'):format(src, containerId))
        TriggerClientEvent('corex-loot:client:searchFailed', src, 'Too far away')
        return
    end

    if not IsContainerAvailable(containerId) then
        Debug('Verbose', 'Container not available: ' .. containerId)
        TriggerClientEvent('corex-loot:client:searchFailed', src, 'This container has already been looted')
        return
    end

    if state.searchedBy and state.searchedBy ~= src then
        TriggerClientEvent('corex-loot:client:searchFailed', src, 'Someone else is searching this')
        return
    end

    state.searchedBy = src
    PlayerSearching[src] = containerId

    local clientItems = BuildClientItems(state)
    local label = GetContainerLabel(containerId)

    TriggerClientEvent('corex-loot:client:containerOpened', src, containerId, clientItems, label)
    Debug('Verbose', 'Player ' .. src .. ' opened container ' .. containerId .. ' with ' .. #clientItems .. ' items')
end)

RegisterNetEvent('corex-loot:server:takeItem', function(containerId, itemIndex)
    local src = source

    if type(containerId) ~= 'string' or #containerId == 0 or #containerId > 128 then return end
    if type(itemIndex) ~= 'number' or itemIndex ~= itemIndex or itemIndex == math.huge or itemIndex == -math.huge then return end

    itemIndex = math.floor(itemIndex)
    if itemIndex < 1 or itemIndex > 10000 then
        Debug('Warn', 'TakeItem: Index out of sanity bounds: ' .. tostring(itemIndex))
        return
    end

    local state = ContainerStates[containerId]
    if not state then
        Debug('Warn', 'TakeItem: Container not found: ' .. tostring(containerId))
        return
    end

    if not IsPlayerNearContainer(src, state) then
        Debug('Warn', ('TakeItem rejected: player %d too far from %s'):format(src, containerId))
        if state.searchedBy == src then state.searchedBy = nil end
        PlayerSearching[src] = nil
        TriggerClientEvent('corex-loot:client:takeResult', src, false, itemIndex, 'Too far away')
        return
    end

    if PlayerSearching[src] ~= containerId then
        Debug('Warn', 'TakeItem: Player ' .. src .. ' not searching container ' .. containerId)
        return
    end

    if itemIndex > #state.items then
        Debug('Warn', 'TakeItem: Index exceeds container items: ' .. tostring(itemIndex))
        return
    end

    local item = state.items[itemIndex]
    if not item or item.taken then
        TriggerClientEvent('corex-loot:client:takeResult', src, false, itemIndex, 'Item already taken')
        return
    end

    local callSuccess, addSuccess, addErr = pcall(function()
        return exports['corex-inventory']:AddItem(src, item.name, item.count)
    end)

    if not callSuccess then
        Debug('Error', 'AddItem export failed: ' .. tostring(addErr))
        TriggerClientEvent('corex-loot:client:takeResult', src, false, itemIndex, 'Inventory error')
        return
    end

    if not addSuccess then
        local reason = addErr or 'No inventory space'
        TriggerClientEvent('corex-loot:client:takeResult', src, false, itemIndex, reason)
        Debug('Verbose', ('TakeItem refused for %s: %s'):format(containerId, tostring(reason)))
        return
    end

    item.taken = true

    TriggerClientEvent('corex-loot:client:takeResult', src, true, itemIndex, nil)
    Debug('Info', 'Player ' .. src .. ' took ' .. item.count .. 'x ' .. item.name .. ' from ' .. containerId)

    local allTaken = true
    for _, it in ipairs(state.items) do
        if not it.taken then
            allTaken = false
            break
        end
    end

    if allTaken then
        MarkContainerLooted(containerId, src)
        if state.dynamic then
            Debug('Verbose', 'Dynamic container ' .. containerId .. ' fully looted')
        else
            Debug('Verbose', 'Container ' .. containerId .. ' fully looted, respawns at ' .. os.date('%H:%M:%S', state.respawnAt))
        end
    end
end)

RegisterNetEvent('corex-loot:server:closeContainer', function(containerId)
    local src = source

    if type(containerId) ~= 'string' then return end

    local state = ContainerStates[containerId]
    if not state then
        if PlayerSearching[src] == containerId then
            PlayerSearching[src] = nil
        end
        pcall(function()
            exports['corex-core']:ClearBusy(src)
        end)
        return
    end

    if state.searchedBy == src then
        state.searchedBy = nil
    end

    PlayerSearching[src] = nil

    local anyTaken = false
    for _, item in ipairs(state.items) do
        if item.taken then
            anyTaken = true
            break
        end
    end

    if anyTaken and not state.lootedAt then
        MarkContainerLooted(containerId, src)
        if state.dynamic then
            Debug('Verbose', 'Dynamic container ' .. containerId .. ' consumed on close')
        else
            Debug('Verbose', 'Container ' .. containerId .. ' partially looted and closed, respawns at ' .. os.date('%H:%M:%S', state.respawnAt))
        end
    end

    pcall(function()
        exports['corex-core']:ClearBusy(src)
    end)

    Debug('Verbose', 'Player ' .. src .. ' closed container ' .. containerId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local containerId = PlayerSearching[src]
    if containerId then
        local state = ContainerStates[containerId]
        if state and state.searchedBy == src then
            state.searchedBy = nil

            local anyTaken = false
            for _, item in ipairs(state.items) do
                if item.taken then anyTaken = true; break end
            end
            if anyTaken and not state.lootedAt then
                MarkContainerLooted(containerId, src)
            end
        end
        PlayerSearching[src] = nil
    end
end)

-- Respawn scanner — iterates all containers once per minute. Cheap per pass
-- (no natives, just a table walk) but we still bail early if nothing has been
-- looted to skip the loop body entirely.
CreateThread(function()
    while true do
        Wait(60000)

        local now = os.time()
        local respawned = 0

        for containerId, state in pairs(ContainerStates) do
            if state.lootedAt and state.respawnAt and now >= state.respawnAt then
                RespawnContainer(containerId)
                respawned = respawned + 1
            end
        end

        if respawned > 0 then
            Debug('Verbose', 'Respawn check: ' .. respawned .. ' containers refreshed')
        end
    end
end)

RegisterCommand('refillcontainers', function(src)
    if src > 0 then
        Debug('Warn', 'refillcontainers is server-console only')
        return
    end

    local count = 0
    for containerId, _ in pairs(ContainerStates) do
        RespawnContainer(containerId)
        count = count + 1
    end

    Debug('Info', 'Admin refilled ' .. count .. ' containers')
end, true)

CreateThread(function()
    Wait(500)
    if not InitCorex() then return end
    InitializeContainers()
end)

-- ═══════════════════════════════════════════════════════════════
-- Dynamic container API · for corex-events and other resources
-- to reuse the loot UI (grid + shimmer reveal).
--
-- Usage:
--   exports['corex-loot']:RegisterDynamicContainer('myid', items, {
--       label      = 'Supply Crate',
--       onDepleted = function(containerId, source) ... end,  -- optional
--   })
--   -- …later, when done:
--   exports['corex-loot']:UnregisterDynamicContainer('myid')
-- ═══════════════════════════════════════════════════════════════

---Register a container whose state is managed externally.
---@param containerId string Unique id
---@param items table Array of { name, count, label?, image?, rarity?, taken? }
---@param options table|nil { label?: string, onDepleted?: function, consumeOnClose?: boolean }
---@return boolean ok, string|nil err
exports('RegisterDynamicContainer', function(containerId, items, options)
    if not containerId or type(containerId) ~= 'string' then
        return false, 'invalid containerId'
    end
    if ContainerStates[containerId] then
        return false, 'containerId already registered'
    end
    if type(items) ~= 'table' then
        return false, 'items must be a table'
    end

    options = options or {}
    local normalized = {}
    for i, it in ipairs(items) do
        local data = GetItemData(it.name)
        if data then
            normalized[#normalized + 1] = {
                name   = it.name,
                count  = it.count or 1,
                label  = it.label  or data.label  or it.name,
                image  = it.image  or data.image  or 'default.png',
                rarity = it.rarity or data.rarity or 'common',
                taken  = it.taken == true,
            }
        else
            Debug('Warn', ('Dynamic container "%s": unknown item "%s" — skipped'):format(
                containerId, tostring(it.name)))
        end
    end

    ContainerStates[containerId] = {
        items      = normalized,
        lootedAt   = nil,
        lootedBy   = nil,
        respawnAt  = nil,
        type       = 'dynamic',
        locIndex   = nil,
        containerIndex = nil,
        coords     = ToVec3(options.coords or options.location or options.center),
        interactDistance = tonumber(options.interactDistance or options.distance) or 3.0,
        searchedBy = nil,
        -- Dynamic-only fields
        dynamic    = true,
        label      = options.label,
        onDepleted = options.onDepleted,
        consumeOnClose = options.consumeOnClose == true,
    }

    Debug('Info', ('Registered dynamic container "%s" with %d items'):format(
        containerId, #normalized))
    return true, nil
end)

---Remove a dynamic container (kicks out any active searcher).
---@param containerId string
---@return boolean ok
exports('UnregisterDynamicContainer', function(containerId)
    local state = ContainerStates[containerId]
    if not state then return false end
    if not state.dynamic then
        Debug('Warn', 'Refused to unregister non-dynamic container: ' .. tostring(containerId))
        return false
    end

    -- Boot out anyone currently searching it
    if state.searchedBy then
        TriggerClientEvent('corex-loot:client:searchFailed', state.searchedBy, 'Container removed')
        PlayerSearching[state.searchedBy] = nil
    end

    ContainerStates[containerId] = nil
    Debug('Info', 'Unregistered dynamic container: ' .. containerId)
    return true
end)

---Check if a dynamic container still has items.
---@param containerId string
---@return boolean hasItems
exports('DynamicContainerHasItems', function(containerId)
    local state = ContainerStates[containerId]
    if not state then return false end
    for _, it in ipairs(state.items) do
        if not it.taken then return true end
    end
    return false
end)
