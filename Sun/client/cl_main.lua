local function getIdentifier()
    local player = Player(PlayerId()).state

    if not player then
        return nil
    end

    local playerId = player.Sun_identifier

    return (type(playerId) == "string" and playerId ~= "") and playerId or nil
end

function Sun:connexion()
    if not getIdentifier() then
        TriggerServerEvent("Sun:CallBack:Connexion")
    end
end

function Sun:reloadRequest()
    TriggerServerEvent("Sun:ReloadRequest")
end

function Sun:reconnecting()
    CreateThread(function()
        Wait(1000)
        for attempt = 1, 5 do
            self:connexion()
            Wait(500)
            self:reloadRequest()
            Wait(500 * attempt) -- backoff: 500ms, 1s, 1.5s, 2s, 2.5s
            if getIdentifier() then
                return
            end
        end
    end)
end

function Sun:initialize()
    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(100) end
        Wait(3000)
        if getIdentifier() then
            self:connexion()
        else
            TriggerServerEvent("Sun:CallBack:Connexion")
        end
    end)

    RegisterNetEvent("Sun:RestartingServer", function()
        CreateThread(function()
            Wait(150)
            self:connexion()
            Wait(500)
            self:reloadRequest()
        end)
    end)

    AddEventHandler("onResourceStart", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then
            return
        end
        self:reconnecting()
    end)
end

exports("getSharedObject", function()
    return Sun
end)

Sun:initialize()