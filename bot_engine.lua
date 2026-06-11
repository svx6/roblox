local genv = _G or {}
if type(getgenv) == "function" then
    local s, r = pcall(getgenv)
    if s and type(r) == "table" then genv = r end
end
if genv.__ULTIMATE_BOT_LOADED then
    pcall(function() if genv.__ULTIMATE_BOT_CLEANUP then genv.__ULTIMATE_BOT_CLEANUP() end end)
end
genv.__ULTIMATE_BOT_LOADED = true

local _unpack = unpack or table.unpack or function(t, i, j)
    i, j = i or 1, j or #t
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
    return t[i], t[i+1], t[i+2], t[i+3], t[i+4], t[i+5], t[i+6], t[i+7]
end

do
    local _ok, _t = pcall(function() return task end)
    if not _ok or not _t or type(_t) ~= "table" then
        pcall(function() task = {} end)
        if type(task) ~= "table" then
            pcall(function() if rawset then rawset(_G, "task", {}) end end)
            pcall(function() if rawget then task = rawget(_G, "task") end end)
        end
    end
end
if type(task) ~= "table" then task = {} end
if not task.spawn then task.spawn = function(fn, ...) local a = {...}; coroutine.wrap(function() fn(_unpack(a)) end)() end end
if not task.wait then task.wait = function(t) local _t = tick or os.clock or function() return 0 end; local s = _t(); repeat game:GetService("RunService").Heartbeat:Wait() until _t() - s >= (t or 0.03); return _t() - s end end
if not task.delay then task.delay = function(t, fn) task.spawn(function() task.wait(t); fn() end) end end
if not task.defer then task.defer = task.spawn end
if not task.cancel then task.cancel = function() end end
if not string.split then
    string.split = function(str, sep)
        if not str then return {} end
        if not sep or sep == "" then local r = {}; for i = 1, #str do r[i] = str:sub(i, i) end; return r end
        local r, s, sl = {}, 1, #sep
        while true do
            local f = str:find(sep, s, true)
            if not f then r[#r+1] = str:sub(s); break end
            r[#r+1] = str:sub(s, f - 1); s = f + sl
        end
        return r
    end
end

local safeTick = tick or os.clock or function() return 0 end

local SuperOwner      = "roboxproplyer"
local Prefixes        = {"?bot ", ".bot ", ",bot ", "/bot "}
local FlingPower      = 99999999
local LoopFlingDelay  = 0.3
local FollowDistance  = 5
local OrbitRadius     = 12
local OrbitSpeed      = 3
local CooldownTime    = 0.12
local FlySpeed        = 80
local SpinSpeed       = 20
local AnnoyDelay      = 0.08
local BringIterations = 250
local ChatRateLimit   = 1.0
local BotStartTime    = safeTick()
local BotMode         = "private"
local LastTarget      = nil

local GITHUB_OWNER    = "svx6"
local GITHUB_REPO     = "roblox"
local GITHUB_BRANCH   = "main"
local GITHUB_CMD_PATH = "commands"
local GITHUB_RAW_BASE = "https://raw.githubusercontent.com/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/" .. GITHUB_CMD_PATH .. "/"
local GITHUB_API_BASE = "https://api.github.com/repos/" .. GITHUB_OWNER .. "/" .. GITHUB_REPO .. "/contents/" .. GITHUB_CMD_PATH

local Console = {}
Console.History = {}
Console.MaxHistory = 500
Console.Categories = {
    CMD = {color = "🟢", label = "CMD"}, LOAD = {color = "🔵", label = "LOAD"},
    ERR = {color = "🔴", label = "ERR"}, WARN = {color = "🟡", label = "WARN"},
    PERM = {color = "🟣", label = "PERM"}, NET = {color = "🌐", label = "NET"},
    SYS = {color = "⚙️", label = "SYS"}, DBG = {color = "🔧", label = "DBG"},
    PHY = {color = "⚡", label = "PHY"},
}
function Console.Log(cat, msg, det)
    local ci = Console.Categories[cat] or Console.Categories.SYS
    local ts = os.date("%H:%M:%S")
    Console.History[#Console.History + 1] = {time = ts, category = cat, message = msg, details = det or "", tick = safeTick()}
    if #Console.History > Console.MaxHistory then table.remove(Console.History, 1) end
    print(string.format("[%s] %s [%s] %s%s", ts, ci.color, ci.label, msg, det and (" | " .. tostring(det)) or ""))
end
function Console.Error(m, d) Console.Log("ERR", m, d) end
function Console.Warn(m, d) Console.Log("WARN", m, d) end
function Console.Command(ex, cmd, tgt, et)
    Console.Log("CMD", ex .. " > " .. cmd .. (tgt and (" -> " .. tostring(tgt)) or "") .. (et and string.format(" (%.1fms)", et * 1000) or ""))
end
function Console.Network(act, url, ok) Console.Log("NET", act .. " [" .. (ok and "OK" or "FAIL") .. "]", url) end
function Console.Permission(pl, cmd, al, lv) Console.Log("PERM", pl .. " " .. (al and "GRANTED" or "DENIED") .. " '" .. cmd .. "'", "Lv:" .. tostring(lv)) end
function Console.GetRecentLogs(c, cf)
    c = c or 20; local f = {}
    for i = #Console.History, 1, -1 do
        local e = Console.History[i]
        if not cf or e.category == cf then f[#f+1] = e; if #f >= c then break end end
    end
    return f
end
function Console.GetSystemDump()
    return "=== STATE ===\nUptime: " .. string.format("%.1f", safeTick() - BotStartTime) .. "s\nMode: " .. BotMode .. "\nOwner: " .. SuperOwner .. "\nLogs: " .. #Console.History
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local TextChatService, VirtualUser, TeleportService, HttpService, MarketplaceService
pcall(function() TextChatService = game:GetService("TextChatService") end)
pcall(function() VirtualUser = game:GetService("VirtualUser") end)
pcall(function() TeleportService = game:GetService("TeleportService") end)
pcall(function() HttpService = game:GetService("HttpService") end)
pcall(function() MarketplaceService = game:GetService("MarketplaceService") end)

local function _sTC(n)
    local o, r = pcall(function()
        local lt = {firetouchinterest=function() return firetouchinterest end, gethiddenproperty=function() return gethiddenproperty end, sethiddenproperty=function() return sethiddenproperty end, setclipboard=function() return setclipboard end, getgenv=function() return getgenv end, request=function() return request end, http_request=function() return http_request end, setfpscap=function() return setfpscap end}
        local g = lt[n]; if not g then return false end
        local o2, v = pcall(g); return o2 and type(v) == "function"
    end)
    return o and r or false
end

local ExecutorInfo = {
    HasFireTouchInterest = _sTC("firetouchinterest"), HasGetHiddenProperty = _sTC("gethiddenproperty"),
    HasSetHiddenProperty = _sTC("sethiddenproperty"), HasSetClipboard = _sTC("setclipboard"),
    HasGetGenv = _sTC("getgenv"), HasHttpRequest = _sTC("request") or _sTC("http_request"),
    HasSetFpsCap = _sTC("setfpscap"), ExecutorName = "Unknown",
}
pcall(function()
    if identifyexecutor then ExecutorInfo.ExecutorName = identifyexecutor()
    elseif getexecutorname then ExecutorInfo.ExecutorName = getexecutorname()
    elseif syn and syn.about then ExecutorInfo.ExecutorName = "Synapse X"
    elseif fluxus then ExecutorInfo.ExecutorName = "Fluxus"
    elseif KRNL_LOADED then ExecutorInfo.ExecutorName = "KRNL" end
end)
pcall(function() if ExecutorInfo.HasSetFpsCap then setfpscap(999) end end)

if not _G.__BOT_SAVED_PERMS then _G.__BOT_SAVED_PERMS = {} end
if not _G.__BOT_SAVED_SETTINGS then _G.__BOT_SAVED_SETTINGS = {} end

local PERM_SAVE_FILE = "bot_saved_perms.json"
local function SavePermsToFile()
    pcall(function()
        if type(writefile) == "function" and HttpService then
            writefile(PERM_SAVE_FILE, HttpService:JSONEncode(_G.__BOT_SAVED_PERMS))
        end
    end)
end
local function LoadPermsFromFile()
    pcall(function()
        if type(readfile) == "function" and type(isfile) == "function" and HttpService then
            if isfile(PERM_SAVE_FILE) then
                local data = readfile(PERM_SAVE_FILE)
                if data and #data > 0 then
                    local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
                    if ok and decoded and type(decoded) == "table" then
                        for k, v in pairs(decoded) do
                            _G.__BOT_SAVED_PERMS[k:lower()] = v
                        end
                    end
                end
            end
        end
    end)
end
LoadPermsFromFile()

local PermittedUsers = {[SuperOwner:lower()] = 4}
for pn, lv in pairs(_G.__BOT_SAVED_PERMS) do
    if pn:lower() ~= SuperOwner:lower() then PermittedUsers[pn:lower()] = lv end
end

local CommandPermissions = {}

local ConnectionRegistry = {}
local ActiveConnections = {}

-- Dynamic set of connections that survive StopAllLoops
local PersistentConnections = {
    NoClip=true, AntiAFK=true, AntiVoid=true, AntiFling=true, AntiSlow=true,
    AutoRespawn=true, AutoJoin=true, MM2AutoGod=true, MM2AutoGun=true, PhysicsStabilizer=true,
}

local function TrackConnection(name, conn)
    if ActiveConnections[name] then
        pcall(function() ActiveConnections[name]:Disconnect() end)
    end
    ActiveConnections[name] = conn
    ConnectionRegistry[name] = {conn = conn, time = safeTick(), alive = true}
end

-- Shared Flags table — GetFlag/SetFlag access this directly, no table copies
local Flags = {
    IsFlying = false, IsNoClip = false, IsGodMode = false, IsAntiAFK = false,
    IsAntiVoid = false, IsInfJump = false, IsSpinning = false, IsCoinFarming = false,
    IsFarming = false, IsBlackHole = false, IsStrobing = false, IsGodKnife = false,
    IsMimicking = false, IsCreeping = false, IsTrailing = false, IsDancing = false,
    IsFloorFlying = false, IsAuraActive = false, IsTracking = false, IsFlingBusy = false,
    IsMagnetOn = false, IsAntiSlow = false, IsAntiFling = false, IsLoopTP = false,
    IsAutoShoot = false, IsAutoMurd = false, IsWallBang = false, IsAutoRespawn = false,
    IsAutoJoin = false, IsDestroyServer = false, PreferredFlingMethod = 0, PhysicsStabilizerActive = false,
    -- Object/reference flags
    FloorFlyTarget = nil, FloorFlyPlatform = nil, TrackTarget = nil, TrackLastPos = nil,
    LoopTPTarget = nil, AutoShootTarget = nil, AutoMurdTarget = nil, AutoJoinTarget = nil,
    SavedCFrame = nil, PlatformPart = nil, OriginalCameraSubject = nil,
    GodHealthConnection = nil, GodDiedConnection = nil,
    FlyBodyGyro = nil, FlyBodyVelocity = nil, LastTarget = nil,
}

-- Convenient local aliases for internal engine use (kept for backward compat)
local FlyBodyGyro, FlyBodyVelocity = nil, nil
local ESPObjects, CommandCooldowns, CommandLog = {}, {}, {}
local CageParts, TrailParts, XRayParts, AuraParts, FreezeCages = {}, {}, {}, {}, {}
local OriginalGravity = Workspace.Gravity
local OriginalLighting = {}
local LastChatTime = 0
local GodHealthConnection, GodDiedConnection = nil, nil
local CommandDedup = {}
local DEDUP_WINDOW = 0.4
local OriginalCameraSubject = nil
local AntiGravityForce = nil

-- AutoJoin tracking state
local AutoJoinStatus = {
    lastCheck = 0,
    lastResult = "idle",
    attempts = 0,
    targetFound = false,
    lastFoundServer = nil,
}

pcall(function()
    OriginalLighting.Ambient = Lighting.Ambient
    OriginalLighting.Brightness = Lighting.Brightness
    OriginalLighting.FogEnd = Lighting.FogEnd
    OriginalLighting.FogStart = Lighting.FogStart
    OriginalLighting.ClockTime = Lighting.ClockTime
    OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
end)

local function GetCharacter(p) return p and p.Character or nil end
local function GetHRP(p) local c = GetCharacter(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid(p) local c = GetCharacter(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function IsAlive(p) if not p or not p.Parent then return false end; local h = GetHumanoid(p); return h and h.Health > 0 end
local function GetBotHRP() return GetHRP(LocalPlayer) end
local function GetBotHumanoid() return GetHumanoid(LocalPlayer) end
local function IsBotAlive() return IsAlive(LocalPlayer) end
local function EnsureCharacter()
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait(); task.wait(0.3) end
    return LocalPlayer.Character
end

local function DisconnectSafe(name)
    if ActiveConnections[name] then
        pcall(function() ActiveConnections[name]:Disconnect() end)
        ActiveConnections[name] = nil
    end
    if ConnectionRegistry[name] then
        ConnectionRegistry[name].alive = false
        ConnectionRegistry[name].conn = nil
    end
end

local function PurgeDeadConnections()
    for name, data in pairs(ConnectionRegistry) do
        if data.conn then
            local ok, connected = pcall(function() return data.conn.Connected end)
            if ok and not connected then
                ConnectionRegistry[name].alive = false
                ConnectionRegistry[name].conn = nil
                ActiveConnections[name] = nil
            end
        end
    end
end

local function ApplyAntiGravity()
    pcall(function()
        local hrp = GetBotHRP()
        if not hrp then return end
        local ag = hrp:FindFirstChild("BotAntiGrav")
        if not ag then
            ag = Instance.new("BodyForce")
            ag.Name = "BotAntiGrav"
            ag.Parent = hrp
        end
        ag.Force = Vector3.new(0, Workspace.Gravity * hrp.AssemblyMass, 0)
        AntiGravityForce = ag
    end)
end

local function RemoveAntiGravity()
    pcall(function()
        if AntiGravityForce then AntiGravityForce:Destroy(); AntiGravityForce = nil end
        local hrp = GetBotHRP()
        if hrp then
            local ag = hrp:FindFirstChild("BotAntiGrav")
            if ag then ag:Destroy() end
        end
    end)
end

local function LockFlingStates()
    pcall(function()
        local hum = GetBotHumanoid()
        if not hum then return end
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    end)
end

local function UnlockFlingStates()
    pcall(function()
        local hum = GetBotHumanoid()
        if not hum then return end
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        if not Flags.IsGodMode then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end)
end

local function DampenVelocity(hrp)
    if not hrp then return end
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function StabilizeCharacter()
    pcall(function()
        local hrp = GetBotHRP()
        local hum = GetBotHumanoid()
        if not hrp or not hum then return end
        DampenVelocity(hrp)
        if hum:GetState() == Enum.HumanoidStateType.FallingDown or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

local HomoglyphMap = {
    a={string.char(208,176),string.char(201,145)}, e={string.char(208,181),string.char(196,153)},
    o={string.char(208,190),string.char(195,182)}, c={string.char(209,129),string.char(196,135)},
    p={string.char(209,128)}, s={string.char(209,149),string.char(197,155)},
    i={string.char(209,150),string.char(195,173)}, x={string.char(209,133)},
    y={string.char(209,131),string.char(195,189)}, n={string.char(208,191)},
    h={string.char(210,187)}, d={string.char(212,129)}, g={string.char(201,161)},
    k={string.char(210,155)}, l={string.char(209,150)}, m={string.char(208,188)},
    t={string.char(209,130)}, u={string.char(209,131)}, v={string.char(209,131)},
    w={string.char(209,161)}, r={string.char(208,179)},
}
local InvisChars = {string.char(226,128,139), string.char(226,128,140), string.char(226,128,141), string.char(226,128,138)}

local function BypassText(text)
    if not text or #text == 0 then return text end
    local r, ic = "", 0
    for i = 1, #text do
        local ch = text:sub(i, i)
        local lo = ch:lower()
        if HomoglyphMap[lo] and math.random(1, 5) <= 2 then
            local g = HomoglyphMap[lo]; r = r .. g[math.random(1, #g)]
        else r = r .. ch end
        ic = ic + 1
        if ic >= math.random(2, 4) and i < #text and ch ~= " " then
            r = r .. InvisChars[math.random(1, #InvisChars)]; ic = 0
        end
    end
    return r
end

local function SendNotification(title, text, dur)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = title or "Bot", Text = text or "", Duration = dur or 3}) end)
end

local function SendChatMessage(text)
    local now = safeTick()
    if (now - LastChatTime) < ChatRateLimit then return end
    LastChatTime = now
    pcall(function()
        if TextChatService then
            local ch = TextChatService:FindFirstChild("TextChannels")
            if ch then local g = ch:FindFirstChild("RBXGeneral"); if g then g:SendAsync(text); return end end
        end
        local ce = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if ce then local sm = ce:FindFirstChild("SayMessageRequest"); if sm then sm:FireServer(text, "All") end end
    end)
end

local function SendWhisperMessage(tp, text)
    if not tp then return end
    pcall(function()
        if TextChatService then
            local ch = TextChatService:FindFirstChild("TextChannels")
            if ch then
                for _, c in ipairs(ch:GetChildren()) do
                    if c.Name:find("RBXWhisper") and c.Name:find(tostring(tp.UserId)) then c:SendAsync(text); return end
                end
                local g = ch:FindFirstChild("RBXGeneral")
                if g then g:SendAsync("/w " .. tp.Name .. " " .. text); return end
            end
        end
        local ce = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if ce then local sm = ce:FindFirstChild("SayMessageRequest"); if sm then sm:FireServer("/w " .. tp.Name .. " " .. text, "All") end end
    end)
end

local function Respond(msg, wt, fc)
    SendNotification("Bot", msg, 3)
    if wt then pcall(function() SendWhisperMessage(wt, BypassText(msg)) end)
    elseif fc then pcall(function() SendChatMessage(BypassText(msg)) end) end
end
local function RespondPrivate(msg, tp) SendNotification("Bot", msg, 5); if tp then pcall(function() SendWhisperMessage(tp, BypassText(msg)) end) end end
local function RespondError(msg, wt) SendNotification("Bot Error", msg, 4); if wt then pcall(function() SendWhisperMessage(wt, BypassText(msg)) end) end end

local function GetPermLevel(p)
    if not p then return 0 end
    if p.Name:lower() == SuperOwner:lower() then return 4 end
    local s = PermittedUsers[p.Name:lower()] or 0
    if BotMode == "public" and s < 1 then return 1 end
    return s
end
local function HasPermission(p, cmd)
    local pl = GetPermLevel(p)
    return pl >= (CommandPermissions[cmd] or 1)
end
local function IsSuperOwner(p) return p and p.Name:lower() == SuperOwner:lower() end
local function CanUseBot(p) return IsSuperOwner(p) or GetPermLevel(p) >= 1 end
local function IsOnCooldown(p)
    if IsSuperOwner(p) then return false end
    local k = p.Name:lower()
    local lu = CommandCooldowns[k]
    if lu and (safeTick() - lu) < CooldownTime then return true end
    CommandCooldowns[k] = safeTick()
    return false
end
local function SetPermission(pn, lv, sv)
    local k = pn:lower()
    if k == SuperOwner:lower() then return end
    PermittedUsers[k] = lv
    if sv then _G.__BOT_SAVED_PERMS[k] = lv; SavePermsToFile() end
end
local function RemovePermission(pn, us)
    local k = pn:lower()
    if k == SuperOwner:lower() then return end
    PermittedUsers[k] = nil
    if us then _G.__BOT_SAVED_PERMS[k] = nil; SavePermsToFile() end
end
local function IsTargetProtected(tp)
    return tp and tp.Name:lower() == SuperOwner:lower()
end

local function GetMultipleTargets(si, ep, aso)
    if not si or si == "" then return {} end
    si = si:lower():match("^%s*(.-)%s*$")
    local function fp(tgts)
        if aso then return tgts end
        local f = {}
        for _, p in ipairs(tgts) do
            if not IsTargetProtected(p) or (ep and IsSuperOwner(ep)) then f[#f+1] = p end
        end
        return f
    end
    if si == "all" then
        local t = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then t[#t+1] = p end end; return fp(t)
    elseif si == "others" then
        local t = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p ~= ep then t[#t+1] = p end end; return fp(t)
    elseif si == "team" or si == "teammates" then
        local t = {}; if ep and ep.Team then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Team == ep.Team then t[#t+1] = p end end end; return fp(t)
    elseif si == "enemies" or si == "enemy" then
        local t = {}; if ep and ep.Team then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Team ~= ep.Team then t[#t+1] = p end end end; return fp(t)
    end
    local single = nil
    if si == "me" then single = ep
    elseif si == "random" or si == "rand" then
        local pool = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then pool[#pool+1] = p end end
        if #pool > 0 then single = pool[math.random(1, #pool)] end
    elseif si == "nearest" or si == "near" or si == "closest" then
        local bh = GetBotHRP(); if bh then
            local md = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then local h = GetHRP(p); if h then local d = (h.Position - bh.Position).Magnitude; if d < md then md = d; single = p end end end
            end
        end
    elseif si == "farthest" or si == "far" then
        local bh = GetBotHRP(); if bh then
            local md = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and IsAlive(p) then local h = GetHRP(p); if h then local d = (h.Position - bh.Position).Magnitude; if d > md then md = d; single = p end end end
            end
        end
    elseif si == "murd" or si == "murderer" or si == "killer" then
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                local c = GetCharacter(p)
                if p.Backpack:FindFirstChild("Knife") or (c and c:FindFirstChild("Knife"))
                    or p.Backpack:FindFirstChild("KnifeClient") or (c and c:FindFirstChild("KnifeClient")) then
                    single = p
                end
            end)
            if single then break end
        end
    elseif si == "sherif" or si == "sheriff" or si == "sher" then
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                local c = GetCharacter(p)
                if p.Backpack:FindFirstChild("Gun") or (c and c:FindFirstChild("Gun"))
                    or p.Backpack:FindFirstChild("Revolver") or (c and c:FindFirstChild("Revolver"))
                    or p.Backpack:FindFirstChild("GunClient") or (c and c:FindFirstChild("GunClient")) then
                    single = p
                end
            end)
            if single then break end
        end
    else
        local ni = tonumber(si)
        if ni then for _, p in ipairs(Players:GetPlayers()) do if p.UserId == ni then single = p; break end end end
        if not single then
            local bm, bs = nil, 0
            for _, p in ipairs(Players:GetPlayers()) do
                local nl, dl = p.Name:lower(), p.DisplayName:lower()
                if nl == si or dl == si then single = p; bm = nil; break end
                if nl:sub(1, #si) == si or dl:sub(1, #si) == si then
                    if bs < 2 or #p.Name < (bm and #bm.Name or math.huge) then bm = p; bs = 2 end
                end
                if bs < 2 and (nl:find(si, 1, true) or dl:find(si, 1, true)) then
                    if bs < 1 or #p.Name < (bm and #bm.Name or math.huge) then bm = p; bs = 1 end
                end
            end
            single = single or bm
        end
    end
    if single then
        if not aso and IsTargetProtected(single) and not (ep and IsSuperOwner(ep)) then return {} end
        LastTarget = single; return {single}
    end
    return {}
end
local function GetSmartTarget(si, ep, aso) return GetMultipleTargets(si, ep, aso)[1] end

local function StopAllLoops()
    for n, _ in pairs(ActiveConnections) do
        if not PersistentConnections[n] then DisconnectSafe(n) end
    end
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end); FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end); FlyBodyVelocity = nil end
    local ffp = Flags.FloorFlyPlatform
    if ffp then pcall(function() ffp:Destroy() end); Flags.FloorFlyPlatform = nil end
    RemoveAntiGravity()
    Flags.IsFlying = false; Flags.IsFloorFlying = false; Flags.FloorFlyTarget = nil; Flags.IsSpinning = false
    Flags.IsCoinFarming = false; Flags.IsFarming = false; Flags.IsBlackHole = false; Flags.IsStrobing = false; Flags.IsGodKnife = false
    Flags.IsMimicking = false; Flags.IsCreeping = false; Flags.IsTrailing = false; Flags.IsDancing = false
    Flags.IsAuraActive = false; Flags.IsTracking = false; Flags.IsMagnetOn = false; Flags.IsLoopTP = false
    Flags.IsAutoShoot = false; Flags.IsAutoMurd = false; Flags.IsWallBang = false; Flags.IsFlingBusy = false; Flags.IsDestroyServer = false
    Flags.LoopTPTarget = nil; Flags.AutoShootTarget = nil; Flags.AutoMurdTarget = nil; Flags.TrackTarget = nil
    for _, pt in ipairs(CageParts) do pcall(function() pt:Destroy() end) end; CageParts = {}
    for _, pt in ipairs(TrailParts) do pcall(function() pt:Destroy() end) end; TrailParts = {}
    for _, pt in ipairs(AuraParts) do pcall(function() pt:Destroy() end) end; AuraParts = {}
    pcall(function()
        local hrp = GetBotHRP()
        if hrp then for _, o in ipairs(hrp:GetChildren()) do
            if o:IsA("BodyAngularVelocity") or o:IsA("BodyVelocity") or o:IsA("BodyGyro") or (o:IsA("BodyForce") and o.Name ~= "BotAntiGrav") then o:Destroy() end
        end end
    end)
end

local function FullCleanup()
    for n, _ in pairs(ActiveConnections) do DisconnectSafe(n) end
    for n, _ in pairs(ConnectionRegistry) do ConnectionRegistry[n] = nil end
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end); GodHealthConnection = nil end
    if GodDiedConnection then pcall(function() GodDiedConnection:Disconnect() end); GodDiedConnection = nil end
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end); FlyBodyGyro = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end); FlyBodyVelocity = nil end
    local pp = Flags.PlatformPart; if pp then pcall(function() pp:Destroy() end); Flags.PlatformPart = nil end
    local ffp = Flags.FloorFlyPlatform; if ffp then pcall(function() ffp:Destroy() end); Flags.FloorFlyPlatform = nil end
    RemoveAntiGravity()
    for _, pt in ipairs(CageParts) do pcall(function() pt:Destroy() end) end; CageParts = {}
    for _, pt in ipairs(TrailParts) do pcall(function() pt:Destroy() end) end; TrailParts = {}
    for _, pt in ipairs(AuraParts) do pcall(function() pt:Destroy() end) end; AuraParts = {}
    for _, d in ipairs(XRayParts) do pcall(function() d.part.Transparency = d.original end) end; XRayParts = {}
    for _, objs in pairs(ESPObjects) do pcall(function() if objs.highlight then objs.highlight:Destroy() end; if objs.billboard then objs.billboard:Destroy() end end) end; ESPObjects = {}
    for _, parts in pairs(FreezeCages) do for _, pt in ipairs(parts) do pcall(function() pt:Destroy() end) end end; FreezeCages = {}
    pcall(function() Workspace.Gravity = OriginalGravity end)
    pcall(function() Lighting.Ambient = OriginalLighting.Ambient; Lighting.Brightness = OriginalLighting.Brightness; Lighting.FogEnd = OriginalLighting.FogEnd; Lighting.FogStart = OriginalLighting.FogStart; Lighting.ClockTime = OriginalLighting.ClockTime; Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient end)
    pcall(function()
        local hrp = GetBotHRP(); if hrp then for _, o in ipairs(hrp:GetChildren()) do if o:IsA("BodyMover") or o:IsA("BodyForce") then o:Destroy() end end end
        local char = LocalPlayer.Character; if char then local ff = char:FindFirstChildOfClass("ForceField"); if ff then ff:Destroy() end end
    end)
    -- Reset all flags
    for k, _ in pairs(Flags) do
        if type(Flags[k]) == "boolean" then Flags[k] = false
        elseif type(Flags[k]) == "number" then Flags[k] = 0
        else Flags[k] = nil end
    end
    AutoJoinStatus.lastCheck = 0; AutoJoinStatus.lastResult = "idle"; AutoJoinStatus.attempts = 0
    AutoJoinStatus.targetFound = false; AutoJoinStatus.lastFoundServer = nil
end
genv.__ULTIMATE_BOT_CLEANUP = FullCleanup

local function PreFling()
    LockFlingStates()
    ApplyAntiGravity()
end

local function PostFling(savedPos)
    local hrp = GetBotHRP()
    if hrp then
        hrp.CFrame = savedPos
        DampenVelocity(hrp)
    end
    RemoveAntiGravity()
    local hum = GetBotHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    UnlockFlingStates()
    StabilizeCharacter()
end

local function FlingMethod1(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame
    PreFling()
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.P = 9999; bv.Parent = bh
    local ba = Instance.new("BodyAngularVelocity"); ba.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower); ba.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); ba.P = 9999; ba.Parent = bh
    local k = false
    for i = 1, (mi or 80) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        cb.CFrame = th.CFrame
        pcall(function() ApplyAntiGravity() end)
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end); pcall(function() ba:Destroy() end)
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod2(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame
    PreFling()
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(FlingPower, 0, FlingPower); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.P = 9999; bv.Parent = bh
    local ba = Instance.new("BodyAngularVelocity"); ba.AngularVelocity = Vector3.new(0, FlingPower, FlingPower); ba.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); ba.P = 9999; ba.Parent = bh
    local k = false
    local ang = {CFrame.new(0,0,0),CFrame.new(2,0,0),CFrame.new(-2,0,0),CFrame.new(0,2,0),CFrame.new(0,-2,0),CFrame.new(0,0,2),CFrame.new(0,0,-2),CFrame.new(1,1,1),CFrame.new(-1,-1,-1)}
    for i = 1, (mi or 90) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        cb.CFrame = th.CFrame * ang[(i % #ang) + 1]
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end); pcall(function() ba:Destroy() end)
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod3(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    PreFling()
    for i = 1, (mi or 60) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); local cm = GetBotHumanoid()
        if not cb or not cm then break end
        cm:ChangeState(Enum.HumanoidStateType.Physics)
        cb.CFrame = th.CFrame
        cb.AssemblyLinearVelocity = Vector3.new(math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower)
        cb.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        RunService.Heartbeat:Wait()
        cb = GetBotHRP()
        if cb then cb.CFrame = th.CFrame * CFrame.new(math.random(-1,1), math.random(-1,1), math.random(-1,1)) end
        RunService.Heartbeat:Wait()
    end
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod4(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false; local char = LocalPlayer.Character
    PreFling()
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    for i = 1, (mi or 100) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        if char then for _, pt in ipairs(char:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide = (i % 2 == 0) end end end
        local off = Vector3.new(math.cos(i*0.5)*2, math.sin(i*0.3)*2, math.sin(i*0.5)*2)
        cb.CFrame = th.CFrame * CFrame.new(off.X, off.Y, off.Z)
        cb.AssemblyLinearVelocity = (th.Position - cb.Position).Unit * FlingPower
        RunService.Heartbeat:Wait()
    end
    if char then for _, pt in ipairs(char:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide = false end end end
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod5(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    PreFling()
    local seat = Instance.new("Seat"); seat.Size = Vector3.new(1,1,1); seat.Transparency = 1; seat.CanCollide = false; seat.Anchored = false; seat.Name = "FlingSeat"; seat.Parent = Workspace
    for i = 1, (mi or 70) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        seat.CFrame = th.CFrame
        seat.AssemblyLinearVelocity = Vector3.new(math.random(-1,1)*FlingPower, FlingPower, math.random(-1,1)*FlingPower)
        cb.CFrame = th.CFrame
        cb.AssemblyLinearVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        RunService.Heartbeat:Wait()
    end
    pcall(function() seat:Destroy() end)
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod6_MicroPulse(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    PreFling()
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    for i = 1, (mi or 120) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        cb.CFrame = th.CFrame * CFrame.new(math.random(-1,1)*0.5, math.random(-1,1)*0.5, math.random(-1,1)*0.5)
        local dir = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit
        cb.AssemblyLinearVelocity = dir * FlingPower
        cb.AssemblyAngularVelocity = Vector3.new(math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower)
        RunService.Heartbeat:Wait()
        cb = GetBotHRP()
        if cb then
            cb.AssemblyLinearVelocity = Vector3.zero
            cb.AssemblyAngularVelocity = Vector3.zero
        end
        cb = GetBotHRP()
        if cb and th then
            cb.CFrame = th.CFrame * CFrame.Angles(math.random()*6.28, math.random()*6.28, math.random()*6.28)
            cb.AssemblyLinearVelocity = (th.Position - cb.Position).Unit * FlingPower * 0.5
        end
        RunService.Heartbeat:Wait()
    end
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod7_MassSlam(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    local char = LocalPlayer.Character
    local origProps = {}
    PreFling()
    pcall(function()
        if char then
            for _, pt in ipairs(char:GetDescendants()) do
                if pt:IsA("BasePart") then
                    origProps[pt] = pt.CustomPhysicalProperties
                    pt.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0, 100, 100)
                end
            end
        end
    end)
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.P = 99999; bv.Parent = bh
    local ba = Instance.new("BodyAngularVelocity"); ba.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower); ba.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); ba.P = 99999; ba.Parent = bh
    for i = 1, (mi or 100) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        local angle = i * 0.8
        local ox = math.cos(angle) * 1.5
        local oz = math.sin(angle) * 1.5
        cb.CFrame = th.CFrame * CFrame.new(ox, math.sin(i*0.5), oz)
        if i % 5 == 0 then
            bv.Velocity = Vector3.new(math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower)
            ba.AngularVelocity = Vector3.new(math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower)
        end
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end); pcall(function() ba:Destroy() end)
    pcall(function()
        if char then
            for pt, props in pairs(origProps) do
                if pt and pt.Parent then
                    if props then pt.CustomPhysicalProperties = props
                    else pt.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) end
                end
            end
        end
    end)
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod8_PartProjectile(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    PreFling()
    local projectiles = {}
    for pIdx = 1, 3 do
        local proj = Instance.new("Part")
        proj.Size = Vector3.new(2, 2, 2)
        proj.Transparency = 1
        proj.CanCollide = true
        proj.Anchored = false
        proj.Massless = false
        proj.Name = "FlingProj" .. pIdx
        proj.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
        proj.Parent = Workspace
        projectiles[pIdx] = proj
    end
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    for i = 1, (mi or 90) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        cb.CFrame = th.CFrame
        cb.AssemblyLinearVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        for pIdx, proj in ipairs(projectiles) do
            if proj and proj.Parent then
                local angle = (i + pIdx * 2.09) * 0.7
                proj.CFrame = th.CFrame * CFrame.new(math.cos(angle)*1.5, math.sin(angle*0.5), math.sin(angle)*1.5)
                proj.AssemblyLinearVelocity = (th.Position - proj.Position).Unit * FlingPower
                proj.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
            end
        end
        RunService.Heartbeat:Wait()
    end
    for _, proj in ipairs(projectiles) do pcall(function() proj:Destroy() end) end
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function FlingMethod9_TouchSpam(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    local hasFTI = ExecutorInfo.HasFireTouchInterest
    PreFling()
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.P = 9999; bv.Parent = bh
    local ba = Instance.new("BodyAngularVelocity"); ba.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower); ba.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); ba.P = 9999; ba.Parent = bh
    for i = 1, (mi or 80) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        cb.CFrame = th.CFrame * CFrame.new(math.random(-1,1)*0.3, math.random(-1,1)*0.3, math.random(-1,1)*0.3)
        if hasFTI then
            pcall(function()
                firetouchinterest(cb, th, 0)
                firetouchinterest(cb, th, 1)
            end)
            local tChar = GetCharacter(tp)
            if tChar then
                for _, part in ipairs(tChar:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= th then
                        pcall(function()
                            firetouchinterest(cb, part, 0)
                            firetouchinterest(cb, part, 1)
                        end)
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end); pcall(function() ba:Destroy() end)
    PostFling(sp)
    return k or not IsAlive(tp)
end

local FlingMethods = {FlingMethod1, FlingMethod2, FlingMethod3, FlingMethod4, FlingMethod5, FlingMethod6_MicroPulse, FlingMethod7_MassSlam, FlingMethod8_PartProjectile, FlingMethod9_TouchSpam}

local function DetectAntiFling(tp)
    local score = 0
    pcall(function()
        local th = GetHRP(tp)
        if not th then return end
        if th.Anchored then score = score + 10 end
        for _, obj in ipairs(th:GetChildren()) do
            if obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("AlignPosition") then score = score + 5 end
            if obj:IsA("BodyVelocity") and obj.Velocity.Magnitude < 1 then score = score + 3 end
        end
        local tChar = GetCharacter(tp)
        if tChar then
            for _, obj in ipairs(tChar:GetDescendants()) do
                if obj:IsA("LocalScript") then
                    local n = obj.Name:lower()
                    if n:find("anti") or n:find("fling") or n:find("protect") or n:find("shield") then score = score + 8 end
                end
            end
        end
    end)
    return score
end

-- UltraFling: Combined best techniques for near-instant fling
local function UltraFling(tp, mi)
    local bh = GetBotHRP(); local bm = GetBotHumanoid()
    if not bh or not bm then return false end
    local sp = bh.CFrame; local k = false
    local char = LocalPlayer.Character
    local hasFTI = ExecutorInfo.HasFireTouchInterest
    PreFling()
    -- Heavy mass for maximum physics impact
    local origProps = {}
    pcall(function()
        if char then
            for _, pt in ipairs(char:GetDescendants()) do
                if pt:IsA("BasePart") then
                    origProps[pt] = pt.CustomPhysicalProperties
                    pt.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
                end
            end
        end
    end)
    bm:ChangeState(Enum.HumanoidStateType.Physics)
    local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.P = 99999; bv.Parent = bh
    local ba = Instance.new("BodyAngularVelocity"); ba.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower); ba.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); ba.P = 99999; ba.Parent = bh
    for i = 1, (mi or 15) do
        if not tp or not tp.Parent then break end
        if not IsAlive(tp) then k = true; break end
        local th = GetHRP(tp); if not th then break end
        local cb = GetBotHRP(); if not cb then break end
        -- Alternate overlap and orbital for maximum physics contact
        if i % 3 == 0 then
            local angle = i * 0.8
            cb.CFrame = th.CFrame * CFrame.new(math.cos(angle)*1.2, math.sin(i*0.5)*0.5, math.sin(angle)*1.2)
        else
            cb.CFrame = th.CFrame * CFrame.new(math.random(-1,1)*0.3, math.random(-1,1)*0.3, math.random(-1,1)*0.3)
        end
        if i % 4 == 0 then
            bv.Velocity = Vector3.new(math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower)
            ba.AngularVelocity = Vector3.new(math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower, math.random(-1,1)*FlingPower)
        end
        cb.AssemblyLinearVelocity = (th.Position - cb.Position).Unit * FlingPower
        cb.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
        -- firetouchinterest for guaranteed contact if executor supports it
        if hasFTI then
            pcall(function()
                firetouchinterest(cb, th, 0)
                firetouchinterest(cb, th, 1)
            end)
            local tChar = GetCharacter(tp)
            if tChar then
                for _, part in ipairs(tChar:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= th then
                        pcall(function() firetouchinterest(cb, part, 0); firetouchinterest(cb, part, 1) end)
                    end
                end
            end
        end
        pcall(function() ApplyAntiGravity() end)
        RunService.Heartbeat:Wait()
    end
    pcall(function() bv:Destroy() end); pcall(function() ba:Destroy() end)
    pcall(function()
        if char then
            for pt, props in pairs(origProps) do
                if pt and pt.Parent then
                    if props then pt.CustomPhysicalProperties = props
                    else pt.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) end
                end
            end
        end
    end)
    PostFling(sp)
    return k or not IsAlive(tp)
end

local function ExecuteSmartFling(tp)
    local ws = safeTick()
    -- Short timeout: flings are now near-instant
    while Flags.IsFlingBusy do task.wait(0.05); if safeTick() - ws > 2 then return end end
    Flags.IsFlingBusy = true
    pcall(function()
        if not tp or not tp.Parent or not IsAlive(tp) then return end
        -- If user set a preferred method, use it with low iterations
        if Flags.PreferredFlingMethod > 0 and Flags.PreferredFlingMethod <= #FlingMethods then
            if FlingMethods[Flags.PreferredFlingMethod](tp, 15) then return end
        end
        -- Try UltraFling first (combines all best techniques, ~15 frames)
        if UltraFling(tp, 15) then return end
        -- If target survived, try focused fallbacks
        if not tp or not tp.Parent or not IsAlive(tp) then return end
        if not IsBotAlive() then task.wait(0.3); EnsureCharacter(); task.wait(0.2) end
        local afScore = DetectAntiFling(tp)
        if afScore >= 5 then
            -- Anti-fling detected: MicroPulse then TouchSpam
            if FlingMethods[6] and FlingMethods[6](tp, 20) then return end
            if tp and tp.Parent and IsAlive(tp) and FlingMethods[9] then FlingMethods[9](tp, 20) end
        else
            -- Normal target: burst then MassSlam
            if FlingMethods[3] and FlingMethods[3](tp, 15) then return end
            if tp and tp.Parent and IsAlive(tp) and FlingMethods[7] then FlingMethods[7](tp, 15) end
        end
    end)
    Flags.IsFlingBusy = false
end

local function ExecuteTargetedFling(tp)
    local ws = safeTick()
    while Flags.IsFlingBusy do task.wait(0.05); if safeTick() - ws > 2 then return end end
    Flags.IsFlingBusy = true
    local ok, err = pcall(function()
        if not tp or not tp.Parent or not IsAlive(tp) then return end
        local bh = GetBotHRP(); local bm = GetBotHumanoid()
        if not bh or not bm then return end
        local sp = bh.CFrame
        PreFling()
        bm:ChangeState(Enum.HumanoidStateType.Physics)
        local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.P = 9999; bv.Parent = bh
        local ba = Instance.new("BodyAngularVelocity"); ba.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower); ba.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); ba.P = 9999; ba.Parent = bh
        for i = 1, 15 do
            if not tp or not tp.Parent or not IsAlive(tp) then break end
            local th = GetHRP(tp); if not th then break end
            local cb = GetBotHRP(); if not cb then break end
            local nn = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p ~= tp and IsAlive(p) then
                    local ph = GetHRP(p)
                    if ph and th and (ph.Position - th.Position).Magnitude < 4 then nn = true; break end
                end
            end
            if nn then RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
            else cb.CFrame = th.CFrame end
            RunService.Heartbeat:Wait()
        end
        pcall(function() bv:Destroy() end); pcall(function() ba:Destroy() end)
        PostFling(sp)
    end)
    Flags.IsFlingBusy = false
end

local BringPlayer
BringPlayer = function(target, cd)
    if not target then return end
    task.spawn(function()
        pcall(function()
            local bh = GetBotHRP(); local bm = GetBotHumanoid()
            if not bh or not bm then return end
            local sp = cd or bh.CFrame
            local wg = Flags.IsGodMode
            if not wg then pcall(function() bm.MaxHealth = math.huge; bm.Health = math.huge end) end
            bm:ChangeState(Enum.HumanoidStateType.Physics)
            for i = 1, BringIterations do
                local th = GetHRP(target); local b = GetBotHRP()
                if not th or not b or not target.Parent then break end
                if (th.Position - sp.Position).Magnitude < 5 then break end
                b.CFrame = th.CFrame; RunService.Heartbeat:Wait()
                b = GetBotHRP(); if b then b.CFrame = sp end
            end
            local rh = GetBotHumanoid(); if rh then rh:ChangeState(Enum.HumanoidStateType.GettingUp) end
            if not wg then pcall(function() local h = GetBotHumanoid(); if h then h.MaxHealth = 100; h.Health = 100 end end) end
        end)
    end)
end

local function StartNoClip()
    DisconnectSafe("NoClip"); Flags.IsNoClip = true
    local conn = RunService.Stepped:Connect(function()
        pcall(function()
            if Flags.IsFloorFlying then return end
            local c = LocalPlayer.Character; if not c then return end
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end
        end)
    end)
    TrackConnection("NoClip", conn)
end
local function StopNoClip() DisconnectSafe("NoClip"); Flags.IsNoClip = false end

local function StartGodMode()
    DisconnectSafe("God")
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end); GodHealthConnection = nil end
    if GodDiedConnection then pcall(function() GodDiedConnection:Disconnect() end); GodDiedConnection = nil end
    Flags.IsGodMode = true
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.MaxHealth = math.huge; hum.Health = math.huge
    GodHealthConnection = hum.HealthChanged:Connect(function() if Flags.IsGodMode and hum then hum.Health = hum.MaxHealth end end)
    local ff = char:FindFirstChildOfClass("ForceField")
    if not ff then ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = char end
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
    GodDiedConnection = hum.Died:Connect(function()
        if Flags.IsGodMode then pcall(function() hum.Health = hum.MaxHealth; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    end)
    pcall(function()
        for _, o in ipairs(char:GetDescendants()) do
            if o:IsA("Script") then local n = o.Name:lower(); if n:find("damage") or n:find("kill") or n:find("hurt") then pcall(function() o:Destroy() end) end end
        end
    end)
    local conn = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not Flags.IsGodMode then DisconnectSafe("God"); return end
            local h = GetBotHumanoid()
            if h then
                if h.MaxHealth ~= math.huge then h.MaxHealth = math.huge end
                if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
                pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
                pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
                if h:GetState() == Enum.HumanoidStateType.Dead then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end
            local c = LocalPlayer.Character
            if c then
                if not c:FindFirstChildOfClass("ForceField") then local f = Instance.new("ForceField"); f.Visible = false; f.Parent = c end
                for _, o in ipairs(c:GetDescendants()) do
                    if o:IsA("Script") then local n = o.Name:lower(); if n:find("damage") or n:find("kill") or n:find("hurt") or n:find("knife") or n:find("gun") then pcall(function() o:Destroy() end) end end
                end
                for _, o in ipairs(c:GetDescendants()) do
                    if o:IsA("BasePart") and o.Name ~= "HumanoidRootPart" then
                        pcall(function()
                            for _, touch in ipairs(o:GetTouchingParts()) do
                                if touch.Name == "Blade" or touch.Name == "Knife" or touch.Name == "KnifeMesh" then
                                    o.CanCollide = false
                                end
                            end
                        end)
                    end
                end
            end
        end)
    end)
    TrackConnection("God", conn)
end

local function StopGodMode()
    DisconnectSafe("God")
    if GodHealthConnection then pcall(function() GodHealthConnection:Disconnect() end); GodHealthConnection = nil end
    if GodDiedConnection then pcall(function() GodDiedConnection:Disconnect() end); GodDiedConnection = nil end
    Flags.IsGodMode = false
    pcall(function()
        local c = LocalPlayer.Character; if not c then return end
        local ff = c:FindFirstChildOfClass("ForceField"); if ff then ff:Destroy() end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.MaxHealth = 100; h.Health = 100; pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, true); h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true); h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end) end
    end)
