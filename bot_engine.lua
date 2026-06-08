--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║        HIGH-PERFORMANCE COMMAND ENGINE v9.0                 ║
    ║        Zero Hardcoded Commands | GitHub Auto-Discovery      ║
    ║        Repo: svx6/roblox | Folder: commands/                ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- SECTION 1: ENVIRONMENT BOOTSTRAP
-- ═══════════════════════════════════════════════════════════════

local genv = _G or {}
if type(getgenv) == "function" then
    local s, r = pcall(getgenv)
    if s and type(r) == "table" then
        genv = r
    end
end

if genv.__ULTIMATE_BOT_LOADED then
    pcall(function()
        if genv.__ULTIMATE_BOT_CLEANUP then genv.__ULTIMATE_BOT_CLEANUP() end
    end)
end
genv.__ULTIMATE_BOT_LOADED = true

local _unpack = unpack or table.unpack or function(t, i, j)
    i = i or 1
    j = j or #t
    if i > j then return end
    local n = j - i + 1
    if n <= 0 then return end
    if n == 1 then return t[i] end
    if n == 2 then return t[i], t[i+1] end
    if n == 3 then return t[i], t[i+1], t[i+2] end
    if n == 4 then return t[i], t[i+1], t[i+2], t[i+3] end
    if n == 5 then return t[i], t[i+1], t[i+2], t[i+3], t[i+4] end
    if n == 6 then return t[i], t[i+1], t[i+2], t[i+3], t[i+4], t[i+5] end
    if n == 7 then return t[i], t[i+1], t[i+2], t[i+3], t[i+4], t[i+5], t[i+6] end
    if n == 8 then return t[i], t[i+1], t[i+2], t[i+3], t[i+4], t[i+5], t[i+6], t[i+7] end
    return t[i], t[i+1], t[i+2], t[i+3], t[i+4], t[i+5], t[i+6], t[i+7]
end

do
    local _ok, _existingTask = pcall(function() return task end)
    if not _ok or not _existingTask or type(_existingTask) ~= "table" then
        pcall(function() task = {} end)
        if type(task) ~= "table" then
            pcall(function()
                if rawset then rawset(_G, "task", {}) end
            end)
            pcall(function()
                if rawget then task = rawget(_G, "task") end
            end)
        end
    end
end
if type(task) ~= "table" then task = {} end
if not task.spawn then
    task.spawn = function(fn, ...)
        local args = {...}
        coroutine.wrap(function() fn(_unpack(args)) end)()
    end
end
if not task.wait then
    task.wait = function(t)
        local _tick = tick or os.clock or function() return 0 end
        local s = _tick()
        repeat game:GetService("RunService").Heartbeat:Wait() until _tick() - s >= (t or 0.03)
        return _tick() - s
    end
end
if not task.delay then
    task.delay = function(t, fn) task.spawn(function() task.wait(t); fn() end) end
end
if not task.defer then
    task.defer = task.spawn
end
if not task.cancel then
    task.cancel = function() end
end
if not string.split then
    string.split = function(str, sep)
        if not str then return {} end
        if not sep or sep == "" then
            local result = {}
            for i = 1, #str do
                table.insert(result, str:sub(i, i))
            end
            return result
        end
        local result = {}
        local start = 1
        local sepLen = #sep
        while true do
            local found = str:find(sep, start, true)
            if not found then
                table.insert(result, str:sub(start))
                break
            end
            table.insert(result, str:sub(start, found - 1))
            start = found + sepLen
        end
        return result
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 2: CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local SuperOwner      = "roboxproplyer"
local Prefixes        = {"?bot ", ".bot ", ",bot ", "/bot "}
local FlingPower      = 9999999
local LoopFlingDelay  = 0.8
local FollowDistance  = 5
local OrbitRadius     = 12
local OrbitSpeed      = 3
local CooldownTime    = 0.15
local FlySpeed        = 80
local SpinSpeed       = 20
local AnnoyDelay      = 0.08
local BringIterations = 250
local BringDelay      = 0
local ChatRateLimit   = 1.0
local BotStartTime    = (tick or os.clock or function() return 0 end)()
local BotMode         = "private"
local LastTarget      = nil

-- GitHub Auto-Discovery Config
local GITHUB_OWNER    = "svx6"
local GITHUB_REPO     = "roblox"
local GITHUB_BRANCH   = "main"
local GITHUB_CMD_PATH = "commands"
local GITHUB_RAW_BASE = "https://raw.githubusercontent.com/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/" .. GITHUB_CMD_PATH .. "/"
local GITHUB_API_BASE = "https://api.github.com/repos/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO .. "/contents/" .. GITHUB_CMD_PATH

-- ═══════════════════════════════════════════════════════════════
-- SECTION 3: ADVANCED DEBUG CONSOLE
-- ═══════════════════════════════════════════════════════════════

local Console = {}
Console.History = {}
Console.MaxHistory = 500
Console.Categories = {
    CMD  = {color = "🟢", label = "CMD "},
    LOAD = {color = "🔵", label = "LOAD"},
    ERR  = {color = "🔴", label = "ERR "},
    WARN = {color = "🟡", label = "WARN"},
    PERM = {color = "🟣", label = "PERM"},
    NET  = {color = "🌐", label = "NET "},
    SYS  = {color = "⚙️", label = "SYS "},
    DBG  = {color = "🔧", label = "DBG "},
}

function Console.Log(category, message, details)
    local catInfo = Console.Categories[category] or Console.Categories.SYS
    local timestamp = os.date("%H:%M:%S")
    local entry = {
        time = timestamp,
        category = category,
        message = message,
        details = details or "",
        tick = tick(),
    }
    table.insert(Console.History, entry)
    if #Console.History > Console.MaxHistory then
        table.remove(Console.History, 1)
    end
    local detailStr = details and (" | " .. tostring(details)) or ""
    print(string.format("[%s] %s [%s] %s%s", timestamp, catInfo.color, catInfo.label, message, detailStr))
end

function Console.Error(message, details)
    Console.Log("ERR", message, details)
end

function Console.Warn(message, details)
    Console.Log("WARN", message, details)
end

function Console.Command(executor, cmdName, target, execTime)
    local timeStr = execTime and string.format(" (%.1fms)", execTime * 1000) or ""
    local targetStr = target and (" -> " .. tostring(target)) or ""
    Console.Log("CMD", executor .. " > " .. cmdName .. targetStr .. timeStr)
end

function Console.Network(action, url, success)
    local statusStr = success and "OK" or "FAIL"
    Console.Log("NET", action .. " [" .. statusStr .. "]", url)
end

function Console.Permission(player, cmd, allowed, level)
    local statusStr = allowed and "GRANTED" or "DENIED"
    Console.Log("PERM", player .. " " .. statusStr .. " for '" .. cmd .. "'", "Level: " .. tostring(level))
end

function Console.GetRecentLogs(count, categoryFilter)
    count = count or 20
    local filtered = {}
    for i = #Console.History, 1, -1 do
        local entry = Console.History[i]
        if not categoryFilter or entry.category == categoryFilter then
            table.insert(filtered, 1, entry)
            if #filtered >= count then break end
        end
    end
    return filtered
end

function Console.GetSystemDump()
    local lines = {}
    table.insert(lines, "=== SYSTEM STATE DUMP ===")
    table.insert(lines, "Uptime: " .. string.format("%.1f", tick() - BotStartTime) .. "s")
    table.insert(lines, "Mode: " .. BotMode)
    table.insert(lines, "SuperOwner: " .. SuperOwner)
    table.insert(lines, "Log entries: " .. #Console.History)
    return table.concat(lines, "\n")
end

Console.Log("SYS", "Advanced Debug Console initialized", "Max history: " .. Console.MaxHistory)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 4: GAME SERVICES
-- ═══════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui         = game:GetService("StarterGui")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocalPlayer        = Players.LocalPlayer

local TextChatService    = nil
pcall(function() TextChatService = game:GetService("TextChatService") end)
local VirtualUser        = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)
local TeleportService    = nil
pcall(function() TeleportService = game:GetService("TeleportService") end)
local HttpService        = nil
pcall(function() HttpService = game:GetService("HttpService") end)
local MarketplaceService = nil
pcall(function() MarketplaceService = game:GetService("MarketplaceService") end)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 5: EXECUTOR DETECTION
-- ═══════════════════════════════════════════════════════════════

local function _safeTypeCheck(name)
    local ok, result = pcall(function()
        local lookupTable = {
            firetouchinterest = function() return firetouchinterest end,
            gethiddenproperty = function() return gethiddenproperty end,
            sethiddenproperty = function() return sethiddenproperty end,
            setclipboard = function() return setclipboard end,
            getgenv = function() return getgenv end,
            request = function() return request end,
            http_request = function() return http_request end,
            setfpscap = function() return setfpscap end,
        }
        local getter = lookupTable[name]
        if not getter then return false end
        local ok2, val = pcall(getter)
        if not ok2 then return false end
        return type(val) == "function"
    end)
    return ok and result or false
end

