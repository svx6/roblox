--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║         🔥🔥🔥 ULTIMATE BOT ENGINE v5.0 — MEGA EDITION 🔥🔥🔥       ║
    ║          Full Executor Support • MM2 Exploits • Zero Anti-Cheat        ║
    ║                                                                        ║
    ║  ✅ 80+ Commands    ✅ 3-Tier Permissions   ✅ Re-execution Safe       ║
    ║  ✅ Fling V3        ✅ Flight System        ✅ ESP/Highlight           ║
    ║  ✅ Anti-AFK        ✅ Anti-Void            ✅ Infinite Jump           ║
    ║  ✅ Teleport        ✅ Speed Boost          ✅ Chat Feedback           ║
    ║  ✅ Notification    ✅ Executor Detection   ✅ Full pcall Safety       ║
    ║  ✅ Bring (Real)    ✅ Platform Teleport    ✅ Player List             ║
    ║  ✅ Loop Kill       ✅ Annoy                ✅ View Target             ║
    ║  ✅ Spin            ✅ Stare                ✅ Gravity Control         ║
    ║  ✅ MM2 GrabKnife   ✅ MM2 GrabGun         ✅ MM2 CoinFarm           ║
    ║  ✅ MM2 Roles       ✅ MM2 XRay            ✅ MM2 GodKnife           ║
    ║  ✅ Auto-Farm       ✅ Private Chat         ✅ Whisper Support        ║
    ║  ✅ Auto-Join       ✅ Rejoin/ServerHop     ✅ Troll Commands         ║
    ║  ✅ Seizure         ✅ Launch/Yeet          ✅ Tornado/Blackhole      ║
    ║  ✅ Cage/Trap       ✅ Giant/Tiny           ✅ Mimic/Creep            ║
    ║  ✅ Strobe          ✅ BTools               ✅ FullBright/Night       ║
    ║  ✅ Dance           ✅ Trail                ✅ Status Dashboard       ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    👑 SuperOwner: roboxproplyer
    🎮 Runs on the BOT's device (executor client-side)
    🔪 MM2 has NO anti-cheat — everything is unlocked
--]]

-- ============================================================================
-- [[ 🔒 RE-EXECUTION GUARD ]]
-- Prevents duplicate hooks/connections when script is run multiple times
-- ============================================================================
local genv = (typeof(getgenv) == "function" and getgenv()) or _G

if genv.__ULTIMATE_BOT_LOADED then
    pcall(function()
        if genv.__ULTIMATE_BOT_CLEANUP then
            genv.__ULTIMATE_BOT_CLEANUP()
        end
    end)
end
genv.__ULTIMATE_BOT_LOADED = true

-- ============================================================================
-- [[ 🔧 COMPATIBILITY LAYER ]]
-- Fallbacks for executors missing standard functions
-- ============================================================================
-- task library fallback
if not task then
    task = {}
end
if not task.spawn then
    task.spawn = function(fn, ...)
        local args = {...}
        coroutine.wrap(function() fn(unpack(args)) end)()
    end
end
if not task.wait then
    task.wait = function(t) local s = tick(); repeat game:GetService("RunService").Heartbeat:Wait() until tick()-s >= (t or 0.03); return tick()-s end
end
if not task.delay then
    task.delay = function(t, fn) task.spawn(function() task.wait(t); fn() end) end
end
if not task.cancel then
    task.cancel = function() end
end

-- string.split fallback
if not string.split then
    string.split = function(str, sep)
        local result = {}
        for part in str:gmatch("([^" .. sep .. "]+)") do
            table.insert(result, part)
        end
        return result
    end
end

-- ============================================================================
-- [[ ⚙️ CORE CONFIGURATION ]]
-- ============================================================================
local SuperOwner      = "roboxproplyer"    -- Level 3: Cannot be unpermed, full control
local Prefix          = "?bot "            -- Command prefix (case-insensitive)
local FlingPower      = 9999999            -- Fling velocity magnitude
local LoopFlingDelay  = 2.0               -- Throttle: seconds between loopfling ticks (FIXED: was 0.15, caused overlaps)
local FollowDistance  = 5                  -- Studs behind target when following
local OrbitRadius     = 12                 -- Studs radius for orbit
local OrbitSpeed      = 3                  -- Orbit rotations speed multiplier
local CooldownTime    = 0.3               -- Seconds between commands per user
local FlySpeed        = 80                 -- Flight speed (studs/sec)
local SpinSpeed       = 20                -- Spin angular speed
local AnnoyDelay      = 0.15              -- Seconds between annoy teleports
local BringIterations = 50                -- Number of rapid-fire bring cycles (INCREASED)
local BringDelay      = 0.03              -- Delay between bring cycles (DECREASED for stronger bring)
local ChatRateLimit   = 1.0               -- Minimum seconds between chat messages (anti-spam filter)
local BotStartTime    = tick()            -- Track uptime

-- ============================================================================
-- [[ 👥 PERMISSIONS DATABASE ]]
-- Permission Levels: 1 = User, 2 = Admin, 3 = SuperOwner
-- ============================================================================
local PermittedUsers = {
    [SuperOwner:lower()] = 3   -- SuperOwner always level 3
}

-- Minimum permission level required per command
local CommandPermissions = {
    -- Level 1: Basic commands (any permitted user)
    tp           = 1, bring        = 1, goto         = 1, follow       = 1,
    orbit        = 1, attach       = 1, fling        = 1, loopfling    = 1,
    loopkill     = 1, annoy        = 1, speed        = 1, jump         = 1,
    hipheight    = 1, gravity      = 1, fly          = 1, unfly        = 1,
    noclip       = 1, clip         = 1, invisible    = 1, invis        = 1,
    visible      = 1, vis          = 1, respawn      = 1, refresh      = 1,
    freeze       = 1, unfreeze     = 1, god          = 1, ungod        = 1,
    spin         = 1, unspin       = 1, stare        = 1, unstare      = 1,
    esp          = 1, unesp        = 1, highlight    = 1, unhighlight  = 1,
    view         = 1, unview       = 1, antivoid     = 1, infjump      = 1,
    platform     = 1, sit          = 1, jumpnow      = 1, players      = 1,
    stop         = 1, reset        = 1, cmds         = 1, help         = 1,
    commands     = 1, antiafk      = 1, ping         = 1, uptime       = 1,
    age          = 1, status       = 1,
    -- MM2 Commands (Level 1)
    grabknife    = 1, grabgun      = 1, mmrole       = 1, cointp       = 1,
    coinfarm     = 1, uncoinfarm   = 1, lobby        = 1, map          = 1,
    xray         = 1, unxray       = 1, godknife     = 1, ungodknife   = 1,
    -- Farm Commands (Level 1)
    farm         = 1, unfarm       = 1,
    -- Troll Commands (Level 1)
    seizure      = 1, launch       = 1, yeet         = 1, tornado      = 1,
    blackhole    = 1, unblackhole  = 1, scatter      = 1, cage         = 1,
    uncage       = 1, trap         = 1, spam         = 1, strobe       = 1,
    unstrobe     = 1, giant        = 1, tiny         = 1, normal       = 1,
    headless     = 1, unheadless   = 1, creep        = 1, mimic        = 1,
    unmimic      = 1, stack        = 1, flingall     = 1, loopflingall = 1,
    -- Utility Commands (Level 1)
    copyname     = 1, btools       = 1, fogoff       = 1, fullbright   = 1,
    nightmode    = 1, daymode      = 1, tpcoords     = 1, dance        = 1,
    undance      = 1, trail        = 1, untrail      = 1, rejoin       = 1,
    serverhop    = 1, char         = 1,
    -- Level 2: Admin commands
    perm         = 2, unperm       = 2,
    -- Level 3: SuperOwner only
    admin        = 3, unadmin      = 3, shutdown     = 3,
}

-- ============================================================================
-- [[ 🚀 SERVICES ]]
-- ============================================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui         = game:GetService("StarterGui")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocalPlayer        = Players.LocalPlayer

-- Safe service loading
local TextChatService = nil
pcall(function() TextChatService = game:GetService("TextChatService") end)

local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local TeleportService = nil
pcall(function() TeleportService = game:GetService("TeleportService") end)

local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)

local MarketplaceService = nil
pcall(function() MarketplaceService = game:GetService("MarketplaceService") end)