end

local function SetInvisible(state)
    pcall(function()
        local c = LocalPlayer.Character; if not c then return end
        local tr = state and 1 or 0
        for _, o in ipairs(c:GetDescendants()) do
            if o:IsA("BasePart") and o.Name ~= "HumanoidRootPart" then o.Transparency = tr
            elseif o:IsA("Decal") or o:IsA("Texture") then o.Transparency = tr
            elseif o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") then o.Enabled = not state end
        end
        for _, ac in ipairs(c:GetChildren()) do
            if ac:IsA("Accessory") then local h = ac:FindFirstChild("Handle"); if h then h.Transparency = tr; for _, m in ipairs(h:GetChildren()) do if m:IsA("SpecialMesh") then pcall(function() m.Scale = state and Vector3.zero or Vector3.one end) end end end end
        end
    end)
end

local function FreezePlayerAdvanced(target)
    if not target then return end
    if target == LocalPlayer then local h = GetBotHRP(); if h then pcall(function() h.Anchored = true end) end; return end
    local th = GetHRP(target); if not th then return end
    if FreezeCages[target] then for _, p in ipairs(FreezeCages[target]) do pcall(function() p:Destroy() end) end end
    FreezeCages[target] = {}
    local pos, sz = th.Position, 4
    local walls = {
        {s=Vector3.new(sz,sz,0.5), p=pos+Vector3.new(0,sz/2,sz/2)}, {s=Vector3.new(sz,sz,0.5), p=pos+Vector3.new(0,sz/2,-sz/2)},
        {s=Vector3.new(0.5,sz,sz), p=pos+Vector3.new(sz/2,sz/2,0)}, {s=Vector3.new(0.5,sz,sz), p=pos+Vector3.new(-sz/2,sz/2,0)},
        {s=Vector3.new(sz,0.5,sz), p=pos+Vector3.new(0,sz,0)}, {s=Vector3.new(sz,0.5,sz), p=pos+Vector3.new(0,0,0)},
    }
    for _, w in ipairs(walls) do
        pcall(function()
            local pt = Instance.new("Part"); pt.Size = w.s; pt.Position = w.p; pt.Anchored = true; pt.Material = Enum.Material.ForceField; pt.Transparency = 0.8; pt.CanCollide = true; pt.Name = "BotFreeze"; pt.Parent = Workspace
            FreezeCages[target][#FreezeCages[target]+1] = pt
        end)
    end
    task.spawn(function() if BringPlayer then BringPlayer(target, CFrame.new(pos)) end end)
end

local function UnfreezePlayerAdvanced(target)
    if not target then return end
    if target == LocalPlayer then local h = GetBotHRP(); if h then pcall(function() h.Anchored = false end) end; return end
    if FreezeCages[target] then for _, p in ipairs(FreezeCages[target]) do pcall(function() p:Destroy() end) end; FreezeCages[target] = nil end
end

local function FormatTime(s) return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), math.floor(s%60)) end

