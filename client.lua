local Config = {
    Position = 'right', -- 'left' or 'right'
    ShowStreet = true,
    ShowCompass = true,
    ShowVehicle = true,
    UpdateInterval = 250,
    Unit = 'mph', -- 'mph' or 'kmh'
    Framework = 'auto', -- 'auto', 'esx', 'qb', or 'standalone'
}

local state = {
    health = 100,
    armor = 0,
    hunger = 100,
    thirst = 100,
    stamina = 100,
    stress = 0,
    voice = 1,
    talking = false,
    pause = false
}

local framework = 'standalone'
local playerLoaded = true

CreateThread(function()
    if Config.Framework == 'auto' or Config.Framework == 'esx' then
        if GetResourceState('es_extended') == 'started' then
            framework = 'esx'
            playerLoaded = false
            RegisterNetEvent('esx:playerLoaded', function() playerLoaded = true end)
            RegisterNetEvent('esx:onPlayerLogout', function() playerLoaded = false end)
        end
    end
    if framework == 'standalone' and (Config.Framework == 'auto' or Config.Framework == 'qb') then
        if GetResourceState('qb-core') == 'started' then
            framework = 'qb'
            playerLoaded = false
            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerLoaded = true end)
            RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() playerLoaded = false end)
        end
    end
end)

RegisterNetEvent('custom_hud:setStatus', function(values)
    if type(values) ~= 'table' then return end
    for _, key in ipairs({ 'hunger', 'thirst', 'stress' }) do
        local value = tonumber(values[key])
        if value then state[key] = math.max(0, math.min(100, value)) end
    end
end)

RegisterNetEvent('custom_hud:setNeeds', function(hunger, thirst)
    local h, t = tonumber(hunger), tonumber(thirst)
    if h then state.hunger = math.max(0, math.min(100, h)) end
    if t then state.thirst = math.max(0, math.min(100, t)) end
end)

RegisterNetEvent('custom_hud:setStress', function(stress)
    local value = tonumber(stress)
    if value then state.stress = math.max(0, math.min(100, value)) end
end)

RegisterNetEvent('custom_hud:setVoice', function(level)
    local value = tonumber(level)
    if value then state.voice = math.max(1, math.min(3, value)) end
end)

RegisterNetEvent('custom_hud:setVisible', function(visible)
    SendNUIMessage({ action = 'visibility', visible = visible == true })
end)

RegisterCommand('hud', function()
    SendNUIMessage({ action = 'toggle' })
end, false)

local function getStreetData(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
    return street or '', crossing
end

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        local ped = PlayerPedId()
        if not DoesEntityExist(ped) then
            SendNUIMessage({ action = 'visibility', visible = false })
        else
            local pause = IsPauseMenuActive()
            local health = math.max(0, GetEntityHealth(ped) - 100)
            local maxHealth = math.max(1, GetEntityMaxHealth(ped) - 100)
            state.health = math.floor(math.min(100, (health / maxHealth) * 100))
            state.armor = math.floor(math.min(100, GetPedArmour(ped)))
            state.stamina = math.floor(100.0 - GetPlayerSprintStaminaRemaining(PlayerId()))
            state.talking = NetworkIsPlayerTalking(PlayerId())
            if framework == 'esx' and playerLoaded then
                TriggerEvent('esx_status:getStatus', 'hunger', function(status)
                    if status and status.getPercent then state.hunger = math.max(0, math.min(100, status.getPercent())) end
                end)
                TriggerEvent('esx_status:getStatus', 'thirst', function(status)
                    if status and status.getPercent then state.thirst = math.max(0, math.min(100, status.getPercent())) end
                end)
            elseif framework == 'qb' and playerLoaded then
                local ok, playerData = pcall(function() return exports['qb-core']:GetCoreObject().Functions.GetPlayerData() end)
                if ok and playerData and playerData.metadata then
                    state.hunger = math.max(0, math.min(100, tonumber(playerData.metadata.hunger) or state.hunger))
                    state.thirst = math.max(0, math.min(100, tonumber(playerData.metadata.thirst) or state.thirst))
                    state.stress = math.max(0, math.min(100, tonumber(playerData.metadata.stress) or state.stress))
                end
            end

            local coords = GetEntityCoords(ped)
            local street, crossing = getStreetData(coords)
            local heading = GetEntityHeading(ped)
            local directions = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }
            local direction = directions[(math.floor((heading + 22.5) / 45.0) % 8) + 1]
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local vehicleData = nil

            if Config.ShowVehicle and inVehicle then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = GetEntitySpeed(vehicle) * (Config.Unit == 'kmh' and 3.6 or 2.236936)
                local fuel = GetVehicleFuelLevel(vehicle)
                local gear = GetVehicleCurrentGear(vehicle)
                local engine = GetIsVehicleEngineRunning(vehicle)
                vehicleData = {
                    speed = math.floor(speed + 0.5),
                    unit = Config.Unit == 'kmh' and 'KM/H' or 'MPH',
                    fuel = math.floor(math.max(0, math.min(100, fuel))),
                    gear = speed < 1 and 'P' or (gear == 0 and 'R' or tostring(gear)),
                    engine = engine,
                    seatbelt = LocalPlayer.state.seatbelt == true
                }
            end

            SendNUIMessage({
                action = 'update',
                visible = not pause and playerLoaded,
                position = Config.Position,
                showStreet = Config.ShowStreet,
                showCompass = Config.ShowCompass,
                showVehicle = Config.ShowVehicle,
                status = state,
                location = { street = street, crossing = crossing, direction = direction },
                vehicle = vehicleData
            })
            state.pause = pause
        end
    end
end)
