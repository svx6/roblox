-- ULTIMATE BOT ENGINE v7.0 — Full rewrite, all bugs fixed, zero decorative headers
-- SuperOwner: roboxproplyer (Level 4, untouchable)
-- Dual prefix: ?bot and .bot — MM2 dead chat fixed — multi-layer god mode
-- Thread-safe fling — instant yeet — private help — fixed permissions

local genv = (typeof(getgenv) == "function" and getgenv()) or _G
if genv.__ULTIMATE_BOT_LOADED then
    pcall(function()
        if genv.__ULTIMATE_BOT_CLEANUP then genv.__ULTIMATE_BOT_CLEANUP() end
    end)
end
genv.__ULTIMATE_BOT_LOADED = true

-- Polyfill task scheduler for executors that lack it
if not task then task = {} end
if not task.spawn then
    task.spawn = function(fn, ...)
        local args = {...}
        coroutine.wrap(function() fn(unpack(args)) end)()
    end
end
if not task.wait then
    task.wait = function(t)
        local s = tick()
        repeat game:GetService("RunService").Heartbeat:Wait() until tick() - s >= (t or 0.03)
        return tick() - s
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
        local result = {}
        for part in str:gmatch("([^" .. sep .. "]+)") do
            table.insert(result, part)
        end
        return result
    end
end

-- Core configuration — all tunable constants in one place
local SuperOwner      = "roboxproplyer"
local Prefixes        = {"?bot ", ".bot "}    -- dual prefix support
local FlingPower      = 9999999
local LoopFlingDelay  = 1.5
local FollowDistance  = 5
local OrbitRadius     = 12
local OrbitSpeed      = 3
local CooldownTime    = 0.3
local FlySpeed        = 80
local SpinSpeed       = 20
local AnnoyDelay      = 0.15
local BringIterations = 200                   -- increased for reliability with items
local BringDelay      = 0                     -- zero delay for instant bring
local ChatRateLimit   = 1.0
local BotStartTime    = tick()

-- Private/public mode — private blocks unpermed users, permed users always work
local BotMode = "private"

-- Permissions database: 1=User 2=Admin 3=Owner 4=SuperOwner
local PermittedUsers = {
    [SuperOwner:lower()] = 4
}

-- Minimum permission level per command
local CommandPermissions = {
    tp = 1, bring = 1, goto = 1, follow = 1, orbit = 1, attach = 1,
    fling = 1, loopfling = 1, loopkill = 1, annoy = 1, speed = 1,
    jump = 1, hipheight = 1, gravity = 1, fly = 1, unfly = 1,
    noclip = 1, clip = 1, invisible = 1, invis = 1, visible = 1,
    vis = 1, respawn = 1, refresh = 1, freeze = 1, unfreeze = 1,
    god = 1, ungod = 1, spin = 1, unspin = 1, stare = 1, unstare = 1,
    esp = 1, unesp = 1, highlight = 1, unhighlight = 1, view = 1,
    unview = 1, spectate = 1, unspectate = 1, antivoid = 1, infjump = 1,
    platform = 1, sit = 1, jumpnow = 1, players = 1, stop = 1,
    reset = 1, cmds = 1, help = 1, commands = 1, antiafk = 1,
    ping = 1, uptime = 1, age = 1, status = 1,
    grabknife = 1, grabgun = 1, mmrole = 1, cointp = 1, coinfarm = 1,
    uncoinfarm = 1, lobby = 1, map = 1, xray = 1, unxray = 1,
    godknife = 1, ungodknife = 1, roles = 1,
    farm = 1, unfarm = 1,
    seizure = 1, launch = 1, yeet = 1, tornado = 1, blackhole = 1,
    unblackhole = 1, scatter = 1, cage = 1, uncage = 1, trap = 1,
    spam = 1, strobe = 1, unstrobe = 1, giant = 1, tiny = 1,
    normal = 1, headless = 1, unheadless = 1, creep = 1, mimic = 1,
    unmimic = 1, stack = 1, flingall = 1, loopflingall = 1,
    copyname = 1, btools = 1, fogoff = 1, fullbright = 1,
    nightmode = 1, daymode = 1, tpcoords = 1, dance = 1, undance = 1,
    trail = 1, untrail = 1, rejoin = 1, serverhop = 1, char = 1,
    -- New commands (level 1)
    perms = 1, tp2me = 1, safetp = 1, back = 1, clone = 1,
    unclone = 1, countdown = 1, aura = 1, unaura = 1, nuke = 1,
    emote = 1, track = 1, untrack = 1,
    -- Level 2: Admin
    perm = 2, unperm = 2,
    -- Level 3: Owner
    owner = 3, unowner = 3, admin = 3, unadmin = 3,
    -- Level 4: SuperOwner only
    shutdown = 4, public = 4, private = 4,
}

-- Services — cached references, pcall-wrapped for non-universal services
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

-- Executor capability flags — detected once at load for branching logic
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