local function ViewPlayer(t) if not t then return end; local h = GetHumanoid(t); if not h then return end; if not OriginalCameraSubject then OriginalCameraSubject = Workspace.CurrentCamera.CameraSubject end; Workspace.CurrentCamera.CameraSubject = h end
local function UnviewPlayer()
    if OriginalCameraSubject then pcall(function() Workspace.CurrentCamera.CameraSubject = OriginalCameraSubject end); OriginalCameraSubject = nil
    else pcall(function() local h = GetBotHumanoid(); if h then Workspace.CurrentCamera.CameraSubject = h end end) end
end

-- NoClip no longer starts at boot — only when user explicitly enables it
-- pcall(StartNoClip)

local function ToggleAntiAFK(state)
    if state then
        DisconnectSafe("AntiAFK"); Flags.IsAntiAFK = true
        local conn
        if VirtualUser then
            conn = LocalPlayer.Idled:Connect(function()
                pcall(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame); task.wait(0.3); VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end)
            end)
        else
            conn = LocalPlayer.Idled:Connect(function() pcall(function() local h = GetBotHRP(); if h then h.CFrame = h.CFrame end end) end)
        end
        TrackConnection("AntiAFK", conn)
    else DisconnectSafe("AntiAFK"); Flags.IsAntiAFK = false end
