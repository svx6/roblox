local MM2 = {}

local IsDetected = false
local RoleCache = {}
local AutoGodEnabled = false
local AutoGunEnabled = false
local MM2LoopActive = false
local GunDropWatcher = nil
local KnifeDodgeConn = nil
local LastRoleCheck = 0
local ROLE_CHECK_INTERVAL = 2

local function DetectMM2()
    local detected = false
    pcall(function()
        if game.PlaceId == 142823291 then detected = true; return end
        local ws = game:GetService("Workspace")
        if ws:FindFirstChild("GunDrop") then detected = true; return end
        if ws:FindFirstChild("Knife") then detected = true; return end
        local rs = game:GetService("ReplicatedStorage")
        if rs:FindFirstChild("Remotes") then
            if rs.Remotes:FindFirstChild("Gameplay") then detected = true; return end
        end
        if rs:FindFirstChild("GameTable") then detected = true; return end
        local sg = game:GetService("StarterGui")
        for _, g in ipairs(sg:GetDescendants()) do
            if g.Name == "MainGUI" or g.Name == "ShopFrame" or g.Name == "RoleReveal" then detected = true; return end
        end
    end)
    return detected
end

local function GetPlayerRole(player, BotEnv)
    if not player then return "innocent" end
    local role = "innocent"
    pcall(function()
        local bp = player:FindFirstChild("Backpack")
        local ch = BotEnv.GetCharacter(player)
        local hasKnife = false
        local hasGun = false
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                local tn = t.Name:lower()
                if tn == "knife" or tn == "knifeclient" then hasKnife = true end
                if tn == "gun" or tn == "gunclient" or tn == "revolver" then hasGun = true end
            end
        end
        if ch then
            for _, t in ipairs(ch:GetChildren()) do
                local tn = t.Name:lower()
                if tn == "knife" or tn == "knifeclient" then hasKnife = true end
                if tn == "gun" or tn == "gunclient" or tn == "revolver" then hasGun = true end
            end
        end
        if hasKnife then role = "murderer" end
        if hasGun then role = "sheriff" end
    end)
    return role
end

local safeTick = tick or os.clock or function() return 0 end

local function ScanAllRoles(BotEnv)
    local now = safeTick()
    if (now - LastRoleCheck) < ROLE_CHECK_INTERVAL then return RoleCache end
    LastRoleCheck = now
    RoleCache = {}
    pcall(function()
        for _, p in ipairs(BotEnv.Players:GetPlayers()) do
            RoleCache[p] = GetPlayerRole(p, BotEnv)
        end
    end)
    return RoleCache
end

local function FindMurderer(BotEnv)
    local roles = ScanAllRoles(BotEnv)
    for p, r in pairs(roles) do if r == "murderer" then return p end end
    return nil
end

local function FindSheriff(BotEnv)
    local roles = ScanAllRoles(BotEnv)
    for p, r in pairs(roles) do if r == "sheriff" then return p end end
    return nil
end

local function GetMyRole(BotEnv)
    return GetPlayerRole(BotEnv.LocalPlayer, BotEnv)
end

local function StartMM2AutoGod(BotEnv)
    if AutoGodEnabled then return end
    AutoGodEnabled = true
    BotEnv.DisconnectSafe("MM2AutoGod")
    if not BotEnv.GetFlag("IsGodMode") then
        pcall(BotEnv.StartGodMode)
    end
    local conn = BotEnv.RunService.Heartbeat:Connect(function()
        pcall(function()
            if not AutoGodEnabled then BotEnv.DisconnectSafe("MM2AutoGod"); return end
            local hum = BotEnv.GetBotHumanoid()
            if not hum then return end
            if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
            if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
            local char = BotEnv.LocalPlayer.Character
            if char then
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("Script") then
                        local n = obj.Name:lower()
                        if n:find("kill") or n:find("damage") or n:find("hurt") or n:find("knife") or n:find("stab") then
                            pcall(function() obj:Destroy() end)
                        end
                    end
                end
                if not char:FindFirstChildOfClass("ForceField") then
                    local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = char
                end
            end
            local hrp = BotEnv.GetBotHRP()
            if hrp then
                local murderer = FindMurderer(BotEnv)
                if murderer and BotEnv.IsAlive(murderer) then
                    local mHRP = BotEnv.GetHRP(murderer)
                    if mHRP then
                        local dist = (mHRP.Position - hrp.Position).Magnitude
                        if dist < 12 then
                            for _, part in ipairs(char and char:GetDescendants() or {}) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                            end
                        end
                    end
                end
            end
        end)
    end)
    BotEnv.TrackConnection("MM2AutoGod", conn)
end

