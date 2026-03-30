Sun.playerData = {
    identifier = nil,
    name = nil,
    group = "user",
    money = {
        cash = 0,
        bank = 0,
        black = 0,
    },
    job = {
        legal = {
            name = "unemployed",
            grade = 0,
        },
        illegal = {
            name = nil,
            grade = 0,
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
            Sun.playerData.job.legal.name = data.job.legal.name or "unemployed"
            Sun.playerData.job.legal.grade = data.job.legal.grade or 0
        end
        if type(data.job.illegal) == "table" then
            Sun.playerData.job.illegal.name = data.job.illegal.name or nil
            Sun.playerData.job.illegal.grade = data.job.illegal.grade or 0
        end
    end

    if type(data.meta) == "table" then
        for k, v in pairs(data.meta) do
            Sun.playerData.meta[k] = v
        end
    end

    TriggerServerEvent("Sun:Perms:Request")

    TriggerEvent("Sun:OnPlayerDataUpdated", "All", Sun.playerData)
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
                Sun.playerData.job.legal.name = value.legal.name or "unemployed"
                Sun.playerData.job.legal.grade = value.legal.grade or 0
            end
            if type(value.illegal) == "table" then
                Sun.playerData.job.illegal.name = value.illegal.name or nil
                Sun.playerData.job.illegal.grade = value.illegal.grade or 0
            end
        else
            local jobType = value.type or "legal"
            if jobType == "legal" then
                Sun.playerData.job.legal.name = value.name or "unemployed"
                Sun.playerData.job.legal.grade = value.grade or 0
            elseif jobType == "illegal" then
                Sun.playerData.job.illegal.name = value.name or nil
                Sun.playerData.job.illegal.grade = value.grade or 0
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