--[[
    Client: the panel (no NUI focus, the game keeps playing), rebindable keys and the Rockstar Editor
    natives. The recording state is read from the game (IsRecording), the panel only shows it.
]]

local abierto = false
local permitido = nil  -- nil = not asked yet
local esperando = nil  -- callback waiting for the server answer
local inicio = nil     -- GetGameTimer() when the recording started
local confirmarEditor = 0

local function textos()
    local t = {}
    for k in pairs(Locales.es) do if k:sub(1, 3) == 'ui_' then t[k] = L(k) end end
    return t
end

--- Key bound to one of our commands, as the player set it (e.g. "7"), or the config default.
local function teclaDe(comando, porDefecto)
    local boton = GetControlInstructionalButton(0, joaat(comando) | 0x80000000, true)
    if boton and boton:sub(1, 2) == 't_' then return boton:sub(3) end
    return porDefecto ~= '' and porDefecto or '—'
end

local function enviarEstado()
    if not abierto then return end
    SendNUIMessage({ action = 'state', recording = IsRecording(), seconds = inicio and math.floor((GetGameTimer() - inicio) / 1000) or 0 })
end

local function abrir()
    abierto = true
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'open', texts = textos(), logo = Config.Branding.LogoUrl, position = Config.Position,
        version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0),
        editor = Config.EditorButton,
        keys = {
            record = teclaDe('jvl_recorder_record', Config.Keys.record), save = teclaDe('jvl_recorder_save', Config.Keys.save),
            discard = teclaDe('jvl_recorder_discard', Config.Keys.discard), editor = teclaDe('jvl_recorder_editor', Config.Keys.editor),
        },
    })
    enviarEstado()
    CreateThread(function()
        while abierto do
            Wait(1000)
            enviarEstado()
        end
    end)
end

local function cerrar()
    abierto = false
    SendNUIMessage({ action = 'close' })
end

--- Runs `fn` only when the server says this player may use the recorder (answer cached).
local function conPermiso(fn)
    if permitido ~= nil then
        if permitido then fn() else Notify(L('no_permission'), 'error') end
        return
    end
    esperando = fn
    TriggerServerEvent('jvl_recorder:permiso')
end

RegisterNetEvent('jvl_recorder:permiso', function(ok)
    permitido = ok
    local fn = esperando
    esperando = nil
    if fn then
        if ok then fn() else Notify(L('no_permission'), 'error') end
    end
end)

-- Jobs can change: ask again after a while
CreateThread(function()
    while true do
        Wait(60000)
        permitido = nil
    end
end)

-- ─── ACTIONS ─────────────────────────────────────────────────────────────────
local function grabar()
    if IsRecording() then return Notify(L('already'), 'info') end
    StartRecording(1) -- 1 = manual recording
    inicio = GetGameTimer()
    TriggerServerEvent('jvl_recorder:log', 'start')
    Notify(L('started'), 'success')
    enviarEstado()
end

local function guardar()
    if not IsRecording() then return Notify(L('not_recording'), 'error') end
    StopRecordingAndSaveClip()
    inicio = nil
    TriggerServerEvent('jvl_recorder:log', 'save')
    SendNUIMessage({ action = 'flash', kind = 'save' })
    Notify(L('saved'), 'success')
    enviarEstado()
end

local function descartar()
    if not IsRecording() then return Notify(L('not_recording'), 'error') end
    StopRecordingAndDiscardClip()
    inicio = nil
    TriggerServerEvent('jvl_recorder:log', 'discard')
    SendNUIMessage({ action = 'flash', kind = 'discard' })
    Notify(L('discarded'), 'info')
    enviarEstado()
end

local function editor()
    if not Config.EditorButton then return end
    -- Opening the editor leaves the server: ask for a second press within 4 seconds
    if GetGameTimer() > confirmarEditor then
        confirmarEditor = GetGameTimer() + 4000
        return Notify(L('editor_confirm'), 'info')
    end
    confirmarEditor = 0
    if IsRecording() then StopRecordingAndSaveClip() end
    TriggerServerEvent('jvl_recorder:log', 'editor')
    Notify(L('editor_opening'), 'info')
    cerrar()
    SetTimeout(500, function()
        NetworkSessionLeaveSinglePlayer()
        ActivateRockstarEditor()
    end)
end

-- ─── COMMANDS AND KEYS ───────────────────────────────────────────────────────
RegisterCommand(Config.Command, function()
    if abierto then return cerrar() end
    conPermiso(abrir)
end, false)

local function tecla(nombre, accion, etiqueta, porDefecto)
    RegisterCommand(nombre, function()
        if Config.KeysOnlyWithPanel and not abierto then return end
        conPermiso(accion)
    end, false)
    RegisterKeyMapping(nombre, L(etiqueta), 'keyboard', porDefecto)
end

RegisterCommand('jvl_recorder_panel', function() ExecuteCommand(Config.Command) end, false)
RegisterKeyMapping('jvl_recorder_panel', L('key_panel'), 'keyboard', Config.Keys.panel)
tecla('jvl_recorder_record', grabar, 'key_record', Config.Keys.record)
tecla('jvl_recorder_save', guardar, 'key_save', Config.Keys.save)
tecla('jvl_recorder_discard', descartar, 'key_discard', Config.Keys.discard)
tecla('jvl_recorder_editor', editor, 'key_editor', Config.Keys.editor)

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    if IsRecording() then StopRecordingAndDiscardClip() end
end)