local ExecutorInfo = {
    HasFireTouchInterest = _safeTypeCheck("firetouchinterest"),
    HasGetHiddenProperty = _safeTypeCheck("gethiddenproperty"),
    HasSetHiddenProperty = _safeTypeCheck("sethiddenproperty"),
    HasSetClipboard      = _safeTypeCheck("setclipboard"),
    HasGetGenv           = _safeTypeCheck("getgenv"),
    HasHttpRequest       = _safeTypeCheck("request") or _safeTypeCheck("http_request"),
    HasSetFpsCap         = _safeTypeCheck("setfpscap"),
    ExecutorName         = "Unknown",
}
pcall(function()
    if identifyexecutor then
        ExecutorInfo.ExecutorName = identifyexecutor()
    elseif getexecutorname then
        ExecutorInfo.ExecutorName = getexecutorname()
    elseif syn and syn.about then
        ExecutorInfo.ExecutorName = "Synapse X"
    elseif fluxus then
        ExecutorInfo.ExecutorName = "Fluxus"
    elseif KRNL_LOADED then
        ExecutorInfo.ExecutorName = "KRNL"
    end
end)

pcall(function()
    if ExecutorInfo.HasSetFpsCap then
        setfpscap(999)
    end
end)

Console.Log("SYS", "Executor detected: " .. ExecutorInfo.ExecutorName)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 6: STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════

local PermittedUsers = {
    [SuperOwner:lower()] = 4
}

local CommandPermissions = {}

local ActiveConnections  = {}
local AllConnectionNames = {
    "LoopFling", "LoopKill", "LoopFlingAll", "Follow", "Orbit", "Attach",
    "Annoy", "NoClip", "Fly", "God", "GodHealth", "AntiAFK", "AntiVoid",
    "InfJump", "Spin", "Stare", "ESP", "CoinFarm", "Farm", "BlackHole",
    "Strobe", "Creep", "Mimic", "Trail", "GodKnife", "Tornado", "Seizure",
    "Dance", "FloorFly", "Aura", "Track", "Magnet", "AntiSlow", "AntiFling",
    "LoopTP", "AutoShoot", "AutoMurd", "WallBang", "AutoRespawn",
}
for _, name in ipairs(AllConnectionNames) do
    ActiveConnections[name] = nil
end

local FlyBodyGyro       = nil
local FlyBodyVelocity   = nil
local IsFlying          = false
local IsNoClip          = false
local IsGodMode         = false
local IsAntiAFK         = false
local IsAntiVoid        = false
local IsInfJump         = false
local IsSpinning        = false
local IsCoinFarming     = false
local IsFarming         = false
local IsBlackHole       = false
local IsStrobing        = false
local IsGodKnife        = false
local IsMimicking       = false
local IsCreeping        = false
local IsTrailing        = false
local IsDancing         = false
local IsFloorFlying     = false
local IsAuraActive      = false
local IsTracking        = false
local IsFlingBusy       = false
local IsMagnetOn        = false
local IsAntiSlow        = false
local IsAntiFling       = false
local IsLoopTP          = false
local IsAutoShoot       = false
local IsAutoMurd        = false
local IsWallBang        = false
local IsAutoRespawn     = false
local PreferredFlingMethod = 0
local FloorFlyTarget    = nil
local FloorFlyPlatform  = nil
local TrackTarget       = nil
local TrackLastPos      = nil
local LoopTPTarget      = nil
local AutoShootTarget   = nil
local AutoMurdTarget    = nil
local SavedCFrame       = nil
local ESPObjects        = {}
local CommandCooldowns  = {}
local CommandLog        = {}
local PlatformPart      = nil
local CageParts         = {}
local TrailParts        = {}
local XRayParts         = {}
local AuraParts         = {}
local FreezeCages       = {}
local OriginalGravity   = Workspace.Gravity
local OriginalLighting  = {}
local LastChatTime      = 0
local GodHealthConnection = nil
local GodDiedConnection = nil
local CommandDedup      = {}
local DEDUP_WINDOW      = 0.3
local OriginalCameraSubject = nil

pcall(function()
    OriginalLighting.Ambient = Lighting.Ambient
    OriginalLighting.Brightness = Lighting.Brightness
    OriginalLighting.FogEnd = Lighting.FogEnd
    OriginalLighting.FogStart = Lighting.FogStart
    OriginalLighting.ClockTime = Lighting.ClockTime
    OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
end)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 7: CORE UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function GetCharacter(player)
    if not player then return nil end
    return player.Character
end

local function GetHRP(player)
    local char = GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    if not player or not player.Parent then return false end
    local hum = GetHumanoid(player)
    if not hum then return false end
    return hum.Health > 0
end

local function GetBotHRP()    return GetHRP(LocalPlayer) end
local function GetBotHumanoid() return GetHumanoid(LocalPlayer) end
local function IsBotAlive()   return IsAlive(LocalPlayer) end

local function EnsureCharacter()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
        task.wait(0.3)
    end
    return LocalPlayer.Character
end

local function DisconnectSafe(name)
    if ActiveConnections[name] then
        pcall(function() ActiveConnections[name]:Disconnect() end)
        ActiveConnections[name] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 8: CHAT BYPASS & MESSAGING
-- ═══════════════════════════════════════════════════════════════

local HomoglyphMap = {
    a = {string.char(208, 176), string.char(201, 145)},
    e = {string.char(208, 181), string.char(196, 153)},
    o = {string.char(208, 190), string.char(195, 182)},
    c = {string.char(209, 129), string.char(196, 135)},
    p = {string.char(209, 128)},
    s = {string.char(209, 149), string.char(197, 155)},
    i = {string.char(209, 150), string.char(195, 173)},
    x = {string.char(209, 133)},
    y = {string.char(209, 131), string.char(195, 189)},
    n = {string.char(208, 191)},
    h = {string.char(210, 187)},
    d = {string.char(212, 129)},
    g = {string.char(201, 161)},
    k = {string.char(210, 155)},
    l = {string.char(209, 150)},
    m = {string.char(208, 188)},
    t = {string.char(209, 130)},
    u = {string.char(209, 131)},
    v = {string.char(209, 131)},
    w = {string.char(209, 161)},
    r = {string.char(208, 179)},
}
local ZeroWidthSpace = string.char(226, 128, 139)
local ZeroWidthNJ    = string.char(226, 128, 140)
local ZeroWidthJ     = string.char(226, 128, 141)
local HairSpace      = string.char(226, 128, 138)
local ThinSpace      = string.char(226, 128, 137)
local InvisChars = {ZeroWidthSpace, ZeroWidthNJ, ZeroWidthJ, HairSpace}

