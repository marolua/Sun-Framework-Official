local function getIdentifier()
    local player = Player(PlayerId()).state

    if not player then
        return nil
    end

    local playerId = player.Sun_identifier

    return (type(playerId) == "string" and playerId ~= "") and playerId or nil
end

function Sun:Connexion()
    if not getIdentifier() then
        TriggerServerEvent("Sun:CallBack:Connexion")
    end
end

function Sun:ReloadRequest()
    TriggerServerEvent("Sun:ReloadRequest")
end

function Sun:Reconnecting()
    CreateThread(function()
        Wait(1200)
        for i = 1, 5 do
            self:Connexion()
            Wait(700)
            self:ReloadRequest()
            Wait(800)
            if getIdentifier() then
                break
            end
            Wait(400)
        end
    end)
end

function Sun:Initialize()
    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(100) end
        Wait(3000)
        if getIdentifier() then
            self:Connexion()
        else
            TriggerServerEvent("Sun:CallBack:Connexion")
        end
    end)

    RegisterNetEvent("Sun:RestartingServer", function()
        CreateThread(function()
            Wait(150)
            self:Connexion()
            Wait(500)
            self:ReloadRequest()
        end)
    end)

    AddEventHandler("onResourceStart", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then
            return
        end
        self:Reconnecting()
    end)
end

exports("getSharedObject", function()
    return Sun
end)

Sun:Initialize()