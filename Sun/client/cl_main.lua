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
            if getIdentifier() then
                self:reloadRequest()
                return
            end
            self:connexion()
            Wait(500 + 500 * attempt) -- backoff: 1s, 1.5s, 2s, 2.5s, 3s
        end
    end)
end

function Sun:initialize()
    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(100) end
        Wait(3000)
        TriggerServerEvent("Sun:CallBack:Connexion")
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