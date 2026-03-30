local listPlayers = {}
local listPlayerIdentifier = {}

local function registerPlayerIdentifiers(source)
    local ok, identifier = pcall(function()
        return Player(source).state.Sun_identifier
    end)

    if ok and type(identifier) == "string" and identifier ~= "" then
        listPlayers[source] = identifier
        listPlayerIdentifier[identifier] = source
    end
end

function Sun:GetIdentifier(source)
    if type(source) ~= "number" or source < 1 then
        return nil
    end

    if listPlayers[source] then
        return listPlayers[source]
    end

    local ok, identifier = pcall(function()
        return Player(source).state.Sun_identifier
    end)

    if ok and type(identifier) == "string" and identifier ~= "" then
        listPlayers[source] = identifier
        listPlayerIdentifier[identifier] = source
        return identifier
    end

    return nil
end

function Sun:GetSourceFromIdentifier(identifier)
    if type(identifier) ~= "string" or identifier == "" then
        return nil
    end

    local src = listPlayerIdentifier[identifier]

    if type(src) == "number" and src > 0 then
        return src
    end

    return nil
end

AddEventHandler("Sun:LoadingCharacter", function(source)
    if type(source) == "number" and source > 0 then
        registerPlayerIdentifiers(source)
    end
end)

AddEventHandler("playerDropped", function()
    local src        = source
    local identifier = listPlayers[src]

    if identifier then
        listPlayerIdentifier[identifier] = nil
    end

    listPlayers[src] = nil
end)
