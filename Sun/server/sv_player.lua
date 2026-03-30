Sun = Sun or {}
Sun.Players = Sun.Players or {}
Sun.Money = Sun.Money or {}
Sun.Money.Data = Sun.Money.Data or {}
Sun.Jobs = Sun.Jobs or {}
Sun.Jobs.Data = Sun.Jobs.Data or {}
Sun.PlayerMeta = Sun.PlayerMeta or {}
Sun.GroupData = Sun.GroupData or {}
Sun.Vehicles = Sun.Vehicles or {}
Sun.Vehicles.Data = Sun.Vehicles.Data or {}

function Sun.Money:LoadingMoney(identifier)
    local result = nil
    pcall(function()
        result = MySQL.single.await(
            'SELECT cash, bank, black_money FROM users WHERE identifier = ? LIMIT 1',
            { identifier }
        )
    end)

    if not result then
        return {
            Cash  = Sun.Config.Money.Default_Money_Liquid,
            Bank  = Sun.Config.Money.Default_Money_Bank,
            Black = Sun.Config.Money.Default_Money_Black,
        }
    end

    return {
        Cash  = tonumber(result.cash) or 0,
        Bank  = tonumber(result.bank) or 0,
        Black = tonumber(result.black_money) or 0,
    }
end

function Sun.Money:SaveMoney(identifier)
    local data = Sun.Money.Data[identifier]
    if not data then return end

    MySQL.update(
        'UPDATE users SET cash = ?, bank = ?, black_money = ? WHERE identifier = ?',
        { data.Cash or 0, data.Bank or 0, data.Black or 0, identifier }
    )
end

function Sun.Money:Sync(source, identifier)
    local data = Sun.Money.Data[identifier] or {}

    TriggerClientEvent("Sun:PlayerData:Update", source, "Money", {
        Cash  = tonumber(data.Cash)  or 0,
        Bank  = tonumber(data.Bank)  or 0,
        Black = tonumber(data.Black) or 0,
    })
end

function Sun.Money:GetMoney(source, accountType)
    local player = Sun.Players[source]
    if not player then return 0 end

    local data = Sun.Money.Data[player.identifier] or {}

    if accountType then
        return tonumber(data[accountType]) or 0
    end

    return {
        Cash  = tonumber(data.Cash)  or 0,
        Bank  = tonumber(data.Bank)  or 0,
        Black = tonumber(data.Black) or 0,
    }
end

function Sun.Money:AddMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0

    if amount <= 0 then return false end

    if not Sun.Money.Data[identifier] then
        Sun.Money.Data[identifier] = { Cash = 0, Bank = 0, Black = 0 }
    end

    Sun.Money.Data[identifier][accountType] = (tonumber(Sun.Money.Data[identifier][accountType]) or 0) + amount

    Sun.Money:SaveMoney(identifier)

    return true
end

function Sun.Money:RemoveMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0

    if amount <= 0 then return false end

    if not Sun.Money.Data[identifier] then return false end

    local current = tonumber(Sun.Money.Data[identifier][accountType]) or 0

    if current < amount then
        return false
    end

    Sun.Money.Data[identifier][accountType] = current - amount

    Sun.Money:SaveMoney(identifier)

    return true
end

function Sun.Money:SetMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0

    if not Sun.Money.Data[identifier] then
        Sun.Money.Data[identifier] = { Cash = 0, Bank = 0, Black = 0 }
    end

    Sun.Money.Data[identifier][accountType] = amount

    Sun.Money:SaveMoney(identifier)

    return true
end

function Sun.Jobs:LoadingJobs(identifier)
    local result = nil
    pcall(function()
        result = MySQL.single.await(
            'SELECT job, job_grade, job_illegal, job_illegal_grade FROM users WHERE identifier = ? LIMIT 1',
            { identifier }
        )
    end)

    if not result then
        return {
            Legal   = { name = "unemployed", grade = 0 },
            Illegal = { name = nil, grade = 0 },
        }
    end

    return {
        Legal   = { name = result.job or "unemployed", grade = tonumber(result.job_grade) or 0 },
        Illegal = { name = result.job_illegal or nil,  grade = tonumber(result.job_illegal_grade) or 0 },
    }
end

function Sun.Jobs:Sync(source, identifier)
    local data    = Sun.Jobs.Data[identifier] or {}
    local legal   = data.Legal or {}
    local illegal = data.Illegal or {}

    TriggerClientEvent("Sun:PlayerData:Update", source, "Job", {
        Legal   = { name = legal.name or "unemployed", grade = legal.grade or 0 },
        Illegal = { name = illegal.name or nil,        grade = illegal.grade or 0 },
    })