-- ============================================================================
-- [[ 🔧 EXECUTOR FEATURE DETECTION ]]
-- ============================================================================
local ExecutorInfo = {
    HasFireTouchInterest = typeof(firetouchinterest) == "function",
    HasGetHiddenProperty = typeof(gethiddenproperty) == "function",
    HasSetHiddenProperty = typeof(sethiddenproperty) == "function",
    HasSetClipboard      = typeof(setclipboard) == "function",
    HasGetGenv           = typeof(getgenv) == "function",
    HasHttpRequest       = typeof(request) == "function" or typeof(http_request) == "function",
    HasSetFpsCap         = typeof(setfpscap) == "function",
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

-- ============================================================================
-- [[ 📊 ENGINE STATES ]]
-- ============================================================================
local ActiveConnections = {}
local AllConnectionNames = {
    "LoopFling", "LoopKill", "LoopFlingAll", "Follow", "Orbit", "Attach",
    "Annoy", "NoClip", "Fly", "God", "AntiAFK", "AntiVoid", "InfJump",
    "Spin", "Stare", "ESP", "CoinFarm", "Farm", "BlackHole", "Strobe",
    "Creep", "Mimic", "Trail", "GodKnife", "Tornado", "Seizure", "Dance",
}

for _, name in ipairs(AllConnectionNames) do
    ActiveConnections[name] = nil
end

local FlyBodyGyro       = nil
local FlyBodyVelocity   = nil
local IsFlying          = false
local IsNoClip          = true
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
local ESPObjects        = {}
local CommandCooldowns  = {}
local CommandLog        = {}
local PlatformPart      = nil
local CageParts         = {}
local TrailParts        = {}
local XRayParts         = {}
local OriginalGravity   = Workspace.Gravity
local OriginalLighting  = {}
local LastChatTime      = 0

-- Save original lighting settings
pcall(function()
    OriginalLighting.Ambient = Lighting.Ambient
    OriginalLighting.Brightness = Lighting.Brightness
    OriginalLighting.FogEnd = Lighting.FogEnd
    OriginalLighting.FogStart = Lighting.FogStart
    OriginalLighting.ClockTime = Lighting.ClockTime
    OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
end)

-- ============================================================================
-- [[ 📋 LOGGING SYSTEM ]]
-- ============================================================================
local function Log(level, message)
    local timestamp = os.date("%H:%M:%S")
    local prefix_map = {
        INFO  = "ℹ️",  WARN  = "⚠️",  ERROR = "❌",
        CMD   = "⚡",  OK    = "✅",  SYS   = "🔧",
    }
    local icon = prefix_map[level] or "📝"
    print(string.format("[%s] %s %s: %s", timestamp, icon, level, message))
end

local function LogCommand(executorName, command, targetName)
    local entry = {
        time     = os.date("%H:%M:%S"),
        executor = executorName,
        command  = command,
        target   = targetName or "N/A",
    }
    table.insert(CommandLog, entry)
    if #CommandLog > 500 then
        table.remove(CommandLog, 1)
    end
    Log("CMD", string.format("%s → %s %s", executorName, command, targetName or ""))
end

-- ============================================================================
-- [[ 💬 CHAT FEEDBACK SYSTEM ]]
-- Rate-limited to prevent spam filter / mute
-- ============================================================================
local function SendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "🤖 Bot",
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
        -- Try TextChatService (modern Roblox chat)
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
        -- Fallback: legacy chat system
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

-- Send response to whisper channel if command came from whisper
local function SendWhisperMessage(targetPlayer, text)
    pcall(function()
        if TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                -- Find whisper channel for this player
                for _, channel in ipairs(channels:GetChildren()) do
                    if channel.Name:find("RBXWhisper") and channel.Name:find(tostring(targetPlayer.UserId)) then
                        channel:SendAsync(text)
                        return
                    end
                end
            end
        end
    end)
end

local function Notify(message, whisperTarget)
    Log("OK", message)
    SendNotification("✅ Bot", message, 3)
    pcall(function() SendChatMessage("[BOT] " .. message) end)
    if whisperTarget then
        pcall(function() SendWhisperMessage(whisperTarget, "[BOT] " .. message) end)
    end
end

local function NotifyError(message, whisperTarget)
    Log("ERROR", message)
    SendNotification("❌ Bot Error", message, 4)
    pcall(function() SendChatMessage("[BOT] ❌ " .. message) end)
    if whisperTarget then
        pcall(function() SendWhisperMessage(whisperTarget, "[BOT] ❌ " .. message) end)
    end
end

-- ============================================================================
-- [[ 🔒 PERMISSION HELPERS ]]
-- ============================================================================
local function GetPermLevel(player)
    if not player then return 0 end
    return PermittedUsers[player.Name:lower()] or 0
end

local function HasPermission(player, command)
    local playerLevel = GetPermLevel(player)
    local requiredLevel = CommandPermissions[command] or 1
    return playerLevel >= requiredLevel
end

local function IsSuperOwner(player)
    return player and player.Name:lower() == SuperOwner:lower()
end

-- ============================================================================
-- [[ ⏱️ COOLDOWN SYSTEM ]]
-- ============================================================================
local function IsOnCooldown(player)
    if IsSuperOwner(player) then return false end
    local key = player.Name:lower()
    local lastUse = CommandCooldowns[key]
    if lastUse and (tick() - lastUse) < CooldownTime then
        return true
    end
    CommandCooldowns[key] = tick()
    return false
end

-- ============================================================================
-- [[ 🛡️ SAFE CHARACTER ACCESS ]]
-- ============================================================================
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
        task.wait(0.5)
    end
    return LocalPlayer.Character
end

-- ============================================================================
-- [[ 🔍 ADVANCED SMART TARGET FINDER v3 ]]
-- Supports: me, all, others, random, nearest, farthest, murd, sherif,
--           team, enemies, partial name, display name, userid
-- ============================================================================
local function GetMultipleTargets(stringInput, executorPlayer)
    if not stringInput or stringInput == "" then return {} end
    stringInput = stringInput:lower()

    -- ─── Multi-target keywords ───
    if stringInput == "all" then
        local targets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(targets, p)
            end
        end
        return targets

    elseif stringInput == "others" then
        local targets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p ~= executorPlayer then
                table.insert(targets, p)
            end
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

    -- ─── Single target keywords ───
    local single = nil

    if stringInput == "me" then
        single = executorPlayer

    elseif stringInput == "random" or stringInput == "rand" then
        local pool = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(pool, p) end
        end
        if #pool > 0 then
            single = pool[math.random(1, #pool)]
        end

    elseif stringInput == "nearest" or stringInput == "near" or stringInput == "closest" then
        local botHRP = GetBotHRP()
        if botHRP then
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then
                    local hrp = GetHRP(p)
                    if hrp then
                        local dist = (hrp.Position - botHRP.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            single = p
                        end
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
                        if dist > maxDist then
                            maxDist = dist
                            single = p
                        end
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
        -- Try UserId match
        local numInput = tonumber(stringInput)
        if numInput then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == numInput then
                    single = p
                    break
                end
            end
        end

        -- Fuzzy partial name matching
        if not single then
            local bestMatch = nil
            local bestLen = math.huge

            for _, p in ipairs(Players:GetPlayers()) do
                local nameLow = p.Name:lower()
                local displayLow = p.DisplayName:lower()

                if nameLow == stringInput or displayLow == stringInput then
                    single = p
                    bestMatch = nil
                    break
                end

                if nameLow:sub(1, #stringInput) == stringInput
                    or displayLow:sub(1, #stringInput) == stringInput then
                    if #p.Name < bestLen then
                        bestMatch = p
                        bestLen = #p.Name
                    end
                end
            end

            single = single or bestMatch
        end
    end

    if single then
        return { single }
    end
    return {}
end

local function GetSmartTarget(stringInput, executorPlayer)
    local targets = GetMultipleTargets(stringInput, executorPlayer)
    return targets[1]
end

-- ============================================================================
-- [[ 🔌 CONNECTION MANAGER ]]
-- ============================================================================
local function DisconnectSafe(name)
    if ActiveConnections[name] then
        pcall(function()
            ActiveConnections[name]:Disconnect()
        end)
        ActiveConnections[name] = nil
    end
end

local function StopAllLoops()
    for name, conn in pairs(ActiveConnections) do
        if name ~= "NoClip" and name ~= "AntiAFK" and name ~= "AntiVoid" then
            DisconnectSafe(name)
        end
    end

    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end
    IsFlying = false
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

    -- Clean up cage parts
    for _, part in ipairs(CageParts) do
        pcall(function() part:Destroy() end)
    end
    CageParts = {}

    -- Clean up trail parts
    for _, part in ipairs(TrailParts) do
        pcall(function() part:Destroy() end)
    end
    TrailParts = {}

    -- Remove spin body velocity
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyAngularVelocity") or obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                    if obj ~= FlyBodyGyro and obj ~= FlyBodyVelocity then
                        obj:Destroy()
                    end
                end
            end
        end
    end)

    Log("INFO", "All active loops stopped.")
end

local function FullCleanup()
    for name, _ in pairs(ActiveConnections) do
        DisconnectSafe(name)
    end
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end
    if PlatformPart then pcall(function() PlatformPart:Destroy() end) PlatformPart = nil end

    for _, part in ipairs(CageParts) do pcall(function() part:Destroy() end) end
    CageParts = {}

    for _, part in ipairs(TrailParts) do pcall(function() part:Destroy() end) end
    TrailParts = {}

    -- Restore XRay
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

    pcall(function() Workspace.Gravity = OriginalGravity end)

    -- Restore lighting
    pcall(function()
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)

    -- Clean body movers from character
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyMover") then obj:Destroy() end
            end
        end
    end)

    IsFlying = false
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
    Log("SYS", "Full cleanup completed.")
end
genv.__ULTIMATE_BOT_CLEANUP = FullCleanup

-- ============================================================================
-- [[ 🚫 NO-CLIP ENGINE ]]
-- ============================================================================
local function StartNoClip()
    DisconnectSafe("NoClip")
    IsNoClip = true
    ActiveConnections.NoClip = RunService.Stepped:Connect(function()
        pcall(function()
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

StartNoClip()

-- ============================================================================
-- [[ 🌪️ FLING ENGINE V3 ]]
-- Multi-phase fling: approach → spin up → impact → reset
-- ============================================================================
local function ExecutePhysicalFling(targetPlayer)
    local success, err = pcall(function()
        if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then return end

        local targetHRP = GetHRP(targetPlayer)
        local botHRP    = GetBotHRP()
        local botHum    = GetBotHumanoid()

        if not targetHRP or not botHRP or not botHum then return end

        local savedPos = botHRP.CFrame
        botHum:ChangeState(Enum.HumanoidStateType.Physics)

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 1250
        bv.Parent = botHRP

        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.P = 1250
        bav.Parent = botHRP

        for i = 1, 30 do
            local tHRP = GetHRP(targetPlayer)
            if not tHRP or not IsAlive(targetPlayer) then break end
            local currentBotHRP = GetBotHRP()
            if not currentBotHRP then break end
            currentBotHRP.CFrame = tHRP.CFrame
            RunService.Heartbeat:Wait()
        end

        pcall(function() bv:Destroy() end)
        pcall(function() bav:Destroy() end)

        task.wait(0.05)
        local resetHRP = GetBotHRP()
        if resetHRP then
            resetHRP.CFrame = savedPos
            resetHRP.AssemblyLinearVelocity = Vector3.zero
            resetHRP.AssemblyAngularVelocity = Vector3.zero
        end

        local resetHum = GetBotHumanoid()
        if resetHum then
            resetHum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)

    if not success then
        Log("ERROR", "Fling failed: " .. tostring(err))
    end
end

-- Directional fling (for launch/yeet)
local function ExecuteDirectionalFling(targetPlayer, direction, power)
    pcall(function()
        if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then return end

        local targetHRP = GetHRP(targetPlayer)
        local botHRP    = GetBotHRP()
        local botHum    = GetBotHumanoid()

        if not targetHRP or not botHRP or not botHum then return end

        local savedPos = botHRP.CFrame
        botHum:ChangeState(Enum.HumanoidStateType.Physics)

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = direction * (power or FlingPower)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 1250
        bv.Parent = botHRP

        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.P = 1250
        bav.Parent = botHRP

        for i = 1, 35 do
            local tHRP = GetHRP(targetPlayer)
            if not tHRP or not IsAlive(targetPlayer) then break end
            local currentBotHRP = GetBotHRP()
            if not currentBotHRP then break end
            currentBotHRP.CFrame = tHRP.CFrame
            RunService.Heartbeat:Wait()
        end

        pcall(function() bv:Destroy() end)
        pcall(function() bav:Destroy() end)

        task.wait(0.05)
        local resetHRP = GetBotHRP()
        if resetHRP then
            resetHRP.CFrame = savedPos
            resetHRP.AssemblyLinearVelocity = Vector3.zero
            resetHRP.AssemblyAngularVelocity = Vector3.zero
        end

        local resetHum = GetBotHumanoid()
        if resetHum then
            resetHum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- ============================================================================
-- [[ ✈️ FLIGHT SYSTEM ]]
-- ============================================================================
local function StartFly()
    local botHRP = GetBotHRP()
    local botHum = GetBotHumanoid()
    if not botHRP or not botHum then
        NotifyError("Cannot fly — no character.")
        return
    end

    DisconnectSafe("Fly")
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) end

    IsFlying = true

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyGyro.CFrame = botHRP.CFrame
    FlyBodyGyro.Parent = botHRP

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyVelocity.Parent = botHRP

    ActiveConnections.Fly = RunService.Heartbeat:Connect(function()
        pcall(function()
            local hrp = GetBotHRP()
            if not hrp or not IsFlying then
                DisconnectSafe("Fly")
                return
            end

            local camera = Workspace.CurrentCamera
            if not camera then return end
            FlyBodyGyro.CFrame = camera.CFrame

            local moveDir = Vector3.zero
            local isMoving = false

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + camera.CFrame.LookVector; isMoving = true
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - camera.CFrame.LookVector; isMoving = true
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - camera.CFrame.RightVector; isMoving = true
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + camera.CFrame.RightVector; isMoving = true
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0); isMoving = true
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0); isMoving = true
            end

            if isMoving and moveDir.Magnitude > 0 then
                FlyBodyVelocity.Velocity = moveDir.Unit * FlySpeed
            else
                FlyBodyVelocity.Velocity = Vector3.zero
            end
        end)
    end)

    Notify("✈️ Flight ON — WASD + Space/Shift")
end

local function StopFly()
    IsFlying = false
    DisconnectSafe("Fly")
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end
    Notify("🛬 Flight OFF")
end

-- ============================================================================
-- [[ 🛡️ GOD MODE ]]
-- ============================================================================
local function StartGodMode()
    DisconnectSafe("God")
    IsGodMode = true
    ActiveConnections.God = RunService.Heartbeat:Connect(function()
        pcall(function()
            local hum = GetBotHumanoid()
            if hum then hum.Health = hum.MaxHealth end
        end)
    end)
    Notify("🛡️ God Mode ON")
end

local function StopGodMode()
    DisconnectSafe("God")
    IsGodMode = false
    Notify("💀 God Mode OFF")
end

-- ============================================================================
-- [[ 🫥 INVISIBILITY SYSTEM ]]
-- ============================================================================
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
    Notify(state and "🫥 Invisible ON" or "👁️ Visible ON")
end

-- ============================================================================
-- [[ ❄️ FREEZE / UNFREEZE ]]
-- ============================================================================
local function FreezePlayer(target)
    if not target then return end
    if target == LocalPlayer then
        local hrp = GetBotHRP()
        if hrp then
            pcall(function() hrp.Anchored = true end)
            Notify("❄️ Bot frozen")
        end
    else
        Notify("❄️ Attempted freeze on " .. target.Name .. " (client-side limit: only works on bot)")
    end
end

local function UnfreezePlayer(target)
    if not target then return end
    if target == LocalPlayer then
        local hrp = GetBotHRP()
        if hrp then
            pcall(function() hrp.Anchored = false end)
            Notify("🔥 Bot unfrozen")
        end
    else
        Notify("🔥 Attempted unfreeze on " .. target.Name)
    end
end

-- ============================================================================
-- [[ 🔄 ANTI-AFK SYSTEM ]]
-- ============================================================================
local function ToggleAntiAFK(state)
    if state then
        DisconnectSafe("AntiAFK")
        IsAntiAFK = true

        if VirtualUser then
            ActiveConnections.AntiAFK = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                    task.wait(0.5)
                    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                end)
            end)
            Notify("🔄 Anti-AFK ON")
        else
            ActiveConnections.AntiAFK = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    local hrp = GetBotHRP()
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 0)
                    end
                end)
            end)
            Notify("🔄 Anti-AFK ON (fallback mode)")
        end
    else
        DisconnectSafe("AntiAFK")
        IsAntiAFK = false
        Notify("💤 Anti-AFK OFF")
    end
