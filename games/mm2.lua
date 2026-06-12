local MM2 = {}

local IsDetected = false
local RoleCache = {}
local AutoGodEnabled = false
local AutoGunEnabled = false
local FarmCoinsEnabled = false
local FarmXPTarget = nil
local FarmXPActive = false
local MM2LoopActive = false
local GunDropWatcher = nil
local KnifeDodgeConn = nil
local LastRoleCheck = 0
local ROLE_CHECK_INTERVAL = 2

local safeTick = tick or os.clock or function() return 0 end

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

----------------------------------------------------------------------
-- AUTOGUN: Fixed using the same CFrame+Physics approach as yeet/fling
-- Teleports bot to the gun, uses BodyVelocity spin to touch it,
-- then equips it from backpack
----------------------------------------------------------------------
local function StartMM2AutoGun(BotEnv)
    if AutoGunEnabled then return end
    AutoGunEnabled = true
    BotEnv.DisconnectSafe("MM2AutoGun")

    task.spawn(function()
        while AutoGunEnabled do
            pcall(function()
                if not AutoGunEnabled then return end
                local ws = game:GetService("Workspace")
                local botHRP = BotEnv.GetBotHRP()
                local botHum = BotEnv.GetBotHumanoid()
                if not botHRP or not botHum then return end

                -- Find any gun drop in workspace
                local gunPart = nil
                local gunDrop = ws:FindFirstChild("GunDrop")
                if gunDrop and gunDrop:IsA("BasePart") then
                    gunPart = gunDrop
                end
                -- Also check for loose gun tools
                if not gunPart then
                    for _, obj in ipairs(ws:GetChildren()) do
                        if obj:IsA("Tool") then
                            local nm = obj.Name:lower()
                            if nm:find("gun") or nm:find("revolver") then
                                local handle = obj:FindFirstChild("Handle")
                                if handle then gunPart = handle; break end
                            end
                        end
                    end
                end
                -- Also check models that contain gun
                if not gunPart then
                    for _, obj in ipairs(ws:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local nm = obj.Name:lower()
                            if (nm == "gundrop" or nm == "gun" or nm == "revolver") and not obj:IsDescendantOf(BotEnv.LocalPlayer.Character or game) then
                                gunPart = obj; break
                            end
                        end
                    end
                end

                if gunPart then
                    -- Save position
                    local savedPos = botHRP.CFrame

                    -- Use the yeet/fling proven method: Physics state + BodyVelocity + CFrame spam
                    botHum:ChangeState(Enum.HumanoidStateType.Physics)

                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.P = 9999
                    bv.Parent = botHRP

                    local bav = Instance.new("BodyAngularVelocity")
                    bav.AngularVelocity = Vector3.new(50, 100, 50)
                    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bav.P = 9999
                    bav.Parent = botHRP

                    -- CFrame spam onto the gun like fling does to target
                    local offsets = {
                        CFrame.new(0, 0, 0), CFrame.new(0, -1, 0), CFrame.new(0, 1, 0),
                        CFrame.new(1, 0, 0), CFrame.new(-1, 0, 0), CFrame.new(0, 0, 1),
                        CFrame.new(0, 0, -1), CFrame.new(0, -2, 0),
                    }

                    for i = 1, 40 do
                        if not AutoGunEnabled then break end
                        local curGun = gunPart
                        -- Re-check if gun still exists
                        if not curGun or not curGun.Parent then break end
                        local cb = BotEnv.GetBotHRP()
                        if not cb then break end

                        -- Teleport directly onto gun with offset cycling
                        cb.CFrame = curGun.CFrame * offsets[(i % #offsets) + 1]
                        cb.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                        -- Also try touch interest if available
                        pcall(function()
                            if BotEnv.ExecutorInfo.HasFireTouchInterest then
                                firetouchinterest(cb, curGun, 0)
                                task.wait()
                                firetouchinterest(cb, curGun, 1)
                            end
                        end)

                        BotEnv.RunService.Heartbeat:Wait()
                    end

                    pcall(function() bv:Destroy() end)
                    pcall(function() bav:Destroy() end)

                    -- Try to equip gun from backpack
                    pcall(function()
                        local bp = BotEnv.LocalPlayer:FindFirstChild("Backpack")
                        if bp then
                            for _, tool in ipairs(bp:GetChildren()) do
                                if tool:IsA("Tool") then
                                    local tn = tool.Name:lower()
                                    if tn:find("gun") or tn:find("revolver") then
                                        local char = BotEnv.LocalPlayer.Character
                                        if char then
                                            tool.Parent = char
                                        end
                                    end
                                end
                            end
                        end
                    end)

                    -- Return to saved position
                    local resetHRP = BotEnv.GetBotHRP()
                    if resetHRP then
                        resetHRP.CFrame = savedPos
                        resetHRP.AssemblyLinearVelocity = Vector3.zero
                        resetHRP.AssemblyAngularVelocity = Vector3.zero
                    end
                    local resetHum = BotEnv.GetBotHumanoid()
                    if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function StopMM2AutoGun(BotEnv)
    AutoGunEnabled = false
    BotEnv.DisconnectSafe("MM2AutoGun")
end

----------------------------------------------------------------------
-- FARMCOINS: Slowly auto-collects coins around the map
-- Walks the bot to each coin, picks it up, moves to next
----------------------------------------------------------------------
local function StartFarmCoins(BotEnv)
    if FarmCoinsEnabled then return end
    FarmCoinsEnabled = true

    task.spawn(function()
        while FarmCoinsEnabled do
            pcall(function()
                if not FarmCoinsEnabled then return end
                local ws = game:GetService("Workspace")
                local botHRP = BotEnv.GetBotHRP()
                local botHum = BotEnv.GetBotHumanoid()
                if not botHRP or not botHum then return end

                -- Find all coin-like objects in workspace
                local coins = {}
                for _, obj in ipairs(ws:GetDescendants()) do
                    pcall(function()
                        if not obj:IsA("BasePart") then return end
                        local nm = obj.Name:lower()
                        -- MM2 coins can be named: Coin, CoinVisual, CoinModel, coin, etc.
                        if nm:find("coin") or nm:find("collectible") or nm:find("pickup") or nm:find("loot") then
                            -- Make sure it's not inside the player character
                            if not obj:IsDescendantOf(BotEnv.LocalPlayer.Character or game) then
                                coins[#coins + 1] = obj
                            end
                        end
                    end)
                end

                -- Also check for coin models (parent named coin with a child part)
                for _, obj in ipairs(ws:GetDescendants()) do
                    pcall(function()
                        if not obj:IsA("Model") then return end
                        local nm = obj.Name:lower()
                        if nm:find("coin") or nm:find("collectible") or nm:find("pickup") then
                            local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if primary then
                                coins[#coins + 1] = primary
                            end
                        end
                    end)
                end

                if #coins == 0 then return end

                -- Sort by distance (closest first for slow farming)
                local myPos = botHRP.Position
                table.sort(coins, function(a, b)
                    local da = (a.Position - myPos).Magnitude
                    local db = (b.Position - myPos).Magnitude
                    return da < db
                end)

                -- Walk to each coin slowly
                for _, coin in ipairs(coins) do
                    if not FarmCoinsEnabled then break end
                    if not coin or not coin.Parent then continue end

                    local cb = BotEnv.GetBotHRP()
                    local hum = BotEnv.GetBotHumanoid()
                    if not cb or not hum then break end

                    local coinPos = coin.Position
                    local dist = (coinPos - cb.Position).Magnitude

                    if dist > 200 then continue end -- skip coins too far

                    -- Walk towards the coin using humanoid MoveTo (slow/natural)
                    if dist > 5 then
                        hum:MoveTo(coinPos)
                        -- Wait for the walk, with timeout
                        local walkStart = safeTick()
                        while FarmCoinsEnabled do
                            cb = BotEnv.GetBotHRP()
                            if not cb then break end
                            if not coin or not coin.Parent then break end
                            local d = (coin.Position - cb.Position).Magnitude
                            if d < 5 then break end
                            if safeTick() - walkStart > 8 then break end -- timeout, move to next
                            task.wait(0.1)
                        end
                    end

                    -- Once close, CFrame spam onto the coin to collect it (same proven method)
                    cb = BotEnv.GetBotHRP()
                    if cb and coin and coin.Parent then
                        for i = 1, 10 do
                            if not FarmCoinsEnabled then break end
                            if not coin or not coin.Parent then break end
                            cb = BotEnv.GetBotHRP()
                            if not cb then break end
                            cb.CFrame = coin.CFrame + Vector3.new(0, 1, 0)
                            -- Touch interest if available
                            pcall(function()
                                if BotEnv.ExecutorInfo.HasFireTouchInterest then
                                    firetouchinterest(cb, coin, 0)
                                    task.wait()
                                    firetouchinterest(cb, coin, 1)
                                end
                            end)
                            BotEnv.RunService.Heartbeat:Wait()
                        end
                    end

                    -- Small delay between coins (slow farming)
                    task.wait(0.5)
                end
            end)
            -- Wait before scanning again
            task.wait(3)
        end
    end)
end

local function StopFarmCoins(BotEnv)
    FarmCoinsEnabled = false
end

----------------------------------------------------------------------
-- FARMXP: Yeet a target straight UP into the sky (super high)
-- Uses the same proven yeet approach but direction is pure Y-axis
----------------------------------------------------------------------
local function FarmXPYeet(BotEnv, target)
    if not target or not BotEnv.IsAlive(target) then return false end

    task.spawn(function()
        local waitStart = safeTick()
        while BotEnv.GetFlag("IsFlingBusy") do
            task.wait(0.05)
            if safeTick() - waitStart > 10 then return end
        end
        BotEnv.SetFlag("IsFlingBusy", true)
        pcall(function()
            if not target or not target.Parent or not BotEnv.IsAlive(target) then
                BotEnv.SetFlag("IsFlingBusy", false)
                return
            end

            local targetHRP = BotEnv.GetHRP(target)
            local botHRP = BotEnv.GetBotHRP()
            local botHum = BotEnv.GetBotHumanoid()
            if not targetHRP or not botHRP or not botHum then
                BotEnv.SetFlag("IsFlingBusy", false)
                return
            end

            local savedPos = botHRP.CFrame
            local FlingPower = BotEnv.FlingPower or 99999999

            -- Physics mode
            botHum:ChangeState(Enum.HumanoidStateType.Physics)

            -- BodyVelocity going STRAIGHT UP with massive power
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0, FlingPower * 5, 0)  -- pure upward, 5x power
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.P = 99999
            bv.Parent = botHRP

            -- Spin for physics contact
            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(FlingPower, FlingPower * 3, FlingPower)
            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bav.P = 99999
            bav.Parent = botHRP

            -- Heavy mass for maximum impact
            local char = BotEnv.LocalPlayer.Character
            local origProps = {}
            if char then
                for _, pt in ipairs(char:GetDescendants()) do
                    if pt:IsA("BasePart") then
                        origProps[pt] = pt.CustomPhysicalProperties
                        pt.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
                    end
                end
            end

            -- CFrame positions: directly under and around the target
            -- Hitting from below sends them UP
            local skyOffsets = {
                CFrame.new(0, -3, 0), CFrame.new(0, -4, 0), CFrame.new(0, -2, 0),
                CFrame.new(1, -3, 0), CFrame.new(-1, -3, 0), CFrame.new(0, -3, 1),
                CFrame.new(0, -3, -1), CFrame.new(0, -5, 0),
                CFrame.new(0.5, -2, 0.5), CFrame.new(-0.5, -4, -0.5),
            }

            for i = 1, 60 do
                if not target or not target.Parent then break end
                if not BotEnv.IsAlive(target) then break end
                local tHRP = BotEnv.GetHRP(target)
                if not tHRP then break end
                local cBotHRP = BotEnv.GetBotHRP()
                if not cBotHRP then break end

                -- Slam into target from below to launch them up
                cBotHRP.CFrame = tHRP.CFrame * skyOffsets[(i % #skyOffsets) + 1]
                cBotHRP.AssemblyLinearVelocity = Vector3.new(0, FlingPower * 5, 0)
                cBotHRP.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)

                -- Fire touch for guaranteed contact
                pcall(function()
                    if BotEnv.ExecutorInfo.HasFireTouchInterest then
                        firetouchinterest(cBotHRP, tHRP, 0)
                        firetouchinterest(cBotHRP, tHRP, 1)
                    end
                end)

                BotEnv.RunService.Heartbeat:Wait()
            end

            pcall(function() bv:Destroy() end)
            pcall(function() bav:Destroy() end)

            -- Restore mass
            if char then
                for pt, props in pairs(origProps) do
                    if pt and pt.Parent then
                        if props then pt.CustomPhysicalProperties = props
                        else pt.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) end
                    end
                end
            end

            -- Return bot to saved position
            local resetHRP = BotEnv.GetBotHRP()
            if resetHRP then
                resetHRP.CFrame = savedPos
                resetHRP.AssemblyLinearVelocity = Vector3.zero
                resetHRP.AssemblyAngularVelocity = Vector3.zero
            end
            local resetHum = BotEnv.GetBotHumanoid()
            if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end)
        BotEnv.SetFlag("IsFlingBusy", false)
    end)

    return true
end

----------------------------------------------------------------------
-- LOOP FARMXP: Repeatedly yeet target to the sky
----------------------------------------------------------------------
local function StartFarmXPLoop(BotEnv, target)
    if FarmXPActive then return end
    FarmXPActive = true
    FarmXPTarget = target

    task.spawn(function()
        while FarmXPActive and FarmXPTarget do
            pcall(function()
                if not FarmXPActive then return end
                local t = FarmXPTarget
                if not t or not t.Parent then
                    FarmXPActive = false
                    return
                end
                -- Wait for target to respawn if dead
                if not BotEnv.IsAlive(t) then return end
                FarmXPYeet(BotEnv, t)
            end)
            task.wait(2) -- delay between yeeting
        end
    end)
end

local function StopFarmXPLoop()
    FarmXPActive = false
    FarmXPTarget = nil
end

----------------------------------------------------------------------
-- Fling using the working yeet method (not ExecuteSmartFling)
----------------------------------------------------------------------
local function FlingMurderer(BotEnv)
    local m = FindMurderer(BotEnv)
    if m then
        -- Use the same yeet-style approach for reliable flinging
        task.spawn(function()
            local waitStart = safeTick()
            while BotEnv.GetFlag("IsFlingBusy") do
                task.wait(0.05)
                if safeTick() - waitStart > 10 then return end
            end
            BotEnv.SetFlag("IsFlingBusy", true)
            pcall(function()
                if not m or not m.Parent or not BotEnv.IsAlive(m) then
                    BotEnv.SetFlag("IsFlingBusy", false)
                    return
                end
                local targetHRP = BotEnv.GetHRP(m)
                local botHRP = BotEnv.GetBotHRP()
                local botHum = BotEnv.GetBotHumanoid()
                if not targetHRP or not botHRP or not botHum then
                    BotEnv.SetFlag("IsFlingBusy", false)
                    return
                end
                local savedPos = botHRP.CFrame
                local FlingPower = BotEnv.FlingPower or 99999999
                botHum:ChangeState(Enum.HumanoidStateType.Physics)

                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = 9999
                bv.Parent = botHRP

                local bav = Instance.new("BodyAngularVelocity")
                bav.AngularVelocity = Vector3.new(FlingPower, FlingPower * 2, FlingPower)
                bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bav.P = 9999
                bav.Parent = botHRP

                local angles = {
                    CFrame.new(0, -3, 0), CFrame.new(1, -2, 0), CFrame.new(-1, -2, 0),
                    CFrame.new(0, -2, 1), CFrame.new(0, -2, -1), CFrame.new(0, -4, 0),
                    CFrame.new(2, -3, 0), CFrame.new(-2, -3, 0),
                }
                for i = 1, 50 do
                    if not m or not m.Parent then break end
                    if not BotEnv.IsAlive(m) then break end
                    local tHRP = BotEnv.GetHRP(m)
                    if not tHRP then break end
                    local cBotHRP = BotEnv.GetBotHRP()
                    if not cBotHRP then break end
                    cBotHRP.CFrame = tHRP.CFrame * angles[(i % #angles) + 1]
                    BotEnv.RunService.Heartbeat:Wait()
                end
                pcall(function() bv:Destroy() end)
                pcall(function() bav:Destroy() end)
                local resetHRP = BotEnv.GetBotHRP()
                if resetHRP then
                    resetHRP.CFrame = savedPos
                    resetHRP.AssemblyLinearVelocity = Vector3.zero
                    resetHRP.AssemblyAngularVelocity = Vector3.zero
                end
                local resetHum = BotEnv.GetBotHumanoid()
                if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
            BotEnv.SetFlag("IsFlingBusy", false)
        end)
        return m
    end
    return nil
end

local function FlingSheriff(BotEnv)
    local s = FindSheriff(BotEnv)
    if s then
        task.spawn(function()
            local waitStart = safeTick()
            while BotEnv.GetFlag("IsFlingBusy") do
                task.wait(0.05)
                if safeTick() - waitStart > 10 then return end
            end
            BotEnv.SetFlag("IsFlingBusy", true)
            pcall(function()
                if not s or not s.Parent or not BotEnv.IsAlive(s) then
                    BotEnv.SetFlag("IsFlingBusy", false)
                    return
                end
                local targetHRP = BotEnv.GetHRP(s)
                local botHRP = BotEnv.GetBotHRP()
                local botHum = BotEnv.GetBotHumanoid()
                if not targetHRP or not botHRP or not botHum then
                    BotEnv.SetFlag("IsFlingBusy", false)
                    return
                end
                local savedPos = botHRP.CFrame
                local FlingPower = BotEnv.FlingPower or 99999999
                botHum:ChangeState(Enum.HumanoidStateType.Physics)

                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = 9999
                bv.Parent = botHRP

                local bav = Instance.new("BodyAngularVelocity")
                bav.AngularVelocity = Vector3.new(FlingPower, FlingPower * 2, FlingPower)
                bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bav.P = 9999
                bav.Parent = botHRP

                local angles = {
                    CFrame.new(0, -3, 0), CFrame.new(1, -2, 0), CFrame.new(-1, -2, 0),
                    CFrame.new(0, -2, 1), CFrame.new(0, -2, -1), CFrame.new(0, -4, 0),
                    CFrame.new(2, -3, 0), CFrame.new(-2, -3, 0),
                }
                for i = 1, 50 do
                    if not s or not s.Parent then break end
                    if not BotEnv.IsAlive(s) then break end
                    local tHRP = BotEnv.GetHRP(s)
                    if not tHRP then break end
                    local cBotHRP = BotEnv.GetBotHRP()
                    if not cBotHRP then break end
                    cBotHRP.CFrame = tHRP.CFrame * angles[(i % #angles) + 1]
                    BotEnv.RunService.Heartbeat:Wait()
                end
                pcall(function() bv:Destroy() end)
                pcall(function() bav:Destroy() end)
                local resetHRP = BotEnv.GetBotHRP()
                if resetHRP then
                    resetHRP.CFrame = savedPos
                    resetHRP.AssemblyLinearVelocity = Vector3.zero
                    resetHRP.AssemblyAngularVelocity = Vector3.zero
                end
                local resetHum = BotEnv.GetBotHumanoid()
                if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
            BotEnv.SetFlag("IsFlingBusy", false)
        end)
        return s
    end
    return nil
end

----------------------------------------------------------------------
-- SETUP: Register all MM2 commands
----------------------------------------------------------------------
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
        FarmCoinsEnabled = function() return FarmCoinsEnabled end,
        FarmXPActive = function() return FarmXPActive end,
    }

    -- mm2god command
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

    -- mm2autogun command (FIXED)
    BotEnv.CommandRegistry["mm2autogun"] = {
        Name = "mm2autogun", Category = "mm2", Permission = 2, Aliases = {"autogun", "autograb", "grabgun"},
        Execute = function(env, args, executor, restArgs)
            if AutoGunEnabled then StopMM2AutoGun(env); env.Respond("MM2 AutoGun OFF") else StartMM2AutoGun(env); env.Respond("MM2 AutoGun ON - using fling method") end
        end,
    }
    BotEnv.AliasMap["autogun"] = "mm2autogun"
    BotEnv.AliasMap["autograb"] = "mm2autogun"
    BotEnv.AliasMap["grabgun"] = "mm2autogun"
    BotEnv.CommandPermissions["mm2autogun"] = 2
    BotEnv.CommandPermissions["autogun"] = 2
    BotEnv.CommandPermissions["autograb"] = 2
    BotEnv.CommandPermissions["grabgun"] = 2

    -- flingmurd command (uses yeet method now)
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

    -- flingsheriff command (uses yeet method now)
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

    -- mm2role command
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

    -- mm2status command
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
                "  FarmCoins: " .. (FarmCoinsEnabled and "ON" or "OFF"),
                "  FarmXP: " .. (FarmXPActive and "ON" or "OFF"),
            }
            env.Respond(table.concat(lines, "\n"))
        end,
    }
    BotEnv.AliasMap["mm2info"] = "mm2status"
    BotEnv.AliasMap["mm2stat"] = "mm2status"
    BotEnv.CommandPermissions["mm2status"] = 1
    BotEnv.CommandPermissions["mm2info"] = 1
    BotEnv.CommandPermissions["mm2stat"] = 1

    -- farmcoins command (NEW - slow auto coin farm)
    BotEnv.CommandRegistry["farmcoins"] = {
        Name = "farmcoins", Category = "mm2", Permission = 1, Aliases = {"coinsfarm", "autocoins", "mm2coins", "fc"},
        Execute = function(env, args, executor, restArgs)
            if FarmCoinsEnabled then
                StopFarmCoins(env)
                env.Respond("MM2 FarmCoins OFF")
            else
                StartFarmCoins(env)
                env.Respond("MM2 FarmCoins ON - slowly collecting coins")
            end
        end,
    }
    BotEnv.AliasMap["coinsfarm"] = "farmcoins"
    BotEnv.AliasMap["autocoins"] = "farmcoins"
    BotEnv.AliasMap["mm2coins"] = "farmcoins"
    BotEnv.AliasMap["fc"] = "farmcoins"
    BotEnv.CommandPermissions["farmcoins"] = 1
    BotEnv.CommandPermissions["coinsfarm"] = 1
    BotEnv.CommandPermissions["autocoins"] = 1
    BotEnv.CommandPermissions["mm2coins"] = 1
    BotEnv.CommandPermissions["fc"] = 1

    -- farmxp command (NEW - yeet target to the sky)
    BotEnv.CommandRegistry["farmxp"] = {
        Name = "farmxp", Category = "mm2", Permission = 1, Aliases = {"skyyeet", "yeetsky", "skylaunch", "xpfarm"},
        Execute = function(env, args, executor, restArgs)
            if not args[2] then
                -- If no target given, toggle loop off
                if FarmXPActive then
                    StopFarmXPLoop()
                    env.Respond("FarmXP loop OFF")
                else
                    env.RespondError("Usage: farmxp <player> - yeets target to the sky")
                end
                return
            end
            local target = env.GetSmartTarget(args[2], executor)
            if not target then
                env.RespondError("Can't find " .. args[2])
                return
            end
            if FarmXPActive and FarmXPTarget == target then
                StopFarmXPLoop()
                env.Respond("FarmXP loop OFF for " .. target.Name)
            else
                if FarmXPActive then StopFarmXPLoop() end
                StartFarmXPLoop(env, target)
                env.Respond("FarmXP ON - yeeting " .. target.Name .. " to the sky on loop")
            end
        end,
    }
    BotEnv.AliasMap["skyyeet"] = "farmxp"
    BotEnv.AliasMap["yeetsky"] = "farmxp"
    BotEnv.AliasMap["skylaunch"] = "farmxp"
    BotEnv.AliasMap["xpfarm"] = "farmxp"
    BotEnv.CommandPermissions["farmxp"] = 1
    BotEnv.CommandPermissions["skyyeet"] = 1
    BotEnv.CommandPermissions["yeetsky"] = 1
    BotEnv.CommandPermissions["skylaunch"] = 1
    BotEnv.CommandPermissions["xpfarm"] = 1

    -- Single yeet to sky (not looped)
    BotEnv.CommandRegistry["skyshot"] = {
        Name = "skyshot", Category = "mm2", Permission = 1, Aliases = {"tosky", "launchup"},
        Execute = function(env, args, executor, restArgs)
            if not args[2] then env.RespondError("Usage: skyshot <player>"); return end
            local target = env.GetSmartTarget(args[2], executor)
            if not target then env.RespondError("Can't find " .. args[2]); return end
            if not env.IsAlive(target) then env.RespondError(target.Name .. " is not alive"); return end
            FarmXPYeet(env, target)
            env.Respond("Launched " .. target.Name .. " to the sky!")
        end,
    }
    BotEnv.AliasMap["tosky"] = "skyshot"
    BotEnv.AliasMap["launchup"] = "skyshot"
    BotEnv.CommandPermissions["skyshot"] = 1
    BotEnv.CommandPermissions["tosky"] = 1
    BotEnv.CommandPermissions["launchup"] = 1

    BotEnv.SendNotification("MM2 Detected", "Murder Mystery 2 commands loaded\nAutoGod + AutoGun(FIXED) + FlingMurd + FlingSheriff + FarmCoins + FarmXP", 6)
end

return MM2