end
pcall(function() ToggleAntiAFK(true) end)

local function StartAutoJoin(tu)
    if not TeleportService then return false end
    Flags.AutoJoinTarget = tu; Flags.IsAutoJoin = true
    _G.__BOT_SAVED_SETTINGS.AutoJoinTarget = tu; _G.__BOT_SAVED_SETTINGS.AutoJoinEnabled = true
    DisconnectSafe("AutoJoin")
    AutoJoinStatus.attempts = 0; AutoJoinStatus.lastResult = "searching"; AutoJoinStatus.targetFound = false
    -- Cache the userId once to avoid repeated lookups
    local cachedUid = nil
    task.spawn(function()
        while Flags.IsAutoJoin and Flags.AutoJoinTarget do
            pcall(function()
                AutoJoinStatus.lastCheck = safeTick()
                AutoJoinStatus.attempts = AutoJoinStatus.attempts + 1
                -- Check if target is already in our server
                local inSrv = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower() == Flags.AutoJoinTarget:lower() then inSrv = true; break end
                end
                if inSrv then
                    AutoJoinStatus.lastResult = "target is here"
                    AutoJoinStatus.targetFound = true
                    return
                end
                AutoJoinStatus.targetFound = false
                -- Resolve userId (cache it after first success)
                if not cachedUid then
                    pcall(function()
                        local b = HttpService:JSONEncode({usernames = {Flags.AutoJoinTarget}, excludeBannedUsers = false})
                        local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
                        if doReq then
                            local r = doReq({Url = "https://users.roblox.com/v1/usernames/users", Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = b})
                            if r and r.Body then
                                local d = HttpService:JSONDecode(r.Body)
                                if d and d.data and #d.data > 0 then cachedUid = d.data[1].id end
                            end
                        end
                    end)
                end
                if not cachedUid then AutoJoinStatus.lastResult = "cant resolve user"; return end
                -- Check presence with multiple methods
                local joined = false
                pcall(function()
                    local b = HttpService:JSONEncode({userIds = {cachedUid}})
                    local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
                    if doReq then
                        local r = doReq({Url = "https://presence.roblox.com/v1/presence/users", Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = b})
                        if r and r.Body then
                            local d = HttpService:JSONDecode(r.Body)
                            if d and d.userPresences and #d.userPresences > 0 then
                                local pr = d.userPresences[1]
                                if pr.userPresenceType == 2 and pr.placeId and pr.gameId then
                                    AutoJoinStatus.lastResult = "joining server"
                                    AutoJoinStatus.lastFoundServer = pr.gameId
                                    SendNotification("AutoJoin", "Found " .. Flags.AutoJoinTarget .. "! Joining... (attempt #" .. AutoJoinStatus.attempts .. ")", 5)
                                    TeleportService:TeleportToPlaceInstance(pr.placeId, pr.gameId, LocalPlayer)
                                    joined = true
                                elseif pr.userPresenceType == 0 then
                                    AutoJoinStatus.lastResult = "target offline"
                                elseif pr.userPresenceType == 1 then
                                    AutoJoinStatus.lastResult = "target on website (not in game)"
                                elseif pr.userPresenceType == 3 then
                                    AutoJoinStatus.lastResult = "target in studio"
                                else
                                    AutoJoinStatus.lastResult = "target not joinable (presence: " .. tostring(pr.userPresenceType) .. ")"
                                end
                            end
                        end
                    end
                end)
                -- If presence API didn't work, try direct follow via TeleportService
                if not joined then
                    pcall(function()
                        local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
                        if doReq then
                            -- Try the thumbnail API to verify user exists, then follow
                            local r = doReq({Url = "https://www.roblox.com/headshot-thumbnail/json?userId=" .. cachedUid .. "&width=48&height=48", Method = "GET"})
                            if r and r.StatusCode == 200 then
                                -- User exists, try follow via TeleportToPlayer
                                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, "", LocalPlayer) end)
                            end
                        end
                    end)
                end
            end)
            -- Smart delay: shorter when target is online, longer when offline
            local delay = 20
            if AutoJoinStatus.lastResult == "target offline" then delay = 45
            elseif AutoJoinStatus.lastResult == "cant resolve user" then delay = 60
            elseif AutoJoinStatus.lastResult == "target is here" then delay = 30
            elseif AutoJoinStatus.lastResult == "joining server" then delay = 10 end
            task.wait(delay)
        end
    end)
    return true