end

-- ============================================================================
-- [[ 🛡️ ANTI-VOID SYSTEM ]]
-- ============================================================================
local LastSafePosition = nil

local function ToggleAntiVoid(state)
    if state then
        DisconnectSafe("AntiVoid")
        IsAntiVoid = true
        LastSafePosition = GetBotHRP() and GetBotHRP().CFrame or CFrame.new(0, 50, 0)

        ActiveConnections.AntiVoid = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hrp = GetBotHRP()
                if not hrp then return end
                if hrp.Position.Y > -50 then
                    LastSafePosition = hrp.CFrame
                else
                    hrp.CFrame = LastSafePosition
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    Notify("🛡️ Anti-Void saved you!")
                end
            end)
        end)
        Notify("🛡️ Anti-Void ON")
    else
        DisconnectSafe("AntiVoid")
        IsAntiVoid = false
        Notify("⬇️ Anti-Void OFF")
    end
end

-- ============================================================================
-- [[ 🦘 INFINITE JUMP ]]
-- ============================================================================
local function ToggleInfJump(state)
    if state then
        DisconnectSafe("InfJump")
        IsInfJump = true
        ActiveConnections.InfJump = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                local hum = GetBotHumanoid()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end)
        Notify("🦘 Infinite Jump ON")
    else
        DisconnectSafe("InfJump")
        IsInfJump = false
        Notify("🦘 Infinite Jump OFF")
    end
end

-- ============================================================================
-- [[ 🌀 SPIN SYSTEM ]]
-- ============================================================================
local function StartSpin()
    DisconnectSafe("Spin")
    IsSpinning = true
    local spinBav = nil

    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            spinBav = Instance.new("BodyAngularVelocity")
            spinBav.AngularVelocity = Vector3.new(0, SpinSpeed, 0)
            spinBav.MaxTorque = Vector3.new(0, math.huge, 0)
            spinBav.P = 1250
            spinBav.Parent = hrp
        end
    end)

    ActiveConnections.Spin = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not GetBotHRP() and spinBav then
                spinBav:Destroy()
                DisconnectSafe("Spin")
                IsSpinning = false
            end
        end)
    end)

    Notify("🌀 Spinning ON")
end

local function StopSpin()
    DisconnectSafe("Spin")
    IsSpinning = false
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyAngularVelocity") then
                    obj:Destroy()
                end
            end
        end
    end)
    Notify("🌀 Spinning OFF")
end

-- ============================================================================
-- [[ 👁️ STARE / LOOK-AT SYSTEM ]]
-- ============================================================================
local function StartStare(target)
    DisconnectSafe("Stare")
    ActiveConnections.Stare = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                botHRP.CFrame = CFrame.new(botHRP.Position, targetHRP.Position)
            else
                DisconnectSafe("Stare")
            end
        end)
    end)
    Notify("👁️ Staring at " .. target.Name)
end

-- ============================================================================
-- [[ 📡 ESP / HIGHLIGHT SYSTEM ]]
-- ============================================================================
local function CreateESPForPlayer(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    local char = GetCharacter(player)
    if not char then return end

    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        billboard.Parent = char

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        nameLabel.Name = "ESPName"
        nameLabel.Parent = billboard

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextScaled = true
        distLabel.Text = "? studs"
        distLabel.Name = "ESPDist"
        distLabel.Parent = billboard

        ESPObjects[player] = {
            highlight = highlight,
            billboard = billboard,
            distLabel = distLabel,
        }
    end)
end

local function RemoveESPForPlayer(player)
    if ESPObjects[player] then
        pcall(function()
            if ESPObjects[player].highlight then ESPObjects[player].highlight:Destroy() end
            if ESPObjects[player].billboard then ESPObjects[player].billboard:Destroy() end
        end)
        ESPObjects[player] = nil
    end
end

local function StartESP()
    for _, p in ipairs(Players:GetPlayers()) do
        CreateESPForPlayer(p)
        -- BUGFIX: Hook CharacterAdded so ESP re-creates on respawn
        pcall(function()
            p.CharacterAdded:Connect(function()
                task.wait(1)
                if ActiveConnections.ESP then
                    RemoveESPForPlayer(p)
                    CreateESPForPlayer(p)
                end
            end)
        end)
    end

    DisconnectSafe("ESP")
    ActiveConnections.ESP = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            for player, objects in pairs(ESPObjects) do
                if player and player.Parent and objects.distLabel then
                    local targetHRP = GetHRP(player)
                    if botHRP and targetHRP then
                        local dist = math.floor((botHRP.Position - targetHRP.Position).Magnitude)
                        objects.distLabel.Text = dist .. " studs"

                        if dist < 30 then
                            objects.distLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                        elseif dist < 80 then
                            objects.distLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
                        else
                            objects.distLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                        end
                    end
                else
                    RemoveESPForPlayer(player)
                end
            end
        end)
    end)

    Notify("📡 ESP ON — all players highlighted")
end

local function StopESP()
    DisconnectSafe("ESP")
    for player, _ in pairs(ESPObjects) do
        RemoveESPForPlayer(player)
    end
    ESPObjects = {}
    Notify("📡 ESP OFF")
end

-- ============================================================================
-- [[ 🔲 PLATFORM SYSTEM ]]
-- ============================================================================
local function CreatePlatform()
    if PlatformPart then pcall(function() PlatformPart:Destroy() end) end

    local hrp = GetBotHRP()
    if not hrp then
        NotifyError("No character for platform.")
        return
    end

    PlatformPart = Instance.new("Part")
    PlatformPart.Size = Vector3.new(15, 1, 15)
    PlatformPart.Position = hrp.Position - Vector3.new(0, 3, 0)
    PlatformPart.Anchored = true
    PlatformPart.BrickColor = BrickColor.new("Lime green")
    PlatformPart.Material = Enum.Material.Neon
    PlatformPart.Transparency = 0.3
    PlatformPart.CanCollide = true
    PlatformPart.Name = "BotPlatform"
    PlatformPart.Parent = Workspace

    Notify("🔲 Platform created under you!")
end

-- ============================================================================
-- [[ 👁️ VIEW CAMERA SYSTEM ]]
-- ============================================================================
local OriginalCameraSubject = nil

local function ViewPlayer(target)
    if not target then return end
    local char = GetCharacter(target)
    local hum = GetHumanoid(target)
    if not char or not hum then
        NotifyError("Cannot view — target has no character.")
        return
    end

    if not OriginalCameraSubject then
        OriginalCameraSubject = Workspace.CurrentCamera.CameraSubject
    end
    Workspace.CurrentCamera.CameraSubject = hum
    Notify("👁️ Viewing " .. target.Name .. "'s perspective")
end

local function UnviewPlayer()
    if OriginalCameraSubject then
        pcall(function()
            Workspace.CurrentCamera.CameraSubject = OriginalCameraSubject
        end)
        OriginalCameraSubject = nil
    else
        pcall(function()
            local hum = GetBotHumanoid()
            if hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
        end)
    end
    Notify("👁️ Camera reset to your character")
end

-- ============================================================================
-- [[ 😈 BRING (Improved) ]]
-- Stronger bring with more iterations and better physics push
-- ============================================================================
local function BringPlayer(target)
    if not target then return end
    local botHRP = GetBotHRP()
    local targetHRP = GetHRP(target)
    if not botHRP or not targetHRP then
        NotifyError("Character not loaded.")
        return
    end

    task.spawn(function()
        pcall(function()
            local savedPos = botHRP.CFrame
            local botHum = GetBotHumanoid()

            -- Use physics state for stronger impact
            if botHum then
                botHum:ChangeState(Enum.HumanoidStateType.Physics)
            end

            for i = 1, BringIterations do
                local tHRP = GetHRP(target)
                local bHRP = GetBotHRP()
                if not tHRP or not bHRP or not target.Parent then break end
                bHRP.CFrame = tHRP.CFrame
                RunService.Heartbeat:Wait()
                bHRP = GetBotHRP()
                if bHRP then
                    bHRP.CFrame = savedPos
                end
                if BringDelay > 0 then task.wait(BringDelay) end
            end

            -- Reset state
            local resetHum = GetBotHumanoid()
            if resetHum then
                resetHum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end)

    Notify("📍 Bringing " .. target.Name)
end

-- ============================================================================
-- [[ 😡 ANNOY SYSTEM ]]
-- ============================================================================
local function StartAnnoy(target)
    DisconnectSafe("Annoy")
    DisconnectSafe("Follow")
    DisconnectSafe("Orbit")
    DisconnectSafe("Attach")

    local lastAnnoyTime = 0
    ActiveConnections.Annoy = RunService.Heartbeat:Connect(function()
        local now = tick()
        if (now - lastAnnoyTime) < AnnoyDelay then return end
        lastAnnoyTime = now

        pcall(function()
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                local rx = math.random(-3, 3)
                local rz = math.random(-3, 3)
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(rx, 0, rz)
            else
                DisconnectSafe("Annoy")
                Notify("⏹️ Annoy stopped — target lost.")
            end
        end)
    end)
    Notify("😈 Annoying " .. target.Name)
end

-- ============================================================================
-- [[ 🔪 MM2-SPECIFIC SYSTEMS ]]
-- Murder Mystery 2 has NO anti-cheat so everything works!
-- ============================================================================

-- Find MM2 coins in workspace
local function FindMM2Coins()
    local coins = {}
    pcall(function()
        -- MM2 coins are typically in a "CoinContainer" or similar folder
        local function searchForCoins(parent)
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    if name:find("coin") or name:find("collectable") or name:find("collectible") then
                        table.insert(coins, obj)
                    end
                    -- Also check for TouchInterest (collectible indicator)
                    if obj:FindFirstChild("TouchInterest") then
                        table.insert(coins, obj)
                    end
                end
                if obj:IsA("Model") or obj:IsA("Folder") then
                    searchForCoins(obj)
                end
            end
        end

        -- Check common MM2 containers
        local coinContainer = Workspace:FindFirstChild("CoinContainer")
            or Workspace:FindFirstChild("Coins")
            or Workspace:FindFirstChild("CoinFolder")
            or Workspace:FindFirstChild("CollectableCoins")
        if coinContainer then
            searchForCoins(coinContainer)
        else
            -- Search entire workspace (slower but thorough)
            searchForCoins(Workspace)
        end
    end)
    return coins
end

-- Grab weapon from map or player backpack
local function GrabWeapon(weaponName)
    pcall(function()
        -- First check if it's a dropped weapon in workspace
        local function findWeapon(parent)
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("Tool") and obj.Name:lower():find(weaponName:lower()) then
                    return obj
                end
                if obj:IsA("Model") or obj:IsA("Folder") then
                    local found = findWeapon(obj)
                    if found then return found end
                end
            end
            return nil
        end

        -- Check workspace for dropped weapons
        local weapon = findWeapon(Workspace)
        if weapon then
            local handle = weapon:FindFirstChild("Handle")
            if handle then
                local botHRP = GetBotHRP()
                if botHRP then
                    botHRP.CFrame = handle.CFrame
                    task.wait(0.2)
                    -- Try to equip
                    if weapon.Parent == Workspace then
                        pcall(function()
                            weapon.Parent = LocalPlayer.Backpack
                        end)
                    end
                end
            end
            Notify("🔪 Grabbed " .. weaponName .. " from map!")
            return
        end

        -- Check own backpack
        local backpackWeapon = LocalPlayer.Backpack:FindFirstChild(weaponName)
            or LocalPlayer.Backpack:FindFirstChild("Knife")
            or LocalPlayer.Backpack:FindFirstChild("Gun")
        if backpackWeapon then
            pcall(function()
                local hum = GetBotHumanoid()
                if hum then
                    hum:EquipTool(backpackWeapon)
                end
            end)
            Notify("🔪 Equipped " .. backpackWeapon.Name .. " from backpack!")
            return
        end

        NotifyError("Could not find " .. weaponName)
    end)
end

-- Get MM2 roles
local function GetMM2Roles()
    local roles = { murderer = nil, sheriff = nil, innocents = {} }
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            local hasKnife = false
            local hasGun = false

            pcall(function()
                hasKnife = p.Backpack:FindFirstChild("Knife") ~= nil
                    or (GetCharacter(p) and GetCharacter(p):FindFirstChild("Knife") ~= nil)
            end)

            pcall(function()
                hasGun = p.Backpack:FindFirstChild("Gun") ~= nil
                    or (GetCharacter(p) and GetCharacter(p):FindFirstChild("Gun") ~= nil)
                    or p.Backpack:FindFirstChild("Revolver") ~= nil
                    or (GetCharacter(p) and GetCharacter(p):FindFirstChild("Revolver") ~= nil)
            end)

            if hasKnife then
                roles.murderer = p
            elseif hasGun then
                roles.sheriff = p
            else
                table.insert(roles.innocents, p)
            end
        end
    end)
    return roles