local function BypassText(text)
    if not text or #text == 0 then return text end
    local result = ""
    local insertCounter = 0
    for i = 1, #text do
        local ch = text:sub(i, i)
        local lower = ch:lower()
        if HomoglyphMap[lower] and math.random(1, 5) <= 2 then
            local glyphs = HomoglyphMap[lower]
            result = result .. glyphs[math.random(1, #glyphs)]
        else
            result = result .. ch
        end
        insertCounter = insertCounter + 1
        if insertCounter >= math.random(2, 4) and i < #text and ch ~= " " then
            result = result .. InvisChars[math.random(1, #InvisChars)]
            insertCounter = 0
        end
    end
    return result
end

local function SendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "Bot",
            Text     = text or "",
            Duration = duration or 3,
        })
    end)
end

local function SendChatMessage(text)
    local now = tick()
    if (now - LastChatTime) < ChatRateLimit then return end
    LastChatTime = now
    pcall(function()
        if TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                local rbxGeneral = channels:FindFirstChild("RBXGeneral")
                if rbxGeneral then
                    rbxGeneral:SendAsync(text)
                    return
                end
            end
        end
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayMsg = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMsg then
                sayMsg:FireServer(text, "All")
                return
            end
        end
    end)
end

local function SendWhisperMessage(targetPlayer, text)
    if not targetPlayer then return end
    pcall(function()
        if TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                for _, channel in ipairs(channels:GetChildren()) do
                    if channel.Name:find("RBXWhisper") and channel.Name:find(tostring(targetPlayer.UserId)) then
                        channel:SendAsync(text)
                        return
                    end
                end
                local rbxGeneral = channels:FindFirstChild("RBXGeneral")
                if rbxGeneral then
                    rbxGeneral:SendAsync("/w " .. targetPlayer.Name .. " " .. text)
                    return
                end
            end
        end
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayMsg = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMsg then
                sayMsg:FireServer("/w " .. targetPlayer.Name .. " " .. text, "All")
            end
        end
    end)
end

local function Respond(message, whisperTarget, forceChat)
    Console.Log("SYS", "Response: " .. message)
    SendNotification("Bot", message, 3)
    if whisperTarget then
        pcall(function() SendWhisperMessage(whisperTarget, BypassText(message)) end)
    elseif forceChat then
        pcall(function() SendChatMessage(BypassText(message)) end)
    end
end

local function RespondPrivate(message, targetPlayer)
    Console.Log("SYS", "Private: " .. message)
    SendNotification("Bot", message, 5)
    if targetPlayer then
        pcall(function() SendWhisperMessage(targetPlayer, BypassText(message)) end)
    end
end

local function RespondError(message, whisperTarget)
    Console.Error("Response Error: " .. message)
    SendNotification("Bot Error", message, 4)
    if whisperTarget then
        pcall(function() SendWhisperMessage(whisperTarget, BypassText(message)) end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 9: PERMISSION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function GetPermLevel(player)
    if not player then return 0 end
    if player.Name:lower() == SuperOwner:lower() then return 4 end
    local stored = PermittedUsers[player.Name:lower()] or 0
    if BotMode == "public" and stored < 1 then return 1 end
    return stored
end

local function HasPermission(player, command)
    local playerLevel = GetPermLevel(player)
    local requiredLevel = CommandPermissions[command] or 1
    local allowed = playerLevel >= requiredLevel
    Console.Permission(player.Name, command, allowed, playerLevel)
    return allowed
end

local function IsSuperOwner(player)
    return player and player.Name:lower() == SuperOwner:lower()
end

local function CanUseBot(player)
    if IsSuperOwner(player) then return true end
    if GetPermLevel(player) >= 1 then return true end
    return false
end

local function IsOnCooldown(player)
    if IsSuperOwner(player) then return false end
    local key = player.Name:lower()
    local lastUse = CommandCooldowns[key]
    if lastUse and (tick() - lastUse) < CooldownTime then return true end
    CommandCooldowns[key] = tick()
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 10: TARGET RESOLUTION
-- ═══════════════════════════════════════════════════════════════

local function GetMultipleTargets(stringInput, executorPlayer)
    if not stringInput or stringInput == "" then return {} end
    stringInput = stringInput:lower():match("^%s*(.-)%s*$")

    if stringInput == "all" then
        local targets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(targets, p) end
        end
        return targets
    elseif stringInput == "others" then
        local targets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p ~= executorPlayer then table.insert(targets, p) end
        end
        return targets
    elseif stringInput == "team" or stringInput == "teammates" then
        local targets = {}
        if executorPlayer and executorPlayer.Team then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Team == executorPlayer.Team then
                    table.insert(targets, p)
                end
            end
        end
        return targets
    elseif stringInput == "enemies" or stringInput == "enemy" then
        local targets = {}
        if executorPlayer and executorPlayer.Team then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Team ~= executorPlayer.Team then
                    table.insert(targets, p)
                end
            end
        end
        return targets
    end

    local single = nil

    if stringInput == "me" then
        single = executorPlayer
    elseif stringInput == "random" or stringInput == "rand" then
        local pool = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(pool, p) end
        end
        if #pool > 0 then single = pool[math.random(1, #pool)] end
    elseif stringInput == "nearest" or stringInput == "near" or stringInput == "closest" then
        local botHRP = GetBotHRP()
        if botHRP then
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then
                    local hrp = GetHRP(p)
                    if hrp then
                        local dist = (hrp.Position - botHRP.Position).Magnitude
                        if dist < minDist then minDist = dist; single = p end
                    end
                end
            end
        end
    elseif stringInput == "farthest" or stringInput == "far" then
        local botHRP = GetBotHRP()
        if botHRP then
            local maxDist = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then
                    local hrp = GetHRP(p)
                    if hrp then
                        local dist = (hrp.Position - botHRP.Position).Magnitude
                        if dist > maxDist then maxDist = dist; single = p end
                    end
                end
            end
        end
    elseif stringInput == "murd" or stringInput == "murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                if p.Backpack:FindFirstChild("Knife") or (GetCharacter(p) and GetCharacter(p):FindFirstChild("Knife")) then
                    single = p
                end
            end)
            if single then break end
        end
    elseif stringInput == "sherif" or stringInput == "sheriff" then
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                if p.Backpack:FindFirstChild("Gun") or (GetCharacter(p) and GetCharacter(p):FindFirstChild("Gun"))
                    or p.Backpack:FindFirstChild("Revolver") or (GetCharacter(p) and GetCharacter(p):FindFirstChild("Revolver")) then
                    single = p
                end
            end)
            if single then break end
        end
    else
        local numInput = tonumber(stringInput)
        if numInput then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == numInput then single = p; break end
            end
        end
        if not single then
            local bestMatch = nil
            local bestScore = 0
            for _, p in ipairs(Players:GetPlayers()) do
                local nameLow = p.Name:lower()
                local displayLow = p.DisplayName:lower()
                if nameLow == stringInput or displayLow == stringInput then
                    single = p
                    bestMatch = nil
                    break
                end
                if nameLow:sub(1, #stringInput) == stringInput or displayLow:sub(1, #stringInput) == stringInput then
                    if bestScore < 2 or #p.Name < (bestMatch and #bestMatch.Name or math.huge) then
                        bestMatch = p
                        bestScore = 2
                    end
                end
                if bestScore < 2 then
                    if nameLow:find(stringInput, 1, true) or displayLow:find(stringInput, 1, true) then
                        if bestScore < 1 or #p.Name < (bestMatch and #bestMatch.Name or math.huge) then
                            bestMatch = p
                            bestScore = 1
                        end
                    end
                end
            end
            single = single or bestMatch
        end
    end

    if single then
        LastTarget = single
        return {single}
    end
    return {}
end

local function GetSmartTarget(stringInput, executorPlayer)
    local targets = GetMultipleTargets(stringInput, executorPlayer)
    return targets[1]
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 11: LOOP / STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════

local function StopAllLoops()
    for name, _ in pairs(ActiveConnections) do
        if name ~= "NoClip" and name ~= "AntiAFK" and name ~= "AntiVoid" and name ~= "AntiFling" and name ~= "AntiSlow" and name ~= "AutoRespawn" then
            DisconnectSafe(name)
        end
    end
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end
    if FloorFlyPlatform then pcall(function() FloorFlyPlatform:Destroy() end) FloorFlyPlatform = nil end
    IsFlying = false
    IsFloorFlying = false
    FloorFlyTarget = nil
    IsSpinning = false
    IsCoinFarming = false
    IsFarming = false
    IsBlackHole = false
    IsStrobing = false
    IsGodKnife = false
    IsMimicking = false
    IsCreeping = false
    IsTrailing = false
    IsDancing = false
    IsAuraActive = false
    IsTracking = false
    IsMagnetOn = false
    IsLoopTP = false
    IsAutoShoot = false
    IsAutoMurd = false
    IsWallBang = false
    IsFlingBusy = false
    LoopTPTarget = nil
    AutoShootTarget = nil
    AutoMurdTarget = nil
    TrackTarget = nil
    for _, part in ipairs(CageParts) do pcall(function() part:Destroy() end) end
    CageParts = {}
    for _, part in ipairs(TrailParts) do pcall(function() part:Destroy() end) end
    TrailParts = {}
    for _, part in ipairs(AuraParts) do pcall(function() part:Destroy() end) end
    AuraParts = {}
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyAngularVelocity") or obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                    obj:Destroy()
                end
            end
        end
    end)
    Console.Log("SYS", "All active loops stopped and states reset")
end

local function FullCleanup()
    for name, _ in pairs(ActiveConnections) do DisconnectSafe(name) end
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end) GodHealthConnection = nil end
    if GodDiedConnection then pcall(function() GodDiedConnection:Disconnect() end) GodDiedConnection = nil end
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end
    if PlatformPart then pcall(function() PlatformPart:Destroy() end) PlatformPart = nil end
    if FloorFlyPlatform then pcall(function() FloorFlyPlatform:Destroy() end) FloorFlyPlatform = nil end
    for _, part in ipairs(CageParts) do pcall(function() part:Destroy() end) end
    CageParts = {}
    for _, part in ipairs(TrailParts) do pcall(function() part:Destroy() end) end
    TrailParts = {}
    for _, part in ipairs(AuraParts) do pcall(function() part:Destroy() end) end
    AuraParts = {}
    for _, data in ipairs(XRayParts) do
        pcall(function() data.part.Transparency = data.original end)
    end
    XRayParts = {}
    for player, objects in pairs(ESPObjects) do
        pcall(function()
            if objects.highlight then objects.highlight:Destroy() end
            if objects.billboard then objects.billboard:Destroy() end
        end)
    end
    ESPObjects = {}
    for target, parts in pairs(FreezeCages) do
        for _, part in ipairs(parts) do pcall(function() part:Destroy() end) end
    end
    FreezeCages = {}
    pcall(function() Workspace.Gravity = OriginalGravity end)
    pcall(function()
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyMover") then obj:Destroy() end
            end
        end
        local char = LocalPlayer.Character
        if char then
            local ff = char:FindFirstChildOfClass("ForceField")
            if ff then ff:Destroy() end
        end
    end)
    IsFlying = false
    IsFloorFlying = false
    FloorFlyTarget = nil
    IsNoClip = false
    IsGodMode = false
    IsAntiAFK = false
    IsAntiVoid = false
    IsInfJump = false
    IsSpinning = false
    IsCoinFarming = false
    IsFarming = false
    IsBlackHole = false
    IsStrobing = false
    IsGodKnife = false
    IsMimicking = false
    IsCreeping = false
    IsTrailing = false
    IsDancing = false
    IsAuraActive = false
    IsTracking = false
    IsFlingBusy = false
    IsMagnetOn = false
    IsAntiSlow = false
    IsAntiFling = false
    IsLoopTP = false
    IsAutoShoot = false
    IsAutoMurd = false
    IsWallBang = false
    IsAutoRespawn = false
    Console.Log("SYS", "Full cleanup completed — all connections, states, and objects destroyed")
