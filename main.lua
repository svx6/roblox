local GITHUB_OWNER = "svx6"
local GITHUB_REPO = "roblox"
local GITHUB_BRANCH = "main"
local GITHUB_RAW_BASE = "https://raw.githubusercontent.com/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"

local function LoadModule(fileName)
    local url = GITHUB_RAW_BASE .. fileName
    local source = nil
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and result and #result > 0 then source = result end
    if not source then
        pcall(function()
            local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
            if doReq then local r = doReq({Url = url, Method = "GET"}); if r and r.Body and #r.Body > 0 then source = r.Body end end
        end)
    end
    if not source then warn("[MAIN] FAIL: " .. fileName); return nil end
    local fn, err = loadstring(source)
    if not fn then warn("[MAIN] COMPILE: " .. fileName .. " " .. tostring(err)); return nil end
    local eOk, mod = pcall(fn)
    if not eOk then warn("[MAIN] EXEC: " .. fileName .. " " .. tostring(mod)); return nil end
    return mod
end

local function LoadGameModule(fileName, BotEnv)
    local url = GITHUB_RAW_BASE .. "games/" .. fileName
    local source = nil
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and result and #result > 0 then source = result end
    if not source then
        pcall(function()
            local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
            if doReq then local r = doReq({Url = url, Method = "GET"}); if r and r.Body and #r.Body > 0 then source = r.Body end end
        end)
    end
    if not source then return nil end
    local fn, err = loadstring(source)
    if not fn then return nil end
    local eOk, mod = pcall(fn)
    if not eOk or not mod then return nil end
    return mod
end

print("╔══════════════════════════════════════════════════════════╗")
print("║  ULTRA-PERFORMANCE ENGINE v11.0                        ║")
print("║  Anti-Gravity Physics | Leak-Proof GC | MM2 Support    ║")
print("║  Exponential Backoff HTTP | Ring-Buffer Dedup          ║")
print("╚══════════════════════════════════════════════════════════╝")

print("[MAIN] 1/4: Core Engine...")
local BotEnv = LoadModule("bot_engine.lua")
if not BotEnv then error("[MAIN] FATAL: Engine failed"); return end

print("[MAIN] 2/4: Network Module...")
local Network = LoadModule("bot_network.lua")
if Network then Network.Setup(BotEnv) end

print("[MAIN] 3/4: Parser Module...")
local ParserModule = LoadModule("bot_parser.lua")
if ParserModule then ParserModule.Setup(BotEnv) end

print("[MAIN] 4/4: Game Modules...")
task.spawn(function()
    local mm2 = LoadGameModule("mm2.lua", BotEnv)
    if mm2 and mm2.Setup then
        mm2.Setup(BotEnv)
        BotEnv.GameModules.MM2 = mm2
        print("[MAIN] MM2 module loaded")
    end
end)

print("[MAIN] Discovering commands...")
task.spawn(function()
    if Network then Network.DiscoverAndLoadAll(BotEnv) end
    task.wait(1.5)
    local lc, fc = 0, 0
    if BotEnv.GetNetworkStats then local s = BotEnv.GetNetworkStats(); lc = s.loaded; fc = s.failed end
    pcall(function()
        BotEnv.SendNotification("Engine v11.0", "Commands: " .. lc .. " | Failed: " .. fc .. "\nPrefixes: ?bot .bot ,bot /bot\nOwner: " .. BotEnv.SuperOwner, 8)
    end)
    print("════════════════════════════════════════")
    print("BOOT COMPLETE | Cmds:" .. lc .. " Fail:" .. fc)
    print("Owner: " .. BotEnv.SuperOwner .. " | Mode: " .. BotEnv.BotMode())
    print("════════════════════════════════════════")

    pcall(function()
        BotEnv.PurgeDeadConnections()
        local alive, dead = 0, 0
        for _, d in pairs(BotEnv.ConnectionRegistry) do if d.alive then alive = alive + 1 else dead = dead + 1 end end
        print("[GC] Connections: " .. alive .. " alive, " .. dead .. " dead")
    end)
end)
