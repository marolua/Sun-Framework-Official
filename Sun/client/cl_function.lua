local waitCallback = {}
local svCallback = {}
local requestingIdCallback = 0

function Sun:triggerCallBack(name, cb, ...)
    requestingIdCallback = requestingIdCallback + 1
    waitCallback[requestingIdCallback] = cb

    TriggerServerEvent("Sun:Callback:Trigger", {
        name = name,
        requestCallbackId = requestingIdCallback,
        args = { ... }
    })
end

function Sun:registerCallBack(name, callback)
    svCallback[name] = callback
end

-- Inventory
function Sun.getInventoryWeight(cb)
    Sun:triggerCallBack("Sun:GetInventoryWeight", function(result)
        if type(cb) == "function" then
            cb(result and result.weight or 0)
        end
    end)
end

function Sun.getInventoryMaxWeight(cb)
    Sun:triggerCallBack("Sun:GetInventoryMaxWeight", function(result)
        if type(cb) == "function" then
            cb(result and result.maxWeight or 0)
        end
    end)
end

function Sun.canCarry(item, count, cb)
    if not item or not count or count <= 0 then
        if type(cb) == "function" then cb(false) end
        return
    end

    Sun:triggerCallBack("Sun:CanCarry", function(result)
        if type(cb) == "function" then
            cb(result and result.canCarry or false)
        end
    end, item, count)
end

-- Money
function Sun.getAccountCash(cb)
    Sun:triggerCallBack("Sun:GetAccountCash", function(result)
        if type(cb) == "function" then
            cb(result and result.cash or 0)
        end
    end)
end

function Sun.getAccountDirty(cb)
    Sun:triggerCallBack("Sun:GetAccountDirty", function(result)
        if type(cb) == "function" then
            cb(result and result.dirty or 0)
        end
    end)
end

function Sun.getAccountBank(cb)
    Sun:triggerCallBack("Sun:GetAccountBank", function(result)
        if type(cb) == "function" then
            cb(result and result.bank or 0)
        end
    end)
end

-- Lifecycle events
RegisterNetEvent("Sun:OnPlayerLoaded", function()
    print("[Sun] The player has been loaded")
end)

RegisterNetEvent("Sun:Client:OnJobUpdated", function(job)
    if type(job) ~= "table" then return end
    if not Sun.playerData.job then Sun.playerData.job = { legal = {}, illegal = {} } end
    Sun.playerData.job.legal.name = job.name or "unemployed"
    Sun.playerData.job.legal.grade = job.grade or 0
    print("[Sun] The job has been updated : " .. (job.name or "unknown"))
end)

RegisterNetEvent("Sun:Client:OnGroupUpdated", function(group)
    Sun.playerData.group = group
    Sun.Permissions.group = group
    print("[Sun] the group of the player has been updated : " .. group)
end)

RegisterNetEvent("Sun:Callback:Response", function(responseId, result)
    if waitCallback[responseId] then
        waitCallback[responseId](result)
        waitCallback[responseId] = nil
    end
end)

RegisterNetEvent("Sun:Callback:Request", function(data)
    if type(data) ~= "table" then return end

    local name = data.name
    local callbackId = data.requestCallbackId
    local handler = svCallback[name]

    local function sending(res)
        TriggerServerEvent("Sun:Callback:ServerResponse", callbackId, res)
    end

    if type(handler) == "function" then
        handler(sending, table.unpack(data.args or {}))
    else
        sending(nil)
    end
end)

function Sun.updatedPlayerJob(job, cb)
    if not job then
        if type(cb) == "function" then cb(false) end
        return
    end

    Sun:triggerCallBack("Sun:SetJob", function(result)
        if type(cb) == "function" then
            cb(result and result.success or false)
        end
    end, job)
end

function Sun.updatedPlayerGroup(group, cb)
    if not group then
        if type(cb) == "function" then cb(false) end
        return
    end

    Sun:triggerCallBack("Sun:SetGroup", function(result)
        if type(cb) == "function" then
            cb(result and result.success or false)
        end
    end, group)
end

function Sun.getPlayerJob()
    return Sun.playerData and Sun.playerData.job or nil
end

function Sun.getPlayerGroup()
    return (Sun.playerData and Sun.playerData.group) or "user"
end
