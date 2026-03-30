exports("getSharedObject", function()
    return Sun
end)

exports("GetPlayer", function(source)
    return Sun and Sun.getPlayer and Sun:getPlayer(source) or nil
end)

exports("GetPlayerFromIdentifier", function(identifier)
    return Sun and Sun.getPlayerFromIdentifier and Sun:getPlayerFromIdentifier(identifier) or nil
end)

exports("GetPlayers", function()
    return Sun and Sun.getPlayers and Sun:getPlayers() or {}
end)

exports("GetPlayerIdentifier", function(source)
    return Sun and Sun.getPlayerIdentifier and Sun:getPlayerIdentifier(source) or nil
end)

exports("GetPlayerData", function(source)
    return Sun and Sun.getPlayerData and Sun:getPlayerData(source) or nil
end)

exports("GetGroup", function(source, refresh)
    return Sun and Sun.getGroup and Sun:getGroup(source, refresh) or nil
end)

exports("SetGroup", function(source, group)
    return Sun and Sun.setGroup and Sun:setGroup(source, group) or false
end)

exports("GetPlayerMeta", function(identifier, key)
    return Sun and Sun.getPlayerMeta and Sun:getPlayerMeta(identifier, key) or nil
end)

exports("SetPlayerMeta", function(identifier, key, value)
    return Sun and Sun.setPlayerMeta and Sun:setPlayerMeta(identifier, key, value) or false
end)

exports("RegisterCallback", function(name, callback)
    if Sun and Sun.Callbacks and Sun.Callbacks.register then
        Sun.Callbacks:register(name, callback)
        return true
    end
    return false
end)

exports("RegisterServerCallback", function(name, callback)
    if Sun and Sun.Callbacks and Sun.Callbacks.registerServer then
        Sun.Callbacks:registerServer(name, callback)
        return true
    end
    return false
end)

exports("TriggerCallback", function(source, name, callback, ...)
    if Sun and Sun.Callbacks and Sun.Callbacks.triggerClient then
        Sun.Callbacks:triggerClient(source, name, callback, ...)
        return true
    end
    return false
end)

exports("TriggerServerCallback", function(name, callback, ...)
    if Sun and Sun.Callbacks and Sun.Callbacks.triggerServer then
        Sun.Callbacks:triggerServer(name, callback, ...)
        return true
    end
    return false
end)

exports("RegisterUsableItem", function(itemName, callback)
    return Sun and Sun.registerUsableItem and Sun:registerUsableItem(itemName, callback) or false
end)

exports("UseItem", function(source, itemName)
    return Sun and Sun.useItem and Sun:useItem(source, itemName) or false
end)

exports("GetPlayerVehicles", function(source)
    local player = Sun and Sun:getPlayer(source) or nil
    return player and player:getVehicles() or {}
end)

exports("AddPlayerVehicle", function(source, plate, model)
    local player = Sun and Sun:getPlayer(source) or nil
    return player and player:addVehicle(plate, model) or false
end)

exports("RemovePlayerVehicle", function(source, plate)
    local player = Sun and Sun:getPlayer(source) or nil
    return player and player:removeVehicle(plate) or false
end)
