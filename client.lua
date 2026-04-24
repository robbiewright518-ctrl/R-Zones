local inZoneType = nil
local zoneBlips = {}

local function disableCombatControls()
    local ped = PlayerPedId()
    DisablePlayerFiring(ped, true)
    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 25, true) -- Aim

    DisableControlAction(0, 257, true) -- Melee attack
    DisableControlAction(0, 263, true) -- Weapon select
    DisableControlAction(0, 140, true) -- Melee light attack
    DisableControlAction(0, 141, true) -- Melee heavy attack
    DisableControlAction(0, 142, true) -- Melee alternate attack
    DisableControlAction(0, 143, true) -- Enter cover
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end

local function clearBlips()
    for _, blip in ipairs(zoneBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    zoneBlips = {}
end

local function createZoneBlip(coords, radius, typeCfg)
    local blipsCfg = Config.Blips or {}
    if blipsCfg.enabled == false then
        return
    end

    local rad = AddBlipForRadius(coords.x, coords.y, coords.z, radius)
    SetBlipColour(rad, typeCfg.blipColor or 0)
    SetBlipAlpha(rad, blipsCfg.alpha or 120)
    table.insert(zoneBlips, rad)

    local icon = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(icon, typeCfg.blipSprite or 1)
    SetBlipScale(icon, typeCfg.blipScale or 0.9)
    SetBlipColour(icon, typeCfg.blipColor or 0)
    SetBlipAsShortRange(icon, blipsCfg.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(typeCfg.label or 'Zone')
    EndTextCommandSetBlipName(icon)
    table.insert(zoneBlips, icon)
end

CreateThread(function()
    Wait(0)

    if Config.Enabled == false then
        clearBlips()
        return
    end

    clearBlips()

    for zoneType, list in pairs(Config.Zones or {}) do
        local typeCfg = (Config.ZoneTypes and Config.ZoneTypes[zoneType]) or {}
        if typeCfg.enabled ~= false then
            for _, zone in ipairs(list) do
                if zone.enabled ~= false then
                    createZoneBlip(zone.coords, zone.radius, typeCfg)
                end
            end
        end
    end
end)

local function isTypeEnabled(zoneType)
    local typeCfg = Config.ZoneTypes and Config.ZoneTypes[zoneType] or nil
    if not typeCfg then
        return false
    end
    return typeCfg.enabled ~= false
end

local function getTypeConfig(zoneType)
    return (Config.ZoneTypes and Config.ZoneTypes[zoneType]) or {}
end

local function findCurrentZoneType(pos)
    local bestType = nil
    local bestDist = nil

    for zoneType, list in pairs(Config.Zones or {}) do
        if isTypeEnabled(zoneType) then
            for _, zone in ipairs(list) do
                if zone.enabled ~= false then
                    local d = #(pos - zone.coords)
                    if d <= (zone.radius or 0.0) then
                        if not bestDist or d < bestDist then
                            bestType = zoneType
                            bestDist = d
                        end
                    end
                end
            end
        end
    end

    return bestType
end

local function getNearestEnabledZoneDistance(pos)
    local nearest = nil
    for zoneType, list in pairs(Config.Zones or {}) do
        if isTypeEnabled(zoneType) then
            for _, zone in ipairs(list) do
                if zone.enabled ~= false then
                    local d = #(pos - zone.coords) - (zone.radius or 0.0)
                    if d < 0.0 then
                        d = 0.0
                    end
                    if not nearest or d < nearest then
                        nearest = d
                    end
                end
            end
        end
    end
    return nearest
end

local function drawSphereAtZone(zone, typeCfg)
    local spheresCfg = Config.Spheres or {}
    if spheresCfg.enabled == false then
        return
    end

    local radius = zone.radius or 50.0

    local opacity = spheresCfg.opacity
    if type(opacity) ~= 'number' then
        local alpha = spheresCfg.alpha
        if type(alpha) == 'number' then
            opacity = alpha / 255.0
        else
            opacity = 0.35
        end
    end

    if opacity < 0.0 then opacity = 0.0 end
    if opacity > 1.0 then opacity = 1.0 end

    local col = typeCfg.sphereColor or { 255, 255, 255 }

    DrawSphere(
        zone.coords.x, zone.coords.y, zone.coords.z,
        radius,
        col[1] or 255, col[2] or 255, col[3] or 255,
        opacity
    )
end

CreateThread(function()
    while true do
        if Config.Enabled == false then
            if inZoneType ~= nil then
                inZoneType = nil
                SendNUIMessage({ action = 'hide' })
            end
            Wait(1000)
            goto continue
        end

        local sleep = 500
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        local perf = Config.Performance or {}
        local insideSleep = perf.insideSleep or 0
        local nearSleep = perf.nearSleep or 150
        local farSleep = perf.farSleep or 750
        local nearDist = perf.nearDistance or 120.0

        local currentType = findCurrentZoneType(pos)
        local nearest = getNearestEnabledZoneDistance(pos)

        if currentType then
            sleep = insideSleep
        elseif nearest and nearest <= nearDist then
            sleep = nearSleep
        else
            sleep = farSleep
        end

        if currentType ~= inZoneType then
            inZoneType = currentType
            if inZoneType then
                local typeCfg = getTypeConfig(inZoneType)
                SendNUIMessage({ action = 'show', zoneType = typeCfg.nuiType or inZoneType })
            else
                SendNUIMessage({ action = 'hide' })
            end
        end

        if inZoneType then
            local typeCfg = getTypeConfig(inZoneType)
            if typeCfg.disableCombat == true then
                disableCombatControls()
            end
        end

        local spheresCfg = Config.Spheres or {}
        if spheresCfg.enabled ~= false then
            local drawDist = spheresCfg.visibleDistance or 250.0
            local bestZone = nil
            local bestDist = nil

            for zoneType, list in pairs(Config.Zones or {}) do
                if isTypeEnabled(zoneType) then
                    local typeCfg = getTypeConfig(zoneType)
                    for _, zone in ipairs(list) do
                        if zone.enabled ~= false then
                            local d = #(pos - zone.coords)
                            if d <= drawDist then
                                if not bestDist or d < bestDist then
                                    bestZone = { zone = zone, typeCfg = typeCfg }
                                    bestDist = d
                                end
                            end
                        end
                    end
                end
            end

            if bestZone then
                drawSphereAtZone(bestZone.zone, bestZone.typeCfg)
                sleep = 0
            end
        end

        Wait(sleep)

        ::continue::
    end
end)