end
genv.__ULTIMATE_BOT_CLEANUP = FullCleanup

-- ═══════════════════════════════════════════════════════════════
-- SECTION 12: SHARED COMBAT FUNCTIONS (Fling Engine)
-- ═══════════════════════════════════════════════════════════════

local function FlingMethod1_CFrameSlam(targetPlayer, maxIter)
    local botHRP = GetBotHRP()
    local botHum = GetBotHumanoid()
    if not botHRP or not botHum then return false end
    local savedPos = botHRP.CFrame
    botHum:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 9999
    bv.Parent = botHRP
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.P = 9999
    bav.Parent = botHRP
    local killed = false
    for i = 1, (maxIter or 80) do
        if not targetPlayer or not targetPlayer.Parent then break end
        if not IsAlive(targetPlayer) then killed = true; break end
        local tHRP = GetHRP(targetPlayer)
        if not tHRP then break end
        local currentBotHRP = GetBotHRP()
        if not currentBotHRP then break end
        currentBotHRP.CFrame = tHRP.CFrame
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end)
    pcall(function() bav:Destroy() end)
    local resetHRP = GetBotHRP()
    if resetHRP then
        resetHRP.CFrame = savedPos
        resetHRP.AssemblyLinearVelocity = Vector3.zero
        resetHRP.AssemblyAngularVelocity = Vector3.zero
    end
    local resetHum = GetBotHumanoid()
    if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    return killed or not IsAlive(targetPlayer)
end

local function FlingMethod2_MultiAngleSlam(targetPlayer, maxIter)
    local botHRP = GetBotHRP()
    local botHum = GetBotHumanoid()
    if not botHRP or not botHum then return false end
    local savedPos = botHRP.CFrame
    botHum:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(FlingPower, 0, FlingPower)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 9999
    bv.Parent = botHRP
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(0, FlingPower, FlingPower)
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.P = 9999
    bav.Parent = botHRP
    local killed = false
    local angles = {
        CFrame.new(0, 0, 0), CFrame.new(2, 0, 0), CFrame.new(-2, 0, 0),
        CFrame.new(0, 2, 0), CFrame.new(0, -2, 0), CFrame.new(0, 0, 2),
        CFrame.new(0, 0, -2), CFrame.new(1, 1, 1), CFrame.new(-1, -1, -1),
    }
    for i = 1, (maxIter or 90) do
        if not targetPlayer or not targetPlayer.Parent then break end
        if not IsAlive(targetPlayer) then killed = true; break end
        local tHRP = GetHRP(targetPlayer)
        if not tHRP then break end
        local currentBotHRP = GetBotHRP()
        if not currentBotHRP then break end
        local angleOffset = angles[(i % #angles) + 1]
        currentBotHRP.CFrame = tHRP.CFrame * angleOffset
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end)
    pcall(function() bav:Destroy() end)
    local resetHRP = GetBotHRP()
    if resetHRP then
        resetHRP.CFrame = savedPos
        resetHRP.AssemblyLinearVelocity = Vector3.zero
        resetHRP.AssemblyAngularVelocity = Vector3.zero
    end
    local resetHum = GetBotHumanoid()
    if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    return killed or not IsAlive(targetPlayer)
end

local function FlingMethod3_VelocityBurst(targetPlayer, maxIter)
    local botHRP = GetBotHRP()
    local botHum = GetBotHumanoid()
    if not botHRP or not botHum then return false end
    local savedPos = botHRP.CFrame
    local killed = false
    for i = 1, (maxIter or 60) do
        if not targetPlayer or not targetPlayer.Parent then break end
        if not IsAlive(targetPlayer) then killed = true; break end
        local tHRP = GetHRP(targetPlayer)
        if not tHRP then break end
        local currentBotHRP = GetBotHRP()
        local currentBotHum = GetBotHumanoid()
        if not currentBotHRP or not currentBotHum then break end
        currentBotHum:ChangeState(Enum.HumanoidStateType.Physics)
        currentBotHRP.CFrame = tHRP.CFrame
        currentBotHRP.AssemblyLinearVelocity = Vector3.new(
            math.random(-1, 1) * FlingPower,
            math.random(-1, 1) * FlingPower,
            math.random(-1, 1) * FlingPower
        )
        currentBotHRP.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        RunService.Heartbeat:Wait()
        currentBotHRP = GetBotHRP()
        if currentBotHRP then
            currentBotHRP.CFrame = tHRP.CFrame * CFrame.new(math.random(-1,1), math.random(-1,1), math.random(-1,1))
        end
        RunService.Heartbeat:Wait()
    end
    local resetHRP = GetBotHRP()
    if resetHRP then
        resetHRP.CFrame = savedPos
        resetHRP.AssemblyLinearVelocity = Vector3.zero
        resetHRP.AssemblyAngularVelocity = Vector3.zero
    end
    local resetHum = GetBotHumanoid()
    if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    return killed or not IsAlive(targetPlayer)
end

local function FlingMethod4_RapidCollision(targetPlayer, maxIter)
    local botHRP = GetBotHRP()
    local botHum = GetBotHumanoid()
    if not botHRP or not botHum then return false end
    local savedPos = botHRP.CFrame
    botHum:ChangeState(Enum.HumanoidStateType.Physics)
    local killed = false
    local char = LocalPlayer.Character
    for i = 1, (maxIter or 100) do
        if not targetPlayer or not targetPlayer.Parent then break end
        if not IsAlive(targetPlayer) then killed = true; break end
        local tHRP = GetHRP(targetPlayer)
        if not tHRP then break end
        local currentBotHRP = GetBotHRP()
        if not currentBotHRP then break end
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = (i % 2 == 0)
                end
            end
        end
        local offset = Vector3.new(
            math.cos(i * 0.5) * 2,
            math.sin(i * 0.3) * 2,
            math.sin(i * 0.5) * 2
        )
        currentBotHRP.CFrame = tHRP.CFrame * CFrame.new(offset.X, offset.Y, offset.Z)
        currentBotHRP.AssemblyLinearVelocity = (tHRP.Position - currentBotHRP.Position).Unit * FlingPower
        RunService.Heartbeat:Wait()
    end
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    local resetHRP = GetBotHRP()
    if resetHRP then
        resetHRP.CFrame = savedPos
        resetHRP.AssemblyLinearVelocity = Vector3.zero
        resetHRP.AssemblyAngularVelocity = Vector3.zero
    end
    local resetHum = GetBotHumanoid()
    if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    return killed or not IsAlive(targetPlayer)
end

local function FlingMethod5_SeatFling(targetPlayer, maxIter)
    local botHRP = GetBotHRP()
    local botHum = GetBotHumanoid()
    if not botHRP or not botHum then return false end
    local savedPos = botHRP.CFrame
    local killed = false
    local seat = Instance.new("Seat")
    seat.Size = Vector3.new(1, 1, 1)
    seat.Transparency = 1
    seat.CanCollide = false
    seat.Anchored = false
    seat.Name = "FlingSeat"
    seat.Parent = Workspace
    for i = 1, (maxIter or 70) do
        if not targetPlayer or not targetPlayer.Parent then break end
        if not IsAlive(targetPlayer) then killed = true; break end
        local tHRP = GetHRP(targetPlayer)
        if not tHRP then break end
        local currentBotHRP = GetBotHRP()
        if not currentBotHRP then break end
        seat.CFrame = tHRP.CFrame
        seat.AssemblyLinearVelocity = Vector3.new(
            math.random(-1, 1) * FlingPower,
            FlingPower,
            math.random(-1, 1) * FlingPower
        )
        currentBotHRP.CFrame = tHRP.CFrame
        currentBotHRP.AssemblyLinearVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        RunService.Heartbeat:Wait()
    end
    pcall(function() seat:Destroy() end)
    local resetHRP = GetBotHRP()
    if resetHRP then
        resetHRP.CFrame = savedPos
        resetHRP.AssemblyLinearVelocity = Vector3.zero
        resetHRP.AssemblyAngularVelocity = Vector3.zero
    end
    local resetHum = GetBotHumanoid()
    if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    return killed or not IsAlive(targetPlayer)
end

local FlingMethods = {
    FlingMethod1_CFrameSlam,
    FlingMethod2_MultiAngleSlam,
    FlingMethod3_VelocityBurst,
    FlingMethod4_RapidCollision,
    FlingMethod5_SeatFling,
}

local function ExecuteSmartFling(targetPlayer)
    local waitStart = tick()
    while IsFlingBusy do
        task.wait(0.05)
        if tick() - waitStart > 10 then return end
    end
    IsFlingBusy = true
    local success = pcall(function()
        if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then return end
        if PreferredFlingMethod > 0 and PreferredFlingMethod <= #FlingMethods then
            local result = FlingMethods[PreferredFlingMethod](targetPlayer)
            if result then return end
        end
        for idx, method in ipairs(FlingMethods) do
            if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then return end
            if not IsBotAlive() then
                task.wait(1)
                EnsureCharacter()
                task.wait(0.3)
            end
            local result = method(targetPlayer)
            if result then return end
            task.wait(0.1)
        end
    end)
    IsFlingBusy = false
end

local function ExecuteTargetedFling(targetPlayer)
    local waitStart = tick()
    while IsFlingBusy do
        task.wait(0.05)
        if tick() - waitStart > 10 then return end
    end
    IsFlingBusy = true
    pcall(function()
        if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then IsFlingBusy = false return end
        local botHRP = GetBotHRP()
        local botHum = GetBotHumanoid()
        if not botHRP or not botHum then IsFlingBusy = false return end
        local savedPos = botHRP.CFrame
        botHum:ChangeState(Enum.HumanoidStateType.Physics)
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 9999
        bv.Parent = botHRP
        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.P = 9999
        bav.Parent = botHRP
        for i = 1, 80 do
            if not targetPlayer or not targetPlayer.Parent then break end
            if not IsAlive(targetPlayer) then break end
            local tHRP = GetHRP(targetPlayer)
            if not tHRP then break end
            local currentBotHRP = GetBotHRP()
            if not currentBotHRP then break end
            local nearbyNonTarget = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p ~= targetPlayer and IsAlive(p) then
                    local pHRP = GetHRP(p)
                    if pHRP and tHRP then
                        local dist = (pHRP.Position - tHRP.Position).Magnitude
                        if dist < 4 then
                            nearbyNonTarget = true
                            break
                        end
                    end
                end
            end
            if nearbyNonTarget then
                RunService.Heartbeat:Wait()
                RunService.Heartbeat:Wait()
            else
                currentBotHRP.CFrame = tHRP.CFrame
            end
            RunService.Heartbeat:Wait()
        end
        pcall(function() bv:Destroy() end)
        pcall(function() bav:Destroy() end)
        local resetHRP = GetBotHRP()
        if resetHRP then
            resetHRP.CFrame = savedPos
            resetHRP.AssemblyLinearVelocity = Vector3.zero
            resetHRP.AssemblyAngularVelocity = Vector3.zero
        end
        local resetHum = GetBotHumanoid()
        if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
    IsFlingBusy = false
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 13: SHARED HELPER FUNCTIONS (exposed to commands)
-- ═══════════════════════════════════════════════════════════════

local BringPlayer
BringPlayer = function(target, customDest)
    if not target then return end
    task.spawn(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local botHum = GetBotHumanoid()
            if not botHRP or not botHum then return end
            local savedPos = customDest or botHRP.CFrame
            local wasGod = IsGodMode
            if not wasGod then
                pcall(function()
                    botHum.MaxHealth = math.huge
                    botHum.Health = math.huge
                end)
            end
            botHum:ChangeState(Enum.HumanoidStateType.Physics)
            for i = 1, BringIterations do
                local tHRP = GetHRP(target)
                local bHRP = GetBotHRP()
                if not tHRP or not bHRP or not target.Parent then break end
                local dist = (tHRP.Position - savedPos.Position).Magnitude
                if dist < 5 then break end
                bHRP.CFrame = tHRP.CFrame
                RunService.Heartbeat:Wait()
                bHRP = GetBotHRP()
                if bHRP then bHRP.CFrame = savedPos end
            end
            local resetHum = GetBotHumanoid()
            if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if not wasGod then
                pcall(function()
                    local h = GetBotHumanoid()
                    if h then h.MaxHealth = 100; h.Health = 100 end
                end)
            end
        end)
    end)
end

local function StartNoClip()
    DisconnectSafe("NoClip")
    IsNoClip = true
    ActiveConnections.NoClip = RunService.Stepped:Connect(function()
        pcall(function()
            if IsFloorFlying then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function StopNoClip()
    DisconnectSafe("NoClip")
    IsNoClip = false
end

local function StartGodMode()
    DisconnectSafe("God")
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end) GodHealthConnection = nil end
    if GodDiedConnection then pcall(function() GodDiedConnection:Disconnect() end) GodDiedConnection = nil end
    IsGodMode = true
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    GodHealthConnection = hum.HealthChanged:Connect(function(newHealth)
        if IsGodMode and hum then
            hum.Health = hum.MaxHealth
        end
    end)
    local ff = char:FindFirstChildOfClass("ForceField")
    if not ff then
        ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)
    GodDiedConnection = hum.Died:Connect(function()
        if IsGodMode then
            pcall(function()
                hum.Health = hum.MaxHealth
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
    end)
    pcall(function()
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Script") then
                local n = obj.Name:lower()
                if n:find("damage") or n:find("kill") or n:find("hurt") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
    ActiveConnections.God = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsGodMode then DisconnectSafe("God") return end
            local h = GetBotHumanoid()
            if h then
                if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end
                if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
                if h:GetState() == Enum.HumanoidStateType.Dead then
                    h:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
            local c = LocalPlayer.Character
            if c then
                if not c:FindFirstChildOfClass("ForceField") then
                    local f = Instance.new("ForceField")
                    f.Visible = false
                    f.Parent = c
                end
                for _, obj in ipairs(c:GetDescendants()) do
                    if obj:IsA("Script") then
                        local n = obj.Name:lower()
                        if n:find("damage") or n:find("kill") or n:find("hurt") then
                            pcall(function() obj:Destroy() end)
                        end
                    end
                end
            end
        end)
    end)
end

local function StopGodMode()
    DisconnectSafe("God")
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end) GodHealthConnection = nil end
    if GodDiedConnection then pcall(function() GodDiedConnection:Disconnect() end) GodDiedConnection = nil end
    IsGodMode = false
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local ff = char:FindFirstChildOfClass("ForceField")
            if ff then ff:Destroy() end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = 100
                hum.Health = 100
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
            end
        end
    end)