end

function Sun.Jobs:GetJobs(source)
    local player = Sun.Players[source]
    if not player then return nil end

    return Sun.Jobs.Data[player.identifier]
end

function Sun.Jobs:SetLegalJob(source, jobName, grade)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier

    if not Sun.Jobs.Data[identifier] then
        Sun.Jobs.Data[identifier] = { Legal = {}, Illegal = {} }
    end

    Sun.Jobs.Data[identifier].Legal = { name = jobName or "unemployed", grade = tonumber(grade) or 0 }

    MySQL.update(
        'UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?',
        { jobName or "unemployed", tonumber(grade) or 0, identifier }
    )

    return true
end

function Sun.Jobs:SetIllegalJob(source, jobName, grade)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier

    if not Sun.Jobs.Data[identifier] then
        Sun.Jobs.Data[identifier] = { Legal = {}, Illegal = {} }
    end

    Sun.Jobs.Data[identifier].Illegal = { name = jobName, grade = tonumber(grade) or 0 }

    MySQL.update(
        'UPDATE users SET job_illegal = ?, job_illegal_grade = ? WHERE identifier = ?',
        { jobName, tonumber(grade) or 0, identifier }
    )

    return true
end

function Sun:GetGroup(source, refresh)
    if type(source) ~= "number" or source < 1 then
        return nil
    end

    local identifier = self:GetPlayerIdentifier(source)
    if not identifier then return nil end

    if not refresh and self.GroupData[identifier] then
        return self.GroupData[identifier]
    end

    local result = nil
    local ok = pcall(function()
        result = MySQL.single.await('SELECT `group` FROM users WHERE identifier = ? LIMIT 1', { identifier })
    end)

    if not ok then return "user" end

    local group = result and result.group or "user"
    self.GroupData[identifier] = group

    return group
end

function Sun:SetGroup(source, group)
    if type(source) ~= "number" or source < 1 then
        return false
    end

    local identifier = self:GetPlayerIdentifier(source)
    if not identifier then return false end

    local ok = pcall(function()
        MySQL.update.await('UPDATE users SET `group` = ? WHERE identifier = ?', { group, identifier })
    end)

    if ok then
        self.GroupData[identifier] = group
        return true
    end

    return false
end

function Sun:GetPlayerData(source)
    if type(source) ~= "number" or source < 1 then
        return nil
    end

    local player = self.Players[source]
    if not player then return nil end

    local identifier = player.identifier
    local moneyData  = self.Money.Data[identifier] or {}
    local jobsData   = self.Jobs.Data[identifier] or {}
    local legalJob   = jobsData.Legal or {}
    local illegalJob = jobsData.Illegal or {}

    return {
        Identifier = identifier,
        Name       = player.name,
        Source     = source,
        Money = {
            Cash  = tonumber(moneyData.Cash)  or 0,
            Bank  = tonumber(moneyData.Bank)  or 0,
            Black = tonumber(moneyData.Black) or 0,
        },
        Job = {
            Legal   = { name = legalJob.name or "unemployed", grade = legalJob.grade or 0 },
            Illegal = { name = illegalJob.name or nil,        grade = illegalJob.grade or 0 },
        },
        Meta = self.PlayerMeta[identifier] or {},
    }
end

function Sun:SetPlayerMeta(identifier, index, value)
    if type(identifier) ~= "string" or identifier == "" then return false end
    if type(index) ~= "string" or index == "" then return false end

    if not self.PlayerMeta[identifier] then
        self.PlayerMeta[identifier] = {}
    end

    self.PlayerMeta[identifier][index] = value

    for src, plr in pairs(self.Players) do
        if plr.identifier == identifier then
            TriggerClientEvent("Sun:PlayerData:Update", src, "Meta", { [index] = value })
            break
        end
    end

    return true
end

function Sun:GetPlayerMeta(identifier, index)
    if type(identifier) ~= "string" or identifier == "" then return nil end

    local meta = self.PlayerMeta[identifier]
    if not meta then return nil end

    if index ~= nil then
        return meta[index]
    end

    return meta
end

function Sun:GetPlayerIdentifier(source)
    if type(source) ~= "number" then return nil end

    local ok, id = pcall(function()
        return Player(source).state.Sun_identifier
    end)

    return (ok and type(id) == "string" and id ~= "") and id or nil
end

local function getIdentifier(source)
    if type(source) ~= "number" or source < 1 then return nil end
    return Sun:GetPlayerIdentifier(source)
