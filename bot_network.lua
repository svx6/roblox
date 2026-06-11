local Network = {}
local CommandCache = {}
local LoadedCommandCount = 0
local FailedCommands = {}
local CacheHits = 0
local TotalRequests = 0
local RetryQueue = {}
local MAX_RETRIES = 4
local BASE_BACKOFF = 0.5
local ActiveDownloads = 0
local MAX_CONCURRENT = 6
local DownloadSemaphore = {}

local function AcquireSlot()
    while ActiveDownloads >= MAX_CONCURRENT do task.wait(0.05) end
    ActiveDownloads = ActiveDownloads + 1
end
local function ReleaseSlot() ActiveDownloads = math.max(0, ActiveDownloads - 1) end

local function HttpGetWithRetry(url, Console, retries)
    retries = retries or 0
    TotalRequests = TotalRequests + 1
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and result and #result > 0 then
        if Console then Console.Network("GET", url, true) end
        return result
    end
    if not ok or not result then
        local ok2, result2 = pcall(function()
            local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
            if doReq then
                local r = doReq({Url = url, Method = "GET"})
                if r and r.StatusCode == 429 then
                    return nil, "RATE_LIMITED"
                end
                if r and r.Body and #r.Body > 0 then return r.Body end
            end
            return nil
        end)
        if ok2 and result2 then
            if Console then Console.Network("GET-ALT", url, true) end
            return result2
        end
    end
    if retries < MAX_RETRIES then
        local delay = BASE_BACKOFF * math.pow(2, retries) + math.random() * 0.5
        if Console then Console.Warn("HTTP retry " .. (retries+1) .. "/" .. MAX_RETRIES .. " in " .. string.format("%.1f", delay) .. "s", url) end
        task.wait(delay)
        return HttpGetWithRetry(url, Console, retries + 1)
    end
    if Console then Console.Network("GET", url, false) end
    return nil
end

local function LoadSingleCommand(fileName, rawUrl, BotEnv)
    local Console = BotEnv.Console
    local cmdName = fileName:gsub("%.lua$", ""):lower()
    if CommandCache[cmdName] then CacheHits = CacheHits + 1; return CommandCache[cmdName] end
    AcquireSlot()
    local source = HttpGetWithRetry(rawUrl, Console)
    ReleaseSlot()
    if not source then FailedCommands[#FailedCommands+1] = cmdName; return nil end
    local fn, err = loadstring(source)
    if not fn then FailedCommands[#FailedCommands+1] = cmdName; return nil end
    local ok, module = pcall(fn)
    if not ok or not module then FailedCommands[#FailedCommands+1] = cmdName; return nil end
    if type(module) ~= "table" or not module.Execute then FailedCommands[#FailedCommands+1] = cmdName; return nil end
    CommandCache[cmdName] = module
    BotEnv.CommandRegistry[cmdName] = module
    BotEnv.CommandPermissions[cmdName] = module.Permission or 1
    LoadedCommandCount = LoadedCommandCount + 1
    if module.Aliases and type(module.Aliases) == "table" then
        for _, a in ipairs(module.Aliases) do
            local al = a:lower(); BotEnv.AliasMap[al] = cmdName; BotEnv.CommandPermissions[al] = module.Permission or 1
        end
    end
    return module
end

local function DiscoverAndLoadAllCommands(BotEnv)
    local Console = BotEnv.Console
    local apiResponse = HttpGetWithRetry(BotEnv.GITHUB_API_BASE, Console)
    if not apiResponse then
        local manifestUrl = BotEnv.GITHUB_RAW_BASE .. "_manifest.lua"
        local ms = HttpGetWithRetry(manifestUrl, Console)
        if ms then
            local ok, manifest = pcall(function() local fn = loadstring(ms); if fn then return fn() end end)
            if ok and manifest and type(manifest) == "table" then
                local threads = {}
                for _, cf in ipairs(manifest) do
                    threads[#threads+1] = task.spawn(function() pcall(function() LoadSingleCommand(cf, BotEnv.GITHUB_RAW_BASE .. cf, BotEnv) end) end)
                end
                return
            end
        end
        return
    end
    local ok, fileList = pcall(function() return BotEnv.HttpService:JSONDecode(apiResponse) end)
    if not ok or not fileList or type(fileList) ~= "table" then return end
    local luaFiles = {}
    for _, item in ipairs(fileList) do
        if type(item) == "table" and item.name and item.name:match("%.lua$") and item.name ~= "_manifest.lua" then
            luaFiles[#luaFiles+1] = {name = item.name, url = item.download_url or (BotEnv.GITHUB_RAW_BASE .. item.name)}
        end
    end
    for _, f in ipairs(luaFiles) do
        task.spawn(function() pcall(function() LoadSingleCommand(f.name, f.url, BotEnv) end) end)
    end
    task.wait(0.5)
end

local function LazyLoadCommand(cmdName, BotEnv)
    return LoadSingleCommand(cmdName .. ".lua", BotEnv.GITHUB_RAW_BASE .. cmdName .. ".lua", BotEnv)
end

local function AddCommandFromUrl(url, BotEnv)
    local fileName = url:match("([^/]+)$") or "unknown.lua"
    if not fileName:match("%.lua$") then fileName = fileName .. ".lua" end
    local module = LoadSingleCommand(fileName, url, BotEnv)
    if module then return true, fileName:gsub("%.lua$", ""):lower() end
    return false, nil
end

local function ReloadAllCommands(BotEnv)
    CommandCache = {}; LoadedCommandCount = 0; FailedCommands = {}
    BotEnv.CommandRegistry = {}; BotEnv.AliasMap = {}
    DiscoverAndLoadAllCommands(BotEnv)
    task.wait(1)
    return LoadedCommandCount, #FailedCommands
end

local function GetNetworkStats()
    return {loaded = LoadedCommandCount, failed = #FailedCommands, failedList = FailedCommands, cacheHits = CacheHits, totalRequests = TotalRequests, activeDownloads = ActiveDownloads}
end

function Network.Setup(BotEnv)
    BotEnv.HttpGet = function(url) return HttpGetWithRetry(url, BotEnv.Console) end
    BotEnv.LoadSingleCommand = function(fn, ru) return LoadSingleCommand(fn, ru, BotEnv) end
    BotEnv.LazyLoadCommand = function(cn) return LazyLoadCommand(cn, BotEnv) end
    BotEnv.AddCommandFromUrl = function(u) return AddCommandFromUrl(u, BotEnv) end
    BotEnv.ReloadAllCommands = function() return ReloadAllCommands(BotEnv) end
    BotEnv.GetNetworkStats = GetNetworkStats
    BotEnv.GetLoadedCommandCount = function() return LoadedCommandCount end
    BotEnv.GetFailedCommands = function() return FailedCommands end
end

function Network.DiscoverAndLoadAll(BotEnv) DiscoverAndLoadAllCommands(BotEnv) end

return Network