-- Engine state — all mutable runtime flags and object pools
local ActiveConnections  = {}
local AllConnectionNames = {
    "LoopFling", "LoopKill", "LoopFlingAll", "Follow", "Orbit", "Attach",
    "Annoy", "NoClip", "Fly", "God", "GodHealth", "AntiAFK", "AntiVoid",
    "InfJump", "Spin", "Stare", "ESP", "CoinFarm", "Farm", "BlackHole",
    "Strobe", "Creep", "Mimic", "Trail", "GodKnife", "Tornado", "Seizure",
    "Dance", "FloorFly", "Aura", "Track",
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
local IsFloorFlying     = false
local IsAuraActive      = false
local IsTracking        = false
local IsFlingBusy       = false   -- mutex lock to prevent concurrent flings hitting bystanders
local FloorFlyTarget    = nil
local FloorFlyPlatform  = nil
local TrackTarget       = nil
local TrackLastPos      = nil
local SavedCFrame       = nil     -- for safetp/back
local ESPObjects        = {}
local CommandCooldowns  = {}
local CommandLog        = {}
local PlatformPart      = nil
local CageParts         = {}
local TrailParts         = {}
local XRayParts         = {}
local AuraParts         = {}
local OriginalGravity   = Workspace.Gravity
local OriginalLighting  = {}
local LastChatTime      = 0

pcall(function()
    OriginalLighting.Ambient = Lighting.Ambient
    OriginalLighting.Brightness = Lighting.Brightness
    OriginalLighting.FogEnd = Lighting.FogEnd
    OriginalLighting.FogStart = Lighting.FogStart
    OriginalLighting.ClockTime = Lighting.ClockTime
    OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
end)

-- Logging — minimal structured output for debugging
local function Log(level, message)
    print(string.format("[%s] %s: %s", os.date("%H:%M:%S"), level, message))
end

local function LogCommand(executorName, command, targetName)
    local entry = {
        time     = os.date("%H:%M:%S"),
        executor = executorName,
        command  = command,
        target   = targetName or "N/A",
    }
    table.insert(CommandLog, entry)
    if #CommandLog > 500 then table.remove(CommandLog, 1) end
    Log("CMD", string.format("%s > %s %s", executorName, command, targetName or ""))
end

-- Homoglyph bypass engine — deterministic Unicode substitution with zero-width fragmentation
-- Maps common Latin characters to visually identical Cyrillic/Unicode confusables
-- Combined with invisible divider insertion every 2-3 characters for filter evasion
local HomoglyphMap = {
    a = {"\xD0\xB0"},             -- Cyrillic а (U+0430)
    e = {"\xD0\xB5"},             -- Cyrillic е (U+0435)
    o = {"\xD0\xBE"},             -- Cyrillic о (U+043E)
    c = {"\xD1\x81"},             -- Cyrillic с (U+0441)
    p = {"\xD1\x80"},             -- Cyrillic р (U+0440)
    s = {"\xD1\x95"},             -- Cyrillic ѕ (U+0455)
    i = {"\xD1\x96"},             -- Cyrillic і (U+0456)
    x = {"\xD1\x85"},             -- Cyrillic х (U+0445)
    y = {"\xD1\x83"},             -- Cyrillic у (U+0443)
}
local ZeroWidthSpace = "\xE2\x80\x8B"    -- U+200B
local ZeroWidthNJ    = "\xE2\x80\x8C"    -- U+200C

local function BypassText(text)
    if not text or #text == 0 then return text end
    local result = ""
    local insertCounter = 0
    for i = 1, #text do
        local ch = text:sub(i, i)
        local lower = ch:lower()
        -- Substitute ~40% of matchable characters with homoglyphs for natural appearance
        if HomoglyphMap[lower] and math.random(1, 5) <= 2 then
            local glyphs = HomoglyphMap[lower]
            result = result .. glyphs[math.random(1, #glyphs)]
        else
            result = result .. ch
        end
        insertCounter = insertCounter + 1
        -- Insert zero-width space every 2-3 characters to fragment filter tokens
        if insertCounter >= math.random(2, 3) and i < #text and ch ~= " " then
            result = result .. ZeroWidthSpace
            insertCounter = 0
        end
    end
    return result
end

-- Chat output — rate-limited message dispatch supporting both TextChatService and legacy
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

-- Whisper — tries existing RBXWhisper channel, falls back to /w command through general
local function SendWhisperMessage(targetPlayer, text)
    if not targetPlayer then return end
    pcall(function()
        if TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                -- Search for existing whisper channel with this player
                for _, channel in ipairs(channels:GetChildren()) do
                    if channel.Name:find("RBXWhisper") and channel.Name:find(tostring(targetPlayer.UserId)) then
                        channel:SendAsync(text)
                        return
                    end
                end
                -- Fallback: initiate whisper via /w command through general channel
                local rbxGeneral = channels:FindFirstChild("RBXGeneral")
                if rbxGeneral then
                    rbxGeneral:SendAsync("/w " .. targetPlayer.Name .. " " .. text)
                    return
                end
            end
        end
        -- Legacy fallback
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayMsg = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMsg then
                sayMsg:FireServer("/w " .. targetPlayer.Name .. " " .. text, "All")
            end
        end
    end)
end

-- Response system — notification + optional whisper or chat
-- whisperTarget: if set, message goes via whisper (never public chat)
-- forceChat: if true AND no whisperTarget, message goes to public chat
local function Respond(message, whisperTarget, forceChat)
    Log("OK", message)
    SendNotification("Bot", message, 3)
    if whisperTarget then
        pcall(function() SendWhisperMessage(whisperTarget, BypassText(message)) end)
    elseif forceChat then
        pcall(function() SendChatMessage(BypassText(message)) end)
    end
end

-- Private response — always whispers, never leaks to public chat
-- Used exclusively for help/cmds to honor user privacy
local function RespondPrivate(message, targetPlayer)
    Log("OK", message)
    SendNotification("Bot", message, 5)
    if targetPlayer then
        pcall(function() SendWhisperMessage(targetPlayer, BypassText(message)) end)
    end
end

local function RespondError(message, whisperTarget)
    Log("ERROR", message)
    SendNotification("Bot Error", message, 4)
    if whisperTarget then
        pcall(function() SendWhisperMessage(whisperTarget, BypassText(message)) end)
    end
end

-- Permission system — fixed: permed users work even in private mode
-- Private mode blocks UNPERMED users, not permed ones
local function GetPermLevel(player)
    if not player then return 0 end
    if player.Name:lower() == SuperOwner:lower() then return 4 end
    local stored = PermittedUsers[player.Name:lower()] or 0
    -- Public mode grants level 1 to everyone, enabling basic command access
    if BotMode == "public" and stored < 1 then return 1 end
    return stored
end

local function HasPermission(player, command)
    local playerLevel = GetPermLevel(player)
    local requiredLevel = CommandPermissions[command] or 1
    return playerLevel >= requiredLevel
end

local function IsSuperOwner(player)
    return player and player.Name:lower() == SuperOwner:lower()
end

-- Fixed CanUseBot: permed users (level >= 1) ALWAYS have access regardless of mode
-- Only unpermed users are blocked in private mode
local function CanUseBot(player)
    if IsSuperOwner(player) then return true end
    if GetPermLevel(player) >= 1 then return true end
    return false
end

-- Cooldown — SuperOwner exempt, prevents command spam from other users
local function IsOnCooldown(player)
    if IsSuperOwner(player) then return false end
    local key = player.Name:lower()
    local lastUse = CommandCooldowns[key]
    if lastUse and (tick() - lastUse) < CooldownTime then return true end
    CommandCooldowns[key] = tick()
    return false
end

-- Safe character access — nil-safe wrappers used throughout all command handlers
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

-- Smart target finder v4 — supports: me, all, others, random, nearest, farthest,
-- murd, sherif, team, enemies, partial name, display name, userid
-- Improved string matching using string.find for partial/fuzzy resolution
local function GetMultipleTargets(stringInput, executorPlayer)
    if not stringInput or stringInput == "" then return {} end
    stringInput = stringInput:lower():match("^%s*(.-)%s*$") -- trim whitespace

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
        -- Try UserId match
        local numInput = tonumber(stringInput)
        if numInput then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == numInput then single = p; break end
            end
        end

        -- Improved fuzzy matching: exact > prefix > substring (both Name and DisplayName)
        if not single then
            local bestMatch = nil
            local bestScore = 0 -- 3=exact, 2=prefix, 1=substring

            for _, p in ipairs(Players:GetPlayers()) do
                local nameLow = p.Name:lower()
                local displayLow = p.DisplayName:lower()

                -- Exact match is highest priority
                if nameLow == stringInput or displayLow == stringInput then
                    single = p
                    bestMatch = nil
                    break
                end

                -- Prefix match (second priority)
                if nameLow:sub(1, #stringInput) == stringInput or displayLow:sub(1, #stringInput) == stringInput then
                    if bestScore < 2 or #p.Name < (bestMatch and #bestMatch.Name or math.huge) then
                        bestMatch = p
                        bestScore = 2
                    end
                end

                -- Substring match via string.find (third priority, catches partial names anywhere)
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

    if single then return {single} end
    return {}
end

local function GetSmartTarget(stringInput, executorPlayer)
    local targets = GetMultipleTargets(stringInput, executorPlayer)
    return targets[1]
end

-- Connection manager — safe disconnect with nil-guarding
local function DisconnectSafe(name)
    if ActiveConnections[name] then
        pcall(function() ActiveConnections[name]:Disconnect() end)
        ActiveConnections[name] = nil
    end
end

local function StopAllLoops()
    for name, _ in pairs(ActiveConnections) do
        if name ~= "NoClip" and name ~= "AntiAFK" and name ~= "AntiVoid" then
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
    Log("SYS", "All active loops stopped.")
end

local function FullCleanup()
    for name, _ in pairs(ActiveConnections) do DisconnectSafe(name) end
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
    Log("SYS", "Full cleanup completed.")
end
genv.__ULTIMATE_BOT_CLEANUP = FullCleanup

-- NoClip engine — disables CanCollide on all character BaseParts every Stepped frame
local function StartNoClip()
    DisconnectSafe("NoClip")
    IsNoClip = true
    ActiveConnections.NoClip = RunService.Stepped:Connect(function()
        pcall(function()
            if IsFloorFlying then return end -- floor fly needs collision, skip noclip
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

-- Thread-safe fling engine v4 — mutex-locked to prevent accidental multi-target collateral
-- Only one fling operation can run at a time; subsequent requests queue and wait
local function ExecutePhysicalFling(targetPlayer)
    -- Spin-wait for mutex — if another fling is active, wait up to 15 seconds
    local waitStart = tick()
    while IsFlingBusy do
        task.wait(0.1)
        if tick() - waitStart > 15 then return end -- timeout safety
    end
    IsFlingBusy = true

    local success, err = pcall(function()
        if not targetPlayer or not targetPlayer.Parent then IsFlingBusy = false return end
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

        -- Tight loop until target dies, leaves, or safety cap reached
        -- Reduced from 300 to 150 for faster completion
        for i = 1, 150 do
            if not targetPlayer or not targetPlayer.Parent then break end
            if not IsAlive(targetPlayer) then break end
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
    end)

    IsFlingBusy = false
    if not success then Log("ERROR", "Fling failed: " .. tostring(err)) end
end

-- Directional fling — used by launch/yeet with custom velocity vectors
-- Reduced maxAttempts for near-instantaneous energy transfer
local function ExecuteDirectionalFling(targetPlayer, direction, power, maxAttempts)
    local waitStart = tick()
    while IsFlingBusy do
        task.wait(0.1)
        if tick() - waitStart > 15 then return end
    end
    IsFlingBusy = true

    pcall(function()
        if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then IsFlingBusy = false return end
        local targetHRP = GetHRP(targetPlayer)
        local botHRP = GetBotHRP()
        local botHum = GetBotHumanoid()
        if not targetHRP or not botHRP or not botHum then IsFlingBusy = false return end

        local savedPos = botHRP.CFrame
        botHum:ChangeState(Enum.HumanoidStateType.Physics)

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = direction * (power or FlingPower)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 9999
        bv.Parent = botHRP

        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.P = 9999
        bav.Parent = botHRP

        local attempts = maxAttempts or 40
        for i = 1, attempts do
            if not targetPlayer or not targetPlayer.Parent then break end
            if not IsAlive(targetPlayer) then break end
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
    end)

    IsFlingBusy = false
end

-- Floor fly v2 — bot lays flat under target as a structural platform
-- Noclip is suspended during flight so collision works properly
-- An invisible welded platform part provides a wider landing surface
-- The bot's HRP is rotated 90 degrees on X-axis so the torso faces upward
local function StartFloorFly(target)
    DisconnectSafe("FloorFly")
    DisconnectSafe("Fly")
    DisconnectSafe("Follow")
    DisconnectSafe("Orbit")
    DisconnectSafe("Attach")
    DisconnectSafe("Annoy")
    DisconnectSafe("Creep")
    DisconnectSafe("Mimic")

    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end

    IsFloorFlying = true
    FloorFlyTarget = target

    -- Create a wide invisible platform welded to bot for stable footing
    if FloorFlyPlatform then pcall(function() FloorFlyPlatform:Destroy() end) end
    FloorFlyPlatform = Instance.new("Part")
    FloorFlyPlatform.Size = Vector3.new(10, 1.5, 10)
    FloorFlyPlatform.Transparency = 1
    FloorFlyPlatform.CanCollide = true
    FloorFlyPlatform.Anchored = true
    FloorFlyPlatform.Massless = true
    FloorFlyPlatform.Name = "FloorFlyPlatform"
    FloorFlyPlatform.Parent = Workspace

    ActiveConnections.FloorFly = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsFloorFlying then
                DisconnectSafe("FloorFly")
                return
            end

            local targetPlayer = FloorFlyTarget
            if not targetPlayer or not targetPlayer.Parent or not IsAlive(targetPlayer) then
                DisconnectSafe("FloorFly")
                IsFloorFlying = false
                FloorFlyTarget = nil
                if FloorFlyPlatform then pcall(function() FloorFlyPlatform:Destroy() end) FloorFlyPlatform = nil end
                if IsNoClip then StartNoClip() end
                return
            end

            local targetHRP = GetHRP(targetPlayer)
            local botHRP = GetBotHRP()
            local botHum = GetBotHumanoid()
            if not targetHRP or not botHRP or not botHum then return end

            -- Suppress walk/idle animations so the bot stays flat
            botHum:ChangeState(Enum.HumanoidStateType.Physics)

            -- Position 2 studs below target feet, rotated 90° on X to lay flat (torso faces up)
            local targetPos = targetHRP.Position
            local underPos = Vector3.new(targetPos.X, targetPos.Y - 2, targetPos.Z)
            botHRP.CFrame = CFrame.new(underPos) * CFrame.Angles(math.rad(90), 0, 0)

            -- Position the invisible platform exactly at the bot's level for extra collision
            if FloorFlyPlatform and FloorFlyPlatform.Parent then
                FloorFlyPlatform.CFrame = CFrame.new(underPos.X, underPos.Y + 0.5, underPos.Z)
            end

            -- Enable collision on all bot parts so player can stand on them
            local botChar = LocalPlayer.Character
            if botChar then
                for _, part in ipairs(botChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end

            -- Zero velocity to prevent drift
            botHRP.AssemblyLinearVelocity = Vector3.zero
            botHRP.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end

local function StopFloorFly()
    IsFloorFlying = false
    FloorFlyTarget = nil
    DisconnectSafe("FloorFly")
    if FloorFlyPlatform then pcall(function() FloorFlyPlatform:Destroy() end) FloorFlyPlatform = nil end
    -- Restore noclip and upright orientation
    if IsNoClip then StartNoClip() end
    pcall(function()
        local hrp = GetBotHRP()
        local hum = GetBotHumanoid()
        if hrp then
            hrp.CFrame = CFrame.new(hrp.Position) -- reset rotation to upright
        end
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- Multi-layer god mode — 4 defense layers working simultaneously:
-- L1: MaxHealth set to math.huge makes the health bar effectively infinite
-- L2: HealthChanged signal immediately restores any damage within the same frame
-- L3: ForceField (invisible) provides server-recognized damage immunity
-- L4: Heartbeat enforcement loop continuously validates all layers are intact
local GodHealthConnection = nil

local function StartGodMode()
    DisconnectSafe("God")
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end) GodHealthConnection = nil end
    IsGodMode = true

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Layer 1: infinite health pool
    hum.MaxHealth = math.huge
    hum.Health = math.huge

    -- Layer 2: instant damage negation via HealthChanged signal
    GodHealthConnection = hum.HealthChanged:Connect(function(newHealth)
        if IsGodMode and hum then
            hum.Health = hum.MaxHealth
        end
    end)

    -- Layer 3: invisible ForceField for engine-level damage blocking
    local ff = char:FindFirstChildOfClass("ForceField")
    if not ff then
        ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end

    -- Layer 4: continuous enforcement — re-applies all layers if anything gets stripped
    ActiveConnections.God = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsGodMode then DisconnectSafe("God") return end
            local h = GetBotHumanoid()
            if h then
                if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end
                if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
            end
            local c = LocalPlayer.Character
            if c and not c:FindFirstChildOfClass("ForceField") then
                local f = Instance.new("ForceField")
                f.Visible = false
                f.Parent = c
            end
        end)
    end)
end

local function StopGodMode()
    DisconnectSafe("God")
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end) GodHealthConnection = nil end
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
            end
        end
    end)
end

-- Invisibility — toggles transparency on all visual parts, decals, particles, and accessories
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

-- Freeze/Unfreeze — anchors the bot's HRP to lock position
local function FreezePlayer(target)
    if not target then return end
    if target == LocalPlayer then
        local hrp = GetBotHRP()
        if hrp then pcall(function() hrp.Anchored = true end) end
    end
end

local function UnfreezePlayer(target)
    if not target then return end
    if target == LocalPlayer then
        local hrp = GetBotHRP()
        if hrp then pcall(function() hrp.Anchored = false end) end
    end
end

-- Anti-AFK — VirtualUser button simulation on idle, fallback to micro-movement
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
        else
            ActiveConnections.AntiAFK = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    local hrp = GetBotHRP()
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 0) end
                end)
            end)
        end
    else
        DisconnectSafe("AntiAFK")
        IsAntiAFK = false
    end
