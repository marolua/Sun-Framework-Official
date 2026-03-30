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
        print("[Sun] Your not have he permission for execute this command")
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
        print("[Sun] The player could has been not found")
        return
    end

    player:addMoney(moneyType, amount)
    print("[Sun] Give money valid")
end, false)

RegisterNetEvent("Sun:SpawnVehicle", function(model)
    local source = source

    if not isAdmin(source) then
        print("[Sun] " .. GetPlayerName(source) .. " tried to spawn a vehicle without permission")
        return
    end

    if type(model) ~= "string" or #model > 64 then
        return
    end

    TriggerClientEvent("Sun:SpawnVehicle:Response", source, model)
end)