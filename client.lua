local safezones = {
    { coords = vec3(140.96, -3092.31, 5.9), radius = 50.0 },
    { coords = vec3(129.46, -1075.94, 29.19), radius = 30.0 },
    { coords = vec3(-451.58, -334.7, 34.36), radius = 60.0 },
    { coords = vec3(-530.42, -228.85, 35.7), radius = 60.0 },
    { coords = vec3(1467.82, 6357.97, 23.8), radius = 50.0 },
    { coords = vec3(-43.86, -1097.93, 26.42), radius = 40.0 },
    { coords = vec3(-1703.3, -1135.83, 13.15), radius = 30.0 },
    { coords = vec3(1070.72, 2310.45, 45.51), radius = 50.0 },
    { coords = vec3(712.86, 146.35, 79.75), radius = 50.0 },
    { coords = vec3(947.0, 41.17, 70.43), radius = 100.0 },

}

local dominationZones = {
    { coords = vec3(687.25, 577.5, 146.67), radius = 80.0 },
}

local drugzones = {
    { coords = vec3(1387.0, 3604.0, 38.9), radius = 80.0 },
    { coords = vec3(2434.97, 4967.01, 41.35), radius = 60.0 },
}

local inSafezone, inDomination, inDrugzone = false, false, false

-- Disable combat in safezones
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

-- Create Domination Zone blips (red radius + skull)
CreateThread(function()
    for _, zone in pairs(dominationZones) do
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipColour(blip, 1) -- Red
        SetBlipAlpha(blip, 120)

        local blipIcon = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(blipIcon, 303) -- Skull
        SetBlipScale(blipIcon, 0.0)
        SetBlipColour(blipIcon, 1)
        SetBlipAsShortRange(blipIcon, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Domination Zone")
        EndTextCommandSetBlipName(blipIcon)
    end
end)

-- Create Drug Zone blips (purple radius + pill/leaf)
CreateThread(function()
    for _, zone in pairs(drugzones) do
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipColour(blip, 7) -- Purple
        SetBlipAlpha(blip, 120)

        local blipIcon = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(blipIcon, 51) -- Pill (swap to 403 for leaf)
        SetBlipScale(blipIcon, 0.9)
        SetBlipColour(blipIcon, 7)
        SetBlipAsShortRange(blipIcon, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Drug Zone")
        EndTextCommandSetBlipName(blipIcon)
    end
end)

-- Zone detection loop
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        local isInSafe, isInDom, isInDrug = false, false, false

        for _, zone in pairs(safezones) do
            if #(pos - zone.coords) <= zone.radius then
                isInSafe = true
                break
            end
        end

        for _, zone in pairs(dominationZones) do
            if #(pos - zone.coords) <= zone.radius then
                isInDom = true
                break
            end
        end

        for _, zone in pairs(drugzones) do
            if #(pos - zone.coords) <= zone.radius then
                isInDrug = true
                break
            end
        end

        if isInSafe then
            sleep = 0
            if not inSafezone then
                inSafezone, inDomination, inDrugzone = true, false, false
                SendNUIMessage({ action = "show", zoneType = "green" })
            end
            disableCombatControls()
        elseif isInDom then
            sleep = 0
            if not inDomination then
                inDomination, inSafezone, inDrugzone = true, false, false
                SendNUIMessage({ action = "show", zoneType = "domination" })
            end
        elseif isInDrug then
            sleep = 0
            if not inDrugzone then
                inDrugzone, inSafezone, inDomination = true, false, false
                SendNUIMessage({ action = "show", zoneType = "drug" })
            end
        else
            if inSafezone or inDomination or inDrugzone then
                inSafezone, inDomination, inDrugzone = false, false, false
                SendNUIMessage({ action = "hide" })
            end
        end

        Wait(sleep)
    end
end)