end

-- Anti-void — saves last safe position and teleports back if falling below Y=-50
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
                end
            end)
        end)
    else
        DisconnectSafe("AntiVoid")
        IsAntiVoid = false
    end
end

-- Infinite jump — re-triggers jump state on every JumpRequest
local function ToggleInfJump(state)
    if state then
        DisconnectSafe("InfJump")
        IsInfJump = true
        ActiveConnections.InfJump = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                local hum = GetBotHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end)
    else
        DisconnectSafe("InfJump")
        IsInfJump = false
    end
end

-- Spin — BodyAngularVelocity on Y axis
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
end

local function StopSpin()
    DisconnectSafe("Spin")
    IsSpinning = false
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyAngularVelocity") then obj:Destroy() end
            end
        end
    end)
end

-- Stare — continuously rotates bot to face target
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
end

-- ESP/Highlight — per-player highlight + distance billboard
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
end

local function StopESP()
    DisconnectSafe("ESP")
    for player, _ in pairs(ESPObjects) do RemoveESPForPlayer(player) end
    ESPObjects = {}
end

-- Platform — creates a solid neon part under the bot's feet
local function CreatePlatform()
    if PlatformPart then pcall(function() PlatformPart:Destroy() end) end
    local hrp = GetBotHRP()
    if not hrp then return end
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
end

-- View/Spectate camera system
local OriginalCameraSubject = nil

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

-- Improved bring — works reliably with or without equipped items
-- Uses physics collision pushing: bot rapidly teleports to target then back to origin
-- Smart loop: continues until target is within 5 studs of destination or max iterations
-- Temporarily boosts bot health to survive kill bricks during the bring sequence
local function BringPlayer(target, customDest)
    if not target then return end
    task.spawn(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local botHum = GetBotHumanoid()
            if not botHRP or not botHum then return end

            local savedPos = customDest or botHRP.CFrame

            -- Temporary health boost if not in god mode to survive the rapid teleporting
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

                -- Check if target arrived close enough to destination
                local dist = (tHRP.Position - savedPos.Position).Magnitude
                if dist < 5 then break end

                -- Teleport to target position to push them via physics collision
                bHRP.CFrame = tHRP.CFrame
                RunService.Heartbeat:Wait()
                -- Teleport back to origin immediately
                bHRP = GetBotHRP()
                if bHRP then bHRP.CFrame = savedPos end
            end

            -- Clean up: restore state
            local resetHum = GetBotHumanoid()
            if resetHum then
                resetHum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            if not wasGod then
                pcall(function()
                    local h = GetBotHumanoid()
                    if h then h.MaxHealth = 100; h.Health = 100 end
                end)
            end
        end)
    end)
end

-- Annoy — rapid random teleports around target
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
            end
        end)
    end)
end

-- MM2 systems — coin finding, weapon grabbing, role detection, xray, godknife
local function FindMM2Coins()
    local coins = {}
    pcall(function()
        local function searchForCoins(parent)
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    if name:find("coin") or name:find("collectable") or name:find("collectible") then
                        table.insert(coins, obj)
                    end
                    if obj:FindFirstChild("TouchInterest") then
                        table.insert(coins, obj)
                    end
                end
                if obj:IsA("Model") or obj:IsA("Folder") then
                    searchForCoins(obj)
                end
            end
        end
        local coinContainer = Workspace:FindFirstChild("CoinContainer")
            or Workspace:FindFirstChild("Coins")
            or Workspace:FindFirstChild("CoinFolder")
            or Workspace:FindFirstChild("CollectableCoins")
        if coinContainer then
            searchForCoins(coinContainer)
        else
            searchForCoins(Workspace)
        end
    end)
    return coins
end

local function GrabWeapon(weaponName)
    pcall(function()
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
        local weapon = findWeapon(Workspace)
        if weapon then
            local handle = weapon:FindFirstChild("Handle")
            if handle then
                local botHRP = GetBotHRP()
                if botHRP then
                    botHRP.CFrame = handle.CFrame
                    task.wait(0.2)
                    if weapon.Parent == Workspace then
                        pcall(function() weapon.Parent = LocalPlayer.Backpack end)
                    end
                end
            end
            return
        end
        local backpackWeapon = LocalPlayer.Backpack:FindFirstChild(weaponName)
            or LocalPlayer.Backpack:FindFirstChild("Knife")
            or LocalPlayer.Backpack:FindFirstChild("Gun")
        if backpackWeapon then
            pcall(function()
                local hum = GetBotHumanoid()
                if hum then hum:EquipTool(backpackWeapon) end
            end)
        end
    end)