end

local function SetInvisible(state)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local transparency = state and 1 or 0
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                obj.Transparency = transparency
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = transparency
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = not state
            end
        end
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = transparency
                    for _, mesh in ipairs(handle:GetChildren()) do
                        if mesh:IsA("SpecialMesh") then
                            pcall(function() mesh.Scale = state and Vector3.zero or Vector3.new(1, 1, 1) end)
                        end
                    end
                end
            end
        end
    end)
end

local function FreezePlayerAdvanced(target)
    if not target then return end
    if target == LocalPlayer then
        local hrp = GetBotHRP()
        if hrp then pcall(function() hrp.Anchored = true end) end
        return
    end
    local targetHRP = GetHRP(target)
    if not targetHRP then return end
    if FreezeCages[target] then
        for _, part in ipairs(FreezeCages[target]) do pcall(function() part:Destroy() end) end
    end
    FreezeCages[target] = {}
    local pos = targetHRP.Position
    local sz = 4
    local walls = {
        { size = Vector3.new(sz, sz, 0.5), pos = pos + Vector3.new(0, sz/2, sz/2) },
        { size = Vector3.new(sz, sz, 0.5), pos = pos + Vector3.new(0, sz/2, -sz/2) },
        { size = Vector3.new(0.5, sz, sz), pos = pos + Vector3.new(sz/2, sz/2, 0) },
        { size = Vector3.new(0.5, sz, sz), pos = pos + Vector3.new(-sz/2, sz/2, 0) },
        { size = Vector3.new(sz, 0.5, sz), pos = pos + Vector3.new(0, sz, 0) },
        { size = Vector3.new(sz, 0.5, sz), pos = pos + Vector3.new(0, 0, 0) },
    }
    for _, wallData in ipairs(walls) do
        pcall(function()
            local wall = Instance.new("Part")
            wall.Size = wallData.size
            wall.Position = wallData.pos
            wall.Anchored = true
            wall.Material = Enum.Material.ForceField
            wall.Transparency = 0.8
            wall.CanCollide = true
            wall.Name = "BotFreeze"
            wall.Parent = Workspace
            table.insert(FreezeCages[target], wall)
        end)
    end
    task.spawn(function()
        if BringPlayer and type(BringPlayer) == "function" then
            BringPlayer(target, CFrame.new(pos))
        end
    end)
end

local function UnfreezePlayerAdvanced(target)
    if not target then return end
    if target == LocalPlayer then
        local hrp = GetBotHRP()
        if hrp then pcall(function() hrp.Anchored = false end) end
        return
    end
    if FreezeCages[target] then
        for _, part in ipairs(FreezeCages[target]) do pcall(function() part:Destroy() end) end
        FreezeCages[target] = nil
    end
end

local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

local function ViewPlayer(target)
    if not target then return end
    local hum = GetHumanoid(target)
    if not hum then return end
    if not OriginalCameraSubject then
        OriginalCameraSubject = Workspace.CurrentCamera.CameraSubject
    end
    Workspace.CurrentCamera.CameraSubject = hum
end