end

local function createPlayer(source)
    local identifier = getIdentifier(source)
    if not identifier then return nil end

    local player = {
        source     = source,
        identifier = identifier,
        name       = GetPlayerName(source) or nil,
    }

    function player:getMoney(accountType)
        if accountType then
            return Sun.Money:GetMoney(self.source, accountType)
        end
        return Sun.Money:GetMoney(self.source)
    end

    function player:addMoney(accountType, amount)
        local result = Sun.Money:AddMoney(self.source, accountType, amount)
        if result then
            local moneyData = Sun.Money.Data[self.identifier] or {}
            TriggerClientEvent("Sun:PlayerData:Update", self.source, "Money", {
                Cash  = tonumber(moneyData.Cash)  or 0,
                Bank  = tonumber(moneyData.Bank)  or 0,
                Black = tonumber(moneyData.Black) or 0,
            })
        end
        return result
    end

    function player:removeMoney(accountType, amount)
        local result = Sun.Money:RemoveMoney(self.source, accountType, amount)
        if result then
            local moneyData = Sun.Money.Data[self.identifier] or {}
            TriggerClientEvent("Sun:PlayerData:Update", self.source, "Money", {
                Cash  = tonumber(moneyData.Cash)  or 0,
                Bank  = tonumber(moneyData.Bank)  or 0,
                Black = tonumber(moneyData.Black) or 0,
            })
        end
        return result
    end

    function player:setMoney(accountType, amount)
        local result     = Sun.Money:SetMoney(self.source, accountType, amount)
        local moneyData  = Sun.Money.Data[self.identifier] or {}
        local updatedMoney = {
            Cash  = tonumber(moneyData.Cash)  or 0,
            Bank  = tonumber(moneyData.Bank)  or 0,
            Black = tonumber(moneyData.Black) or 0,
        }
        updatedMoney[accountType] = tonumber(amount) or 0
        TriggerClientEvent("Sun:PlayerData:Update", self.source, "Money", updatedMoney)
        return result
    end

    function player:getJob()
        local jobs = Sun.Jobs:GetJobs(self.source)
        if not jobs or not jobs.Legal then
            return "unemployed", 0
        end
        return jobs.Legal.name or "unemployed", jobs.Legal.grade or 0
    end

    function player:setJob(jobName, grade)
        local result = Sun.Jobs:SetLegalJob(self.source, jobName, grade)
        TriggerClientEvent("Sun:PlayerData:Update", self.source, "Job", {
            name  = jobName or "unemployed",
            grade = grade or 0,
            type  = "legal",
        })
        return result
    end

    function player:setIllegalJob(jobName, grade)
        local result = Sun.Jobs:SetIllegalJob(self.source, jobName, grade)
        TriggerClientEvent("Sun:PlayerData:Update", self.source, "Job", {
            name  = jobName or nil,
            grade = grade or 0,
            type  = "illegal",
        })
        return result
    end

    function player:getInventory()
        return Sun_GetPlayerInventory and Sun_GetPlayerInventory(self.identifier) or nil
    end

    function player:hasItem(itemName, quantity)
        return Sun_HasItem and Sun_HasItem(self.identifier, itemName, quantity or 1) or false
    end

    function player:addItem(itemName, quantity)
        local result = Sun_AddItem and Sun_AddItem(self.identifier, itemName, quantity or 1) or false
        if result then
            TriggerClientEvent("Sun:Client:RefreshInventory", self.source)
        end
        return result
    end

    function player:removeItem(itemName, quantity)
        local result = Sun_RemoveItem and Sun_RemoveItem(self.identifier, itemName, quantity or 1) or false
        if result then
            TriggerClientEvent("Sun:Client:RefreshInventory", self.source)
        end
        return result
    end

    function player:getVehicles()
        return Sun.Vehicles.Data[self.identifier] or {}
    end

    function player:addVehicle(plate, model)
        if type(plate) ~= "string" or plate == "" then return false end
        if type(model) ~= "string" or model == "" then return false end

        plate = string.upper(string.sub(plate, 1, 10))

        local ok = pcall(function()
            MySQL.insert.await(
                'INSERT INTO owned_vehicle (identifier, plate, model) VALUES (?, ?, ?)',
                { self.identifier, plate, model }
            )
        end)

        if not ok then return false end

        if not Sun.Vehicles.Data[self.identifier] then
            Sun.Vehicles.Data[self.identifier] = {}
        end

        table.insert(Sun.Vehicles.Data[self.identifier], {
            plate  = plate,
            model  = model,
            stored = true,
        })

        return true
    end

    function player:removeVehicle(plate)
        if type(plate) ~= "string" or plate == "" then return false end

        plate = string.upper(string.sub(plate, 1, 10))

        local ok = pcall(function()
            MySQL.update.await(
                'DELETE FROM owned_vehicle WHERE identifier = ? AND plate = ?',
                { self.identifier, plate }
            )
        end)

        if not ok then return false end

        local vehicles = Sun.Vehicles.Data[self.identifier]
        if vehicles then
            for i, v in ipairs(vehicles) do
                if v.plate == plate then
                    table.remove(vehicles, i)
                    break
                end
            end
        end

        return true
    end

    function player:triggerEvent(eventName, ...)
        if type(eventName) ~= "string" or eventName == "" then return false end
        TriggerClientEvent(eventName, self.source, ...)
        return true
    end

    return player