end

local function StopAutoJoin()
    Flags.IsAutoJoin = false; Flags.AutoJoinTarget = nil
    DisconnectSafe("AutoJoin")
    _G.__BOT_SAVED_SETTINGS.AutoJoinEnabled = false; _G.__BOT_SAVED_SETTINGS.AutoJoinTarget = nil
    AutoJoinStatus.lastResult = "disabled"; AutoJoinStatus.targetFound = false
end

local function GetAutoJoinStatus()
    return {
        enabled = Flags.IsAutoJoin,
        target = Flags.AutoJoinTarget,
        lastCheck = AutoJoinStatus.lastCheck,
        lastResult = AutoJoinStatus.lastResult,
        attempts = AutoJoinStatus.attempts,
        targetFound = AutoJoinStatus.targetFound,
        lastFoundServer = AutoJoinStatus.lastFoundServer,
    }
end

pcall(function()
    if _G.__BOT_SAVED_SETTINGS.AutoJoinEnabled and _G.__BOT_SAVED_SETTINGS.AutoJoinTarget then
        task.spawn(function() task.wait(5); StartAutoJoin(_G.__BOT_SAVED_SETTINGS.AutoJoinTarget) end)
    end
end)

-- RegisterCommand: single function to register any command module properly
local function RegisterCommand(module)
    if type(module) ~= "table" or not module.Execute or not module.Name then return false end
    local name = module.Name:lower()
    -- Will be set on BotEnv after it's created, but we need the function now
    return name, module
