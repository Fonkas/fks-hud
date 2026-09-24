---------------------------------------------------------------------------
-- Update checker: compares the version in fxmanifest.lua with the latest
-- GitHub release of Config.VersionCheck.repo and warns in the server console.
---------------------------------------------------------------------------
local cfg = Config.VersionCheck
local resource = GetCurrentResourceName()

-- '1.2.10' -> { 1, 2, 10 }
local function parse(v)
    local parts = {}
    for n in tostring(v):gsub('^[vV]', ''):gmatch('%d+') do parts[#parts + 1] = tonumber(n) end
    return parts
end

local function isNewer(latest, current)
    local a, b = parse(latest), parse(current)
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

local function check()
    local current = GetResourceMetadata(resource, 'version', 0) or '0.0.0'
    local url = ('https://api.github.com/repos/%s/releases/latest'):format(cfg.repo)

    PerformHttpRequest(url, function(status, body)
        if status == 404 then
            return -- no release published yet
        end
        if status ~= 200 or not body then
            print(('^3[%s] could not check for updates (HTTP %s)^0'):format(resource, tostring(status)))
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' or not data.tag_name then return end

        local latest = data.tag_name:gsub('^[vV]', '')
        if isNewer(latest, current) then
            print('^1================================================================^0')
            print(('^1[%s] OUTDATED VERSION^0  installed: ^3%s^0  ->  latest: ^2%s^0'):format(resource, current, latest))
            if data.name and data.name ~= '' and data.name ~= data.tag_name then
                print(('^1[%s]^0 %s'):format(resource, data.name))
            end
            print(('^1[%s]^0 download: %s'):format(resource, data.html_url or ('https://github.com/' .. cfg.repo .. '/releases/latest')))
            print('^1================================================================^0')
        else
            print(('^2[%s] up to date (v%s)^0'):format(resource, current))
        end
    end, 'GET', '', {
        ['User-Agent'] = resource,
        ['Accept']     = 'application/vnd.github+json',
    })
end

CreateThread(function()
    if not cfg or not cfg.enabled or not cfg.repo or cfg.repo == '' or cfg.repo:find('YOUR_GITHUB_USER', 1, true) then
        return
    end
    Wait(5000) -- let the server finish starting
    check()

    -- check again from time to time (servers that run for days)
    local hours = tonumber(cfg.interval) or 0
    while hours > 0 do
        Wait(hours * 3600000)
        check()
    end
end)
