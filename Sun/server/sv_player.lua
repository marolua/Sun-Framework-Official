Sun = Sun or {}
Sun.Players = Sun.Players or {}
Sun.Money = Sun.Money or {}
Sun.Money.Data = Sun.Money.Data or {}
Sun.Jobs = Sun.Jobs or {}
Sun.Jobs.Data = Sun.Jobs.Data or {}
Sun.Jobs.Labels = Sun.Jobs.Labels or {}
Sun.Jobs.GradeLabels = Sun.Jobs.GradeLabels or {}
Sun.PlayerMeta = Sun.PlayerMeta or {}
Sun.GroupData = Sun.GroupData or {}
Sun.Vehicles = Sun.Vehicles or {}
Sun.Vehicles.Data = Sun.Vehicles.Data or {}
Sun.Weapons = Sun.Weapons or {}
Sun.Weapons.Data = Sun.Weapons.Data or {}
Sun.IdentifierData = Sun.IdentifierData or {}

CreateThread(function()
    local jobs = MySQL.query.await('SELECT name, label FROM jobs')
    if jobs then
        for i = 1, #jobs do
            local j = jobs[i]
            Sun.Jobs.Labels[j.name] = j.label
        end
    end
    local grades = MySQL.query.await('SELECT job_name, grade, label, salary FROM job_grades')
    if grades then
        for i = 1, #grades do
            local g = grades[i]
            if not Sun.Jobs.GradeLabels[g.job_name] then
                Sun.Jobs.GradeLabels[g.job_name] = {}
            end
            Sun.Jobs.GradeLabels[g.job_name][g.grade] = { label = g.label, salary = g.salary }
        end
    end
    print('[Sun] Job loaded (' .. #(jobs or {}) .. ' jobs)')
end)

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

    local mData = Sun.Money.Data[identifier]
    local maxValues = {
        cash = Sun.Config.money.defaultMoneyLiquidMax,
        bank = Sun.Config.money.defaultMoneyBankMax,
        black = Sun.Config.money.defaultMoneyBlackMax,
    }

    local newAmount = (tonumber(mData[accountType]) or 0) + amount
    local cap = maxValues[accountType]
    local final = newAmount
    if cap and newAmount > cap then final = cap end
    mData[accountType] = final
    mData._dirty = true

    return true
end

function Sun.Money:removeMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0

    if amount <= 0 then return false end

    local mData = Sun.Money.Data[identifier]
    if not mData then return false end

    local current = tonumber(mData[accountType]) or 0

    if current < amount then
        return false
    end

    mData[accountType] = current - amount
    mData._dirty = true

    return true
end

function Sun.Money:setMoney(source, accountType, amount)
    local player = Sun.Players[source]
    if not player then return false end

    local identifier = player.identifier
    amount = tonumber(amount) or 0
    if amount < 0 then amount = 0 end

    local maxValues = {
        cash = Sun.Config.money.defaultMoneyLiquidMax,
        bank = Sun.Config.money.defaultMoneyBankMax,
        black = Sun.Config.money.defaultMoneyBlackMax,
    }

    local cap = maxValues[accountType]
    if cap and amount > cap then amount = cap end

    local mData = Sun.Money.Data[identifier]
    if not mData then
        Sun.Money.Data[identifier] = { cash = 0, bank = 0, black = 0 }
        mData = Sun.Money.Data[identifier]
    end

    mData[accountType] = amount
    mData._dirty = true

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

function Sun.Jobs:buildObject(jobName, grade)
    local gradeData = Sun.Jobs.GradeLabels[jobName] and Sun.Jobs.GradeLabels[jobName][grade] or {}
    return {
        name = jobName or "unemployed",
        grade = grade or 0,
        label = Sun.Jobs.Labels[jobName] or jobName or "Unemployed",
        gradeLabel = gradeData.label or "",
        salary = gradeData.salary or 0,
    }
end

function Sun.Weapons:load(identifier)
    local result = nil
    pcall(function()
        result = MySQL.single.await('SELECT loadout FROM users WHERE identifier = ? LIMIT 1', { identifier })
    end)
    if not result or not result.loadout then return {} end
    local ok, weapons = pcall(json.decode, result.loadout)
    return (ok and type(weapons) == "table") and weapons or {}
end

function Sun.Weapons:save(identifier)
    local data = self.Data[identifier]
    if not data then return end
    local ok, encoded = pcall(json.encode, data)
    if not ok then return end
    MySQL.update('UPDATE users SET loadout = ? WHERE identifier = ?', { encoded, identifier })
end

function Sun.Weapons:sanitizeAmmo(ammo)
    ammo = tonumber(ammo) or 0
    if ammo < 0 then return 0 end
    if ammo > 9999 then return 9999 end
    return ammo
end

function Sun.Weapons:sanitizeTint(tint)
    tint = tonumber(tint) or 0
    if tint < 0 then return 0 end
    if tint > 8 then return 8 end
    return tint
end

function Sun.Weapons:has(identifier, weaponHash)
    local data = self.Data[identifier]
    if not data then return false, nil end
    weaponHash = tonumber(weaponHash)
    if not weaponHash then return false, nil end
    for i = 1, #data do
        if data[i].weapon == weaponHash then
            return true, i
        end
    end
    return false, nil
end

function Sun.Weapons:add(identifier, weapon, ammo, tint)
    weapon = tonumber(weapon)
    if not weapon or weapon <= 0 then return false end

    if not self.Data[identifier] then self.Data[identifier] = {} end

    ammo = self:sanitizeAmmo(ammo)
    tint = self:sanitizeTint(tint)

    local found, idx = self:has(identifier, weapon)
    if found then
        self.Data[identifier][idx].ammo = ammo
        self.Data[identifier][idx].tint = tint
    else
        self.Data[identifier][#self.Data[identifier] + 1] = {
            weapon = weapon, ammo = ammo, tint = tint
        }
    end
    return true
end

function Sun.Weapons:remove(identifier, weapon)
    weapon = tonumber(weapon)
    if not weapon then return false end
    local data = self.Data[identifier]
    if not data then return false end
    for i = 1, #data do
        if data[i].weapon == weapon then
            data[i] = data[#data]
            data[#data] = nil
            return true
        end
    end
    return false
end

function Sun.Weapons:updateAmmo(identifier, weapon, ammo)
    local found, idx = self:has(identifier, weapon)
    if not found then return false end
    self.Data[identifier][idx].ammo = self:sanitizeAmmo(ammo)
    return true
end

function Sun.Weapons:updateTint(identifier, weapon, tint)
    local found, idx = self:has(identifier, weapon)
    if not found then return false end
    self.Data[identifier][idx].tint = self:sanitizeTint(tint)
    return true
end

function Sun.Jobs:sync(source, identifier)
    local data = Sun.Jobs.Data[identifier] or {}
    local legal = data.legal or {}
    local illegal = data.illegal or {}

    TriggerClientEvent("Sun:PlayerData:Update", source, "job", {
        legal = Sun.Jobs:buildObject(legal.name, legal.grade),
        illegal = Sun.Jobs:buildObject(illegal.name, illegal.grade),
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
    local inventory = Sun.Config.inventory.inventoryResourceName
    if inventory and GetResourceState(inventory) == "started" then
        return exports[inventory]:GetInventory(self.source)
    end
    return nil
end

function PlayerMethods:hasItem(itemName, quantity)
    local inventory = Sun.Config.inventory.inventoryResourceName
    if inventory and GetResourceState(inventory) == "started" then
        return exports[inventory]:HasItem(self.source, itemName, quantity or 1)
    end
    return false
end

function PlayerMethods:addItem(itemName, quantity)
    local inventory = Sun.Config.inventory.inventoryResourceName
    if not inventory or GetResourceState(inventory) ~= "started" then return false end
    local result = exports[inventory]:AddItem(self.source, itemName, quantity or 1)
    if result then
        TriggerClientEvent("Sun:Client:RefreshInventory", self.source)
    end
    return result or false
end

function PlayerMethods:removeItem(itemName, quantity)
    local inventory = Sun.Config.inventory.inventoryResourceName
    if not inventory or GetResourceState(inventory) ~= "started" then return false end
    local result = exports[inventory]:RemoveItem(self.source, itemName, quantity or 1)
    if result then
        TriggerClientEvent("Sun:Client:RefreshInventory", self.source)
    end
    return result or false
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

    local vData = Sun.Vehicles.Data[self.identifier]
    vData[#vData + 1] = {
        plate = plate,
        model = model,
        stored = true,
    }

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
        for i = 1, #vehicles do
            if vehicles[i].plate == plate then
                vehicles[i] = vehicles[#vehicles]
                vehicles[#vehicles] = nil
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

function PlayerMethods:kick(reason)
    DropPlayer(self.source, type(reason) == "string" and reason or "Kicked by admin")
end

function PlayerMethods:ban(reason, bannedBy)
    local banReason = type(reason) == "string" and reason or "Banned"
    MySQL.insert(
        'INSERT INTO sun_bans (identifier, reason, banned_by) VALUES (?, ?, ?)',
        { self.identifier, banReason, type(bannedBy) == "string" and bannedBy or "Server" }
    )
    DropPlayer(self.source, "Banned: " .. banReason)
end

function PlayerMethods:getLoadout()
    return Sun.Weapons.Data[self.identifier] or {}
end

function PlayerMethods:setLoadout(weapons)
    if type(weapons) ~= "table" then return false end
    Sun.Weapons.Data[self.identifier] = weapons
    TriggerClientEvent("Sun:Loadout:Restore", self.source, weapons)
    return true
end

local function createPlayer(source)
    local identifier = getIdentifier(source)
    if not identifier then return nil end

    return setmetatable({
        source = source,
        identifier = identifier,
        name = GetPlayerName(source) or nil,
        identifiers = Sun.IdentifierData[source] or {},
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
    local count = 0

    for _, player in pairs(self.Players) do
        if player then
            count = count + 1
            playersList[count] = player
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
    Sun.Weapons.Data[identifier] = Sun.Weapons:load(identifier)

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
            legal = Sun.Jobs:buildObject(legalJob.name, legalJob.grade),
            illegal = Sun.Jobs:buildObject(illegalJob.name, illegalJob.grade),
        },
        meta = Sun.PlayerMeta[identifier] or {},
        loadout = Sun.Weapons.Data[identifier] or {},
    })
end)

AddEventHandler("playerDropped", function()
    local src = source
    local player = Sun.Players[src]

    if not player then return end

    local identifier = player.identifier

    Sun.Money:saveMoney(identifier)
    Sun.Weapons:save(identifier)
    Sun.Money.Data[identifier] = nil
    Sun.Jobs.Data[identifier] = nil
    Sun.PlayerMeta[identifier] = nil
    Sun.GroupData[identifier] = nil
    Sun.Vehicles.Data[identifier] = nil
    Sun.Weapons.Data[identifier] = nil
    Sun.IdentifierData[src] = nil

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

    local identifier = player.identifier
    local moneyData = Sun.Money.Data[identifier] or {}
    local jobsData = Sun.Jobs.Data[identifier] or {}
    local legalJob = jobsData.legal or {}
    local illegalJob = jobsData.illegal or {}

    TriggerClientEvent("Sun:PlayerData:Load", src, {
        identifier = identifier,
        name = player.name,
        group = Sun.GroupData[identifier] or "user",
        money = {
            cash = tonumber(moneyData.cash) or 0,
            bank = tonumber(moneyData.bank) or 0,
            black = tonumber(moneyData.black) or 0,
        },
        job = {
            legal = Sun.Jobs:buildObject(legalJob.name, legalJob.grade),
            illegal = Sun.Jobs:buildObject(illegalJob.name, illegalJob.grade),
        },
        meta = Sun.PlayerMeta[identifier] or {},
        loadout = Sun.Weapons.Data[identifier] or {},
    })
end)

RegisterNetEvent("Sun:Loadout:Sync", function(weapons)
    local src = source
    if type(src) ~= "number" or src < 1 then return end
    local player = Sun:getPlayer(src)
    if not player then return end
    if type(weapons) ~= "table" or #weapons > 50 then return end
    local sanitized = {}
    local count = 0
    for i = 1, #weapons do
        local item = weapons[i]
        if type(item) == "table" and type(item.weapon) == "number" and item.weapon > 0 then
            local ammo = tonumber(item.ammo) or 0
            local tint = tonumber(item.tint) or 0
            if ammo < 0 then ammo = 0 elseif ammo > 9999 then ammo = 9999 end
            if tint < 0 then tint = 0 elseif tint > 8 then tint = 8 end
            count = count + 1
            sanitized[count] = { weapon = item.weapon, ammo = ammo, tint = tint }
        end
    end
    Sun.Weapons.Data[player.identifier] = sanitized
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