end

local BotEnv = {
    Players = Players, RunService = RunService, UserInputService = UserInputService, StarterGui = StarterGui,
    Workspace = Workspace, Lighting = Lighting, ReplicatedStorage = ReplicatedStorage,
    TextChatService = TextChatService, TeleportService = TeleportService, HttpService = HttpService,
    MarketplaceService = MarketplaceService, VirtualUser = VirtualUser,
    LocalPlayer = LocalPlayer, SuperOwner = SuperOwner, Prefixes = Prefixes,
    ExecutorInfo = ExecutorInfo, Console = Console, safeTick = safeTick,
    FlingPower = FlingPower, LoopFlingDelay = LoopFlingDelay, FollowDistance = FollowDistance,
    OrbitRadius = OrbitRadius, OrbitSpeed = OrbitSpeed, FlySpeed = FlySpeed, SpinSpeed = SpinSpeed,
    AnnoyDelay = AnnoyDelay, BringIterations = BringIterations, ChatRateLimit = ChatRateLimit,
    BotStartTime = BotStartTime,
    GITHUB_OWNER = GITHUB_OWNER, GITHUB_REPO = GITHUB_REPO, GITHUB_BRANCH = GITHUB_BRANCH,
    GITHUB_CMD_PATH = GITHUB_CMD_PATH, GITHUB_RAW_BASE = GITHUB_RAW_BASE, GITHUB_API_BASE = GITHUB_API_BASE,
    BotMode = function() return BotMode end, SetBotMode = function(m) BotMode = m end,
    ActiveConnections = ActiveConnections, ConnectionRegistry = ConnectionRegistry,
    PersistentConnections = PersistentConnections,
    PermittedUsers = PermittedUsers, CommandPermissions = CommandPermissions,
    FlingMethods = FlingMethods, ESPObjects = ESPObjects, CageParts = CageParts,
    TrailParts = TrailParts, XRayParts = XRayParts, AuraParts = AuraParts,
    FreezeCages = FreezeCages, CommandLog = CommandLog, CommandDedup = CommandDedup,
    DEDUP_WINDOW = DEDUP_WINDOW, OriginalLighting = OriginalLighting, OriginalGravity = OriginalGravity,
    Flags = Flags,
    TrackConnection = TrackConnection, PurgeDeadConnections = PurgeDeadConnections,
    ApplyAntiGravity = ApplyAntiGravity, RemoveAntiGravity = RemoveAntiGravity,
    LockFlingStates = LockFlingStates, UnlockFlingStates = UnlockFlingStates,
    DampenVelocity = DampenVelocity, StabilizeCharacter = StabilizeCharacter,
    -- GC-free flag access: direct table read/write, no snapshot copies
    GetFlag = function(n) return Flags[n] end,
    SetFlag = function(n, v) Flags[n] = v end,
    GetCharacter=GetCharacter, GetHRP=GetHRP, GetHumanoid=GetHumanoid, IsAlive=IsAlive,
    IsBotAlive=IsBotAlive, GetBotHRP=GetBotHRP, GetBotHumanoid=GetBotHumanoid, EnsureCharacter=EnsureCharacter,
    GetSmartTarget=GetSmartTarget, GetMultipleTargets=GetMultipleTargets,
    DisconnectSafe=DisconnectSafe, StopAllLoops=StopAllLoops, FullCleanup=FullCleanup,
    SendChatMessage=SendChatMessage, SendWhisperMessage=SendWhisperMessage, BypassText=BypassText,
    Respond=Respond, RespondError=RespondError, RespondPrivate=RespondPrivate, SendNotification=SendNotification,
    ExecuteSmartFling=ExecuteSmartFling, ExecuteTargetedFling=ExecuteTargetedFling, BringPlayer=BringPlayer,
    StartNoClip=StartNoClip, StopNoClip=StopNoClip, StartGodMode=StartGodMode, StopGodMode=StopGodMode,
    SetInvisible=SetInvisible, FreezePlayerAdvanced=FreezePlayerAdvanced, UnfreezePlayerAdvanced=UnfreezePlayerAdvanced,
    FormatTime=FormatTime, ViewPlayer=ViewPlayer, UnviewPlayer=UnviewPlayer, ToggleAntiAFK=ToggleAntiAFK,
    SetPermission=SetPermission, RemovePermission=RemovePermission, GetPermLevel=GetPermLevel,
    HasPermission=HasPermission, IsSuperOwner=IsSuperOwner, CanUseBot=CanUseBot, IsOnCooldown=IsOnCooldown,
    IsTargetProtected=IsTargetProtected, StartAutoJoin=StartAutoJoin, StopAutoJoin=StopAutoJoin,
    GetAutoJoinStatus=GetAutoJoinStatus, AutoJoinStatus=AutoJoinStatus,
    PreFling=PreFling, PostFling=PostFling,
    -- Mark a connection as persistent (survives ?bot stop)
    MarkPersistent = function(name) PersistentConnections[name] = true end,
    UnmarkPersistent = function(name) PersistentConnections[name] = nil end,
    CommandRegistry = {}, AliasMap = {}, GameModules = {},
}

-- RegisterCommand: single function to properly register any command module
-- Use this instead of manually setting CommandRegistry + AliasMap + CommandPermissions
BotEnv.RegisterCommand = function(module)
    if type(module) ~= "table" or not module.Execute or not module.Name then return false end
    local name = module.Name:lower()
    BotEnv.CommandRegistry[name] = module
    BotEnv.CommandPermissions[name] = module.Permission or 1
    if module.Aliases and type(module.Aliases) == "table" then
        for _, a in ipairs(module.Aliases) do
            local al = a:lower()
            BotEnv.AliasMap[al] = name
            BotEnv.CommandPermissions[al] = module.Permission or 1
        end
    end
    return true
end

return BotEnv
