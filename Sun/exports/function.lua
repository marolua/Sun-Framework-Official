exports("getSharedObject", function()
    return Sun
end)

exports("GetPlayer", function(source)
    return Sun and Sun.GetPlayer and Sun:GetPlayer(source) or nil
end)

exports("GetPlayerFromIdentifier", function(identifier)
    return Sun and Sun.GetPlayerFromIdentifier and Sun:GetPlayerFromIdentifier(identifier) or nil
end)

exports("GetPlayers", function()
    return Sun and Sun.GetPlayers and Sun:GetPlayers() or {}
end)

exports("GetPlayerIdentifier", function(source)
    return Sun and Sun.GetPlayerIdentifier and Sun:GetPlayerIdentifier(source) or nil
end)

exports("GetPlayerData", function(source)
    return Sun and Sun.GetPlayerData and Sun:GetPlayerData(source) or nil
end)

exports("GetGroup", function(source, refresh)
    return Sun and Sun.GetGroup and Sun:GetGroup(source, refresh) or nil
end)

exports("SetGroup", function(source, group)
    return Sun and Sun.SetGroup and Sun:SetGroup(source, group) or false
end)

exports("GetPlayerMeta", function(identifier, key)
    return Sun and Sun.GetPlayerMeta and Sun:GetPlayerMeta(identifier, key) or nil
end)

exports("SetPlayerMeta", function(identifier, key, value)
    return Sun and Sun.SetPlayerMeta and Sun:SetPlayerMeta(identifier, key, value) or false
end)

exports("RegisterCallback", function(name, callback)
    if Sun and Sun.Callbacks and Sun.Callbacks.Register then
        Sun.Callbacks:Register(name, callback)
        return true
    end
    return false
end)

exports("RegisterServerCallback", function(name, callback)
    if Sun and Sun.Callbacks and Sun.Callbacks.Register_Server then
        Sun.Callbacks:Register_Server(name, callback)
        return true
    end
    return false
end)

exports("TriggerCallback", function(source, name, callback, ...)
    if Sun and Sun.Callbacks and Sun.Callbacks.TriggerClient then
        Sun.Callbacks:TriggerClient(source, name, callback, ...)
        return true
    end
    return false
end)

exports("TriggerServerCallback", function(name, callback, ...)
    if Sun and Sun.Callbacks and Sun.Callbacks.Trigger_Server then
        Sun.Callbacks:Trigger_Server(name, callback, ...)
        return true
    end
    return false
end)

exports("RegisterUsableItem", function(itemName, callback)
    return Sun and Sun.RegisterUsableItem and Sun:RegisterUsableItem(itemName, callback) or false
end)

exports("UseItem", function(source, itemName)
    return Sun and Sun.UseItem and Sun:UseItem(source, itemName) or false
end)

exports("GetPlayerVehicles", function(source)
    local player = Sun and Sun:GetPlayer(source) or nil
    return player and player:getVehicles() or {}
end)

exports("AddPlayerVehicle", function(source, plate, model)
    local player = Sun and Sun:GetPlayer(source) or nil
    return player and player:addVehicle(plate, model) or false
end)

exports("RemovePlayerVehicle", function(source, plate)
    local player = Sun and Sun:GetPlayer(source) or nil
    return player and player:removeVehicle(plate) or false
end)