end

-- XRay (see through walls)
local function StartXRay()
    XRayParts = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character or game)
                and not Players:GetPlayerFromCharacter(obj.Parent)
                and obj.Transparency < 0.5 then
                table.insert(XRayParts, { part = obj, original = obj.Transparency })
                obj.Transparency = 0.7
            end
        end
    end)
    Notify("👁️ XRay ON — walls are transparent!")
end

local function StopXRay()
    for _, data in ipairs(XRayParts) do
        pcall(function()
            data.part.Transparency = data.original
        end)
    end
    XRayParts = {}
    Notify("👁️ XRay OFF — walls restored")
end

-- ============================================================================
-- [[ 💰 AUTO-FARM SYSTEM ]]
-- ============================================================================

-- MM2 Coin Farm
local function StartCoinFarm()
    DisconnectSafe("CoinFarm")
    IsCoinFarming = true

    task.spawn(function()
        while IsCoinFarming do
            pcall(function()
                local coins = FindMM2Coins()
                local botHRP = GetBotHRP()
                if not botHRP then return end

                for _, coin in ipairs(coins) do
                    if not IsCoinFarming then break end
                    if coin and coin.Parent then
                        botHRP.CFrame = coin.CFrame
                        -- Use firetouchinterest if available for instant collection
                        if ExecutorInfo.HasFireTouchInterest then
                            local touchInterest = coin:FindFirstChild("TouchInterest")
                            if touchInterest then
                                firetouchinterest(botHRP, coin, 0)
                                task.wait(0.05)
                                firetouchinterest(botHRP, coin, 1)
                            end
                        end
                        task.wait(0.1)
                    end
                end
            end)
            task.wait(1) -- Wait before scanning again
        end
    end)

    -- Track with a heartbeat connection for clean disconnect
    ActiveConnections.CoinFarm = RunService.Heartbeat:Connect(function()
        if not IsCoinFarming then
            DisconnectSafe("CoinFarm")
        end
    end)

    Notify("💰 MM2 CoinFarm ON — teleporting to coins!")
end

local function StopCoinFarm()
    IsCoinFarming = false
    DisconnectSafe("CoinFarm")
    Notify("💰 CoinFarm OFF")
end

-- Generic auto-farm (collects all TouchInterest objects)
local function StartFarm()
    DisconnectSafe("Farm")
    IsFarming = true

    task.spawn(function()
        while IsFarming do
            pcall(function()
                local botHRP = GetBotHRP()
                if not botHRP then return end

                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not IsFarming then break end
                    if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
                        -- Skip player characters
                        local isPlayer = false
                        pcall(function()
                            isPlayer = Players:GetPlayerFromCharacter(obj.Parent) ~= nil
                                or Players:GetPlayerFromCharacter(obj.Parent and obj.Parent.Parent) ~= nil
                        end)
                        if not isPlayer then
                            botHRP.CFrame = obj.CFrame
                            if ExecutorInfo.HasFireTouchInterest then
                                firetouchinterest(botHRP, obj, 0)
                                task.wait(0.05)
                                firetouchinterest(botHRP, obj, 1)
                            end
                            task.wait(0.1)
                        end
                    end
                end
            end)
            task.wait(2) -- Scan interval
        end
    end)

    ActiveConnections.Farm = RunService.Heartbeat:Connect(function()
        if not IsFarming then
            DisconnectSafe("Farm")
        end
    end)

    Notify("🌾 Auto-Farm ON — collecting all items!")
end

local function StopFarm()
    IsFarming = false
    DisconnectSafe("Farm")
    Notify("🌾 Auto-Farm OFF")
end

-- ============================================================================
-- [[ 🤡 INSANE TROLL COMMANDS ]]
-- ============================================================================

-- Seizure: Rapid random teleport around target
local function StartSeizure(target)
    DisconnectSafe("Seizure")
    DisconnectSafe("Follow")
    DisconnectSafe("Orbit")
    DisconnectSafe("Attach")
    DisconnectSafe("Annoy")

    ActiveConnections.Seizure = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                local rx = math.random(-5, 5)
                local ry = math.random(-2, 5)
                local rz = math.random(-5, 5)
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(rx, ry, rz) * CFrame.Angles(
                    math.random() * math.pi * 2,
                    math.random() * math.pi * 2,
                    math.random() * math.pi * 2
                )
            else
                DisconnectSafe("Seizure")
                Notify("⏹️ Seizure stopped — target lost.")
            end
        end)
    end)
    Notify("🤪 Seizure mode on " .. target.Name .. "!")
end

-- Launch: Fling straight UP
local function LaunchPlayer(target)
    task.spawn(function()
        ExecuteDirectionalFling(target, Vector3.new(0, 1, 0), FlingPower * 2)
    end)
    Notify("🚀 Launched " .. target.Name .. " into the SKY!")
end

-- Yeet: Fling horizontally
local function YeetPlayer(target)
    task.spawn(function()
        local botHRP = GetBotHRP()
        local targetHRP = GetHRP(target)
        if botHRP and targetHRP then
            local direction = (targetHRP.Position - botHRP.Position)
            if direction.Magnitude > 0 then
                direction = direction.Unit
            else
                direction = Vector3.new(1, 0, 0)
            end
            ExecuteDirectionalFling(target, direction, FlingPower * 2)
        end
    end)
    Notify("💨 YEETED " .. target.Name .. "!")
end

-- Tornado: Orbit at insane speed while flinging
local function StartTornado(target)
    DisconnectSafe("Tornado")
    DisconnectSafe("Follow")
    DisconnectSafe("Orbit")
    DisconnectSafe("Attach")
    DisconnectSafe("Annoy")

    local angle = 0
    local lastFlingTime = 0
    local tornadoRadius = 5
    local tornadoSpeed = 15

    ActiveConnections.Tornado = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            local targetHRP = GetHRP(target)
            local botHRP = GetBotHRP()
            local botHum = GetBotHumanoid()
            if targetHRP and botHRP and target and target.Parent and IsAlive(target) then
                angle = angle + (dt * tornadoSpeed)
                local x = math.cos(angle) * tornadoRadius
                local z = math.sin(angle) * tornadoRadius
                local y = math.sin(angle * 2) * 3 -- Bobbing up/down
                local orbitPos = targetHRP.Position + Vector3.new(x, y + 2, z)
                botHRP.CFrame = CFrame.new(orbitPos, targetHRP.Position)

                -- Fling every 1.5 seconds
                local now = tick()
                if (now - lastFlingTime) > 1.5 then
                    lastFlingTime = now
                    if botHum then
                        botHum:ChangeState(Enum.HumanoidStateType.Physics)
                    end
                    -- Quick ram into target
                    botHRP.CFrame = targetHRP.CFrame
                    botHRP.AssemblyLinearVelocity = Vector3.new(
                        math.random(-FlingPower, FlingPower),
                        math.random(-FlingPower, FlingPower),
                        math.random(-FlingPower, FlingPower)
                    )
                    task.delay(0.1, function()
                        local rHum = GetBotHumanoid()
                        if rHum then rHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                    end)
                end
            else
                DisconnectSafe("Tornado")
                Notify("⏹️ Tornado stopped — target lost.")
            end
        end)
    end)
    Notify("🌪️ TORNADO on " .. target.Name .. " — orbiting + flinging!")
end

-- Blackhole: Suck all players toward bot
local function StartBlackHole()
    DisconnectSafe("BlackHole")
    IsBlackHole = true

    ActiveConnections.BlackHole = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local botHum = GetBotHumanoid()
            if not botHRP or not botHum then return end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then
                    local targetHRP = GetHRP(p)
                    if targetHRP then
                        local savedPos = botHRP.CFrame
                        botHum:ChangeState(Enum.HumanoidStateType.Physics)
                        botHRP.CFrame = targetHRP.CFrame
                        botHRP.AssemblyLinearVelocity = Vector3.new(FlingPower, 0, FlingPower)
                        RunService.Heartbeat:Wait()
                        local bHRP = GetBotHRP()
                        if bHRP then
                            bHRP.CFrame = savedPos
                            bHRP.AssemblyLinearVelocity = Vector3.zero
                        end
                        local bHum = GetBotHumanoid()
                        if bHum then bHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                    end
                end
            end
        end)
    end)
    Notify("🕳️ BLACKHOLE ON — sucking all players!")
end

local function StopBlackHole()
    DisconnectSafe("BlackHole")
    IsBlackHole = false
    Notify("🕳️ Blackhole OFF")
end

-- Scatter: Fling ALL players in random directions
local function ScatterAll()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsAlive(p) then
                local dir = Vector3.new(
                    math.random(-1, 1),
                    math.random(0, 1),
                    math.random(-1, 1)
                )
                if dir.Magnitude > 0 then dir = dir.Unit end
                task.spawn(function()
                    ExecuteDirectionalFling(p, dir, FlingPower)
                end)
                task.wait(0.2)
            end
        end
    end)
    Notify("💥 SCATTER — all players flung in random directions!")
end

-- Cage: Create a cage of parts around target
local function CagePlayer(target)
    if not target then return end
    local targetHRP = GetHRP(target)
    if not targetHRP then
        NotifyError("Target has no character.")
        return
    end

    -- Remove old cage
    for _, part in ipairs(CageParts) do
        pcall(function() part:Destroy() end)
    end
    CageParts = {}

    local pos = targetHRP.Position
    local cageSize = 6

    -- Create 6 walls (cube cage)
    local walls = {
        { size = Vector3.new(cageSize, cageSize, 1), pos = pos + Vector3.new(0, cageSize/2, cageSize/2) },   -- Front
        { size = Vector3.new(cageSize, cageSize, 1), pos = pos + Vector3.new(0, cageSize/2, -cageSize/2) },  -- Back
        { size = Vector3.new(1, cageSize, cageSize), pos = pos + Vector3.new(cageSize/2, cageSize/2, 0) },   -- Right
        { size = Vector3.new(1, cageSize, cageSize), pos = pos + Vector3.new(-cageSize/2, cageSize/2, 0) },  -- Left
        { size = Vector3.new(cageSize, 1, cageSize), pos = pos + Vector3.new(0, cageSize, 0) },              -- Top
        { size = Vector3.new(cageSize, 1, cageSize), pos = pos + Vector3.new(0, 0, 0) },                     -- Bottom
    }

    for _, wallData in ipairs(walls) do
        pcall(function()
            local wall = Instance.new("Part")
            wall.Size = wallData.size
            wall.Position = wallData.pos
            wall.Anchored = true
            wall.Material = Enum.Material.ForceField
            wall.BrickColor = BrickColor.new("Really red")
            wall.Transparency = 0.5
            wall.CanCollide = true
            wall.Name = "BotCage"
            wall.Parent = Workspace
            table.insert(CageParts, wall)
        end)
    end

    Notify("🔒 Caged " .. target.Name .. "!")
