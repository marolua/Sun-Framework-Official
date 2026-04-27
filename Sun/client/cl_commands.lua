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

RegisterNetEvent("Sun:SpawnVehicle:Response", function(model)
    local modelHash = GetHashKey(model)

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        return
    end

    Citizen.CreateThread(function()
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(0)
        end

        local player = PlayerPedId()
        local playerCoord = GetEntityCoords(player)
        local playerCoordHeading = GetEntityHeading(player)
        local playerCoordForwardVector = GetEntityForwardVector(player)

        local vehicle = CreateVehicle(modelHash, playerCoord.x + playerCoordForwardVector.x * 3.0, playerCoord.y + playerCoordForwardVector.y * 3.0, playerCoord.z + 0.5, playerCoordHeading, true, false)

        SetVehicleOnGroundProperly(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleEngineOn(vehicle, true, true, false)
        TaskWarpPedIntoVehicle(player, vehicle, -1)
        SetModelAsNoLongerNeeded(modelHash)
    end)
end)

Sun:initializeCommands()