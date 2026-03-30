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

function Sun.Money:loadingMoney(identifier)
    local result = nil
    pcall(function()
        result = MySQL.single.await(
            'SELECT cash, bank, black_money FROM users WHERE identifier = ? LIMIT 1',
            { identifier }
        )
    end)

    if not result then
        return {
            cash = Sun.Config.money.defaultMoneyLiquid,
            bank = Sun.Config.money.defaultMoneyBank,
            black = Sun.Config.money.defaultMoneyBlack,
            _dirty = false,
        }
    end

    return {
        cash = tonumber(result.cash) or 0,
        bank = tonumber(result.bank) or 0,
        black = tonumber(result.black_money) or 0,
        _dirty = false,
    }
end

function Sun.Money:saveMoney(identifier)
    local data = Sun.Money.Data[identifier]
    if not data or not data._dirty then return end

    data._dirty = false

    MySQL.update(
        'UPDATE users SET cash = ?, bank = ?, black_money = ? WHERE identifier = ?',
        { data.cash or 0, data.bank or 0, data.black or 0, identifier }
    )
end

function Sun.Money:sync(source, identifier)
    local data = Sun.Money.Data[identifier] or {}

    TriggerClientEvent("Sun:PlayerData:Update", source, "money", {
        cash = tonumber(data.cash) or 0,
        bank = tonumber(data.bank) or 0,
        black = tonumber(data.black) or 0,
    })
end

function Sun.Money:getMoney(source, accountType)
    local player = Sun.Players[source]
    if not player then return 0 end

    local data = Sun.Money.Data[player.identifier] or {}

    if accountType then
        return tonumber(data[accountType]) or 0
    end

    return {
        cash = tonumber(data.cash) or 0,
        bank = tonumber(data.bank) or 0,
        black = tonumber(data.black) or 0,
    }
end

function Sun.Money:addMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0

    if amount <= 0 then return false end

    if not Sun.Money.Data[identifier] then
        Sun.Money.Data[identifier] = { cash = 0, bank = 0, black = 0 }
    end

    local maxValues = {
        cash = Sun.Config.money.defaultMoneyLiquidMax,
        bank = Sun.Config.money.defaultMoneyBankMax,
        black = Sun.Config.money.defaultMoneyBlackMax,
    }

    local newAmount = (tonumber(Sun.Money.Data[identifier][accountType]) or 0) + amount
    local cap = maxValues[accountType]
    Sun.Money.Data[identifier][accountType] = cap and math.min(newAmount, cap) or newAmount
    Sun.Money.Data[identifier]._dirty = true

    return true
end

function Sun.Money:removeMoney(source, accountType, amount)
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
    Sun.Money.Data[identifier]._dirty = true

    return true
end

function Sun.Money:setMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0

    if not Sun.Money.Data[identifier] then
        Sun.Money.Data[identifier] = { cash = 0, bank = 0, black = 0 }
    end

    Sun.Money.Data[identifier][accountType] = amount
    Sun.Money.Data[identifier]._dirty = true

    return true
end

function Sun.Jobs:loadingJobs(identifier)
    local result = nil
    pcall(function()
        result = MySQL.single.await(
            'SELECT job, job_grade, job_illegal, job_illegal_grade FROM users WHERE identifier = ? LIMIT 1',
            { identifier }
        )
    end)

    if not result then
        return {
            legal = { name = "unemployed", grade = 0 },
            illegal = { name = nil, grade = 0 },
        }
    end

    return {
        legal = { name = result.job or "unemployed", grade = tonumber(result.job_grade) or 0 },
        illegal = { name = result.job_illegal or nil, grade = tonumber(result.job_illegal_grade) or 0 },
    }
end

function Sun.Jobs:sync(source, identifier)
    local data = Sun.Jobs.Data[identifier] or {}
    local legal = data.legal or {}
    local illegal = data.illegal or {}

    TriggerClientEvent("Sun:PlayerData:Update", source, "job", {
        legal = { name = legal.name or "unemployed", grade = legal.grade or 0 },
        illegal = { name = illegal.name or nil, grade = illegal.grade or 0 },
    })