end

local function RemoveCage()
    for _, part in ipairs(CageParts) do
        pcall(function() part:Destroy() end)
    end
    CageParts = {}
    Notify("🔓 Cage removed!")
end

-- Trap: Teleport target into void repeatedly (via fling downward)
local function TrapPlayer(target)
    task.spawn(function()
        for i = 1, 5 do
            if not target or not target.Parent then break end
            ExecuteDirectionalFling(target, Vector3.new(0, -1, 0), FlingPower)
            task.wait(0.5)
        end
    end)
    Notify("🕳️ Trapping " .. target.Name .. " in the void!")
end

-- Spam: Send a message repeatedly
local function SpamChat(message, count)
    count = math.min(count or 10, 20) -- Cap at 20
    task.spawn(function()
        for i = 1, count do
            pcall(function() SendChatMessage(message) end)
            task.wait(ChatRateLimit + 0.1) -- Respect rate limit
        end
    end)
    Notify("📢 Spamming: " .. message .. " (" .. count .. "x)")
end

-- Strobe: Rapidly flash lighting
local function StartStrobe()
    DisconnectSafe("Strobe")
    IsStrobing = true
    local strobeState = false

    ActiveConnections.Strobe = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsStrobing then
                DisconnectSafe("Strobe")
                return
            end
            strobeState = not strobeState
            if strobeState then
                Lighting.Brightness = 10
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            else
                Lighting.Brightness = 0
                Lighting.Ambient = Color3.new(0, 0, 0)
                Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            end
        end)
    end)
    Notify("💡 STROBE ON — flashing lights!")
end

local function StopStrobe()
    IsStrobing = false
    DisconnectSafe("Strobe")
    pcall(function()
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
    Notify("💡 Strobe OFF — lighting restored")
end

-- Giant/Tiny/Normal: Scale bot character
local function ScaleCharacter(scale)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Try to scale via Humanoid description
        local desc = hum:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            desc.HeightScale = scale
            desc.WidthScale = scale
            desc.DepthScale = scale
            desc.HeadScale = scale
            hum:ApplyDescription(desc)
            return
        end

        -- Fallback: manual scale via body parts
        for _, partName in ipairs({"Head", "Torso", "UpperTorso", "LowerTorso",
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.Size = part.Size * scale
            end
        end
    end)
end

-- Headless: Remove head visually
local function SetHeadless(state)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if head then
            if state then
                head.Transparency = 1
                local face = head:FindFirstChildOfClass("Decal")
                if face then face.Transparency = 1 end
                -- Hide hat meshes
                for _, acc in ipairs(char:GetChildren()) do
                    if acc:IsA("Accessory") then
                        local handle = acc:FindFirstChild("Handle")
                        if handle then handle.Transparency = 1 end
                    end
                end
            else
                head.Transparency = 0
                local face = head:FindFirstChildOfClass("Decal")
                if face then face.Transparency = 0 end
                for _, acc in ipairs(char:GetChildren()) do
                    if acc:IsA("Accessory") then
                        local handle = acc:FindFirstChild("Handle")
                        if handle then handle.Transparency = 0 end
                    end
                end
            end
        end
    end)
    Notify(state and "💀 Headless ON" or "🗣️ Head restored")
end

-- Creep: Slowly walk toward target staring
local function StartCreep(target)
    DisconnectSafe("Creep")
    DisconnectSafe("Follow")
    DisconnectSafe("Stare")
    IsCreeping = true

    -- Slow walk speed
    pcall(function()
        local hum = GetBotHumanoid()
        if hum then hum.WalkSpeed = 3 end
    end)

    ActiveConnections.Creep = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            local botHum = GetBotHumanoid()
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) and botHum then
                -- Face target
                botHRP.CFrame = CFrame.new(botHRP.Position, targetHRP.Position)
                -- Walk toward
                botHum:MoveTo(targetHRP.Position)
            else
                DisconnectSafe("Creep")
                IsCreeping = false
                Notify("⏹️ Creep stopped — target lost.")
            end
        end)
    end)
    Notify("👻 Creeping toward " .. target.Name .. "...")
end

-- Mimic: Copy target's every movement
local function StartMimic(target)
    DisconnectSafe("Mimic")
    DisconnectSafe("Follow")
    DisconnectSafe("Orbit")
    IsMimicking = true

    local offset = CFrame.new(3, 0, 0) -- Slightly offset so you can see both

    ActiveConnections.Mimic = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                botHRP.CFrame = targetHRP.CFrame * offset
            else
                DisconnectSafe("Mimic")
                IsMimicking = false
                Notify("⏹️ Mimic stopped — target lost.")
            end
        end)
    end)
    Notify("🪞 Mimicking " .. target.Name .. "'s movements!")
end

local function StopMimic()
    DisconnectSafe("Mimic")
    IsMimicking = false
    Notify("🪞 Mimic OFF")
end

-- Stack: Teleport on top of target's head
local function StackOnPlayer(target)
    local targetHRP = GetHRP(target)
    local botHRP = GetBotHRP()
    if targetHRP and botHRP then
        botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
        Notify("📚 Stacked on " .. target.Name .. "'s head!")
    else
        NotifyError("Target has no character.")
    end
end

-- FlingAll: Fling every player
local function FlingAllPlayers()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsAlive(p) then
                task.spawn(function()
                    ExecutePhysicalFling(p)
                end)
                task.wait(0.3)
            end
        end
    end)
    Notify("🌪️ FLINGING ALL PLAYERS!")
end

-- LoopFlingAll: Continuously fling all players
local function StartLoopFlingAll()
    DisconnectSafe("LoopFlingAll")
    DisconnectSafe("LoopFling")
    DisconnectSafe("LoopKill")

    local lastFlingTime = 0
    ActiveConnections.LoopFlingAll = RunService.Heartbeat:Connect(function()
        local now = tick()
        if (now - lastFlingTime) < LoopFlingDelay then return end
        lastFlingTime = now

        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) and GetHRP(p) then
                    task.spawn(function()
                        ExecutePhysicalFling(p)
                    end)
                end
            end
        end)
    end)
    Notify("🌪️🔁 LOOP FLINGING ALL PLAYERS!")
end

-- GodKnife: Teleport to target and use knife (MM2)
local function StartGodKnife(target)
    DisconnectSafe("GodKnife")
    IsGodKnife = true

    ActiveConnections.GodKnife = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsGodKnife then
                DisconnectSafe("GodKnife")
                return
            end

            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                -- Teleport to target
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)

                -- Try to equip and use knife
                local char = LocalPlayer.Character
                local knife = char and char:FindFirstChild("Knife")
                if not knife then
                    knife = LocalPlayer.Backpack:FindFirstChild("Knife")
                    if knife then
                        local hum = GetBotHumanoid()
                        if hum then hum:EquipTool(knife) end
                    end
                end

                -- Activate the tool (click/attack)
                if knife then
                    pcall(function() knife:Activate() end)
                end
            else
                DisconnectSafe("GodKnife")
                IsGodKnife = false
                Notify("⏹️ GodKnife stopped — target lost.")
            end
        end)
    end)
    Notify("🔪💀 GodKnife ON — chasing " .. target.Name .. "!")
end

local function StopGodKnife()
    IsGodKnife = false
    DisconnectSafe("GodKnife")
    Notify("🔪 GodKnife OFF")
end

-- Trail: Leave neon trail parts behind
local function StartTrail()
    DisconnectSafe("Trail")
    IsTrailing = true

    local lastTrailTime = 0
    ActiveConnections.Trail = RunService.Heartbeat:Connect(function()
        local now = tick()
        if (now - lastTrailTime) < 0.15 then return end
        lastTrailTime = now

        pcall(function()
            local hrp = GetBotHRP()
            if not hrp then return end

            local trailPart = Instance.new("Part")
            trailPart.Size = Vector3.new(1, 1, 1)
            trailPart.Position = hrp.Position - Vector3.new(0, 3, 0)
            trailPart.Anchored = true
            trailPart.CanCollide = false
            trailPart.Material = Enum.Material.Neon
            trailPart.BrickColor = BrickColor.random()
            trailPart.Shape = Enum.PartType.Ball
            trailPart.Name = "BotTrail"
            trailPart.Parent = Workspace
            table.insert(TrailParts, trailPart)

            -- Fade and remove after 3 seconds
            task.spawn(function()
                for i = 0, 10 do
                    task.wait(0.3)
                    pcall(function() trailPart.Transparency = i / 10 end)
                end
                pcall(function() trailPart:Destroy() end)
                -- Remove from table
                for idx, tp in ipairs(TrailParts) do
                    if tp == trailPart then
                        table.remove(TrailParts, idx)
                        break
                    end
                end
            end)

            -- Cap trail parts
            if #TrailParts > 100 then
                local old = table.remove(TrailParts, 1)
                pcall(function() old:Destroy() end)
            end
        end)
    end)
    Notify("🌈 Trail ON — leaving neon trail!")
end

local function StopTrail()
    IsTrailing = false
    DisconnectSafe("Trail")
    for _, part in ipairs(TrailParts) do
        pcall(function() part:Destroy() end)
    end
    TrailParts = {}
    Notify("🌈 Trail OFF")
end

-- Dance: Make bot play emote animation
local function StartDance()
    DisconnectSafe("Dance")
    IsDancing = true

    local danceAngle = 0
    ActiveConnections.Dance = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            local hrp = GetBotHRP()
            if not hrp or not IsDancing then
                DisconnectSafe("Dance")
                return
            end
            danceAngle = danceAngle + dt * 8
            local bounce = math.sin(danceAngle) * 2
            local spin = math.sin(danceAngle * 0.5) * 0.3
            hrp.CFrame = hrp.CFrame * CFrame.new(0, bounce * 0.1, 0) * CFrame.Angles(0, spin, 0)
        end)
    end)
    Notify("💃 Dancing!")
end

local function StopDance()
    IsDancing = false
    DisconnectSafe("Dance")
    Notify("💃 Dance OFF")
end

-- ============================================================================
-- [[ 🎮 UTILITY SYSTEMS ]]
-- ============================================================================

-- BTools: Give building tools
local function GiveBTools()
    pcall(function()
        -- Delete tool
        local deleteTool = Instance.new("Tool")
        deleteTool.Name = "Delete"
        deleteTool.RequiresHandle = false
        deleteTool.Parent = LocalPlayer.Backpack

        deleteTool.Activated:Connect(function()
            pcall(function()
                local mouse = LocalPlayer:GetMouse()
                if mouse.Target then
                    mouse.Target:Destroy()
                end
            end)
        end)

        -- Clone tool
        local cloneTool = Instance.new("Tool")
        cloneTool.Name = "Clone"
        cloneTool.RequiresHandle = false
        cloneTool.Parent = LocalPlayer.Backpack

        cloneTool.Activated:Connect(function()
            pcall(function()
                local mouse = LocalPlayer:GetMouse()
                if mouse.Target then
                    local clone = mouse.Target:Clone()
                    clone.Parent = Workspace
                end
            end)
        end)
    end)
    Notify("🔨 BTools given! (Delete, Clone)")
end

