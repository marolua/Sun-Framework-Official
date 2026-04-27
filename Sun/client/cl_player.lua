Sun.playerData = {
    identifier = nil,
    name = nil,
    group = "user",
    loadout = {},
    money = {
        cash = 0,
        bank = 0,
        black = 0,
    },
    job = {
        legal = {
            name = "unemployed",
            grade = 0,
            label = "Unemployed",
            gradeLabel = "",
            salary = 0,
        },
        illegal = {
            name = nil,
            grade = 0,
            label = "",
            gradeLabel = "",
            salary = 0,
        },
    },
    meta = {},
}

Sun.Permissions = Sun.Permissions or {
    sunAdmin = false,
    group = "user",
    commands = {
        setjob = false,
        givemoney = false,
        kick = false,
        ban = false,
    }
}

RegisterNetEvent("Sun:Perms:Update", function(perms)
    if type(perms) ~= "table" then return end
    Sun.Permissions.sunAdmin = perms.sunAdmin == true
    Sun.Permissions.group = type(perms.group) == "string" and perms.group or "user"
    if type(perms.commands) == "table" then
        for k, v in pairs(perms.commands) do
            Sun.Permissions.commands[k] = v == true
        end
    end
end)

exports("GetPermissions", function()
    return Sun.Permissions
end)

RegisterNetEvent("Sun:PlayerData:Load", function(data)
    if type(data) ~= "table" then
        return
    end

    Sun.playerData.identifier = data.identifier or nil
    Sun.playerData.name = data.name or nil
    Sun.playerData.group = type(data.group) == "string" and data.group or "user"

    if type(data.money) == "table" then
        Sun.playerData.money.cash = tonumber(data.money.cash) or 0
        Sun.playerData.money.bank = tonumber(data.money.bank) or 0
        Sun.playerData.money.black = tonumber(data.money.black) or 0
    end

    if type(data.job) == "table" then
        if type(data.job.legal) == "table" then
            local l = data.job.legal
            Sun.playerData.job.legal.name = l.name or "unemployed"
            Sun.playerData.job.legal.grade = l.grade or 0
            Sun.playerData.job.legal.label = l.label or l.name or "Unemployed"
            Sun.playerData.job.legal.gradeLabel = l.gradeLabel or ""
            Sun.playerData.job.legal.salary = l.salary or 0
        end
        if type(data.job.illegal) == "table" then
            local il = data.job.illegal
            Sun.playerData.job.illegal.name = il.name or nil
            Sun.playerData.job.illegal.grade = il.grade or 0
            Sun.playerData.job.illegal.label = il.label or ""
            Sun.playerData.job.illegal.gradeLabel = il.gradeLabel or ""
            Sun.playerData.job.illegal.salary = il.salary or 0
        end
    end

    if type(data.meta) == "table" then
        for k, v in pairs(data.meta) do
            Sun.playerData.meta[k] = v
        end
    end

    if type(data.loadout) == "table" then
        Sun.playerData.loadout = data.loadout
        TriggerEvent("Sun:Loadout:Restore", data.loadout)
    end

    TriggerServerEvent("Sun:Perms:Request")

    TriggerEvent("Sun:OnPlayerDataUpdated", "All", Sun.playerData)
end)

local function syncLoadout()
    TriggerServerEvent("Sun:Loadout:Sync", Sun.playerData.loadout or {})
end

local function applyWeapons(weapons)
    local player = PlayerPedId()
    for i = 1, #weapons do
        local items = weapons[i]
        if type(items.weapon) == "number" and items.weapon ~= 0 then
            GiveWeaponToPed(player, items.weapon, items.ammo or 0, false, false)
            SetPedWeaponTintIndex(player, items.weapon, items.tint or 0)
        end
    end
end

local function loadOut(weapons)
    if type(weapons) ~= "table" then
        return
    end
    CreateThread(function() applyWeapons(weapons) end)
end

CreateThread(function()
    local unarmed = GetHashKey("WEAPON_UNARMED")
    while true do
        Wait(5000)
        if Sun.playerData.identifier then
            local ped = PlayerPedId()
            local hash = GetCurrentPedWeapon(ped, true)
            if hash and hash ~= 0 and hash ~= unarmed then
                for i = 1, #Sun.playerData.loadout do
                    if Sun.playerData.loadout[i].weapon == hash then
                        Sun.playerData.loadout[i].ammo = GetAmmoInPedWeapon(ped, hash)
                        Sun.playerData.loadout[i].tint = GetPedWeaponTintIndex(ped, hash)
                        break
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(300000)
        if Sun.playerData.identifier then
            syncLoadout()
        end
    end
end)