end

function Sun.Jobs:getJobs(source)
    local player = Sun.Players[source]
    if not player then return nil end

    return Sun.Jobs.Data[player.identifier]
end

function Sun.Jobs:setLegalJob(source, jobName, grade)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier

    if not Sun.Jobs.Data[identifier] then
        Sun.Jobs.Data[identifier] = { legal = {}, illegal = {} }
    end

    Sun.Jobs.Data[identifier].legal = { name = jobName or "unemployed", grade = tonumber(grade) or 0 }

    MySQL.update(
        'UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?',
        { jobName or "unemployed", tonumber(grade) or 0, identifier }
    )

    return true
end

function Sun.Jobs:setIllegalJob(source, jobName, grade)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier

    if not Sun.Jobs.Data[identifier] then
        Sun.Jobs.Data[identifier] = { legal = {}, illegal = {} }
    end

    Sun.Jobs.Data[identifier].illegal = { name = jobName, grade = tonumber(grade) or 0 }

    MySQL.update(
        'UPDATE users SET job_illegal = ?, job_illegal_grade = ? WHERE identifier = ?',
        { jobName, tonumber(grade) or 0, identifier }
    )

    return true
end

function Sun:getGroup(source, refresh)
    if type(source) ~= "number" or source < 1 then
        return nil
    end

    local identifier = self:getPlayerIdentifier(source)
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

function Sun:setGroup(source, group)
    if type(source) ~= "number" or source < 1 then
        return false
    end

    local identifier = self:getPlayerIdentifier(source)
    if not identifier then return false end

    local ok = pcall(function()
        MySQL.update.await('UPDATE users SET `group` = ? WHERE identifier = ?', { group, identifier })
    end)

    if ok then
        self.GroupData[identifier] = group
        TriggerClientEvent("Sun:PlayerData:Update", source, "group", group)
        return true
    end

    return false
end

function Sun:getPlayerData(source)
    if type(source) ~= "number" or source < 1 then
        return nil
    end

    local player = self.Players[source]
    if not player then return nil end

    local identifier = player.identifier
    local moneyData = self.Money.Data[identifier] or {}
    local jobsData = self.Jobs.Data[identifier] or {}
    local legalJob = jobsData.legal or {}
    local illegalJob = jobsData.illegal or {}

    return {
        identifier = identifier,
        name = player.name,
        source = source,
        money = {
            cash = tonumber(moneyData.cash) or 0,
            bank = tonumber(moneyData.bank) or 0,
            black = tonumber(moneyData.black) or 0,
        },
        job = {
            legal = { name = legalJob.name or "unemployed", grade = legalJob.grade or 0 },
            illegal = { name = illegalJob.name or nil, grade = illegalJob.grade or 0 },
        },
        meta = self.PlayerMeta[identifier] or {},
    }
end

function Sun:setPlayerMeta(identifier, index, value)
    if type(identifier) ~= "string" or identifier == "" then return false end
    if type(index) ~= "string" or index == "" then return false end

    if not self.PlayerMeta[identifier] then
        self.PlayerMeta[identifier] = {}
    end

    self.PlayerMeta[identifier][index] = value

    for src, plr in pairs(self.Players) do
        if plr.identifier == identifier then
            TriggerClientEvent("Sun:PlayerData:Update", src, "meta", { [index] = value })
            break
        end
    end

    return true
end

function Sun:getPlayerMeta(identifier, index)
    if type(identifier) ~= "string" or identifier == "" then return nil end

    local meta = self.PlayerMeta[identifier]
    if not meta then return nil end

    if index ~= nil then
        return meta[index]
    end

    return meta
end

function Sun:getPlayerIdentifier(source)
    if type(source) ~= "number" then return nil end

    local ok, id = pcall(function()
        return Player(source).state.Sun_identifier
    end)

    return (ok and type(id) == "string" and id ~= "") and id or nil
end

local function getIdentifier(source)
    if type(source) ~= "number" or source < 1 then return nil end
    return Sun:getPlayerIdentifier(source)
end

local PlayerMethods = {}
PlayerMethods.__index = PlayerMethods