local function UnviewPlayer()
    if OriginalCameraSubject then
        pcall(function() Workspace.CurrentCamera.CameraSubject = OriginalCameraSubject end)
        OriginalCameraSubject = nil
    else
        pcall(function()
            local hum = GetBotHumanoid()
            if hum then Workspace.CurrentCamera.CameraSubject = hum end
        end)
    end
end

-- Start NoClip by default
pcall(StartNoClip)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 14: TYPO CORRECTION
-- ═══════════════════════════════════════════════════════════════

local TypoCorrections = {
    flig = "fling", flimg = "fling", filng = "fling", flng = "fling",
    yeeet = "yeet", yet = "yeet",
    kil = "kill", killl = "kill",
    tp2m = "tp2me", tp2mee = "tp2me",
    shoo = "shoot", sho = "shoot", schoot = "shoot",
    murdr = "murd", murder = "murd", murde = "murd",
    folw = "follow", follw = "follow",
    orbt = "orbit",
    sezure = "seizure", seizur = "seizure",
    torndo = "tornado", tornad = "tornado",
    blckhole = "blackhole", blkhole = "blackhole",
    scater = "scatter", scattr = "scatter",
    cag = "cage",
    trp = "trap",
    spm = "spam",
    strb = "strobe",
    gient = "giant", gint = "giant",
    tny = "tiny",
    creap = "creep", crep = "creep",
    mimik = "mimic", mimck = "mimic",
    stck = "stack",
    flngall = "flingall",
    resp = "respawn", rspwn = "respawn",
    refr = "refresh", refrsh = "refresh",
    freze = "freeze", freez = "freeze",
    unfreze = "unfreeze",
    invs = "invis", invisble = "invisible",
    visibl = "visible",
    nclip = "noclip",
    hlp = "help", hep = "help",
    cmd = "cmds", comands = "commands",
    gd = "god", ugod = "ungod",
    spd = "speed",
    jmp = "jump",
    hl = "highlight", unehl = "unhighlight",
    vew = "view", spectat = "spectate",
    rprt = "report", reprt = "report",
    rport = "report",
    magnt = "magnet",
    roket = "rocket", rcket = "rocket",
    pul = "pull",
    crsh = "crash",
    ragdol = "ragdoll", ragdl = "ragdoll",
    wallbng = "wallbang", wlbang = "wallbang",
    antiflng = "antifling",
    antislw = "antislow",
    autoshoot = "shoot",
    automurd = "murd",
    infojump = "infjump",
    loopteleport = "looptp",
}

local function CorrectTypo(cmd)
    return TypoCorrections[cmd] or cmd
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 15: BOTENV — THE SHARED ENVIRONMENT TABLE
-- ═══════════════════════════════════════════════════════════════

local BotEnv = {
    -- Services
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    StarterGui = StarterGui,
    Workspace = Workspace,
    Lighting = Lighting,
    ReplicatedStorage = ReplicatedStorage,
    TextChatService = TextChatService,
    TeleportService = TeleportService,
    HttpService = HttpService,
    MarketplaceService = MarketplaceService,
    VirtualUser = VirtualUser,

    -- Core refs
    LocalPlayer = LocalPlayer,
    SuperOwner = SuperOwner,
    Prefixes = Prefixes,
    ExecutorInfo = ExecutorInfo,
    Console = Console,

    -- Config
    FlingPower = FlingPower,
    LoopFlingDelay = LoopFlingDelay,
    FollowDistance = FollowDistance,
    OrbitRadius = OrbitRadius,
    OrbitSpeed = OrbitSpeed,
    FlySpeed = FlySpeed,
    SpinSpeed = SpinSpeed,
    AnnoyDelay = AnnoyDelay,
    BringIterations = BringIterations,
    ChatRateLimit = ChatRateLimit,
    BotStartTime = BotStartTime,

    -- State (mutable — commands read/write these)
    BotMode = function() return BotMode end,
    SetBotMode = function(mode) BotMode = mode end,
    ActiveConnections = ActiveConnections,
    PermittedUsers = PermittedUsers,
    CommandPermissions = CommandPermissions,
    FlingMethods = FlingMethods,
    ESPObjects = ESPObjects,
    CageParts = CageParts,
    TrailParts = TrailParts,
    XRayParts = XRayParts,
    AuraParts = AuraParts,
    FreezeCages = FreezeCages,
    CommandLog = CommandLog,
    OriginalLighting = OriginalLighting,
    OriginalGravity = OriginalGravity,

    -- Is-flags (getters/setters for all state booleans)
    GetFlag = function(name)
        local flags = {
            IsFlying = IsFlying, IsNoClip = IsNoClip, IsGodMode = IsGodMode,
            IsAntiAFK = IsAntiAFK, IsAntiVoid = IsAntiVoid, IsInfJump = IsInfJump,
            IsSpinning = IsSpinning, IsCoinFarming = IsCoinFarming, IsFarming = IsFarming,
            IsBlackHole = IsBlackHole, IsStrobing = IsStrobing, IsGodKnife = IsGodKnife,
            IsMimicking = IsMimicking, IsCreeping = IsCreeping, IsTrailing = IsTrailing,
            IsDancing = IsDancing, IsFloorFlying = IsFloorFlying, IsAuraActive = IsAuraActive,
            IsTracking = IsTracking, IsFlingBusy = IsFlingBusy, IsMagnetOn = IsMagnetOn,
            IsAntiSlow = IsAntiSlow, IsAntiFling = IsAntiFling, IsLoopTP = IsLoopTP,
            IsAutoShoot = IsAutoShoot, IsAutoMurd = IsAutoMurd, IsWallBang = IsWallBang,
            IsAutoRespawn = IsAutoRespawn, PreferredFlingMethod = PreferredFlingMethod,
        }
        return flags[name]
    end,
    SetFlag = function(name, value)
        -- Direct upvalue mutation via a setter dispatch
        if name == "IsFlying" then IsFlying = value
        elseif name == "IsNoClip" then IsNoClip = value
        elseif name == "IsGodMode" then IsGodMode = value
        elseif name == "IsAntiAFK" then IsAntiAFK = value
        elseif name == "IsAntiVoid" then IsAntiVoid = value
        elseif name == "IsInfJump" then IsInfJump = value
        elseif name == "IsSpinning" then IsSpinning = value
        elseif name == "IsCoinFarming" then IsCoinFarming = value
        elseif name == "IsFarming" then IsFarming = value
        elseif name == "IsBlackHole" then IsBlackHole = value
        elseif name == "IsStrobing" then IsStrobing = value
        elseif name == "IsGodKnife" then IsGodKnife = value
        elseif name == "IsMimicking" then IsMimicking = value
        elseif name == "IsCreeping" then IsCreeping = value
        elseif name == "IsTrailing" then IsTrailing = value
        elseif name == "IsDancing" then IsDancing = value
        elseif name == "IsFloorFlying" then IsFloorFlying = value
        elseif name == "IsAuraActive" then IsAuraActive = value
        elseif name == "IsTracking" then IsTracking = value
        elseif name == "IsFlingBusy" then IsFlingBusy = value
        elseif name == "IsMagnetOn" then IsMagnetOn = value
        elseif name == "IsAntiSlow" then IsAntiSlow = value
        elseif name == "IsAntiFling" then IsAntiFling = value
        elseif name == "IsLoopTP" then IsLoopTP = value
        elseif name == "IsAutoShoot" then IsAutoShoot = value
        elseif name == "IsAutoMurd" then IsAutoMurd = value
        elseif name == "IsWallBang" then IsWallBang = value
        elseif name == "IsAutoRespawn" then IsAutoRespawn = value
        elseif name == "PreferredFlingMethod" then PreferredFlingMethod = value
        elseif name == "FloorFlyTarget" then FloorFlyTarget = value
        elseif name == "FloorFlyPlatform" then FloorFlyPlatform = value
        elseif name == "TrackTarget" then TrackTarget = value
        elseif name == "TrackLastPos" then TrackLastPos = value
        elseif name == "LoopTPTarget" then LoopTPTarget = value
        elseif name == "AutoShootTarget" then AutoShootTarget = value
        elseif name == "AutoMurdTarget" then AutoMurdTarget = value
        elseif name == "SavedCFrame" then SavedCFrame = value
        elseif name == "LastTarget" then LastTarget = value
        elseif name == "PlatformPart" then PlatformPart = value
        elseif name == "OriginalCameraSubject" then OriginalCameraSubject = value
        elseif name == "GodHealthConnection" then GodHealthConnection = value
        elseif name == "GodDiedConnection" then GodDiedConnection = value
        elseif name == "FlyBodyGyro" then FlyBodyGyro = value
        elseif name == "FlyBodyVelocity" then FlyBodyVelocity = value
        end
    end,

    -- Shared functions
    GetCharacter = GetCharacter,
    GetHRP = GetHRP,
    GetHumanoid = GetHumanoid,
    IsAlive = IsAlive,
    IsBotAlive = IsBotAlive,
    GetBotHRP = GetBotHRP,
    GetBotHumanoid = GetBotHumanoid,
    EnsureCharacter = EnsureCharacter,
    GetSmartTarget = GetSmartTarget,
    GetMultipleTargets = GetMultipleTargets,
    DisconnectSafe = DisconnectSafe,
    StopAllLoops = StopAllLoops,
    FullCleanup = FullCleanup,
    SendChatMessage = SendChatMessage,
    SendWhisperMessage = SendWhisperMessage,
    BypassText = BypassText,
    Respond = Respond,
    RespondError = RespondError,
    RespondPrivate = RespondPrivate,
    SendNotification = SendNotification,
    ExecuteSmartFling = ExecuteSmartFling,
    ExecuteTargetedFling = ExecuteTargetedFling,
    BringPlayer = BringPlayer,
    StartNoClip = StartNoClip,
    StopNoClip = StopNoClip,
    StartGodMode = StartGodMode,
    StopGodMode = StopGodMode,
    SetInvisible = SetInvisible,
    FreezePlayerAdvanced = FreezePlayerAdvanced,
    UnfreezePlayerAdvanced = UnfreezePlayerAdvanced,
    FormatTime = FormatTime,
    ViewPlayer = ViewPlayer,
    UnviewPlayer = UnviewPlayer,

    -- Command registry (populated by loader)
    CommandRegistry = {},
    AliasMap = {},
}

