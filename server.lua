--[[
    Server: who can use the recorder (ACE / job / everyone) and the log (database + optional Discord).
]]

local webhook = GetConvar('jvl_recorder_webhook', '')

local QBCore, ESX
if Framework == 'qb' then QBCore = exports['qb-core']:GetCoreObject()
elseif Framework == 'esx' then ESX = exports.es_extended:getSharedObject() end

local function jugador(source)
    if Framework == 'qbox' then return exports.qbx_core:GetPlayer(source) end
    if Framework == 'qb' then return QBCore.Functions.GetPlayer(source) end
    if Framework == 'esx' then return ESX.GetPlayerFromId(source) end
end

local function trabajo(source)
    local p = jugador(source)
    if not p then return end
    if Framework == 'esx' then return p.getJob().name end
    return p.PlayerData.job and p.PlayerData.job.name
end

local function puedeUsar(source)
    if Config.Permission.everyone or IsPlayerAceAllowed(source, 'jvl_recorder.use') then return true end
    local job = trabajo(source)
    for _, j in ipairs(Config.Permission.jobs or {}) do
        if j == job then return true end
    end
    return false
end

RegisterNetEvent('jvl_recorder:permiso', function()
    local source = source
    TriggerClientEvent('jvl_recorder:permiso', source, puedeUsar(source))
end)

-- ─── LOG ─────────────────────────────────────────────────────────────────────
if Config.Log.database then
    CreateThread(function()
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jvl_recorder_logs` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `name` VARCHAR(60) NOT NULL DEFAULT '',
            `action` VARCHAR(20) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    end)
end

local acciones = { start = true, save = true, discard = true, editor = true }
local ultimo = {} -- [source] = GetGameTimer(), simple anti spam

RegisterNetEvent('jvl_recorder:log', function(accion)
    local source = source
    if not acciones[accion] or not puedeUsar(source) then return end
    local ahora = GetGameTimer()
    if ultimo[source] and ahora - ultimo[source] < 1000 then return end
    ultimo[source] = ahora

    local nombre = GetPlayerName(source) or '?'
    local id = GetPlayerIdentifierByType(source, 'license') or '?'
    if Config.Log.database then
        MySQL.insert('INSERT INTO `jvl_recorder_logs` (`identifier`, `name`, `action`) VALUES (?, ?, ?)', { id, nombre:sub(1, 60), accion })
    end
    if webhook ~= '' then
        PerformHttpRequest(webhook, function() end, 'POST', json.encode({ username = 'JVL Recorder', embeds = { {
            title = 'Recorder: ' .. accion, description = ('%s (%s)'):format(nombre, source), color = 3447003,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
        } } }), { ['Content-Type'] = 'application/json' })
    end
end)

AddEventHandler('playerDropped', function() ultimo[source] = nil end)