function PlayerMethods:getMoney(accountType)
    if accountType then
        return Sun.Money:getMoney(self.source, accountType)
    end
    return Sun.Money:getMoney(self.source)
end

function PlayerMethods:addMoney(accountType, amount)
    local result = Sun.Money:addMoney(self.source, accountType, amount)
    if result then
        local moneyData = Sun.Money.Data[self.identifier] or {}
        TriggerClientEvent("Sun:PlayerData:Update", self.source, "money", {
            cash = tonumber(moneyData.cash) or 0,
            bank = tonumber(moneyData.bank) or 0,
            black = tonumber(moneyData.black) or 0,
        })
    end
    return result
end

function PlayerMethods:removeMoney(accountType, amount)
    local result = Sun.Money:removeMoney(self.source, accountType, amount)
    if result then
        local moneyData = Sun.Money.Data[self.identifier] or {}
        TriggerClientEvent("Sun:PlayerData:Update", self.source, "money", {
            cash = tonumber(moneyData.cash) or 0,
            bank = tonumber(moneyData.bank) or 0,
            black = tonumber(moneyData.black) or 0,
        })
    end
    return result
end

function PlayerMethods:setMoney(accountType, amount)
    local result = Sun.Money:setMoney(self.source, accountType, amount)
    local moneyData = Sun.Money.Data[self.identifier] or {}
    local updatedMoney = {
        cash = tonumber(moneyData.cash) or 0,
        bank = tonumber(moneyData.bank) or 0,
        black = tonumber(moneyData.black) or 0,
    }
    updatedMoney[accountType] = tonumber(amount) or 0
    TriggerClientEvent("Sun:PlayerData:Update", self.source, "money", updatedMoney)
    return result
end

function PlayerMethods:getJob()
    local jobs = Sun.Jobs:getJobs(self.source)
    if not jobs or not jobs.legal then
        return "unemployed", 0
    end
    return jobs.legal.name or "unemployed", jobs.legal.grade or 0
end

function PlayerMethods:setJob(jobName, grade)
    local result = Sun.Jobs:setLegalJob(self.source, jobName, grade)
    TriggerClientEvent("Sun:PlayerData:Update", self.source, "job", {
        name = jobName or "unemployed",
        grade = grade or 0,
        type = "legal",
    })
    return result
end

function PlayerMethods:setIllegalJob(jobName, grade)
    local result = Sun.Jobs:setIllegalJob(self.source, jobName, grade)
    TriggerClientEvent("Sun:PlayerData:Update", self.source, "job", {
        name = jobName or nil,
        grade = grade or 0,
        type = "illegal",
    })
    return result
end

function PlayerMethods:getInventory()
    return Sun_GetPlayerInventory and Sun_GetPlayerInventory(self.identifier) or nil
end

function PlayerMethods:hasItem(itemName, quantity)
    return Sun_HasItem and Sun_HasItem(self.identifier, itemName, quantity or 1) or false
end

function PlayerMethods:addItem(itemName, quantity)
    local result = Sun_AddItem and Sun_AddItem(self.identifier, itemName, quantity or 1) or false
    if result then
        TriggerClientEvent("Sun:Client:RefreshInventory", self.source)
    end
    return result
end

function PlayerMethods:removeItem(itemName, quantity)
    local result = Sun_RemoveItem and Sun_RemoveItem(self.identifier, itemName, quantity or 1) or false
    if result then
        TriggerClientEvent("Sun:Client:RefreshInventory", self.source)
    end
    return result
end

function PlayerMethods:getVehicles()
    return Sun.Vehicles.Data[self.identifier] or {}
end

function PlayerMethods:addVehicle(plate, model)
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
        plate = plate,
        model = model,
        stored = true,
    })

    return true
end