local function StopMM2AutoGod(BotEnv)
    AutoGodEnabled = false
    BotEnv.DisconnectSafe("MM2AutoGod")
end

local function StartMM2AutoGun(BotEnv)
    if AutoGunEnabled then return end
    AutoGunEnabled = true
    BotEnv.DisconnectSafe("MM2AutoGun")
    local conn = BotEnv.RunService.Heartbeat:Connect(function()
        pcall(function()
            if not AutoGunEnabled then BotEnv.DisconnectSafe("MM2AutoGun"); return end
            local ws = game:GetService("Workspace")
            local gunDrop = ws:FindFirstChild("GunDrop")
            if gunDrop then
                local hrp = BotEnv.GetBotHRP()
                if hrp and gunDrop:IsA("BasePart") then
                    local dist = (gunDrop.Position - hrp.Position).Magnitude
                    if dist > 5 then
                        hrp.CFrame = gunDrop.CFrame + Vector3.new(0, 2, 0)
                    end
                    pcall(function()
                        if BotEnv.ExecutorInfo.HasFireTouchInterest then
                            firetouchinterest(hrp, gunDrop, 0)
                            task.wait()
                            firetouchinterest(hrp, gunDrop, 1)
                        end
                    end)
                end
            end
            for _, obj in ipairs(ws:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver")) then
                    local handle = obj:FindFirstChild("Handle")
                    if handle then
                        local hrp = BotEnv.GetBotHRP()
                        if hrp then
                            local dist = (handle.Position - hrp.Position).Magnitude
                            if dist > 5 then
                                hrp.CFrame = handle.CFrame + Vector3.new(0, 2, 0)
                            end
                            pcall(function()
                                if BotEnv.ExecutorInfo.HasFireTouchInterest then
                                    firetouchinterest(hrp, handle, 0)
                                    task.wait()
                                    firetouchinterest(hrp, handle, 1)
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end)
    BotEnv.TrackConnection("MM2AutoGun", conn)
end

local function StopMM2AutoGun(BotEnv)
    AutoGunEnabled = false
    BotEnv.DisconnectSafe("MM2AutoGun")
end

local function FlingMurderer(BotEnv)
    local m = FindMurderer(BotEnv)
    if m then
        task.spawn(function() BotEnv.ExecuteSmartFling(m) end)
        return m
    end
    return nil
end

local function FlingSheriff(BotEnv)
    local s = FindSheriff(BotEnv)
    if s then
        task.spawn(function() BotEnv.ExecuteSmartFling(s) end)
        return s
    end
    return nil
end

function MM2.Setup(BotEnv)
    IsDetected = DetectMM2()
    if not IsDetected then return end

    BotEnv.MM2 = {
        IsDetected = function() return IsDetected end,
        FindMurderer = function() return FindMurderer(BotEnv) end,
        FindSheriff = function() return FindSheriff(BotEnv) end,
        GetMyRole = function() return GetMyRole(BotEnv) end,
        ScanRoles = function() return ScanAllRoles(BotEnv) end,
        StartAutoGod = function() StartMM2AutoGod(BotEnv) end,
        StopAutoGod = function() StopMM2AutoGod(BotEnv) end,
        StartAutoGun = function() StartMM2AutoGun(BotEnv) end,
        StopAutoGun = function() StopMM2AutoGun(BotEnv) end,
        FlingMurderer = function() return FlingMurderer(BotEnv) end,
        FlingSheriff = function() return FlingSheriff(BotEnv) end,
        AutoGodEnabled = function() return AutoGodEnabled end,
        AutoGunEnabled = function() return AutoGunEnabled end,
    }

    BotEnv.CommandRegistry["mm2god"] = {
        Name = "mm2god", Category = "mm2", Permission = 2, Aliases = {"murdgod", "mm2autogod"},
        Execute = function(env, args, executor, restArgs)
            if AutoGodEnabled then StopMM2AutoGod(env); env.Respond("MM2 AutoGod OFF") else StartMM2AutoGod(env); env.Respond("MM2 AutoGod ON") end
        end,
    }
    BotEnv.AliasMap["murdgod"] = "mm2god"
    BotEnv.AliasMap["mm2autogod"] = "mm2god"
    BotEnv.CommandPermissions["mm2god"] = 2
    BotEnv.CommandPermissions["murdgod"] = 2
    BotEnv.CommandPermissions["mm2autogod"] = 2

    BotEnv.CommandRegistry["mm2autogun"] = {
        Name = "mm2autogun", Category = "mm2", Permission = 2, Aliases = {"autogun", "autograb", "grabgun"},
        Execute = function(env, args, executor, restArgs)
            if AutoGunEnabled then StopMM2AutoGun(env); env.Respond("MM2 AutoGun OFF") else StartMM2AutoGun(env); env.Respond("MM2 AutoGun ON") end
        end,
    }
    BotEnv.AliasMap["autogun"] = "mm2autogun"
    BotEnv.AliasMap["autograb"] = "mm2autogun"
    BotEnv.AliasMap["grabgun"] = "mm2autogun"
    BotEnv.CommandPermissions["mm2autogun"] = 2
    BotEnv.CommandPermissions["autogun"] = 2
    BotEnv.CommandPermissions["autograb"] = 2
    BotEnv.CommandPermissions["grabgun"] = 2

    BotEnv.CommandRegistry["flingmurd"] = {
        Name = "flingmurd", Category = "mm2", Permission = 1, Aliases = {"flingmurderer", "flingkiller", "fm"},
        Execute = function(env, args, executor, restArgs)
            local m = FlingMurderer(env)
            if m then env.Respond("Flinging murderer: " .. m.Name) else env.RespondError("No murderer found") end
        end,
    }
    BotEnv.AliasMap["flingmurderer"] = "flingmurd"
    BotEnv.AliasMap["flingkiller"] = "flingmurd"
    BotEnv.AliasMap["fm"] = "flingmurd"
    BotEnv.CommandPermissions["flingmurd"] = 1
    BotEnv.CommandPermissions["flingmurderer"] = 1
    BotEnv.CommandPermissions["flingkiller"] = 1
    BotEnv.CommandPermissions["fm"] = 1

    BotEnv.CommandRegistry["flingsheriff"] = {
        Name = "flingsheriff", Category = "mm2", Permission = 1, Aliases = {"flingsherif", "flingcop", "fs"},
        Execute = function(env, args, executor, restArgs)
            local s = FlingSheriff(env)
            if s then env.Respond("Flinging sheriff: " .. s.Name) else env.RespondError("No sheriff found") end
        end,
    }
    BotEnv.AliasMap["flingsherif"] = "flingsheriff"
    BotEnv.AliasMap["flingcop"] = "flingsheriff"
    BotEnv.AliasMap["fs"] = "flingsheriff"
    BotEnv.CommandPermissions["flingsheriff"] = 1
    BotEnv.CommandPermissions["flingsherif"] = 1
    BotEnv.CommandPermissions["flingcop"] = 1
    BotEnv.CommandPermissions["fs"] = 1

    BotEnv.CommandRegistry["mm2role"] = {
        Name = "mm2role", Category = "mm2", Permission = 1, Aliases = {"role", "roles", "whorole"},
        Execute = function(env, args, executor, restArgs)
            local roles = ScanAllRoles(env)
            local lines = {"MM2 Roles:"}
            for p, r in pairs(roles) do
                if r ~= "innocent" then lines[#lines+1] = "  " .. p.Name .. " = " .. r:upper() end
            end
            if #lines == 1 then lines[#lines+1] = "  No special roles detected" end
            env.Respond(table.concat(lines, "\n"))
        end,
    }
    BotEnv.AliasMap["role"] = "mm2role"
    BotEnv.AliasMap["roles"] = "mm2role"
    BotEnv.AliasMap["whorole"] = "mm2role"
    BotEnv.CommandPermissions["mm2role"] = 1
    BotEnv.CommandPermissions["role"] = 1
    BotEnv.CommandPermissions["roles"] = 1
    BotEnv.CommandPermissions["whorole"] = 1

    BotEnv.CommandRegistry["mm2status"] = {
        Name = "mm2status", Category = "mm2", Permission = 1, Aliases = {"mm2info", "mm2stat"},
        Execute = function(env, args, executor, restArgs)
            local myRole = GetMyRole(env)
            local m = FindMurderer(env)
            local s = FindSheriff(env)
            local lines = {
                "MM2 Status:",
                "  Your Role: " .. myRole:upper(),
                "  Murderer: " .. (m and m.Name or "???"),
                "  Sheriff: " .. (s and s.Name or "???"),
                "  AutoGod: " .. (AutoGodEnabled and "ON" or "OFF"),
                "  AutoGun: " .. (AutoGunEnabled and "ON" or "OFF"),
            }
            env.Respond(table.concat(lines, "\n"))
        end,
    }
    BotEnv.AliasMap["mm2info"] = "mm2status"
    BotEnv.AliasMap["mm2stat"] = "mm2status"
    BotEnv.CommandPermissions["mm2status"] = 1
    BotEnv.CommandPermissions["mm2info"] = 1
    BotEnv.CommandPermissions["mm2stat"] = 1

    BotEnv.SendNotification("MM2 Detected", "Murder Mystery 2 commands loaded\nAutoGod + AutoGun + FlingMurd + FlingSheriff", 6)
end

return MM2