RegisterNetEvent("Sun:Loadout:Restore", function(weapons)
    if type(weapons) ~= "table" then
        return
    end

    Sun.playerData.loadout = weapons
    RemoveAllPedWeapons(PlayerPedId(), true)
    loadOut(weapons)
end)

RegisterNetEvent("Sun:Loadout:GiveWeapon", function(item)
    if type(item) ~= "table" then return end
    local hash = tonumber(item.weapon)
    if not hash or hash <= 0 then return end

    local ammo = tonumber(item.ammo) or 0
    local tint = tonumber(item.tint) or 0

    local found = false
    for i = 1, #Sun.playerData.loadout do
        if Sun.playerData.loadout[i].weapon == hash then
            Sun.playerData.loadout[i].ammo = ammo
            Sun.playerData.loadout[i].tint = tint
            found = true
            break
        end
    end
    if not found then
        Sun.playerData.loadout[#Sun.playerData.loadout + 1] = {
            weapon = hash, ammo = ammo, tint = tint
        }
    end

    local ped = PlayerPedId()
    GiveWeaponToPed(ped, hash, ammo, false, false)
    SetPedWeaponTintIndex(ped, hash, tint)
end)

RegisterNetEvent("Sun:Loadout:RemoveWeapon", function(weapon)
    weapon = tonumber(weapon)
    if not weapon then return end

    local loadout = Sun.playerData.loadout
    for i = 1, #loadout do
        if loadout[i].weapon == weapon then
            loadout[i] = loadout[#loadout]
            loadout[#loadout] = nil
            break
        end
    end

    RemoveWeaponFromPed(PlayerPedId(), weapon)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    syncLoadout()
end)

RegisterNetEvent("Sun:PlayerData:Update", function(key, value)
    if type(key) ~= "string" then
        return
    end

    if key == "group" and type(value) == "string" then
        Sun.playerData.group = value
        Sun.Permissions.group = value
    elseif key == "money" and type(value) == "table" then
        Sun.playerData.money.cash = tonumber(value.cash) or 0
        Sun.playerData.money.bank = tonumber(value.bank) or 0
        Sun.playerData.money.black = tonumber(value.black) or 0
    elseif key == "job" and type(value) == "table" then
        if type(value.legal) == "table" or type(value.illegal) == "table" then
            if type(value.legal) == "table" then
                local l = value.legal
                Sun.playerData.job.legal.name = l.name or "unemployed"
                Sun.playerData.job.legal.grade = l.grade or 0
                Sun.playerData.job.legal.label = l.label or l.name or "Unemployed"
                Sun.playerData.job.legal.gradeLabel = l.gradeLabel or ""
                Sun.playerData.job.legal.salary = l.salary or 0
            end
            if type(value.illegal) == "table" then
                local il = value.illegal
                Sun.playerData.job.illegal.name = il.name or nil
                Sun.playerData.job.illegal.grade = il.grade or 0
                Sun.playerData.job.illegal.label = il.label or ""
                Sun.playerData.job.illegal.gradeLabel = il.gradeLabel or ""
                Sun.playerData.job.illegal.salary = il.salary or 0
            end
        else
            local jobType = value.type or "legal"
            if jobType == "legal" then
                Sun.playerData.job.legal.name = value.name or "unemployed"
                Sun.playerData.job.legal.grade = value.grade or 0
                Sun.playerData.job.legal.label = value.label or value.name or "Unemployed"
                Sun.playerData.job.legal.gradeLabel = value.gradeLabel or ""
                Sun.playerData.job.legal.salary = value.salary or 0
            elseif jobType == "illegal" then
                Sun.playerData.job.illegal.name = value.name or nil
                Sun.playerData.job.illegal.grade = value.grade or 0
                Sun.playerData.job.illegal.label = value.label or ""
                Sun.playerData.job.illegal.gradeLabel = value.gradeLabel or ""
                Sun.playerData.job.illegal.salary = value.salary or 0
            end
        end
    elseif key == "meta" and type(value) == "table" then
        for k, v in pairs(value) do
            Sun.playerData.meta[k] = v
        end
    end

    TriggerEvent("Sun:OnPlayerDataUpdated", key, value)
end)

exports("GetPlayerData", function()
    return Sun.playerData
end)