function PlayerMethods:removeVehicle(plate)
    if type(plate) ~= "string" or plate == "" then return false end

    plate = string.upper(string.sub(plate, 1, 10))

    local ok = pcall(function()
        MySQL.query.await(
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

function PlayerMethods:triggerEvent(eventName, ...)
    if type(eventName) ~= "string" or eventName == "" then return false end
    TriggerClientEvent(eventName, self.source, ...)
    return true
end

local function createPlayer(source)
    local identifier = getIdentifier(source)
    if not identifier then return nil end

    return setmetatable({
        source = source,
        identifier = identifier,
        name = GetPlayerName(source) or nil,
    }, PlayerMethods)
end

function Sun:getPlayer(source)
    if type(source) ~= "number" or source < 1 then return nil end
    return self.Players[source]
end

function Sun:getPlayerFromIdentifier(identifier)
    if type(identifier) ~= "string" or identifier == "" then return nil end

    for _, player in pairs(self.Players) do
        if player.identifier == identifier then
            return player
        end
    end

    return nil
end

function Sun:getPlayers()
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

    Sun.Money.Data[identifier] = Sun.Money:loadingMoney(identifier)
    Sun.Money:sync(source, identifier)

    Sun.Jobs.Data[identifier] = Sun.Jobs:loadingJobs(identifier)
    Sun.Jobs:sync(source, identifier)

    Sun:getGroup(source, true)

    local vehiclesResult = nil
    pcall(function()
        vehiclesResult = MySQL.query.await(
            'SELECT plate, model, stored FROM owned_vehicle WHERE identifier = ?',
            { identifier }
        )
    end)
    Sun.Vehicles.Data[identifier] = vehiclesResult or {}

    local moneyData = Sun.Money.Data[identifier] or {}
    local jobsData = Sun.Jobs.Data[identifier] or {}
    local legalJob = jobsData.legal or {}
    local illegalJob = jobsData.illegal or {}

    TriggerClientEvent("Sun:PlayerData:Load", source, {
        identifier = identifier,
        name = player.name,
        group = Sun.GroupData[identifier] or "user",
        money = {
            cash = tonumber(moneyData.cash) or 0,
            bank = tonumber(moneyData.bank) or 0,
            black = tonumber(moneyData.black) or 0,
        },
        job = {
            legal = { name = legalJob.name or "unemployed", grade = legalJob.grade or 0 },
            illegal = { name = illegalJob.name or nil, grade = illegalJob.grade or 0 },
        },
        meta = Sun.PlayerMeta[identifier] or {},
    })
end)

AddEventHandler("playerDropped", function()
    local src = source
    local player = Sun.Players[src]

    if not player then return end

    local identifier = player.identifier

    Sun.Money:saveMoney(identifier)
    Sun.Money.Data[identifier] = nil
    Sun.Jobs.Data[identifier] = nil
    Sun.PlayerMeta[identifier] = nil
    Sun.GroupData[identifier] = nil
    Sun.Vehicles.Data[identifier] = nil

    Sun.Players[src] = nil
end)

RegisterNetEvent("Sun:Perms:Request", function()
    local src = source
    if type(src) ~= "number" or src < 1 then return end

    local player = Sun:getPlayer(src)
    if not player then return end

    local group = Sun:getGroup(src) or "user"
    local isAdmin = Sun.Config.adminGroups and Sun.Config.adminGroups[group] == true

    TriggerClientEvent("Sun:Perms:Update", src, {
        sunAdmin = isAdmin,
        group = group,
        commands = {
            setjob = isAdmin,
            givemoney = isAdmin,
            kick = isAdmin,
            ban = isAdmin,
        }
    })
end)

RegisterNetEvent("Sun:ReloadRequest", function()
    local src = source

    if type(src) ~= "number" or src < 1 then return end

    local player = Sun:getPlayer(src)
    if not player then return end

    if Sun.reloadRateLimit and Sun.reloadRateLimit[src] and (GetGameTimer() - Sun.reloadRateLimit[src]) < 5000 then
        return
    end

    Sun.reloadRateLimit = Sun.reloadRateLimit or {}
    Sun.reloadRateLimit[src] = GetGameTimer()

    TriggerEvent("Sun:LoadingCharacter", src)
end)

CreateThread(function()
    while true do
        Wait(30000)
        for _, player in pairs(Sun.Players) do
            Wait(0)
            if player then
                Sun.Money:saveMoney(player.identifier)
            end
        end
    end
end)