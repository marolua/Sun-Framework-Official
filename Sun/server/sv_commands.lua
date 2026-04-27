local type, tonumber = type, tonumber

local function isAdmin(source)
    if source == 0 then
        return true
    end

    local group = Sun:getGroup(source)

    if not group then
        return false
    end

    return Sun.Config.adminGroups[group] == true
end

RegisterCommand("givemoney", function(source, args)
    if not isAdmin(source) then
        print("[Sun] You don't have permission to execute this command")
        return
    end

    local targetId = tonumber(args[1])
    local moneyType = args[2]
    local amount = tonumber(args[3])

    if not targetId or not moneyType or not amount or amount <= 0 then
        print("[Sun] The syntax of the command is not valid")
        return
    end

    local validMoney = { cash = true, bank = true, black = true }

    if not validMoney[moneyType] then
        print("[Sun] The money type informed is not valid")
        return
    end

    local player = Sun:getPlayer(targetId)

    if not player then
        print("[Sun] The player could not be found")
        return
    end

    player:addMoney(moneyType, amount)
    print("[Sun] Give money valid")
end, false)

local validVehicleTypes = {
    automobile = true, bike = true, boat = true, heli = true,
    plane = true, submarine = true, trailer = true, train = true, blimp = true
}

local spawnRateLimit = {}

RegisterNetEvent("Sun:SpawnVehicle", function(model, vtype)
    local src = source

    if not isAdmin(src) then
        print(("[Sun] %s tried to spawn a vehicle without permission"):format(GetPlayerName(src) or "unknown"))
        return
    end

    if type(model) ~= "string" or #model == 0 or #model > 64 or not model:match("^[%w_%-]+$") then
        return
    end

    local now = GetGameTimer()
    if spawnRateLimit[src] and (now - spawnRateLimit[src]) < 1000 then return end
    spawnRateLimit[src] = now

    vtype = (type(vtype) == "string" and validVehicleTypes[vtype]) and vtype or "automobile"

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local hash = joaat(model)

    local vehicle = CreateVehicleServerSetter(hash, vtype, coords.x, coords.y, coords.z + 0.5, heading)
    if not vehicle or vehicle == 0 then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerClientEvent("Sun:SpawnVehicle:Response", src, netId)
end)

AddEventHandler("playerDropped", function()
    spawnRateLimit[source] = nil
end)