-- Rejoin same server
local function RejoinServer()
    pcall(function()
        if TeleportService then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    Notify("🔄 Rejoining server...")
end

-- Server hop
local function ServerHop()
    pcall(function()
        if TeleportService and HttpService then
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, result = pcall(function()
                if request then
                    return request({ Url = url, Method = "GET" })
                elseif http_request then
                    return http_request({ Url = url, Method = "GET" })
                end
            end)

            if success and result and result.Body then
                local decoded = HttpService:JSONDecode(result.Body)
                if decoded and decoded.data then
                    for _, server in ipairs(decoded.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                            Notify("🌐 Server hopping...")
                            return
                        end
                    end
                end
            end

            -- Fallback: just rejoin
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
            Notify("🌐 Server hopping (fallback)...")
        end
    end)
end

-- Format time for uptime
local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- ============================================================================
-- [[ 🧠 COMMAND ROUTER ]]
-- Central command processing — full validation, permissions, cooldowns
-- ============================================================================
local function HandleBotCommand(message, executorPlayer, isWhisper)
    if not message or not executorPlayer then return end
    if typeof(message) ~= "string" then return end

    -- ─── Prefix check (case-insensitive) ───
    local msgLower = message:lower()
    local prefixLower = Prefix:lower()
    if msgLower:sub(1, #prefixLower) ~= prefixLower then return end

    -- ─── Permission check ───
    local permLevel = GetPermLevel(executorPlayer)
    if permLevel < 1 then return end

    -- ─── Cooldown check ───
    if IsOnCooldown(executorPlayer) then return end

    -- ─── Parse command and arguments ───
    local cleanString = message:sub(#Prefix + 1)
    if not cleanString or cleanString == "" then return end

    local args = string.split(cleanString, " ")
    if not args or not args[1] or args[1] == "" then return end

    local cmd = args[1]:lower()

    -- ─── Permission check for specific command ───
    if not HasPermission(executorPlayer, cmd) then
        NotifyError(executorPlayer.Name .. " lacks permission for: " .. cmd, isWhisper and executorPlayer)
        return
    end

    -- Build rest-of-args string (for spam, etc)
    local restArgs = ""
    if #args > 1 then
        local parts = {}
        for i = 2, #args do
            table.insert(parts, args[i])
        end
        restArgs = table.concat(parts, " ")
    end

    -- Log the command
    LogCommand(executorPlayer.Name, cmd, args[2])

    -- Whisper target for responses (nil if public chat)
    local wt = isWhisper and executorPlayer or nil

    -- ════════════════════════════════════════════════════════════════
    -- 📍 MOVEMENT COMMANDS
    -- ════════════════════════════════════════════════════════════════

    if cmd == "tp" then
        if not args[2] then NotifyError("Usage: ?bot tp <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        local targetHRP = GetHRP(target)
        local botHRP = GetBotHRP()
        if targetHRP and botHRP then
            botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            Notify("📍 Teleported to " .. target.Name, wt)
        else
            NotifyError("Character not loaded.", wt)
        end

    elseif cmd == "bring" then
        if not args[2] then NotifyError("Usage: ?bot bring <target>", wt) return end
        local targets = GetMultipleTargets(args[2], executorPlayer)
        if #targets == 0 then NotifyError("Player not found: " .. args[2], wt) return end
        for _, target in ipairs(targets) do
            BringPlayer(target)
            task.wait(0.1)
        end

    elseif cmd == "goto" then
        if not args[2] then NotifyError("Usage: ?bot goto <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        local targetHRP = GetHRP(target)
        local botHum = GetBotHumanoid()
        if targetHRP and botHum then
            botHum:MoveTo(targetHRP.Position)
            Notify("🚶 Walking to " .. target.Name, wt)
        else
            NotifyError("Character not loaded.", wt)
        end

    elseif cmd == "follow" then
        if not args[2] then NotifyError("Usage: ?bot follow <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end

        DisconnectSafe("Follow")
        DisconnectSafe("Orbit")
        DisconnectSafe("Attach")
        DisconnectSafe("Annoy")
        DisconnectSafe("Creep")
        DisconnectSafe("Mimic")

        ActiveConnections.Follow = RunService.Heartbeat:Connect(function()
            pcall(function()
                local targetHRP = GetHRP(target)
                local botHRP = GetBotHRP()
                if targetHRP and botHRP and target and target.Parent and IsAlive(target) then
                    local dir = (botHRP.Position - targetHRP.Position)
                    if dir.Magnitude > 0 then
                        local offset = dir.Unit * FollowDistance
                        botHRP.CFrame = CFrame.new(targetHRP.Position + offset, targetHRP.Position)
                    end
                else
                    DisconnectSafe("Follow")
                    Notify("⏹️ Follow stopped — target lost.")
                end
            end)
        end)
        Notify("🔗 Following " .. target.Name, wt)

    elseif cmd == "orbit" then
        if not args[2] then NotifyError("Usage: ?bot orbit <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end

        DisconnectSafe("Follow")
        DisconnectSafe("Orbit")
        DisconnectSafe("Attach")
        DisconnectSafe("Annoy")
        DisconnectSafe("Creep")
        DisconnectSafe("Mimic")

        local angle = 0
        ActiveConnections.Orbit = RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                local targetHRP = GetHRP(target)
                local botHRP = GetBotHRP()
                if targetHRP and botHRP and target and target.Parent and IsAlive(target) then
                    angle = angle + (dt * OrbitSpeed)
                    local x = math.cos(angle) * OrbitRadius
                    local z = math.sin(angle) * OrbitRadius
                    local orbitPos = targetHRP.Position + Vector3.new(x, 2, z)
                    botHRP.CFrame = CFrame.new(orbitPos, targetHRP.Position)
                else
                    DisconnectSafe("Orbit")
                    Notify("⏹️ Orbit stopped — target lost.")
                end
            end)
        end)
        Notify("🌀 Orbiting " .. target.Name, wt)

    elseif cmd == "attach" then
        if not args[2] then NotifyError("Usage: ?bot attach <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end

        DisconnectSafe("Follow")
        DisconnectSafe("Orbit")
        DisconnectSafe("Attach")
        DisconnectSafe("Annoy")
        DisconnectSafe("Creep")
        DisconnectSafe("Mimic")

        ActiveConnections.Attach = RunService.Heartbeat:Connect(function()
            pcall(function()
                local targetHRP = GetHRP(target)
                local botHRP = GetBotHRP()
                if targetHRP and botHRP and target and target.Parent and IsAlive(target) then
                    botHRP.CFrame = targetHRP.CFrame
                else
                    DisconnectSafe("Attach")
                    Notify("⏹️ Attach stopped — target lost.")
                end
            end)
        end)
        Notify("📎 Attached to " .. target.Name, wt)

    elseif cmd == "annoy" then
        if not args[2] then NotifyError("Usage: ?bot annoy <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartAnnoy(target)

    elseif cmd == "tpcoords" then
        local x = tonumber(args[2])
        local y = tonumber(args[3])
        local z = tonumber(args[4])
        if not x or not y or not z then
            NotifyError("Usage: ?bot tpcoords <x> <y> <z>", wt)
            return
        end
        local botHRP = GetBotHRP()
        if botHRP then
            botHRP.CFrame = CFrame.new(x, y, z)
            Notify("📍 Teleported to " .. x .. ", " .. y .. ", " .. z, wt)
        end

    -- ════════════════════════════════════════════════════════════════
    -- 🌪️ FLING COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "fling" then
        if not args[2] then NotifyError("Usage: ?bot fling <target|all|others>", wt) return end
        local targets = GetMultipleTargets(args[2], executorPlayer)
        if #targets == 0 then NotifyError("No targets found: " .. args[2], wt) return end

        for _, target in ipairs(targets) do
            Notify("🌪️ Flinging " .. target.Name, wt)
            task.spawn(function()
                ExecutePhysicalFling(target)
            end)
            task.wait(0.2)
        end

    elseif cmd == "loopfling" then
        if not args[2] then NotifyError("Usage: ?bot loopfling <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end

        DisconnectSafe("LoopFling")
        DisconnectSafe("LoopKill")
        DisconnectSafe("LoopFlingAll")

        local lastFlingTime = 0
        ActiveConnections.LoopFling = RunService.Heartbeat:Connect(function()
            local now = tick()
            if (now - lastFlingTime) < LoopFlingDelay then return end
            lastFlingTime = now

            if target and target.Parent and IsAlive(target) and GetHRP(target) then
                pcall(function() ExecutePhysicalFling(target) end)
            elseif not target or not target.Parent then
                DisconnectSafe("LoopFling")
                Notify("⏹️ LoopFling stopped — target left.")
            end
        end)
        Notify("🌪️🔁 LoopFling on " .. target.Name, wt)

    elseif cmd == "loopkill" then
        if not args[2] then NotifyError("Usage: ?bot loopkill <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end

        DisconnectSafe("LoopFling")
        DisconnectSafe("LoopKill")
        DisconnectSafe("LoopFlingAll")

        local lastFlingTime = 0
        ActiveConnections.LoopKill = RunService.Heartbeat:Connect(function()
            local now = tick()
            if (now - lastFlingTime) < LoopFlingDelay then return end
            lastFlingTime = now

            pcall(function()
                if not target or not target.Parent then
                    DisconnectSafe("LoopKill")
                    Notify("⏹️ LoopKill stopped — player left the game.")
                    return
                end
                if IsAlive(target) and GetHRP(target) then
                    ExecutePhysicalFling(target)
                end
            end)
        end)
        Notify("💀🔁 LoopKill on " .. target.Name .. " (persists through respawn)", wt)

    elseif cmd == "flingall" then
        FlingAllPlayers()

    elseif cmd == "loopflingall" then
        StartLoopFlingAll()

    -- ════════════════════════════════════════════════════════════════
    -- 🦸 CHARACTER COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "speed" then
        local value = tonumber(args[2])
        if not value then NotifyError("Usage: ?bot speed <number>", wt) return end
        local hum = GetBotHumanoid()
        if hum then
            hum.WalkSpeed = value
            Notify("⚡ WalkSpeed → " .. value, wt)
        end

    elseif cmd == "jump" then
        local value = tonumber(args[2])
        if not value then NotifyError("Usage: ?bot jump <number>", wt) return end
        local hum = GetBotHumanoid()
        if hum then
            hum.JumpPower = value
            hum.UseJumpPower = true
            Notify("🦘 JumpPower → " .. value, wt)
        end

    elseif cmd == "hipheight" then
        local value = tonumber(args[2])
        if not value then NotifyError("Usage: ?bot hipheight <number>", wt) return end
        local hum = GetBotHumanoid()
        if hum then
            hum.HipHeight = value
            Notify("📏 HipHeight → " .. value, wt)
        end

    elseif cmd == "gravity" then
        local value = tonumber(args[2])
        if not value then NotifyError("Usage: ?bot gravity <number> (default 196.2)", wt) return end
        pcall(function() Workspace.Gravity = value end)
        Notify("🌍 Gravity → " .. value, wt)

    elseif cmd == "fly" then
        StartFly()

    elseif cmd == "unfly" then
        StopFly()

    elseif cmd == "noclip" then
        StartNoClip()
        Notify("👻 NoClip ON", wt)

    elseif cmd == "clip" then
        StopNoClip()
        Notify("🧱 NoClip OFF", wt)

    elseif cmd == "invisible" or cmd == "invis" then
        SetInvisible(true)

    elseif cmd == "visible" or cmd == "vis" then
        SetInvisible(false)

    elseif cmd == "respawn" or cmd == "refresh" then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                char:BreakJoints()
            end
        end)
        Notify("🔄 Respawning...", wt)

    elseif cmd == "freeze" then
        if not args[2] then
            FreezePlayer(LocalPlayer)
        else
            local target = GetSmartTarget(args[2], executorPlayer)
            if not target then NotifyError("Player not found: " .. args[2], wt) return end
            FreezePlayer(target)
        end

    elseif cmd == "unfreeze" then
        if not args[2] then
            UnfreezePlayer(LocalPlayer)
        else
            local target = GetSmartTarget(args[2], executorPlayer)
            if not target then NotifyError("Player not found: " .. args[2], wt) return end
            UnfreezePlayer(target)
        end

    elseif cmd == "god" then
        StartGodMode()

    elseif cmd == "ungod" then
        StopGodMode()

    elseif cmd == "spin" then
        StartSpin()

    elseif cmd == "unspin" then
        StopSpin()

    elseif cmd == "stare" then
        if not args[2] then NotifyError("Usage: ?bot stare <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartStare(target)

    elseif cmd == "unstare" then
        DisconnectSafe("Stare")
        Notify("👁️ Stare OFF", wt)

    -- ════════════════════════════════════════════════════════════════
    -- 📡 ESP / VISUAL COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "esp" then
        StartESP()

    elseif cmd == "unesp" then
        StopESP()

    elseif cmd == "highlight" then
        if not args[2] then NotifyError("Usage: ?bot highlight <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        CreateESPForPlayer(target)
        Notify("🔦 Highlighted " .. target.Name, wt)

    elseif cmd == "unhighlight" then
        if not args[2] then
            for player, _ in pairs(ESPObjects) do
                RemoveESPForPlayer(player)
            end
            ESPObjects = {}
            Notify("🔦 All highlights removed", wt)
        else
            local target = GetSmartTarget(args[2], executorPlayer)
            if target then
                RemoveESPForPlayer(target)
                Notify("🔦 Unhighlighted " .. target.Name, wt)
            end
        end

    elseif cmd == "view" then
        if not args[2] then NotifyError("Usage: ?bot view <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        ViewPlayer(target)

    elseif cmd == "unview" then
        UnviewPlayer()

    -- ════════════════════════════════════════════════════════════════
    -- 🛡️ SAFETY / UTILITY COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "antivoid" then
        ToggleAntiVoid(not IsAntiVoid)

    elseif cmd == "infjump" then
        ToggleInfJump(not IsInfJump)

    elseif cmd == "platform" then
        CreatePlatform()

    elseif cmd == "sit" then
        local hum = GetBotHumanoid()
        if hum then
            hum.Sit = true
            Notify("🪑 Bot sat down", wt)
        end

    elseif cmd == "jumpnow" then
        local hum = GetBotHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            Notify("⬆️ Bot jumped", wt)
        end

    elseif cmd == "players" then
        Notify("👥 Players in server: " .. #Players:GetPlayers(), wt)
        for _, p in ipairs(Players:GetPlayers()) do
            local alive = IsAlive(p) and "✅" or "💀"
            local perm = GetPermLevel(p)
            local permStr = perm > 0 and (" [L" .. perm .. "]") or ""
            local isBot = p == LocalPlayer and " [BOT]" or ""
            Notify("  " .. alive .. " " .. p.Name .. " (" .. p.DisplayName .. ")" .. permStr .. isBot, wt)
        end

    elseif cmd == "ping" then
        Notify("🏓 Pong! Bot is alive and running!", wt)

    elseif cmd == "uptime" then
        local uptimeSeconds = tick() - BotStartTime
        Notify("⏱️ Bot uptime: " .. FormatTime(uptimeSeconds), wt)

    elseif cmd == "age" then
        if not args[2] then NotifyError("Usage: ?bot age <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        local ageDays = target.AccountAge
        local years = math.floor(ageDays / 365)
        local days = ageDays % 365
        Notify("📅 " .. target.Name .. "'s account age: " .. years .. " years, " .. days .. " days (" .. ageDays .. " total days)", wt)

    elseif cmd == "status" then
        Notify("━━━━ 📊 BOT STATUS ━━━━", wt)
        Notify("🕐 Uptime: " .. FormatTime(tick() - BotStartTime), wt)
        Notify("🔧 Executor: " .. ExecutorInfo.ExecutorName, wt)
        Notify("👻 NoClip: " .. (IsNoClip and "ON" or "OFF"), wt)
        Notify("✈️ Flying: " .. (IsFlying and "ON" or "OFF"), wt)
        Notify("🛡️ GodMode: " .. (IsGodMode and "ON" or "OFF"), wt)
        Notify("🔄 AntiAFK: " .. (IsAntiAFK and "ON" or "OFF"), wt)
        Notify("🛡️ AntiVoid: " .. (IsAntiVoid and "ON" or "OFF"), wt)
        Notify("🦘 InfJump: " .. (IsInfJump and "ON" or "OFF"), wt)
        Notify("🌀 Spinning: " .. (IsSpinning and "ON" or "OFF"), wt)
        Notify("💰 CoinFarm: " .. (IsCoinFarming and "ON" or "OFF"), wt)
        Notify("🌾 Farm: " .. (IsFarming and "ON" or "OFF"), wt)
        Notify("📡 ESP: " .. (ActiveConnections.ESP and "ON" or "OFF"), wt)
        -- Count active loops
        local activeCount = 0
        for name, conn in pairs(ActiveConnections) do
            if conn then activeCount = activeCount + 1 end
        end
        Notify("⚡ Active connections: " .. activeCount, wt)

    elseif cmd == "copyname" then
        if not args[2] then NotifyError("Usage: ?bot copyname <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        if ExecutorInfo.HasSetClipboard then
            pcall(function() setclipboard(target.Name) end)
            Notify("📋 Copied " .. target.Name .. " to clipboard!", wt)
        else
            Notify("📋 " .. target.Name .. " (clipboard not available on this executor)", wt)
        end

    -- ════════════════════════════════════════════════════════════════
    -- 🔪 MM2 COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "grabknife" then
        GrabWeapon("Knife")

    elseif cmd == "grabgun" then
        GrabWeapon("Gun")

    elseif cmd == "mmrole" or cmd == "roles" then
        local roles = GetMM2Roles()
        Notify("━━━━ 🔪 MM2 ROLES ━━━━", wt)
        Notify("🔪 Murderer: " .. (roles.murderer and roles.murderer.Name or "Unknown"), wt)
        Notify("🔫 Sheriff: " .. (roles.sheriff and roles.sheriff.Name or "Unknown"), wt)
        Notify("😇 Innocents: " .. #roles.innocents .. " players", wt)

    elseif cmd == "cointp" then
        local coins = FindMM2Coins()
        if #coins > 0 then
            local botHRP = GetBotHRP()
            if botHRP then
                task.spawn(function()
                    for _, coin in ipairs(coins) do
                        if coin and coin.Parent then
                            botHRP.CFrame = coin.CFrame
                            if ExecutorInfo.HasFireTouchInterest then
                                local ti = coin:FindFirstChild("TouchInterest")
                                if ti then
                                    firetouchinterest(botHRP, coin, 0)
                                    task.wait(0.05)
                                    firetouchinterest(botHRP, coin, 1)
                                end
                            end
                            task.wait(0.15)
                        end
                    end
                end)
                Notify("💰 Teleporting to " .. #coins .. " coins!", wt)
            end
        else
            NotifyError("No coins found!", wt)
        end

    elseif cmd == "coinfarm" then
        StartCoinFarm()

    elseif cmd == "uncoinfarm" then
        StopCoinFarm()

    elseif cmd == "lobby" then
        local botHRP = GetBotHRP()
        if botHRP then
            -- Common MM2 lobby positions
            botHRP.CFrame = CFrame.new(-109, 140, -12)
            Notify("🏠 Teleported to lobby!", wt)
        end

    elseif cmd == "map" then
        local botHRP = GetBotHRP()
        if botHRP then
            -- Try to find map center
            pcall(function()
                local mapFolder = Workspace:FindFirstChild("Map")
                    or Workspace:FindFirstChild("CurrentMap")
                if mapFolder then
                    -- Find center of map parts
                    local totalPos = Vector3.zero
                    local count = 0
                    for _, obj in ipairs(mapFolder:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            totalPos = totalPos + obj.Position
                            count = count + 1
                        end
                    end
                    if count > 0 then
                        botHRP.CFrame = CFrame.new(totalPos / count + Vector3.new(0, 5, 0))
                        Notify("🗺️ Teleported to map center!", wt)
                        return
                    end
                end
                -- Fallback
                botHRP.CFrame = CFrame.new(0, 50, 0)
                Notify("🗺️ Teleported to center (fallback)", wt)
            end)
        end

    elseif cmd == "xray" then
        StartXRay()

    elseif cmd == "unxray" then
        StopXRay()

    elseif cmd == "godknife" then
        if not args[2] then NotifyError("Usage: ?bot godknife <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartGodKnife(target)

    elseif cmd == "ungodknife" then
        StopGodKnife()

    -- ════════════════════════════════════════════════════════════════
    -- 🌾 FARM COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "farm" then
        StartFarm()

    elseif cmd == "unfarm" then
        StopFarm()

    -- ════════════════════════════════════════════════════════════════
    -- 🤡 TROLL COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "seizure" then
        if not args[2] then NotifyError("Usage: ?bot seizure <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartSeizure(target)

    elseif cmd == "launch" then
        if not args[2] then NotifyError("Usage: ?bot launch <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        LaunchPlayer(target)

    elseif cmd == "yeet" then
        if not args[2] then NotifyError("Usage: ?bot yeet <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        YeetPlayer(target)

    elseif cmd == "tornado" then
        if not args[2] then NotifyError("Usage: ?bot tornado <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartTornado(target)

    elseif cmd == "blackhole" then
        StartBlackHole()

    elseif cmd == "unblackhole" then
        StopBlackHole()

    elseif cmd == "scatter" then
        ScatterAll()

    elseif cmd == "cage" then
        if not args[2] then NotifyError("Usage: ?bot cage <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        CagePlayer(target)

    elseif cmd == "uncage" then
        RemoveCage()

    elseif cmd == "trap" then
        if not args[2] then NotifyError("Usage: ?bot trap <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        TrapPlayer(target)

    elseif cmd == "spam" then
        if restArgs == "" then NotifyError("Usage: ?bot spam <message>", wt) return end
        local count = tonumber(args[#args])
        local msg = restArgs
        if count then
            -- Last arg is count, remove it from message
            local parts = {}
            for i = 2, #args - 1 do table.insert(parts, args[i]) end
            msg = table.concat(parts, " ")
        else
            count = 10
        end
        SpamChat(msg, count)

    elseif cmd == "strobe" then
        StartStrobe()

    elseif cmd == "unstrobe" then
        StopStrobe()

    elseif cmd == "giant" then
        ScaleCharacter(3)
        Notify("🗿 GIANT MODE ON!", wt)

    elseif cmd == "tiny" then
        ScaleCharacter(0.3)
        Notify("🐜 TINY MODE ON!", wt)

    elseif cmd == "normal" then
        ScaleCharacter(1)
        Notify("👤 Normal size restored", wt)

    elseif cmd == "headless" then
        SetHeadless(true)

    elseif cmd == "unheadless" then
        SetHeadless(false)

    elseif cmd == "creep" then
        if not args[2] then NotifyError("Usage: ?bot creep <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartCreep(target)

    elseif cmd == "mimic" then
        if not args[2] then NotifyError("Usage: ?bot mimic <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StartMimic(target)

    elseif cmd == "unmimic" then
        StopMimic()

    elseif cmd == "stack" then
        if not args[2] then NotifyError("Usage: ?bot stack <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        StackOnPlayer(target)

    elseif cmd == "dance" then
        StartDance()

    elseif cmd == "undance" then
        StopDance()

    elseif cmd == "trail" then
        StartTrail()

    elseif cmd == "untrail" then
        StopTrail()

    -- ════════════════════════════════════════════════════════════════
    -- 🎨 VISUAL / ENVIRONMENT COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "btools" then
        GiveBTools()

    elseif cmd == "fogoff" then
        pcall(function()
            Lighting.FogEnd = 9999999
            Lighting.FogStart = 9999999
        end)
        Notify("🌫️ Fog removed!", wt)

    elseif cmd == "fullbright" then
        pcall(function()
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 9999999
            Lighting.GlobalShadows = false
        end)
        Notify("☀️ FullBright ON!", wt)

    elseif cmd == "nightmode" then
        pcall(function()
            Lighting.ClockTime = 0
        end)
        Notify("🌙 Night mode!", wt)

    elseif cmd == "daymode" then
        pcall(function()
            Lighting.ClockTime = 14
        end)
        Notify("☀️ Day mode!", wt)

    elseif cmd == "char" then
        if not args[2] then NotifyError("Usage: ?bot char <userid>", wt) return end
        local userId = tonumber(args[2])
        if not userId then NotifyError("Invalid UserId", wt) return end
        pcall(function()
            local desc = Players:GetHumanoidDescriptionFromUserId(userId)
            if desc then
                local hum = GetBotHumanoid()
                if hum then
                    hum:ApplyDescription(desc)
                    Notify("🎭 Changed appearance to UserId " .. userId, wt)
                end
            end
        end)

    -- ════════════════════════════════════════════════════════════════
    -- 🛑 CONTROL COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "rejoin" then
        RejoinServer()

    elseif cmd == "serverhop" then
        ServerHop()

    -- ════════════════════════════════════════════════════════════════
    -- 🛡️ PERMISSION COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "perm" then
        if not args[2] then NotifyError("Usage: ?bot perm <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        local currentLevel = GetPermLevel(target)
        if currentLevel >= 1 then
            Notify("ℹ️ " .. target.Name .. " already has permissions (level " .. currentLevel .. ")", wt)
            return
        end
        PermittedUsers[target.Name:lower()] = 1
        Notify("✅ " .. target.Name .. " → User (level 1)", wt)

    elseif cmd == "unperm" then
        if not args[2] then NotifyError("Usage: ?bot unperm <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        if IsSuperOwner(target) then
            NotifyError("Cannot unperm the SuperOwner!", wt)
            return
        end
        if GetPermLevel(target) >= GetPermLevel(executorPlayer) then
            NotifyError("Cannot unperm someone of equal or higher rank!", wt)
            return
        end
        PermittedUsers[target.Name:lower()] = nil
        Notify("🚫 " .. target.Name .. " → permissions revoked", wt)

    elseif cmd == "admin" then
        if not args[2] then NotifyError("Usage: ?bot admin <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        PermittedUsers[target.Name:lower()] = 2
        Notify("⭐ " .. target.Name .. " → Admin (level 2)", wt)

    elseif cmd == "unadmin" then
        if not args[2] then NotifyError("Usage: ?bot unadmin <target>", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then NotifyError("Player not found: " .. args[2], wt) return end
        if IsSuperOwner(target) then
            NotifyError("Cannot demote the SuperOwner!", wt)
            return
        end
        PermittedUsers[target.Name:lower()] = 1
        Notify("⬇️ " .. target.Name .. " → User (level 1)", wt)

    -- ════════════════════════════════════════════════════════════════
    -- 🛑 CONTROL COMMANDS
    -- ════════════════════════════════════════════════════════════════

    elseif cmd == "stop" or cmd == "reset" then
        StopAllLoops()
        Notify("⏹️ All loops stopped", wt)

    elseif cmd == "antiafk" then
        ToggleAntiAFK(not IsAntiAFK)

    elseif cmd == "shutdown" then
        Notify("💀 Bot shutting down...", wt)
        task.wait(0.5)
        FullCleanup()
        genv.__ULTIMATE_BOT_LOADED = false

    elseif cmd == "cmds" or cmd == "help" or cmd == "commands" then
        Notify("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", wt)
        Notify("📋 ULTIMATE BOT v5.0 — COMMAND LIST", wt)
        Notify("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", wt)
        Notify("📍 MOVE: tp, bring, goto, follow, orbit, attach, annoy, tpcoords", wt)
        Notify("🌪️ FLING: fling, loopfling, loopkill, flingall, loopflingall", wt)
        Notify("⚡ STATS: speed, jump, hipheight, gravity", wt)
        Notify("✈️ MOVE: fly, unfly, noclip, clip", wt)
        Notify("🦸 CHAR: invisible, visible, respawn, god, ungod, char", wt)
        Notify("🌀 CHAR: spin, unspin, freeze, unfreeze, sit, jumpnow", wt)
        Notify("👁️ VIEW: stare, unstare, view, unview", wt)
        Notify("📡 ESP: esp, unesp, highlight, unhighlight", wt)
        Notify("🛡️ SAFE: antivoid, infjump, platform, antiafk", wt)
        Notify("🔪 MM2: grabknife, grabgun, mmrole, cointp, coinfarm, uncoinfarm", wt)
        Notify("🔪 MM2: lobby, map, xray, unxray, godknife, ungodknife", wt)
        Notify("🌾 FARM: farm, unfarm, coinfarm, uncoinfarm", wt)
        Notify("🤡 TROLL: seizure, launch, yeet, tornado, blackhole, unblackhole", wt)
        Notify("🤡 TROLL: scatter, cage, uncage, trap, spam, strobe, unstrobe", wt)
        Notify("🤡 TROLL: giant, tiny, normal, headless, unheadless", wt)
        Notify("🤡 TROLL: creep, mimic, unmimic, stack, flingall, loopflingall", wt)
        Notify("🎮 UTIL: dance, undance, trail, untrail, btools, copyname", wt)
        Notify("🎨 VISUAL: fogoff, fullbright, nightmode, daymode", wt)
        Notify("📊 INFO: ping, uptime, age, players, status", wt)
        Notify("👥 PERM: perm, unperm, admin, unadmin", wt)
        Notify("🛑 CTRL: stop, rejoin, serverhop, cmds, shutdown", wt)
        Notify("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", wt)
        Notify("🎯 TARGETS: <name>, me, all, others, random, nearest, farthest", wt)
        Notify("🎯 TARGETS: team, enemies, murd, sherif", wt)
        Notify("💬 Works in PUBLIC chat AND PRIVATE whispers!", wt)
        Notify("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", wt)

    else
        NotifyError("Unknown command: " .. cmd .. " — Type ?bot cmds", wt)
    end
end

-- ============================================================================
-- [[ 📡 NETWORK CHAT CONNECTORS ]]
-- Supports BOTH public chat AND private whispers!
-- ============================================================================
local ChatHooks = {}

local function HookPlayerChat(player)
    if ChatHooks[player] then return end
    ChatHooks[player] = true

    pcall(function()
        player.Chatted:Connect(function(msg)
            pcall(function()
                HandleBotCommand(msg, player, false)
            end)
        end)
    end)
end

-- Hook existing players
for _, p in ipairs(Players:GetPlayers()) do
    HookPlayerChat(p)
end

-- Hook new players + ESP support
Players.PlayerAdded:Connect(function(player)
    HookPlayerChat(player)

    -- If ESP is active, add ESP for new player
    if ActiveConnections.ESP then
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if ActiveConnections.ESP then
                CreateESPForPlayer(player)
            end
        end)
    end
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    CommandCooldowns[player.Name:lower()] = nil
    ChatHooks[player] = nil
    RemoveESPForPlayer(player)
end)

-- Modern TextChatService support (public + whisper channels!)
pcall(function()
    if TextChatService then
        TextChatService.MessageReceived:Connect(function(incomingMessage)
            pcall(function()
                local textSrc = incomingMessage.TextSource
                if textSrc then
                    local actualPlayer = Players:GetPlayerByUserId(textSrc.UserId)
                    if actualPlayer then
                        -- Check if this is a whisper channel
                        local isWhisper = false
                        pcall(function()
                            local channel = incomingMessage.TextChannel
                            if channel and channel.Name:find("RBXWhisper") then
                                isWhisper = true
                            end
                        end)
                        HandleBotCommand(incomingMessage.Text, actualPlayer, isWhisper)
                    end
                end
            end)
        end)
    end
end)

-- Legacy whisper support (DefaultChatSystemChatEvents)
pcall(function()
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local onMessage = chatEvents:FindFirstChild("OnMessageDoneFiltering")
        if onMessage then
            onMessage.OnClientEvent:Connect(function(msgData)
                pcall(function()
                    if msgData and msgData.FromSpeaker and msgData.Message then
                        -- Check if it's a whisper
                        local isWhisper = msgData.MessageType == "Whisper"
                            or (msgData.ExtraData and msgData.ExtraData.ChatColor == Color3.new(1, 1, 1))
                        local sender = Players:FindFirstChild(msgData.FromSpeaker)
                        if sender then
                            HandleBotCommand(msgData.Message, sender, isWhisper)
                        end
                    end
                end)
            end)
        end
    end
end)

-- ============================================================================
-- [[ 🔄 CHARACTER RESPAWN HANDLER ]]
-- Re-applies persistent effects on respawn
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)

    if IsNoClip then StartNoClip() end
    if IsGodMode then StartGodMode() end
    if IsFlying then
        task.wait(0.3)
        StartFly()
    end
    if IsSpinning then
        task.wait(0.3)
        StartSpin()
    end

    Log("INFO", "Character respawned — persistent effects re-applied.")
end)

-- ============================================================================
-- [[ 🤖 AUTO-JOIN SUPPORT FOR ROBOXPROPLYER ]]
-- When roboxproplyer joins, auto-perm them (redundant safety)
-- ============================================================================
Players.PlayerAdded:Connect(function(player)
    if player.Name:lower() == SuperOwner:lower() then
        PermittedUsers[player.Name:lower()] = 3
        Log("SYS", "👑 SuperOwner " .. player.Name .. " joined! Auto-permed L3.")
        SendNotification("👑 Welcome Boss", SuperOwner .. " has joined! Full control active.", 5)
    end
end)

-- If SuperOwner is already in server
for _, p in ipairs(Players:GetPlayers()) do
    if p.Name:lower() == SuperOwner:lower() then
        PermittedUsers[p.Name:lower()] = 3
    end
end

-- ============================================================================
-- [[ 🚀 STARTUP BANNER ]]
-- ============================================================================
print("")
print("╔══════════════════════════════════════════════════════════════════════╗")
print("║       🔥🔥🔥 ULTIMATE BOT ENGINE v5.0 — MEGA EDITION 🔥🔥🔥     ║")
print("╠══════════════════════════════════════════════════════════════════════╣")
print("║  👑 SuperOwner: " .. SuperOwner .. string.rep(" ", math.max(1, 51 - #SuperOwner)) .. "║")
print("║  📡 Prefix: \"" .. Prefix .. "\"" .. string.rep(" ", math.max(1, 52 - #Prefix)) .. "║")
print("║  🔧 Executor: " .. ExecutorInfo.ExecutorName .. string.rep(" ", math.max(1, 52 - #ExecutorInfo.ExecutorName)) .. "║")
print("║  👻 NoClip: ON    🔄 Anti-AFK: ON    🛡️ Anti-Void: OFF           ║")
print("╠══════════════════════════════════════════════════════════════════════╣")
print("║  80+ Commands • 3-Tier Perms • ESP • Flight • Fling V3            ║")
print("║  MM2 GrabKnife/GrabGun • CoinFarm • GodKnife • XRay              ║")
print("║  Troll: Seizure/Launch/Yeet/Tornado/Blackhole/Cage/Trap           ║")
print("║  Giant/Tiny/Headless/Creep/Mimic/Strobe/Trail/Dance               ║")
print("║  Auto-Farm • Private Chat/Whisper Support • Rejoin/ServerHop      ║")
print("║  BTools • FullBright • Night/Day • FogOff • Character Change      ║")
print("║  Re-execution Safe • Full pcall Safety • Executor Aware           ║")
print("╠══════════════════════════════════════════════════════════════════════╣")
print("║  📋 Chat \"?bot cmds\" for full command list                        ║")
print("║  💬 Works in PUBLIC chat AND PRIVATE whispers!                     ║")
print("╚══════════════════════════════════════════════════════════════════════╝")
print("")

-- Display in-game notification
SendNotification("🔥 Bot v5.0 MEGA Loaded", "80+ cmds! Type ?bot cmds\nSuperOwner: " .. SuperOwner .. "\n💬 Whispers supported!", 10)

-- Auto-enable Anti-AFK
ToggleAntiAFK(true)

-- Log startup
Log("SYS", "🔥 ULTIMATE BOT ENGINE v5.0 — FULLY LOADED")
Log("SYS", "👑 SuperOwner: " .. SuperOwner)
Log("SYS", "🔧 Executor: " .. ExecutorInfo.ExecutorName)
Log("SYS", "📋 80+ commands ready | Private chat: YES | MM2: YES")