end

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
end

local function StopXRay()
    for _, data in ipairs(XRayParts) do
        pcall(function() data.part.Transparency = data.original end)
    end
    XRayParts = {}
end

-- Coin farm — continuous teleport-collect loop
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
                        if ExecutorInfo.HasFireTouchInterest then
                            local ti = coin:FindFirstChild("TouchInterest")
                            if ti then
                                firetouchinterest(botHRP, coin, 0)
                                task.wait(0.05)
                                firetouchinterest(botHRP, coin, 1)
                            end
                        end
                        task.wait(0.1)
                    end
                end
            end)
            task.wait(1)
        end
    end)
    ActiveConnections.CoinFarm = RunService.Heartbeat:Connect(function()
        if not IsCoinFarming then DisconnectSafe("CoinFarm") end
    end)
end

local function StopCoinFarm()
    IsCoinFarming = false
    DisconnectSafe("CoinFarm")
end

-- Generic farm — collects all TouchInterest parts in workspace
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
            task.wait(2)
        end
    end)
    ActiveConnections.Farm = RunService.Heartbeat:Connect(function()
        if not IsFarming then DisconnectSafe("Farm") end
    end)
end

local function StopFarm()
    IsFarming = false
    DisconnectSafe("Farm")
end

-- Troll commands — seizure, launch, yeet, tornado, blackhole, scatter, cage, trap, spam, strobe,
-- scale, headless, creep, mimic, stack, flingall, loopflingall, godknife, dance, trail

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
            end
        end)
    end)
end

-- Launch — flings target straight upward with massive force
local function LaunchPlayer(target)
    task.spawn(function()
        ExecuteDirectionalFling(target, Vector3.new(0, 1, 0), FlingPower * 2, 40)
    end)
end

-- Yeet v2 — fixed: positions bot BELOW target and applies upward diagonal force
-- Reduced to 35 max attempts for near-instantaneous yeeting with zero delay
local function YeetPlayer(target)
    task.spawn(function()
        local waitStart = tick()
        while IsFlingBusy do
            task.wait(0.1)
            if tick() - waitStart > 15 then return end
        end
        IsFlingBusy = true

        pcall(function()
            if not target or not target.Parent or not IsAlive(target) then IsFlingBusy = false return end
            local targetHRP = GetHRP(target)
            local botHRP = GetBotHRP()
            local botHum = GetBotHumanoid()
            if not targetHRP or not botHRP or not botHum then IsFlingBusy = false return end

            local savedPos = botHRP.CFrame
            botHum:ChangeState(Enum.HumanoidStateType.Physics)

            -- Upward + forward diagonal vector for maximum yeet distance
            local lookDir = targetHRP.CFrame.LookVector
            local yeetDir = (Vector3.new(lookDir.X, 2, lookDir.Z)).Unit

            local bv = Instance.new("BodyVelocity")
            bv.Velocity = yeetDir * FlingPower * 2
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.P = 9999
            bv.Parent = botHRP

            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bav.P = 9999
            bav.Parent = botHRP

            -- Position bot below target for upward launch physics
            for i = 1, 35 do
                if not target or not target.Parent then break end
                if not IsAlive(target) then break end
                local tHRP = GetHRP(target)
                if not tHRP then break end
                local cBotHRP = GetBotHRP()
                if not cBotHRP then break end
                -- Place bot directly under target's bounding box for upward energy transfer
                cBotHRP.CFrame = CFrame.new(tHRP.Position.X, tHRP.Position.Y - 3, tHRP.Position.Z)
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
    end)
end

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
                local y = math.sin(angle * 2) * 3
                botHRP.CFrame = CFrame.new(targetHRP.Position + Vector3.new(x, y + 2, z), targetHRP.Position)
                local now = tick()
                if (now - lastFlingTime) > 1.5 then
                    lastFlingTime = now
                    if botHum then botHum:ChangeState(Enum.HumanoidStateType.Physics) end
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
            end
        end)
    end)
end

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
end

local function StopBlackHole()
    DisconnectSafe("BlackHole")
    IsBlackHole = false
end

local function ScatterAll()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsAlive(p) then
                local dir = Vector3.new(math.random(-1, 1), math.random(0, 1), math.random(-1, 1))
                if dir.Magnitude > 0 then dir = dir.Unit end
                task.spawn(function()
                    ExecuteDirectionalFling(p, dir, FlingPower, 40)
                end)
                task.wait(0.3)
            end
        end
    end)
end

local function CagePlayer(target)
    if not target then return end
    local targetHRP = GetHRP(target)
    if not targetHRP then return end
    for _, part in ipairs(CageParts) do pcall(function() part:Destroy() end) end
    CageParts = {}
    local pos = targetHRP.Position
    local cageSize = 6
    local walls = {
        { size = Vector3.new(cageSize, cageSize, 1), pos = pos + Vector3.new(0, cageSize/2, cageSize/2) },
        { size = Vector3.new(cageSize, cageSize, 1), pos = pos + Vector3.new(0, cageSize/2, -cageSize/2) },
        { size = Vector3.new(1, cageSize, cageSize), pos = pos + Vector3.new(cageSize/2, cageSize/2, 0) },
        { size = Vector3.new(1, cageSize, cageSize), pos = pos + Vector3.new(-cageSize/2, cageSize/2, 0) },
        { size = Vector3.new(cageSize, 1, cageSize), pos = pos + Vector3.new(0, cageSize, 0) },
        { size = Vector3.new(cageSize, 1, cageSize), pos = pos + Vector3.new(0, 0, 0) },
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
end

local function RemoveCage()
    for _, part in ipairs(CageParts) do pcall(function() part:Destroy() end) end
    CageParts = {}
end

local function TrapPlayer(target)
    task.spawn(function()
        for i = 1, 5 do
            if not target or not target.Parent then break end
            ExecuteDirectionalFling(target, Vector3.new(0, -1, 0), FlingPower, 40)
            task.wait(0.3)
        end
    end)
end

local function SpamChat(message, count)
    count = math.min(count or 10, 20)
    task.spawn(function()
        for i = 1, count do
            pcall(function() SendChatMessage(BypassText(message)) end)
            task.wait(ChatRateLimit + 0.1)
        end
    end)
end

local function StartStrobe()
    DisconnectSafe("Strobe")
    IsStrobing = true
    local strobeState = false
    ActiveConnections.Strobe = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsStrobing then DisconnectSafe("Strobe") return end
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
end

local function StopStrobe()
    IsStrobing = false
    DisconnectSafe("Strobe")
    pcall(function()
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
end

local function ScaleCharacter(scale)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local desc = hum:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            desc.HeightScale = scale
            desc.WidthScale = scale
            desc.DepthScale = scale
            desc.HeadScale = scale
            hum:ApplyDescription(desc)
            return
        end
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

local function SetHeadless(state)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = state and 1 or 0
            local face = head:FindFirstChildOfClass("Decal")
            if face then face.Transparency = state and 1 or 0 end
            for _, acc in ipairs(char:GetChildren()) do
                if acc:IsA("Accessory") then
                    local handle = acc:FindFirstChild("Handle")
                    if handle then handle.Transparency = state and 1 or 0 end
                end
            end
        end
    end)
end

local function StartCreep(target)
    DisconnectSafe("Creep")
    DisconnectSafe("Follow")
    DisconnectSafe("Stare")
    IsCreeping = true
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
                botHRP.CFrame = CFrame.new(botHRP.Position, targetHRP.Position)
                botHum:MoveTo(targetHRP.Position)
            else
                DisconnectSafe("Creep")
                IsCreeping = false
            end
        end)
    end)
end

local function StartMimic(target)
    DisconnectSafe("Mimic")
    DisconnectSafe("Follow")
    DisconnectSafe("Orbit")
    IsMimicking = true
    local offset = CFrame.new(3, 0, 0)
    ActiveConnections.Mimic = RunService.Heartbeat:Connect(function()
        pcall(function()
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                botHRP.CFrame = targetHRP.CFrame * offset
            else
                DisconnectSafe("Mimic")
                IsMimicking = false
            end
        end)
    end)
end

local function StopMimic()
    DisconnectSafe("Mimic")
    IsMimicking = false
end

local function StackOnPlayer(target)
    local targetHRP = GetHRP(target)
    local botHRP = GetBotHRP()
    if targetHRP and botHRP then
        botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
    end
end

-- FlingAll — sequential processing through mutex to prevent collateral damage
local function FlingAllPlayers()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and IsAlive(p) then
                ExecutePhysicalFling(p) -- mutex inside handles sequential execution
                task.wait(0.1)
            end
        end
    end)
end

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
                    task.spawn(function() ExecutePhysicalFling(p) end)
                end
            end
        end)
    end)
end