-- ═══════════════════════════════════════════════════════════════
-- SECTION 16: GITHUB AUTO-DISCOVERY COMMAND LOADER
-- ═══════════════════════════════════════════════════════════════

local CommandCache = {}
local LoadedCommandCount = 0
local FailedCommands = {}

local function HttpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and result then
        Console.Network("HttpGet", url, true)
        return result
    end
    Console.Network("HttpGet", url, false)
    return nil
end

local function LoadSingleCommand(fileName, rawUrl)
    local cmdName = fileName:gsub("%.lua$", ""):lower()
    if CommandCache[cmdName] then
        Console.Log("LOAD", "Cache hit: " .. cmdName)
        return CommandCache[cmdName]
    end

    local source = HttpGet(rawUrl)
    if not source then
        Console.Error("Failed to download command: " .. cmdName, rawUrl)
        table.insert(FailedCommands, cmdName)
        return nil
    end

    local fn, err = loadstring(source)
    if not fn then
        Console.Error("Failed to compile command: " .. cmdName, tostring(err))
        table.insert(FailedCommands, cmdName)
        return nil
    end

    local ok, module = pcall(fn)
    if not ok or not module then
        Console.Error("Failed to execute command module: " .. cmdName, tostring(module))
        table.insert(FailedCommands, cmdName)
        return nil
    end

    if type(module) ~= "table" or not module.Execute then
        Console.Error("Invalid command format (missing .Execute): " .. cmdName)
        table.insert(FailedCommands, cmdName)
        return nil
    end

    -- Register command
    CommandCache[cmdName] = module
    BotEnv.CommandRegistry[cmdName] = module
    CommandPermissions[cmdName] = module.Permission or 1
    LoadedCommandCount = LoadedCommandCount + 1

    -- Register aliases if present
    if module.Aliases and type(module.Aliases) == "table" then
        for _, alias in ipairs(module.Aliases) do
            local aliasLower = alias:lower()
            BotEnv.AliasMap[aliasLower] = cmdName
            CommandPermissions[aliasLower] = module.Permission or 1
            Console.Log("LOAD", "Alias registered: " .. aliasLower .. " -> " .. cmdName)
        end
    end

    Console.Log("LOAD", "Command loaded: " .. cmdName, "Permission: " .. tostring(module.Permission or 1) .. " | Category: " .. tostring(module.Category or "none"))
    return module
end