end

function Sun:GetPlayer(source)
    if type(source) ~= "number" or source < 1 then return nil end
    return self.Players[source]
end

function Sun:GetPlayerFromIdentifier(identifier)
    if type(identifier) ~= "string" or identifier == "" then return nil end

    for _, player in pairs(self.Players) do
        if player.identifier == identifier then
            return player
        end
    end

    return nil
end

function Sun:GetPlayers()
    local playersList = {}

    for _, player in pairs(self.Players) do
        if player then
            table.insert(playersList, player)
        end
    end

    return playersList
end

AddEventHandler("Sun:LoadingCharacter", function(source)
    if type(source) ~= "number" then return end

    local player = createPlayer(source)
    if not player then return end

    Sun.Players[source] = player

    local identifier = player.identifier

    Sun.Money.Data[identifier] = Sun.Money:LoadingMoney(identifier)
    Sun.Money:Sync(source, identifier)

    Sun.Jobs.Data[identifier] = Sun.Jobs:LoadingJobs(identifier)
    Sun.Jobs:Sync(source, identifier)

    Sun:GetGroup(source, true)

    local vehiclesResult = nil
    pcall(function()
        vehiclesResult = MySQL.query.await(
            'SELECT plate, model, stored FROM owned_vehicle WHERE identifier = ?',
            { identifier }
        )
    end)
    Sun.Vehicles.Data[identifier] = vehiclesResult or {}

    local moneyData  = Sun.Money.Data[identifier] or {}
    local jobsData   = Sun.Jobs.Data[identifier] or {}
    local legalJob   = jobsData.Legal or {}
    local illegalJob = jobsData.Illegal or {}

    TriggerClientEvent("Sun:PlayerData:Load", source, {
        Identifier = identifier,
        Name       = player.name,
        Money = {
            Cash  = tonumber(moneyData.Cash)  or 0,
            Bank  = tonumber(moneyData.Bank)  or 0,
            Black = tonumber(moneyData.Black) or 0,
        },
        Job = {
            Legal   = { name = legalJob.name or "unemployed", grade = legalJob.grade or 0 },
            Illegal = { name = illegalJob.name or nil,        grade = illegalJob.grade or 0 },
        },
        Meta = Sun.PlayerMeta[identifier] or {},
    })
end)

AddEventHandler("playerDropped", function()
    local src    = source
    local player = Sun.Players[src]

    if not player then return end

    local identifier = player.identifier

    Sun.Money:SaveMoney(identifier)
    Sun.Money.Data[identifier]    = nil
    Sun.Jobs.Data[identifier]     = nil
    Sun.PlayerMeta[identifier]    = nil
    Sun.GroupData[identifier]     = nil
    Sun.Vehicles.Data[identifier] = nil

    Sun.Players[src] = nil
end)

RegisterNetEvent("Sun:ReloadRequest", function()
    local src = source

    if type(src) ~= "number" or src < 1 then return end

    local player = Sun:GetPlayer(src)
    if not player then return end

    if Sun.ReloadRateLimit and Sun.ReloadRateLimit[src] and (GetGameTimer() - Sun.ReloadRateLimit[src]) < 5000 then
        return
    end

    Sun.ReloadRateLimit = Sun.ReloadRateLimit or {}
    Sun.ReloadRateLimit[src] = GetGameTimer()

    TriggerEvent("Sun:LoadingCharacter", src)
end)

CreateThread(function()
    while true do
        Wait(30000)
        for _, player in pairs(Sun.Players) do
            Wait(0)
            if player then
                Sun.Money:SaveMoney(player.identifier)
            end
        end
    end
end)