local function StartGodKnife(target)
    DisconnectSafe("GodKnife")
    IsGodKnife = true
    ActiveConnections.GodKnife = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsGodKnife then DisconnectSafe("GodKnife") return end
            local botHRP = GetBotHRP()
            local targetHRP = GetHRP(target)
            if botHRP and targetHRP and target and target.Parent and IsAlive(target) then
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -2)
                local char = LocalPlayer.Character
                local knife = char and char:FindFirstChild("Knife")
                if not knife then
                    knife = LocalPlayer.Backpack:FindFirstChild("Knife")
                    if knife then
                        local hum = GetBotHumanoid()
                        if hum then hum:EquipTool(knife) end
                    end
                end
                if knife then pcall(function() knife:Activate() end) end
            else
                DisconnectSafe("GodKnife")
                IsGodKnife = false
            end
        end)
    end)
end

local function StopGodKnife()
    IsGodKnife = false
    DisconnectSafe("GodKnife")
end

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
            task.spawn(function()
                for i = 0, 10 do
                    task.wait(0.3)
                    pcall(function() trailPart.Transparency = i / 10 end)
                end
                pcall(function() trailPart:Destroy() end)
                for idx, tp in ipairs(TrailParts) do
                    if tp == trailPart then table.remove(TrailParts, idx) break end
                end
            end)
            if #TrailParts > 100 then
                local old = table.remove(TrailParts, 1)
                pcall(function() old:Destroy() end)
            end
        end)
    end)
end

local function StopTrail()
    IsTrailing = false
    DisconnectSafe("Trail")
    for _, part in ipairs(TrailParts) do pcall(function() part:Destroy() end) end
    TrailParts = {}
end

local function StartDance()
    DisconnectSafe("Dance")
    IsDancing = true
    local danceAngle = 0
    ActiveConnections.Dance = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            local hrp = GetBotHRP()
            if not hrp or not IsDancing then DisconnectSafe("Dance") return end
            danceAngle = danceAngle + dt * 8
            local bounce = math.sin(danceAngle) * 2
            local spin = math.sin(danceAngle * 0.5) * 0.3
            hrp.CFrame = hrp.CFrame * CFrame.new(0, bounce * 0.1, 0) * CFrame.Angles(0, spin, 0)
        end)
    end)
end

local function StopDance()
    IsDancing = false
    DisconnectSafe("Dance")
end

-- New command: Aura — spawns orbiting neon particles around the bot
local function StartAura()
    DisconnectSafe("Aura")
    IsAuraActive = true
    for _, p in ipairs(AuraParts) do pcall(function() p:Destroy() end) end
    AuraParts = {}
    -- Create 6 orbiting neon spheres
    for i = 1, 6 do
        local ball = Instance.new("Part")
        ball.Shape = Enum.PartType.Ball
        ball.Size = Vector3.new(0.8, 0.8, 0.8)
        ball.Material = Enum.Material.Neon
        ball.Color = Color3.fromHSV(i / 6, 1, 1)
        ball.Anchored = true
        ball.CanCollide = false
        ball.Transparency = 0.2
        ball.Name = "BotAura"
        ball.Parent = Workspace
        table.insert(AuraParts, ball)
    end
    local auraAngle = 0
    ActiveConnections.Aura = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            if not IsAuraActive then DisconnectSafe("Aura") return end
            local hrp = GetBotHRP()
            if not hrp then return end
            auraAngle = auraAngle + dt * 4
            for idx, ball in ipairs(AuraParts) do
                if ball and ball.Parent then
                    local offset = (idx - 1) * (math.pi * 2 / #AuraParts)
                    local radius = 3
                    local x = math.cos(auraAngle + offset) * radius
                    local z = math.sin(auraAngle + offset) * radius
                    local y = math.sin(auraAngle * 2 + offset) * 1.5
                    ball.CFrame = CFrame.new(hrp.Position + Vector3.new(x, y + 1, z))
                    ball.Color = Color3.fromHSV(((auraAngle + offset) % (math.pi * 2)) / (math.pi * 2), 1, 1)
                end
            end
        end)
    end)
end

local function StopAura()
    IsAuraActive = false
    DisconnectSafe("Aura")
    for _, p in ipairs(AuraParts) do pcall(function() p:Destroy() end) end
    AuraParts = {}
end

-- New command: Track — monitors target position and notifies on significant movement
local function StartTrack(target)
    DisconnectSafe("Track")
    IsTracking = true
    TrackTarget = target
    TrackLastPos = GetHRP(target) and GetHRP(target).Position or nil
    ActiveConnections.Track = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not IsTracking or not TrackTarget or not TrackTarget.Parent then
                DisconnectSafe("Track")
                IsTracking = false
                return
            end
            local tHRP = GetHRP(TrackTarget)
            if not tHRP then return end
            if TrackLastPos then
                local moved = (tHRP.Position - TrackLastPos).Magnitude
                if moved > 50 then
                    SendNotification("Track", TrackTarget.Name .. " moved " .. math.floor(moved) .. " studs", 3)
                    TrackLastPos = tHRP.Position
                end
            else
                TrackLastPos = tHRP.Position
            end
        end)
    end)
end

local function StopTrack()
    IsTracking = false
    TrackTarget = nil
    TrackLastPos = nil
    DisconnectSafe("Track")
end

