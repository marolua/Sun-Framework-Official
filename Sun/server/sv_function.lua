Sun = Sun or {}
Sun.Callbacks = Sun.Callbacks or {}
Sun.Callbacks.registry = Sun.Callbacks.registry or {}
Sun.Callbacks.serverRegistry = Sun.Callbacks.serverRegistry or {}
Sun.Callbacks.data = Sun.Callbacks.data or {}
Sun.Callbacks.dataSource = Sun.Callbacks.dataSource or {}
Sun.Callbacks.requestCallbackId = Sun.Callbacks.requestCallbackId or 0
Sun.usableItems = Sun.usableItems or {}

function Sun.Callbacks:register(name, callback)
    if type(name) ~= "string" or name == "" then return end
    if type(callback) ~= "function" then return end

    self.registry[name] = callback
end

function Sun.Callbacks:registerServer(name, callback)
    if type(name) ~= "string" or name == "" then return end
    if type(callback) ~= "function" then return end

    self.serverRegistry[name] = callback
end

function Sun.Callbacks:triggerServer(name, callback, ...)
    if type(name) ~= "string" or name == "" then return end

    local handler = self.serverRegistry[name]

    if type(handler) ~= "function" then
        if type(callback) == "function" then
            callback(nil)
        end
        return
    end

    local args = { ... }

    local function send(result)
        if type(callback) == "function" then
            callback(result)
        end
    end

    handler(send, table.unpack(args))
end

function Sun.Callbacks:triggerClient(source, name, callback, ...)
    if type(source) ~= "number" or source < 1 then return end
    if type(name) ~= "string" then return end

    self.requestCallbackId = self.requestCallbackId + 1

    local requestCallbackId = self.requestCallbackId
    local args = { ... }

    self.data[requestCallbackId] = function(result)
        self.data[requestCallbackId] = nil
        self.dataSource[requestCallbackId] = nil

        if type(callback) == "function" then
            callback(result)
        end
    end

    self.dataSource[requestCallbackId] = source

    TriggerClientEvent("Sun:Callback:Request", source, {
        requestCallbackId = requestCallbackId,
        name = name,
        args = args,
    })
end

-- Inventory callbacks
Sun.Callbacks:register("Sun:GetInventoryWeight", function(source, callback)
    local player = Sun:getPlayer(source)

    if not player then
        callback({ weight = 0 })
        return
    end

    local inventory = Sun.Config.inventory.inventoryResourceName

    if inventory and GetResourceState(inventory) == "started" then
        local weight = exports[inventory]:GetInventoryWeight(source)
        callback({ weight = weight or 0 })
    else
        callback({ weight = 0 })
    end
end)

Sun.Callbacks:register("Sun:GetInventoryMaxWeight", function(source, callback)
    local player = Sun:getPlayer(source)

    if not player then
        callback({ maxWeight = 0 })
        return
    end

    local inventory = Sun.Config.inventory.inventoryResourceName

    if inventory and GetResourceState(inventory) == "started" then
        local maxWeight = exports[inventory]:GetInventoryMaxWeight(source)
        callback({ maxWeight = maxWeight or 0 })
    else
        callback({ maxWeight = 0 })
    end
end)

Sun.Callbacks:register("Sun:CanCarry", function(source, callback, item, count)
    if not item or not count or count <= 0 then
        callback({ canCarry = false })
        return
    end

    local player = Sun:getPlayer(source)

    if not player then
        callback({ canCarry = false })
        return
    end

    local inventory = Sun.Config.inventory.inventoryResourceName

    if inventory and GetResourceState(inventory) == "started" then
        local canCarry = exports[inventory]:CanCarryItem(source, item, count)
        callback({ canCarry = canCarry or false })
    else
        callback({ canCarry = false })
    end
end)

-- Money callbacks (read-only, safe)
Sun.Callbacks:register("Sun:GetAccountBank", function(source, callback)
    local player = Sun:getPlayer(source)
    local bank = player and player:getMoney("bank") or 0
    callback({ bank = bank })
end)

Sun.Callbacks:register("Sun:GetAccountCash", function(source, callback)
    local player = Sun:getPlayer(source)
    local cash = player and player:getMoney("cash") or 0
    callback({ cash = cash })
end)

Sun.Callbacks:register("Sun:GetAccountDirty", function(source, callback)
    local player = Sun:getPlayer(source)
    local dirty = player and player:getMoney("black") or 0
    callback({ dirty = dirty })
end)

