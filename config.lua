--[[
    JVL Recorder | Configuration
    Small panel to record clips with the Rockstar Editor without leaving the server: start, save, discard,
    and open the editor (that one disconnects you, it asks to press twice).

    Multiframework: Qbox, QBCore, ESX or standalone (auto-detected). No fxmanifest dependencies.
    Table (created on start): jvl_recorder_logs (only when Config.Log.database = true)
    ACE: add_ace group.admin jvl_recorder.use allow     -- who can use it (see Config.Permission)
    Convars (server only, "set"): set jvl_recorder_webhook "..."   Discord log ("" = off)
]]

Config = {}

Config.Framework = 'auto' -- 'auto' | 'qbox' | 'qb' | 'esx' | 'standalone'
Config.Locale = 'auto'    -- 'auto' (player's GTA language) | 'es' | 'en'

Config.Branding = {
    LogoUrl = 'https://r2.fivemanage.com/X1XK135fBbC6NDyRj5dwS/logomediacode.png', -- '' = icon
}

Config.Command = 'recorder' -- opens / closes the panel

-- Keys (players can change them in Settings > Key Bindings > FiveM). '' = no default key.
Config.Keys = {
    panel   = '',   -- open / close the panel (besides /recorder)
    record  = '7',  -- start recording
    save    = '8',  -- stop and save the clip
    discard = '9',  -- stop and throw the clip away
    editor  = '0',  -- open the Rockstar Editor (press twice: it disconnects you)
}
Config.KeysOnlyWithPanel = true -- true = the record / save / discard / editor keys only work while the panel is open

-- Open the Rockstar Editor from the server (key 0). The panel shows a note: on servers with many streamed
-- resources FiveM may crash on the way to the editor, so edit the clips after closing FiveM and opening it again.
Config.EditorButton = true

-- Who can use it: ACE `jvl_recorder.use`, OR one of these jobs, OR everybody
Config.Permission = {
    everyone = false,
    jobs = {}, -- e.g. { 'reporter', 'weazel' }
}

Config.Position = 'bottom-right' -- 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left'

Config.Log = {
    database = true, -- jvl_recorder_logs (start / save / discard / editor)
}

-- ─── INTEGRATION ─────────────────────────────────────────────────────────────
--- Client notification. kind: 'success' | 'error' | 'info'
function Notify(message, kind)
    if GetResourceState('jvl_notify') == 'started' then
        exports.jvl_notify:ShowNotification(kind or 'info', 'Recorder', message, 4000)
    elseif GetResourceState('ox_lib') == 'started' then
        TriggerEvent('ox_lib:notify', { title = 'Recorder', description = message, type = kind == 'info' and 'inform' or kind })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
    -- exports['okokNotify']:Alert('Recorder', message, 4000, kind or 'info')
    -- TriggerEvent('QBCore:Notify', message, kind == 'info' and 'primary' or kind, 4000)
    -- TriggerEvent('esx:showNotification', message)
    -- exports['wasabi_notify']:notify('Recorder', message, 4000, kind or 'info')
end
