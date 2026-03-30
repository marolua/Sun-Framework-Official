Sun.PlayerData = {
    Identifier = nil,
    Name = nil,

    Money = {
        Cash = 0,
        Bank = 0,
        Black = 0,
    },
    Job = {
        Legal = {
            name = "unemployed",
            grade = 0,
        },
        Illegal = {
            name = nil,
            grade = 0,
        },
    },
    Meta = {},
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

    Sun.PlayerData.Identifier = data.Identifier or nil
    Sun.PlayerData.Name       = data.Name or nil

    if type(data.Money) == "table" then
        Sun.PlayerData.Money.Cash  = tonumber(data.Money.Cash)  or 0
        Sun.PlayerData.Money.Bank  = tonumber(data.Money.Bank)  or 0
        Sun.PlayerData.Money.Black = tonumber(data.Money.Black) or 0
    end

    if type(data.Job) == "table" then
        if type(data.Job.Legal) == "table" then
            Sun.PlayerData.Job.Legal.name  = data.Job.Legal.name or "unemployed"
            Sun.PlayerData.Job.Legal.grade = data.Job.Legal.grade or 0
        end
        if type(data.Job.Illegal) == "table" then
            Sun.PlayerData.Job.Illegal.name  = data.Job.Illegal.name or nil
            Sun.PlayerData.Job.Illegal.grade = data.Job.Illegal.grade or 0
        end
    end

    if type(data.Meta) == "table" then
        for k, v in pairs(data.Meta) do
            Sun.PlayerData.Meta[k] = v
        end
    end

    TriggerServerEvent("Sun:Perms:Request")

    TriggerEvent("Sun:OnPlayerDataUpdated", "All", Sun.PlayerData)
end)

RegisterNetEvent("Sun:PlayerData:Update", function(key, value)
    if type(key) ~= "string" then
        return
    end

    if key == "Money" and type(value) == "table" then
        Sun.PlayerData.Money.Cash = tonumber(value.Cash) or 0
        Sun.PlayerData.Money.Bank = tonumber(value.Bank) or 0
        Sun.PlayerData.Money.Black = tonumber(value.Black) or 0
    elseif key == "Job" and type(value) == "table" then
        if type(value.Legal) == "table" or type(value.Illegal) == "table" then
            if type(value.Legal) == "table" then
                Sun.PlayerData.Job.Legal.name = value.Legal.name or "unemployed"
                Sun.PlayerData.Job.Legal.grade = value.Legal.grade or 0
            end
            if type(value.Illegal) == "table" then
                Sun.PlayerData.Job.Illegal.name = value.Illegal.name or nil
                Sun.PlayerData.Job.Illegal.grade = value.Illegal.grade or 0
            end
        else
            local jobType = value.type or "legal"
            if jobType == "legal" then
                Sun.PlayerData.Job.Legal.name = value.name or "unemployed"
                Sun.PlayerData.Job.Legal.grade = value.grade or 0
            elseif jobType == "illegal" then
                Sun.PlayerData.Job.Illegal.name = value.name or nil
                Sun.PlayerData.Job.Illegal.grade = value.grade or 0
            end
        end
    elseif key == "Meta" and type(value) == "table" then
        for k, v in pairs(value) do
            Sun.PlayerData.Meta[k] = v
        end
    end

    TriggerEvent("Sun:OnPlayerDataUpdated", key, value)
end)

exports("GetPlayerData", function()
    return Sun.PlayerData
end)