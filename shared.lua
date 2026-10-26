--[[
    Shared: framework detection and translations.
]]

local frameworks = { { name = 'qbox', resource = 'qbx_core' }, { name = 'qb', resource = 'qb-core' }, { name = 'esx', resource = 'es_extended' } }

Framework = Config.Framework
if Framework == 'auto' then
    Framework = 'standalone'
    for _, f in ipairs(frameworks) do
        if GetResourceState(f.resource) == 'started' then Framework = f.name break end
    end
end

-- Client: the player's GTA language. Server: Spanish for console messages.
local locale = Config.Locale
if locale == 'auto' then
    if IsDuplicityVersion() then locale = 'es'
    else
        local gameLanguages = { [0] = 'en', 'fr', 'de', 'it', 'es', 'pt', 'pl', 'ru', 'ko', 'zh', 'ja', 'es', 'zh' }
        locale = gameLanguages[GetCurrentLanguage()] or 'en'
    end
end
if not Locales[locale] then locale = 'en' end

function L(key, ...)
    local text = (Locales[locale] and Locales[locale][key]) or (Locales.es and Locales.es[key]) or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end
