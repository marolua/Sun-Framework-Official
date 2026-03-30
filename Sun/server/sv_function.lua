Sun = Sun or {}
Sun.Callbacks = Sun.Callbacks or {}
Sun.Callbacks.Registry = Sun.Callbacks.Registry or {}
Sun.Callbacks.Server_Registry = Sun.Callbacks.Server_Registry or {}
Sun.Callbacks.Data = Sun.Callbacks.Data or {}
Sun.Callbacks.Data_Source = Sun.Callbacks.Data_Source or {}
Sun.Callbacks.Request_Callback_Id = Sun.Callbacks.Request_Callback_Id or 0
Sun.Usable_Items = Sun.Usable_Items or {}

function Sun.Callbacks:Register(name, callback)
    if type(name) ~= "string" or name == "" then return end
    if type(callback) ~= "function" then return end

    self.Registry[name] = callback
end

function Sun.Callbacks:Register_Server(name, callback)
    if type(name) ~= "string" or name == "" then return end
    if type(callback) ~= "function" then return end

    self.Server_Registry[name] = callback
end

function Sun.Callbacks:Trigger_Server(name, callback, ...)
    if type(name) ~= "string" or name == "" then return end

    local handler = self.Server_Registry[name]

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

function Sun.Callbacks:TriggerClient(source, name, callback, ...)
    if type(source) ~= "number" or source < 1 then return end
    if type(name) ~= "string" then return end

    self.Request_Callback_Id = self.Request_Callback_Id + 1

    local requestCallbackId = self.Request_Callback_Id
    local args = { ... }

    self.Data[requestCallbackId] = function(result)
        self.Data[requestCallbackId] = nil
        self.Data_Source[requestCallbackId] = nil

        if type(callback) == "function" then
            callback(result)
        end
    end

    self.Data_Source[requestCallbackId] = source

    TriggerClientEvent("Sun:Callback:Request", source, {
        Request_Callback_Id = requestCallbackId,
        name = name,
        args = args,
    })
end

-- Inventory callbacks
Sun.Callbacks:Register("Sun:GetInventoryWeight", function(source, callback)
    local player = Sun:GetPlayer(source)

    if not player then
        callback({ weight = 0 })
        return
    end

    local inventory = Sun.Config.Inventory.Inventory_Resource_Name

    if inventory and GetResourceState(inventory) == "started" then
        local weight = exports[inventory]:GetInventoryWeight(source)
        callback({ weight = weight or 0 })
    else
        callback({ weight = 0 })
    end
end)

Sun.Callbacks:Register("Sun:GetInventoryMaxWeight", function(source, callback)
    local player = Sun:GetPlayer(source)

    if not player then
        callback({ maxWeight = 0 })
        return
    end

    local inventory = Sun.Config.Inventory.Inventory_Resource_Name

    if inventory and GetResourceState(inventory) == "started" then
        local maxWeight = exports[inventory]:GetInventoryMaxWeight(source)
        callback({ maxWeight = maxWeight or 0 })
    else
        callback({ maxWeight = 0 })
    end
end)

Sun.Callbacks:Register("Sun:CanCarry", function(source, callback, item, count)
    if not item or not count or count <= 0 then
        callback({ canCarry = false })
        return
    end

    local player = Sun:GetPlayer(source)

    if not player then
        callback({ canCarry = false })
        return
    end

    local inventory = Sun.Config.Inventory.Inventory_Resource_Name

    if inventory and GetResourceState(inventory) == "started" then
        local canCarry = exports[inventory]:CanCarryItem(source, item, count)
        callback({ canCarry = canCarry or false })
    else
        callback({ canCarry = false })
    end
end)

-- Money callbacks (read-only, safe)
Sun.Callbacks:Register("Sun:GetAccountBank", function(source, callback)
    local player = Sun:GetPlayer(source)
    local bank = player and player:getMoney("Bank") or 0
    callback({ bank = bank })
end)

Sun.Callbacks:Register("Sun:GetAccountCash", function(source, callback)
    local player = Sun:GetPlayer(source)
    local cash = player and player:getMoney("Cash") or 0
    callback({ cash = cash })
end)

Sun.Callbacks:Register("Sun:GetAccountDirty", function(source, callback)
    local player = Sun:GetPlayer(source)
    local dirty = player and player:getMoney("Black") or 0
    callback({ dirty = dirty })
end)

-- Usable items
function Sun:RegisterUsableItem(itemName, callback)
    if type(itemName) ~= "string" or itemName == "" then return false end
    if type(callback) ~= "function" then return false end

    self.Usable_Items[itemName] = callback

    return true
end

function Sun:UseItem(source, itemName)
    if type(source) ~= "number" or source < 1 then return false end
    if type(itemName) ~= "string" or itemName == "" then return false end

    local player = self:GetPlayer(source)
    if not player then return false end

    local callback = self.Usable_Items[itemName]
    if type(callback) ~= "function" then return false end

    callback(source, player)

    return true
end

AddEventHandler("playerDropped", function(reason)
    local src = source

    if Sun.Players and Sun.Players[src] then
        TriggerEvent("Sun:OnPlayerDropped", src, reason)
        print("[Sun] The player " .. src .. " disconnected: " .. tostring(reason))
    end
end)

function Sun.SetPlayerJob(source, job)
    if not Sun.Players or not Sun.Players[source] then return false end

    TriggerEvent("Sun:OnJobUpdated", source, job)
    TriggerClientEvent("Sun:Client:OnJobUpdated", source, job)

    return true
end

function Sun.SetPlayerGroup(source, group)
    if not Sun.Players or not Sun.Players[source] then return false end

    TriggerEvent("Sun:OnGroupUpdated", source, group)
    TriggerClientEvent("Sun:Client:OnGroupUpdated", source, group)

    return true
end

RegisterNetEvent("Sun:Callback:ServerResponse", function(requestCallbackId, result)
    local src = source

    if type(src) ~= "number" or src < 1 then return end

    requestCallbackId = tonumber(requestCallbackId)
    if not requestCallbackId then return end

    if Sun.Callbacks.Data_Source[requestCallbackId] ~= src then return end
    if not Sun.Callbacks.Data[requestCallbackId] then return end

    if type(result) == "function" then return end

    if type(result) == "table" then
        for _, v in pairs(result) do
            if type(v) == "function" then return end
        end
    end

    Sun.Callbacks.Data[requestCallbackId](result)
end)

RegisterNetEvent("Sun:Callback:Trigger", function(data)
    local src = source

    if type(src) ~= "number" or src < 1 then return end

    if Sun.CallbackRateLimit and Sun.CallbackRateLimit[src] and (GetGameTimer() - Sun.CallbackRateLimit[src]) < 100 then
        return
    end
    Sun.CallbackRateLimit = Sun.CallbackRateLimit or {}
    Sun.CallbackRateLimit[src] = GetGameTimer()

    if type(data) ~= "table" then return end

    local name              = data.name
    local requestCallbackId = data.Request_Callback_Id
    local args              = data.args or {}

    if type(name) ~= "string" then return end
    if string.len(name) > 50 or not string.match(name, "^[%w_:%-]+$") then return end
    if type(requestCallbackId) ~= "number" then return end
    if type(args) ~= "table" then return end
    if #args > 10 then return end

    for _, arg in ipairs(args) do
        if type(arg) == "function" then return end
        if type(arg) == "table" then
            for _, v in pairs(arg) do
                if type(v) == "function" then return end
            end
        end
    end

    local callback = Sun.Callbacks.Registry[name]

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