Sun.Callbacks:register("Sun:SetJob", function(source, callback, job)
    local callerGroup = Sun:getGroup(source) or "user"
    if not (Sun.Config.adminGroups and Sun.Config.adminGroups[callerGroup] == true) then
        callback({success = false})
        return
    end
    if type(job) ~= "table" or type(job.name) ~= "string" then
        callback({success = false})
        return
    end
    local player = Sun:getPlayer(source)
    local success = player and player:setJob(job.name, job.grade) or false
    callback({success = success})
end)

Sun.Callbacks:register("Sun:SetGroup", function(source, callback, group)
    local callerGroup = Sun:getGroup(source) or "user"
    if not (Sun.Config.adminGroups and Sun.Config.adminGroups[callerGroup] == true) then
        callback({success = false})
        return
    end
    if type(group) ~= "string" or group == "" or #group > 50 or not group:match("^[%w_%-]+$") then
        callback({success = false})
        return
    end
    local success = Sun:setGroup(source, group)
    callback({success = success})
end)

-- Usable items
function Sun:registerUsableItem(itemName, callback)
    if type(itemName) ~= "string" or itemName == "" then return false end
    if type(callback) ~= "function" then return false end

    self.usableItems[itemName] = callback

    return true
end

function Sun:useItem(source, itemName)
    if type(source) ~= "number" or source < 1 then return false end
    if type(itemName) ~= "string" or itemName == "" then return false end

    local player = self:getPlayer(source)
    if not player then return false end

    local callback = self.usableItems[itemName]
    if type(callback) ~= "function" then return false end

    callback(source, player)

    return true
end

local useItemRateLimit = {}

RegisterNetEvent("Sun:UseItem", function(itemName)
    local src = source
    if type(src) ~= "number" or src < 1 then return end
    if type(itemName) ~= "string" or itemName == "" or #itemName > 50 then return end

    local now = GetGameTimer()
    useItemRateLimit[src] = useItemRateLimit[src] or {}
    if useItemRateLimit[src][itemName] and (now - useItemRateLimit[src][itemName]) < 500 then
        return
    end
    useItemRateLimit[src][itemName] = now

    local player = Sun:getPlayer(src)
    if not player then return end

    if not player:hasItem(itemName, 1) then return end

    Sun:useItem(src, itemName)
end)

AddEventHandler("playerDropped", function()
    useItemRateLimit[source] = nil
end)

AddEventHandler("playerDropped", function(reason)
    local src = source

    if Sun.Players and Sun.Players[src] then
        TriggerEvent("Sun:OnPlayerDropped", src, reason)
        print("[Sun] The player " .. src .. " disconnected: " .. tostring(reason))
    end
    if Sun.callbackRateLimit then Sun.callbackRateLimit[src] = nil end
end)


RegisterNetEvent("Sun:Callback:ServerResponse", function(requestCallbackId, result)
    local src = source

    if type(src) ~= "number" or src < 1 then return end

    requestCallbackId = tonumber(requestCallbackId)
    if not requestCallbackId then return end

    if Sun.Callbacks.dataSource[requestCallbackId] ~= src then return end
    if not Sun.Callbacks.data[requestCallbackId] then return end

    if type(result) == "function" then return end

    if type(result) == "table" then
        for _, v in pairs(result) do
            if type(v) == "function" then return end
        end
    end

    Sun.Callbacks.data[requestCallbackId](result)
end)

RegisterNetEvent("Sun:Callback:Trigger", function(data)
    local src = source

    if type(src) ~= "number" or src < 1 then return end

    if type(data) ~= "table" then return end

    local name = data.name
    local requestCallbackId = data.requestCallbackId
    local args = data.args or {}

    if type(name) ~= "string" then return end
    if #name > 50 or not name:match("^[%w_:%-]+$") then return end
    if type(requestCallbackId) ~= "number" then return end

    Sun.callbackRateLimit = Sun.callbackRateLimit or {}
    if not Sun.callbackRateLimit[src] then Sun.callbackRateLimit[src] = {} end
    local now = GetGameTimer()
    if Sun.callbackRateLimit[src][name] and (now - Sun.callbackRateLimit[src][name]) < 500 then
        return
    end
    Sun.callbackRateLimit[src][name] = now

    if type(args) ~= "table" then return end
    if #args > 10 then return end

    for i = 1, #args do
        local arg = args[i]
        if type(arg) == "function" then return end
        if type(arg) == "table" then
            for _, v in pairs(arg) do
                if type(v) == "function" then return end
            end
        end
    end

    local callback = Sun.Callbacks.registry[name]

    local function send(result)
        if type(result) == "function" then return end
        if type(result) == "table" then
            for _, v in pairs(result) do
                if type(v) == "function" then return end
            end
        end
        TriggerClientEvent("Sun:Callback:Response", src, requestCallbackId, result)
    end

    if type(callback) == "function" then
        callback(src, send, table.unpack(args))
    else
        send(nil)
    end
end)