local function DiscoverAndLoadAllCommands()
    Console.Log("NET", "Starting GitHub auto-discovery scan...", GITHUB_API_BASE)

    local apiResponse = HttpGet(GITHUB_API_BASE)
    if not apiResponse then
        Console.Error("GitHub API request failed — cannot discover commands", "Check internet or repo URL")
        Console.Warn("Attempting fallback: loading from known command list...")

        -- Fallback: try loading commands from a manifest file
        local manifestUrl = GITHUB_RAW_BASE .. "_manifest.lua"
        local manifestSrc = HttpGet(manifestUrl)
        if manifestSrc then
            local ok, manifest = pcall(function()
                local fn = loadstring(manifestSrc)
                if fn then return fn() end
            end)
            if ok and manifest and type(manifest) == "table" then
                Console.Log("LOAD", "Manifest found with " .. #manifest .. " commands")
                for _, cmdFile in ipairs(manifest) do
                    local rawUrl = GITHUB_RAW_BASE .. cmdFile
                    pcall(function() LoadSingleCommand(cmdFile, rawUrl) end)
                end
                return
            end
        end

        Console.Error("Manifest fallback also failed — no commands loaded")
        return
    end

    -- Parse GitHub API JSON response
    local ok, fileList = pcall(function()
        return HttpService:JSONDecode(apiResponse)
    end)

    if not ok or not fileList or type(fileList) ~= "table" then
        Console.Error("Failed to parse GitHub API response", tostring(fileList))
        return
    end

    local luaFiles = {}
    for _, item in ipairs(fileList) do
        if type(item) == "table" and item.name and item.name:match("%.lua$") and item.name ~= "_manifest.lua" then
            table.insert(luaFiles, {
                name = item.name,
                url = item.download_url or (GITHUB_RAW_BASE .. item.name),
            })
        end
    end

    Console.Log("NET", "Discovered " .. #luaFiles .. " command files on GitHub")

    for _, file in ipairs(luaFiles) do
        pcall(function()
            LoadSingleCommand(file.name, file.url)
        end)
    end

    Console.Log("SYS", "===== COMMAND LOADING COMPLETE =====")
    Console.Log("SYS", "Loaded: " .. LoadedCommandCount .. " commands | Failed: " .. #FailedCommands)
    if #FailedCommands > 0 then
        Console.Warn("Failed commands: " .. table.concat(FailedCommands, ", "))
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 17: COMMAND DISPATCH ENGINE
-- ═══════════════════════════════════════════════════════════════

local function StripChatTags(message)
    if not message then return "" end
    local stripped = message
    stripped = stripped:gsub("^%s*%[.-%]%s*", "")
    stripped = stripped:gsub("^%s*%{.-%}%s*", "")
    stripped = stripped:gsub("^%s*%(.-%)%s*", "")
    stripped = stripped:match("^%s*(.-)%s*$") or stripped
    return stripped
end

local function FindPrefix(message)
    local cleaned = StripChatTags(message)
    local lower = cleaned:lower()
    for _, prefix in ipairs(Prefixes) do
        local prefixLower = prefix:lower()
        if lower:sub(1, #prefixLower) == prefixLower then
            return prefix, cleaned
        end
    end
    return nil, nil
end

local function HandleBotCommand(message, executorPlayer, isWhisper)
    if not message or not executorPlayer then return end
    if type(message) ~= "string" then return end

    local matchedPrefix, cleanedMessage = FindPrefix(message)
    if not matchedPrefix then return end

    -- Dedup: prevent the same message from being processed multiple times
    local dedupKey = executorPlayer.Name .. ":" .. message
    local now = tick()
    if CommandDedup[dedupKey] and (now - CommandDedup[dedupKey]) < DEDUP_WINDOW then
        return
    end
    CommandDedup[dedupKey] = now

    -- Clean old dedup entries periodically
    if math.random(1, 20) == 1 then
        for k, t in pairs(CommandDedup) do
            if (now - t) > DEDUP_WINDOW * 3 then
                CommandDedup[k] = nil
            end
        end
    end

    if not CanUseBot(executorPlayer) then return end
    local permLevel = GetPermLevel(executorPlayer)
    if permLevel < 1 then return end
    if IsOnCooldown(executorPlayer) then return end

    local cleanString = cleanedMessage:sub(#matchedPrefix + 1)
    if not cleanString or cleanString == "" then return end
    cleanString = cleanString:match("^%s*(.-)%s*$") or cleanString

    local args = {}
    for token in cleanString:gmatch("%S+") do
        table.insert(args, token)
    end
    if not args[1] or args[1] == "" then return end

    -- Resolve command name: typo correction -> alias resolution
    local cmd = CorrectTypo(args[1]:lower())
    if BotEnv.AliasMap[cmd] then
        cmd = BotEnv.AliasMap[cmd]
    end

    -- Permission check
    if not HasPermission(executorPlayer, cmd) then
        RespondError("Access denied — you don't have permission for '" .. cmd .. "'. Your level: " .. permLevel .. ", required: " .. (CommandPermissions[cmd] or 1), isWhisper and executorPlayer)
        return
    end

    -- Build restArgs
    local restArgs = ""
    if #args > 1 then
        local parts = {}
        for i = 2, #args do table.insert(parts, args[i]) end
        restArgs = table.concat(parts, " ")
    end

    -- Log command
    local wt = isWhisper and executorPlayer or nil
    Console.Command(executorPlayer.Name, cmd, args[2], nil)

    -- Lookup and execute
    local module = BotEnv.CommandRegistry[cmd]
    if not module then
        -- Try lazy-loading from GitHub
        Console.Log("LOAD", "Command '" .. cmd .. "' not in registry — attempting lazy load from GitHub...")
        local rawUrl = GITHUB_RAW_BASE .. cmd .. ".lua"
        module = LoadSingleCommand(cmd .. ".lua", rawUrl)
    end

    if module and module.Execute then
        local startTime = tick()
        local execOk, execErr = pcall(function()
            module.Execute(BotEnv, args, executorPlayer, restArgs)
        end)
        local execTime = tick() - startTime

        if not execOk then
            Console.Error("Command '" .. cmd .. "' threw an error during execution", tostring(execErr))
            RespondError("Command '" .. cmd .. "' encountered an error. Check debug console for details. Error: " .. tostring(execErr):sub(1, 80), wt)
        else
            Console.Command(executorPlayer.Name, cmd, args[2], execTime)
        end
    else
        RespondError("Unknown command: '" .. cmd .. "'. Type '?bot cmds' for a full list of available commands.", wt)
        Console.Warn("Unknown command attempted: " .. cmd, "By: " .. executorPlayer.Name)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 18: CHAT HOOKS (Chatted + TextChatService + Whisper)
-- ═══════════════════════════════════════════════════════════════

local ChatHooks = {}
local HookedChannels = {}

local function HookPlayerChat(player)
    if ChatHooks[player] then return end
    ChatHooks[player] = true
    pcall(function()
        player.Chatted:Connect(function(msg)
            pcall(function() HandleBotCommand(msg, player, false) end)
        end)
    end)
    Console.Log("SYS", "Hooked chat for player: " .. player.Name)
end

local function HookTextChannel(channel)
    if not channel:IsA("TextChannel") then return end
    if HookedChannels[channel] then return end
    HookedChannels[channel] = true
    pcall(function()
        channel.MessageReceived:Connect(function(incomingMessage)
            pcall(function()
                local textSrc = incomingMessage.TextSource
                if textSrc then
                    local actualPlayer = Players:GetPlayerByUserId(textSrc.UserId)
                    if actualPlayer then
                        local isWhisper = channel.Name:find("RBXWhisper") ~= nil
                        HandleBotCommand(incomingMessage.Text, actualPlayer, isWhisper)
                    end
                end
            end)
        end)
    end)
    Console.Log("SYS", "Hooked TextChannel: " .. channel.Name)
end

-- Hook existing players
pcall(function()
    for _, p in ipairs(Players:GetPlayers()) do
        HookPlayerChat(p)
    end
end)

-- Hook new players
pcall(function()
    Players.PlayerAdded:Connect(function(player)
        pcall(function()
            HookPlayerChat(player)
            if player.Name:lower() == SuperOwner:lower() then
                PermittedUsers[player.Name:lower()] = 4
                SendNotification("Boss Alert", SuperOwner .. " has joined the server!", 5)
                Console.Log("PERM", "SuperOwner joined: " .. SuperOwner)
            end
            if ActiveConnections.ESP then
                player.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    if ActiveConnections.ESP then
                        -- ESP re-hook handled by command module
                    end
                end)
            end
        end)
    end)
end)

-- Cleanup on player leave
pcall(function()
    Players.PlayerRemoving:Connect(function(player)
        pcall(function()
            CommandCooldowns[player.Name:lower()] = nil
            ChatHooks[player] = nil
            if ESPObjects[player] then
                pcall(function()
                    if ESPObjects[player].highlight then ESPObjects[player].highlight:Destroy() end
                    if ESPObjects[player].billboard then ESPObjects[player].billboard:Destroy() end
                end)
                ESPObjects[player] = nil
            end
            if FreezeCages[player] then
                for _, part in ipairs(FreezeCages[player]) do pcall(function() part:Destroy() end) end
                FreezeCages[player] = nil
            end
            Console.Log("SYS", "Player left — cleaned up: " .. player.Name)
        end)
    end)
end)

-- Hook TextChatService channels
pcall(function()
    if TextChatService then
        for _, desc in ipairs(TextChatService:GetDescendants()) do
            if desc:IsA("TextChannel") then
                HookTextChannel(desc)
            end
        end
        TextChatService.DescendantAdded:Connect(function(desc)
            if desc:IsA("TextChannel") then
                task.wait(0.05)
                HookTextChannel(desc)
            end
        end)
    end
end)

-- Hook legacy chat system
pcall(function()
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local onMessage = chatEvents:FindFirstChild("OnMessageDoneFiltering")
        if onMessage then
            onMessage.OnClientEvent:Connect(function(msgData)
                pcall(function()
                    if msgData and msgData.FromSpeaker and msgData.Message then
                        local isWhisper = msgData.MessageType == "Whisper"
                            or (msgData.ExtraData and msgData.ExtraData.ChatColor == Color3.new(1, 1, 1))
                        local sender = Players:FindFirstChild(msgData.FromSpeaker)
                        if sender then HandleBotCommand(msgData.Message, sender, isWhisper) end
                    end
                end)
            end)
        end
    end
end)

-- Re-hook TextChannels periodically (catches late-loading channels)
pcall(function()
    if TextChatService then
        local function hookGlobalReceive()
            for _, channel in ipairs(TextChatService:GetDescendants()) do
                if channel:IsA("TextChannel") then
                    HookTextChannel(channel)
                end
            end
        end
        hookGlobalReceive()
        task.delay(3, hookGlobalReceive)
        task.delay(10, hookGlobalReceive)
        task.delay(30, hookGlobalReceive)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 19: CHARACTER RE-HOOKS
-- ═══════════════════════════════════════════════════════════════

pcall(function()
    LocalPlayer.CharacterAdded:Connect(function(char)
        pcall(function()
            task.wait(0.3)
            if IsNoClip then pcall(StartNoClip) end
            if IsGodMode then
                task.wait(0.2)
                pcall(StartGodMode)
            end
            if IsFloorFlying and FloorFlyTarget then
                task.wait(0.2)
                -- FloorFly re-start handled by command module via BotEnv
            end
            if IsSpinning then
                task.wait(0.2)
                -- Spin re-start handled by command module
            end
            if IsAntiFling then
                -- AntiFling re-start handled by command module
            end
            if IsAntiSlow then
                -- AntiSlow re-start handled by command module
            end
            Console.Log("SYS", "Character respawned — re-applied active states")
        end)
    end)
end)

-- Ensure SuperOwner is always level 4
pcall(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == SuperOwner:lower() then
            PermittedUsers[p.Name:lower()] = 4
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 20: ANTI-AFK (auto-start)
-- ═══════════════════════════════════════════════════════════════

local function ToggleAntiAFK(state)
    if state then
        DisconnectSafe("AntiAFK")
        IsAntiAFK = true
        if VirtualUser then
            ActiveConnections.AntiAFK = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                    task.wait(0.3)
                    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                end)
            end)
        else
            ActiveConnections.AntiAFK = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    local hrp = GetBotHRP()
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 0) end
                end)
            end)
        end
        Console.Log("SYS", "AntiAFK enabled")
    else
        DisconnectSafe("AntiAFK")
        IsAntiAFK = false
        Console.Log("SYS", "AntiAFK disabled")
    end
end

-- Expose to BotEnv
BotEnv.ToggleAntiAFK = ToggleAntiAFK

pcall(function() ToggleAntiAFK(true) end)

-- ═══════════════════════════════════════════════════════════════
-- SECTION 21: BOOT SEQUENCE
-- ═══════════════════════════════════════════════════════════════

Console.Log("SYS", "╔══════════════════════════════════════════════════════════╗")
Console.Log("SYS", "║  HIGH-PERFORMANCE COMMAND ENGINE v9.0                   ║")
Console.Log("SYS", "║  GitHub Auto-Discovery | Dynamic Command Loading        ║")
Console.Log("SYS", "╚══════════════════════════════════════════════════════════╝")
Console.Log("SYS", "SuperOwner: " .. SuperOwner)
Console.Log("SYS", "Prefixes: " .. table.concat(Prefixes, "| "))
Console.Log("SYS", "Executor: " .. (ExecutorInfo.ExecutorName or "Unknown"))
Console.Log("SYS", "Mode: " .. BotMode)
Console.Log("SYS", "GitHub Repo: " .. GITHUB_OWNER .. "/" .. GITHUB_REPO)
Console.Log("SYS", "")
Console.Log("SYS", "Scanning GitHub for commands...")

-- Start async command loading
task.spawn(function()
    DiscoverAndLoadAllCommands()

    -- Boot notification
    pcall(function()
        SendNotification(
            "Bot Engine v9.0",
            "Loaded " .. LoadedCommandCount .. " commands from GitHub\n"
            .. "Prefixes: ?bot .bot ,bot /bot\n"
            .. "SuperOwner: " .. SuperOwner .. "\n"
            .. "Type ?bot cmds for help",
            8
        )
    end)

    Console.Log("SYS", "════════════════════════════════════════")
    Console.Log("SYS", "BOOT COMPLETE — Engine is fully operational")
    Console.Log("SYS", "Commands: " .. LoadedCommandCount .. " loaded | " .. #FailedCommands .. " failed")
    Console.Log("SYS", "════════════════════════════════════════")
end)