-- Utility functions
local function GiveBTools()
    pcall(function()
        local deleteTool = Instance.new("Tool")
        deleteTool.Name = "Delete"
        deleteTool.RequiresHandle = false
        deleteTool.Parent = LocalPlayer.Backpack
        deleteTool.Activated:Connect(function()
            pcall(function()
                local mouse = LocalPlayer:GetMouse()
                if mouse.Target then mouse.Target:Destroy() end
            end)
        end)
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
end

local function RejoinServer()
    pcall(function()
        if TeleportService then TeleportService:Teleport(game.PlaceId, LocalPlayer) end
    end)
end

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
                            return
                        end
                    end
                end
            end
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- Dual-prefix detection with chat tag stripping
-- Strips common badge/VIP/system prefixes like [VIP], {Admin}, (Mod) before checking
-- Uses %s+ tokenization to handle extra whitespace and typos
local function StripChatTags(message)
    if not message then return "" end
    local stripped = message
    -- Remove bracket-style tags at the start: [VIP], {Admin}, (Mod), etc.
    stripped = stripped:gsub("^%s*%[.-%]%s*", "")
    stripped = stripped:gsub("^%s*%{.-%}%s*", "")
    stripped = stripped:gsub("^%s*%(.-%)%s*", "")
    -- Trim leading/trailing whitespace
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

-- Command router — central processing with dual prefix, chat tag stripping,
-- full validation, permissions, cooldowns, and human-like responses
local function HandleBotCommand(message, executorPlayer, isWhisper)
    if not message or not executorPlayer then return end
    if typeof(message) ~= "string" then return end

    -- Dual prefix detection with chat tag stripping
    local matchedPrefix, cleanedMessage = FindPrefix(message)
    if not matchedPrefix then return end

    -- Access control
    if not CanUseBot(executorPlayer) then return end
    local permLevel = GetPermLevel(executorPlayer)
    if permLevel < 1 then return end
    if IsOnCooldown(executorPlayer) then return end

    -- Parse command and arguments from cleaned message (tags already stripped)
    local cleanString = cleanedMessage:sub(#matchedPrefix + 1)
    if not cleanString or cleanString == "" then return end

    -- Smart tokenization: collapse multiple spaces, trim
    cleanString = cleanString:match("^%s*(.-)%s*$") or cleanString
    local args = {}
    for token in cleanString:gmatch("%S+") do
        table.insert(args, token)
    end
    if not args[1] or args[1] == "" then return end

    local cmd = args[1]:lower()

    -- Permission check for the specific command
    if not HasPermission(executorPlayer, cmd) then
        RespondError("no perms for " .. cmd, isWhisper and executorPlayer)
        return
    end

    -- Build rest-of-args string
    local restArgs = ""
    if #args > 1 then
        local parts = {}
        for i = 2, #args do table.insert(parts, args[i]) end
        restArgs = table.concat(parts, " ")
    end

    LogCommand(executorPlayer.Name, cmd, args[2])

    -- Whisper target for responses
    local wt = isWhisper and executorPlayer or nil

    -- MOVEMENT COMMANDS

    if cmd == "tp" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        local targetHRP = GetHRP(target)
        local botHRP = GetBotHRP()
        if targetHRP and botHRP then
            botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            Respond("tp'd to " .. target.Name, wt)
        else
            RespondError("character not loaded", wt)
        end

    elseif cmd == "bring" then
        if not args[2] then RespondError("need a target", wt) return end
        local targets = GetMultipleTargets(args[2], executorPlayer)
        if #targets == 0 then RespondError("cant find " .. args[2], wt) return end
        for _, target in ipairs(targets) do
            BringPlayer(target)
            task.wait(0.1)
        end
        Respond("bringing", wt)

    elseif cmd == "goto" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        local targetHRP = GetHRP(target)
        local botHum = GetBotHumanoid()
        if targetHRP and botHum then
            botHum:MoveTo(targetHRP.Position)
            Respond("walking to " .. target.Name, wt)
        else
            RespondError("character not loaded", wt)
        end

    elseif cmd == "follow" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
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
                end
            end)
        end)
        Respond("following " .. target.Name, wt)

    elseif cmd == "orbit" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
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
                    botHRP.CFrame = CFrame.new(targetHRP.Position + Vector3.new(x, 2, z), targetHRP.Position)
                else
                    DisconnectSafe("Orbit")
                end
            end)
        end)
        Respond("orbiting " .. target.Name, wt)

    elseif cmd == "attach" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
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
                end
            end)
        end)
        Respond("attached to " .. target.Name, wt)

    elseif cmd == "annoy" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartAnnoy(target)
        Respond("annoying " .. target.Name, wt)

    elseif cmd == "tpcoords" then
        local x = tonumber(args[2])
        local y = tonumber(args[3])
        local z = tonumber(args[4])
        if not x or not y or not z then RespondError("need x y z coords", wt) return end
        local botHRP = GetBotHRP()
        if botHRP then
            botHRP.CFrame = CFrame.new(x, y, z)
            Respond("tp'd to coords", wt)
        end

    -- FLING COMMANDS

    elseif cmd == "fling" then
        if not args[2] then RespondError("need a target", wt) return end
        local targets = GetMultipleTargets(args[2], executorPlayer)
        if #targets == 0 then RespondError("cant find " .. args[2], wt) return end
        -- Sequential fling via mutex — prevents collateral multi-target hits
        task.spawn(function()
            for _, target in ipairs(targets) do
                ExecutePhysicalFling(target)
                task.wait(0.1)
            end
        end)
        Respond("flinging", wt)

    elseif cmd == "loopfling" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        DisconnectSafe("LoopFling")
        DisconnectSafe("LoopKill")
        DisconnectSafe("LoopFlingAll")
        local lastFlingTime = 0
        ActiveConnections.LoopFling = RunService.Heartbeat:Connect(function()
            local now = tick()
            if (now - lastFlingTime) < LoopFlingDelay then return end
            lastFlingTime = now
            if target and target.Parent and IsAlive(target) and GetHRP(target) then
                task.spawn(function() ExecutePhysicalFling(target) end)
            elseif not target or not target.Parent then
                DisconnectSafe("LoopFling")
            end
        end)
        Respond("loopfling on " .. target.Name, wt)

    elseif cmd == "loopkill" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
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
                    return
                end
                if IsAlive(target) and GetHRP(target) then
                    task.spawn(function() ExecutePhysicalFling(target) end)
                end
            end)
        end)
        Respond("loopkill on " .. target.Name, wt)

    elseif cmd == "flingall" then
        FlingAllPlayers()
        Respond("flinging everyone", wt)

    elseif cmd == "loopflingall" then
        StartLoopFlingAll()
        Respond("loopfling all on", wt)

    -- CHARACTER COMMANDS

    elseif cmd == "speed" then
        local value = tonumber(args[2])
        if not value then RespondError("need a number", wt) return end
        local hum = GetBotHumanoid()
        if hum then hum.WalkSpeed = value; Respond("speed set to " .. value, wt) end

    elseif cmd == "jump" then
        local value = tonumber(args[2])
        if not value then RespondError("need a number", wt) return end
        local hum = GetBotHumanoid()
        if hum then
            hum.JumpPower = value
            hum.UseJumpPower = true
            Respond("jump set to " .. value, wt)
        end

    elseif cmd == "hipheight" then
        local value = tonumber(args[2])
        if not value then RespondError("need a number", wt) return end
        local hum = GetBotHumanoid()
        if hum then hum.HipHeight = value; Respond("hipheight set to " .. value, wt) end

    elseif cmd == "gravity" then
        local value = tonumber(args[2])
        if not value then RespondError("need a number", wt) return end
        pcall(function() Workspace.Gravity = value end)
        Respond("gravity set to " .. value, wt)

    elseif cmd == "fly" then
        local target = nil
        if args[2] then
            target = GetSmartTarget(args[2], executorPlayer)
        else
            target = executorPlayer
        end
        if not target then RespondError("cant find target", wt) return end
        StartFloorFly(target)
        Respond("floor fly on " .. target.Name .. " - spam jump to go up", wt)

    elseif cmd == "unfly" then
        StopFloorFly()
        Respond("fly off", wt)

    elseif cmd == "noclip" then
        StartNoClip()
        Respond("noclip on", wt)

    elseif cmd == "clip" then
        StopNoClip()
        Respond("noclip off", wt)

    elseif cmd == "invisible" or cmd == "invis" then
        SetInvisible(true)
        Respond("invisible", wt)

    elseif cmd == "visible" or cmd == "vis" then
        SetInvisible(false)
        Respond("visible", wt)

    elseif cmd == "respawn" or cmd == "refresh" then
        pcall(function()
            local char = LocalPlayer.Character
            if char then char:BreakJoints() end
        end)
        Respond("respawning", wt)

    elseif cmd == "freeze" then
        if not args[2] then
            FreezePlayer(LocalPlayer)
        else
            local target = GetSmartTarget(args[2], executorPlayer)
            if not target then RespondError("cant find " .. args[2], wt) return end
            FreezePlayer(target)
        end
        Respond("frozen", wt)

    elseif cmd == "unfreeze" then
        if not args[2] then
            UnfreezePlayer(LocalPlayer)
        else
            local target = GetSmartTarget(args[2], executorPlayer)
            if not target then RespondError("cant find " .. args[2], wt) return end
            UnfreezePlayer(target)
        end
        Respond("unfrozen", wt)

    elseif cmd == "god" then
        StartGodMode()
        Respond("god on", wt)

    elseif cmd == "ungod" then
        StopGodMode()
        Respond("god off", wt)

    elseif cmd == "spin" then
        StartSpin()
        Respond("spinning", wt)

    elseif cmd == "unspin" then
        StopSpin()
        Respond("spin off", wt)

    elseif cmd == "stare" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartStare(target)
        Respond("staring at " .. target.Name, wt)

    elseif cmd == "unstare" then
        DisconnectSafe("Stare")
        Respond("stare off", wt)

    -- ESP / VISUAL COMMANDS

    elseif cmd == "esp" then
        StartESP()
        Respond("esp on", wt)

    elseif cmd == "unesp" then
        StopESP()
        Respond("esp off", wt)

    elseif cmd == "highlight" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        CreateESPForPlayer(target)
        Respond("highlighted " .. target.Name, wt)

    elseif cmd == "unhighlight" then
        if not args[2] then
            for player, _ in pairs(ESPObjects) do RemoveESPForPlayer(player) end
            ESPObjects = {}
            Respond("all highlights removed", wt)
        else
            local target = GetSmartTarget(args[2], executorPlayer)
            if target then
                RemoveESPForPlayer(target)
                Respond("unhighlighted " .. target.Name, wt)
            end
        end

    elseif cmd == "view" or cmd == "spectate" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        ViewPlayer(target)
        Respond("viewing " .. target.Name, wt)

    elseif cmd == "unview" or cmd == "unspectate" then
        UnviewPlayer()
        Respond("camera reset", wt)

    -- SAFETY / UTILITY COMMANDS

    elseif cmd == "antivoid" then
        ToggleAntiVoid(not IsAntiVoid)
        Respond("antivoid " .. (IsAntiVoid and "on" or "off"), wt)

    elseif cmd == "infjump" then
        ToggleInfJump(not IsInfJump)
        Respond("infjump " .. (IsInfJump and "on" or "off"), wt)

    elseif cmd == "platform" then
        CreatePlatform()
        Respond("platform made", wt)

    elseif cmd == "sit" then
        local hum = GetBotHumanoid()
        if hum then hum.Sit = true; Respond("sat down", wt) end

    elseif cmd == "jumpnow" then
        local hum = GetBotHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end

    elseif cmd == "players" then
        local count = #Players:GetPlayers()
        Respond(count .. " players in server", wt)

    elseif cmd == "ping" then
        Respond("pong", wt)

    elseif cmd == "uptime" then
        Respond("uptime " .. FormatTime(tick() - BotStartTime), wt)

    elseif cmd == "age" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        local ageDays = target.AccountAge
        local years = math.floor(ageDays / 365)
        local days = ageDays % 365
        Respond(target.Name .. " account age: " .. years .. "y " .. days .. "d", wt)

    elseif cmd == "status" then
        local statusMsg = "up: " .. FormatTime(tick() - BotStartTime)
            .. " | noclip: " .. (IsNoClip and "on" or "off")
            .. " | god: " .. (IsGodMode and "on" or "off")
            .. " | mode: " .. BotMode
        Respond(statusMsg, wt)

    elseif cmd == "copyname" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        if ExecutorInfo.HasSetClipboard then
            pcall(function() setclipboard(target.Name) end)
            Respond("copied " .. target.Name, wt)
        else
            Respond(target.Name .. " (clipboard not available)", wt)
        end

    -- MM2 COMMANDS

    elseif cmd == "grabknife" then
        GrabWeapon("Knife")
        Respond("grabbing knife", wt)

    elseif cmd == "grabgun" then
        GrabWeapon("Gun")
        Respond("grabbing gun", wt)

    elseif cmd == "mmrole" or cmd == "roles" then
        local roles = GetMM2Roles()
        local murdName = roles.murderer and roles.murderer.Name or "unknown"
        local sheriffName = roles.sheriff and roles.sheriff.Name or "unknown"
        Respond("murd: " .. murdName, wt, true)
        task.wait(ChatRateLimit + 0.2)
        Respond("sherif: " .. sheriffName, wt, true)

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
                Respond("collecting " .. #coins .. " coins", wt)
            end
        else
            RespondError("no coins found", wt)
        end

    elseif cmd == "coinfarm" then
        StartCoinFarm()
        Respond("coinfarm on", wt)

    elseif cmd == "uncoinfarm" then
        StopCoinFarm()
        Respond("coinfarm off", wt)

    elseif cmd == "lobby" then
        local botHRP = GetBotHRP()
        if botHRP then
            botHRP.CFrame = CFrame.new(-109, 140, -12)
            Respond("tp'd to lobby", wt)
        end

    elseif cmd == "map" then
        local botHRP = GetBotHRP()
        if botHRP then
            pcall(function()
                local mapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("CurrentMap")
                if mapFolder then
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
                        Respond("tp'd to map", wt)
                        return
                    end
                end
                botHRP.CFrame = CFrame.new(0, 50, 0)
                Respond("tp'd to center", wt)
            end)
        end

    elseif cmd == "xray" then
        StartXRay()
        Respond("xray on", wt)

    elseif cmd == "unxray" then
        StopXRay()
        Respond("xray off", wt)

    elseif cmd == "godknife" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartGodKnife(target)
        Respond("godknife on " .. target.Name, wt)

    elseif cmd == "ungodknife" then
        StopGodKnife()
        Respond("godknife off", wt)

    -- FARM COMMANDS

    elseif cmd == "farm" then
        StartFarm()
        Respond("farm on", wt)

    elseif cmd == "unfarm" then
        StopFarm()
        Respond("farm off", wt)

    -- TROLL COMMANDS

    elseif cmd == "seizure" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartSeizure(target)
        Respond("seizure on " .. target.Name, wt)

    elseif cmd == "launch" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        LaunchPlayer(target)
        Respond("launched " .. target.Name, wt)

    elseif cmd == "yeet" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        YeetPlayer(target)
        Respond("yeeted " .. target.Name, wt)

    elseif cmd == "tornado" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartTornado(target)
        Respond("tornado on " .. target.Name, wt)

    elseif cmd == "blackhole" then
        StartBlackHole()
        Respond("blackhole on", wt)

    elseif cmd == "unblackhole" then
        StopBlackHole()
        Respond("blackhole off", wt)

    elseif cmd == "scatter" then
        ScatterAll()
        Respond("scattered everyone", wt)

    elseif cmd == "cage" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        CagePlayer(target)
        Respond("caged " .. target.Name, wt)

    elseif cmd == "uncage" then
        RemoveCage()
        Respond("cage removed", wt)

    elseif cmd == "trap" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        TrapPlayer(target)
        Respond("trapping " .. target.Name, wt)

    elseif cmd == "spam" then
        if restArgs == "" then RespondError("need a message", wt) return end
        local count = tonumber(args[#args])
        local msg = restArgs
        if count and #args > 2 then
            local parts = {}
            for i = 2, #args - 1 do table.insert(parts, args[i]) end
            msg = table.concat(parts, " ")
        else
            count = 10
        end
        SpamChat(msg, count)

    elseif cmd == "strobe" then
        StartStrobe()
        Respond("strobe on", wt)

    elseif cmd == "unstrobe" then
        StopStrobe()
        Respond("strobe off", wt)

    elseif cmd == "giant" then
        ScaleCharacter(3)
        Respond("giant mode", wt)

    elseif cmd == "tiny" then
        ScaleCharacter(0.3)
        Respond("tiny mode", wt)

    elseif cmd == "normal" then
        ScaleCharacter(1)
        Respond("normal size", wt)

    elseif cmd == "headless" then
        SetHeadless(true)
        Respond("headless on", wt)

    elseif cmd == "unheadless" then
        SetHeadless(false)
        Respond("head restored", wt)

    elseif cmd == "creep" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartCreep(target)
        Respond("creeping on " .. target.Name, wt)

    elseif cmd == "mimic" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartMimic(target)
        Respond("mimicking " .. target.Name, wt)

    elseif cmd == "unmimic" then
        StopMimic()
        Respond("mimic off", wt)

    elseif cmd == "stack" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StackOnPlayer(target)
        Respond("stacked on " .. target.Name, wt)

    elseif cmd == "dance" then
        StartDance()
        Respond("dancing", wt)

    elseif cmd == "undance" then
        StopDance()
        Respond("dance off", wt)

    elseif cmd == "trail" then
        StartTrail()
        Respond("trail on", wt)

    elseif cmd == "untrail" then
        StopTrail()
        Respond("trail off", wt)

    -- VISUAL / ENVIRONMENT COMMANDS

    elseif cmd == "btools" then
        GiveBTools()
        Respond("btools given", wt)

    elseif cmd == "fogoff" then
        pcall(function()
            Lighting.FogEnd = 9999999
            Lighting.FogStart = 9999999
        end)
        Respond("fog removed", wt)

    elseif cmd == "fullbright" then
        pcall(function()
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 9999999
            Lighting.GlobalShadows = false
        end)
        Respond("fullbright on", wt)

    elseif cmd == "nightmode" then
        pcall(function() Lighting.ClockTime = 0 end)
        Respond("night mode", wt)

    elseif cmd == "daymode" then
        pcall(function() Lighting.ClockTime = 14 end)
        Respond("day mode", wt)

    elseif cmd == "char" then
        if not args[2] then RespondError("need a userid", wt) return end
        local userId = tonumber(args[2])
        if not userId then RespondError("invalid userid", wt) return end
        pcall(function()
            local desc = Players:GetHumanoidDescriptionFromUserId(userId)
            if desc then
                local hum = GetBotHumanoid()
                if hum then hum:ApplyDescription(desc); Respond("changed appearance", wt) end
            end
        end)

    -- CONTROL COMMANDS

    elseif cmd == "rejoin" then
        RejoinServer()
        Respond("rejoining", wt)

    elseif cmd == "serverhop" then
        ServerHop()
        Respond("server hopping", wt)

    -- PERMISSION COMMANDS (fixed: works 100%)

    elseif cmd == "perm" then
        if not args[2] then RespondError("need a player name", wt) return end
        -- Support both in-game players and offline name strings
        local target = GetSmartTarget(args[2], executorPlayer)
        if target then
            local currentLevel = GetPermLevel(target)
            if currentLevel >= 1 and not (BotMode == "public" and PermittedUsers[target.Name:lower()] == nil) then
                Respond(target.Name .. " already has perms (level " .. currentLevel .. ")", wt)
                return
            end
            PermittedUsers[target.Name:lower()] = 1
            Respond(target.Name .. " permed (user)", wt, true)
        else
            -- Offline perm: store the name directly
            local nameKey = args[2]:lower()
            PermittedUsers[nameKey] = 1
            Respond(args[2] .. " permed (offline)", wt)
        end

    elseif cmd == "unperm" then
        if not args[2] then RespondError("need a player name", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        local nameKey = target and target.Name:lower() or args[2]:lower()
        if nameKey == SuperOwner:lower() then
            RespondError("cant unperm the super owner", wt)
            return
        end
        local targetLevel = PermittedUsers[nameKey] or 0
        if targetLevel >= GetPermLevel(executorPlayer) then
            RespondError("cant unperm someone same rank or higher", wt)
            return
        end
        PermittedUsers[nameKey] = nil
        Respond((target and target.Name or args[2]) .. " unpermed", wt)

    elseif cmd == "admin" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        local nameKey = target and target.Name:lower() or args[2]:lower()
        if nameKey == SuperOwner:lower() then
            RespondError("cant change super owner rank", wt)
            return
        end
        PermittedUsers[nameKey] = 2
        Respond((target and target.Name or args[2]) .. " is now admin", wt, true)

    elseif cmd == "unadmin" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        local nameKey = target and target.Name:lower() or args[2]:lower()
        if nameKey == SuperOwner:lower() then
            RespondError("cant demote super owner", wt)
            return
        end
        local targetLevel = PermittedUsers[nameKey] or 0
        if targetLevel >= GetPermLevel(executorPlayer) then
            RespondError("cant demote someone same rank or higher", wt)
            return
        end
        PermittedUsers[nameKey] = 1
        Respond((target and target.Name or args[2]) .. " demoted to user", wt)

    elseif cmd == "owner" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        local nameKey = target and target.Name:lower() or args[2]:lower()
        if nameKey == SuperOwner:lower() then
            RespondError("cant change super owner rank", wt)
            return
        end
        PermittedUsers[nameKey] = 3
        Respond((target and target.Name or args[2]) .. " is now owner", wt, true)

    elseif cmd == "unowner" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        local nameKey = target and target.Name:lower() or args[2]:lower()
        if nameKey == SuperOwner:lower() then
            RespondError("cant demote super owner", wt)
            return
        end
        PermittedUsers[nameKey] = 2
        Respond((target and target.Name or args[2]) .. " demoted to admin", wt)

    -- NEW COMMANDS

    elseif cmd == "perms" then
        local permList = {}
        for name, level in pairs(PermittedUsers) do
            local levelName = level == 4 and "super" or level == 3 and "owner" or level == 2 and "admin" or "user"
            table.insert(permList, name .. "(" .. levelName .. ")")
        end
        local msg = #permList > 0 and table.concat(permList, ", ") or "no permed users"
        RespondPrivate("perms: " .. msg, executorPlayer)

    elseif cmd == "tp2me" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        -- Bring target to the executor's position using the improved bring system
        local executorHRP = GetHRP(executorPlayer)
        if executorHRP then
            BringPlayer(target, executorHRP.CFrame)
            Respond("bringing " .. target.Name .. " to you", wt)
        else
            RespondError("your character not loaded", wt)
        end

    elseif cmd == "safetp" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        local botHRP = GetBotHRP()
        if botHRP then
            SavedCFrame = botHRP.CFrame
            local targetHRP = GetHRP(target)
            if targetHRP then
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                Respond("safetp to " .. target.Name .. " (use back to return)", wt)
            end
        end

    elseif cmd == "back" then
        if SavedCFrame then
            local botHRP = GetBotHRP()
            if botHRP then
                botHRP.CFrame = SavedCFrame
                SavedCFrame = nil
                Respond("returned to saved position", wt)
            end
        else
            RespondError("no saved position (use safetp first)", wt)
        end

    elseif cmd == "clone" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        pcall(function()
            local targetHum = GetHumanoid(target)
            if targetHum then
                local desc = targetHum:GetAppliedDescription()
                if desc then
                    local botHum = GetBotHumanoid()
                    if botHum then
                        botHum:ApplyDescription(desc)
                        Respond("cloned " .. target.Name .. "'s look", wt)
                    end
                end
            end
        end)

    elseif cmd == "unclone" then
        pcall(function()
            local char = LocalPlayer.Character
            if char then char:BreakJoints() end
        end)
        Respond("appearance reset (respawning)", wt)

    elseif cmd == "countdown" then
        local seconds = tonumber(args[2]) or 5
        seconds = math.min(math.max(seconds, 1), 30)
        task.spawn(function()
            for i = seconds, 1, -1 do
                pcall(function() SendChatMessage(BypassText(tostring(i))) end)
                task.wait(ChatRateLimit + 0.1)
            end
            task.wait(ChatRateLimit + 0.1)
            pcall(function() SendChatMessage(BypassText("GO")) end)
        end)
        Respond("countdown from " .. seconds, wt)

    elseif cmd == "aura" then
        StartAura()
        Respond("aura on", wt)

    elseif cmd == "unaura" then
        StopAura()
        Respond("aura off", wt)

    elseif cmd == "nuke" then
        Respond("nuking server", wt, true)
        task.spawn(function()
            -- Fling everyone sequentially
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then
                    ExecutePhysicalFling(p)
                    task.wait(0.05)
                end
            end
            -- Cage any survivors
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then
                    CagePlayer(p)
                end
            end
        end)

    elseif cmd == "emote" then
        local emoteId = args[2]
        if not emoteId then RespondError("need an emote id or name", wt) return end
        local emoteMap = {
            wave = "507770239", point = "507770453", dance = "507771019",
            dance2 = "507776043", dance3 = "507777268", laugh = "507770818",
            cheer = "507770677",
        }
        local animId = emoteMap[emoteId:lower()] or emoteId
        pcall(function()
            local hum = GetBotHumanoid()
            if hum then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. animId
                local track = hum:LoadAnimation(anim)
                track:Play()
                Respond("playing emote", wt)
            end
        end)

    elseif cmd == "track" then
        if not args[2] then RespondError("need a target", wt) return end
        local target = GetSmartTarget(args[2], executorPlayer)
        if not target then RespondError("cant find " .. args[2], wt) return end
        StartTrack(target)
        Respond("tracking " .. target.Name, wt)

    elseif cmd == "untrack" then
        StopTrack()
        Respond("tracking off", wt)

    -- MODE COMMANDS (SuperOwner only)

    elseif cmd == "public" then
        BotMode = "public"
        Respond("bot is now public - anyone can use basic commands", wt, true)

    elseif cmd == "private" then
        BotMode = "private"
        Respond("bot is now private - only permed users can use it", wt)

    -- STOP / CONTROL

    elseif cmd == "stop" or cmd == "reset" then
        StopAllLoops()
        Respond("all loops stopped", wt)

    elseif cmd == "antiafk" then
        ToggleAntiAFK(not IsAntiAFK)
        Respond("antiafk " .. (IsAntiAFK and "on" or "off"), wt)

    elseif cmd == "shutdown" then
        Respond("shutting down", wt)
        task.wait(0.5)
        FullCleanup()
        genv.__ULTIMATE_BOT_LOADED = false

    -- HELP — always private, never leaks to public chat
    elseif cmd == "cmds" or cmd == "help" or cmd == "commands" then
        RespondPrivate("MOVE: tp, bring, goto, follow, orbit, attach, annoy, tpcoords, safetp, back, tp2me", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("FLING: fling, loopfling, loopkill, flingall, loopflingall, yeet, launch, nuke", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("CHAR: speed, jump, fly, unfly, noclip, clip, invis, vis, god, ungod, spin, unspin", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("MM2: grabknife, grabgun, mmrole, cointp, coinfarm, godknife, xray, lobby, map", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("TROLL: seizure, tornado, blackhole, scatter, cage, trap, spam, strobe, aura", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("UTIL: btools, fogoff, fullbright, nightmode, daymode, trail, dance, platform, char, emote, clone, countdown, track", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("PERM: perm, unperm, admin, unadmin, owner, unowner, perms | CTRL: stop, rejoin, serverhop, public, private, shutdown", executorPlayer)
        task.wait(ChatRateLimit + 0.1)
        RespondPrivate("TARGETS: <name>, me, all, others, random, nearest, farthest, team, enemies, murd, sherif", executorPlayer)

    else
        RespondError("unknown cmd: " .. cmd, wt)
    end
end

-- Multi-channel chat connectors — hooks ALL channels for MM2 dead/spectator chat support
-- Uses player.Chatted as primary (fires for ALL messages regardless of death state)
-- Also hooks every individual TextChannel via MessageReceived for cross-channel bridging
-- DescendantAdded listener catches dynamically created match/round channels
local ChatHooks = {}
local HookedChannels = {}

local function HookPlayerChat(player)
    if ChatHooks[player] then return end
    ChatHooks[player] = true
    -- player.Chatted fires for every message from this player regardless of
    -- whether they are alive, dead, in spectator mode, or in any special channel
    pcall(function()
        player.Chatted:Connect(function(msg)
            pcall(function() HandleBotCommand(msg, player, false) end)
        end)
    end)
end

-- Hook a single TextChannel for direct message interception
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
end

-- Hook existing players
for _, p in ipairs(Players:GetPlayers()) do
    HookPlayerChat(p)
end

-- Hook new players joining
Players.PlayerAdded:Connect(function(player)
    HookPlayerChat(player)
    if ActiveConnections.ESP then
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if ActiveConnections.ESP then CreateESPForPlayer(player) end
        end)
    end
end)

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
    CommandCooldowns[player.Name:lower()] = nil
    ChatHooks[player] = nil
    RemoveESPForPlayer(player)
end)

-- TextChatService multi-channel hooking for MM2 dead/spectator/team channels
pcall(function()
    if TextChatService then
        -- Hook all existing TextChannel descendants (covers default + game-specific channels)
        for _, desc in ipairs(TextChatService:GetDescendants()) do
            HookTextChannel(desc)
        end
        -- Watch for dynamically created channels (MM2 creates round-specific channels)
        TextChatService.DescendantAdded:Connect(function(desc)
            if desc:IsA("TextChannel") then
                task.wait(0.1) -- brief yield to let the channel fully initialize
                HookTextChannel(desc)
            end
        end)
    end
end)

-- Legacy chat system support (DefaultChatSystemChatEvents)
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

-- Character respawn handler — re-applies all persistent effects after death
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if IsNoClip then StartNoClip() end
    if IsGodMode then
        task.wait(0.3)
        StartGodMode()
    end
    if IsFloorFlying and FloorFlyTarget then
        task.wait(0.3)
        StartFloorFly(FloorFlyTarget)
    end
    if IsSpinning then
        task.wait(0.3)
        StartSpin()
    end
    Log("SYS", "Character respawned — effects re-applied.")
end)

-- Auto-perm SuperOwner on join
Players.PlayerAdded:Connect(function(player)
    if player.Name:lower() == SuperOwner:lower() then
        PermittedUsers[player.Name:lower()] = 4
        Log("SYS", "SuperOwner " .. player.Name .. " joined. Auto-permed L4.")
        SendNotification("Boss joined", SuperOwner .. " is here", 5)
    end
end)

-- Ensure SuperOwner is permed if already in server
for _, p in ipairs(Players:GetPlayers()) do
    if p.Name:lower() == SuperOwner:lower() then
        PermittedUsers[p.Name:lower()] = 4
    end
end

-- Startup
print("")
print("BOT v7.0 loaded")
print("SuperOwner: " .. SuperOwner)
print("Prefix: ?bot / .bot")
print("Executor: " .. ExecutorInfo.ExecutorName)
print("Mode: " .. BotMode)
print("90+ commands ready")
print("")

SendNotification("Bot v7.0", "Type ?bot help or .bot help\nSuper: " .. SuperOwner, 8)

-- Auto-enable Anti-AFK at startup
ToggleAntiAFK(true)

Log("SYS", "BOT v7.0 LOADED")
Log("SYS", "SuperOwner: " .. SuperOwner .. " (L4)")
Log("SYS", "Mode: " .. BotMode)
Log("SYS", "Executor: " .. ExecutorInfo.ExecutorName)
