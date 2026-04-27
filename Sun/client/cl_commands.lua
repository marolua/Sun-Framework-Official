local function isAdmin()
    local group = Sun.Permissions and Sun.Permissions.group or "user"

    return Sun.Config.adminGroups[group] == true
end

function Sun:initializeCommands()
    RegisterCommand("car", function(k, args)
        local model = args and args[1] and tostring(args[1]):lower() or ""
        local vtype = args and args[2] and tostring(args[2]):lower() or nil

        if model == "" then
            return
        end

        TriggerServerEvent("Sun:SpawnVehicle", model, vtype)
    end, false)

    RegisterCommand("tp", function(k, args)
        if not isAdmin() then
            return
        end

        if not args[1] or not args[2] or not args[3] then
            return
        end

        local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])

        if not x or not y or not z then
            return
        end

        SetEntityCoords(PlayerPedId(), x, y, z, false, false, false)
    end, false)

    RegisterCommand("dv", function(k, args)
        if not isAdmin() then
            return
        end

        local distanceDv = args[1] and tonumber(args[1]) or 2.0

        local player = PlayerPedId()
        local playerCoord = GetEntityCoords(player)
        local vehicleDv = GetVehiclePedIsIn(player, false)

        if vehicleDv ~= 0 then
            SetEntityAsMissionEntity(vehicleDv, true, false)
            DeleteVehicle(vehicleDv)
            return
        end

        local pool = GetGamePool('CVehicle')
        for i = 1, #pool do
            local v = pool[i]
            if DoesEntityExist(v) then
                if #(playerCoord - GetEntityCoords(v)) <= distanceDv then
                    SetEntityAsMissionEntity(v, true, true)
                    DeleteVehicle(v)
                end
            end
        end
    end, false)
end

RegisterNetEvent("Sun:SpawnVehicle:Response", function(netId)
    netId = tonumber(netId)
    if not netId or netId == 0 then return end

    Citizen.CreateThread(function()
        local timeout = GetGameTimer() + 5000
        while not NetworkDoesEntityExistWithNetworkId(netId) and GetGameTimer() < timeout do
            Wait(50)
        end

        if not NetworkDoesEntityExistWithNetworkId(netId) then return end

        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if not vehicle or vehicle == 0 then return end

        SetVehicleOnGroundProperly(vehicle)
        SetVehicleEngineOn(vehicle, true, true, false)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end)

Sun:initializeCommands()