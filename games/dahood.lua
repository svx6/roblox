--[[
    Da Hood Game Module
    Detects Da Hood and registers game-specific commands.

    Da Hood Place IDs (main + redirects):
        2788229376  (Da Hood)

    Commands registered:
        ?bot dh           - show Da Hood command list
        ?bot daspeed [n]  - set WalkSpeed (default 80)
        ?bot dajump [n]   - set JumpPower (default 120)
        ?bot dagod        - toggle invincibility
        ?bot daanti       - toggle anti-ragdoll (stop getting knocked)
        ?bot datp <p>     - instant TP to player
        ?bot dakill <p>   - fling / kill target
        ?bot daesp        - toggle ESP highlights on all players
        ?bot dagrabs      - auto-grab nearby dropped guns / items
        ?bot darich [n]   - give yourself cash (client-side edit, may not persist)
        ?bot darun        - sprint at max speed continuously
        ?bot dastop       - stop all Da Hood loops
]]

local DaHood = {}

local DA_HOOD_IDS = {
    2788229376,   -- Da Hood (main)
    7902edelta = nil,  -- placeholder for future IDs
}
-- Fix the table (remove bad entry)
DA_HOOD_IDS = {2788229376}

function DaHood.Setup(BotEnv)
    local Players    = BotEnv.Players
    local LocalPlayer = BotEnv.LocalPlayer
    local RunService  = BotEnv.RunService
    local Workspace   = BotEnv.Workspace
    local ws          = Workspace

    local function isDaHood()
        for _, id in ipairs(DA_HOOD_IDS) do
            if game.PlaceId == id then return true end
        end
        return false
    end

    -- ── Helper: get humanoid / HRP of local player ─────────────────────────
    local function GetBotHum() return BotEnv.GetBotHumanoid() end
    local function GetBotHRP() return BotEnv.GetBotHRP()      end

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: dh / dahood — info panel
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "dh",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dahood", "dahoodcmds", "dhcmds"},
        Description = "Da Hood command list",
        Execute     = function(BE, args, exec, rest)
            BE.Respond(
                "🏙️ DA HOOD | daspeed · dajump · dagod · daanti · " ..
                "datp · dakill · daesp · dagrabs · darich · darun · dastop"
            )
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: daspeed [n]
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "daspeed",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhspeed", "daspd"},
        Description = "Set WalkSpeed in Da Hood (default 80)",
        Execute     = function(BE, args, exec, rest)
            local spd = tonumber(args[2]) or 80
            pcall(function()
                local h = GetBotHum()
                if h then h.WalkSpeed = spd end
            end)
            -- Keep setting it on respawn / character change
            BE.SetFlag("DaHoodSpeed", spd)
            BE.DisconnectSafe("DaHood_Speed")
            local conn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BE.GetFlag("DaHoodSpeed") then BE.DisconnectSafe("DaHood_Speed"); return end
                    local h = GetBotHum()
                    if h and h.WalkSpeed ~= BE.GetFlag("DaHoodSpeed") then
                        h.WalkSpeed = BE.GetFlag("DaHoodSpeed")
                    end
                end)
            end)
            BE.TrackConnection("DaHood_Speed", conn)
            BE.Respond("🏃 Speed → " .. spd)
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: dajump [n]
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "dajump",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhjump", "dajp"},
        Description = "Set JumpPower in Da Hood (default 120)",
        Execute     = function(BE, args, exec, rest)
            local jp = tonumber(args[2]) or 120
            pcall(function()
                local h = GetBotHum()
                if h then h.JumpPower = jp; h.UseJumpPower = true end
            end)
            BE.Respond("🦘 JumpPower → " .. jp)
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: dagod — toggle god mode using existing engine
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "dagod",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhgod", "dahood_god"},
        Description = "Toggle god mode in Da Hood",
        Execute     = function(BE, args, exec, rest)
            if BE.GetFlag("IsGodMode") then
                BE.StopGodMode()
                BE.Respond("💀 God Mode OFF")
            else
                BE.StartGodMode()
                BE.Respond("🛡️ God Mode ON — you can't die")
            end
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: daanti — anti-ragdoll (stop getting knocked in Da Hood)
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "daanti",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhanti", "antiknock", "noragdoll", "darag"},
        Description = "Toggle anti-ragdoll in Da Hood (prevents getting knocked)",
        Execute     = function(BE, args, exec, rest)
            if BE.GetFlag("DaAntiRag") then
                BE.SetFlag("DaAntiRag", false)
                BE.DisconnectSafe("DaHood_AntiRag")
                -- restore ragdoll states
                pcall(function()
                    local h = GetBotHum()
                    if not h then return end
                    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     true)
                    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                end)
                BE.Respond("☠️ Anti-Ragdoll OFF")
                return
            end

            BE.SetFlag("DaAntiRag", true)
            local conn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BE.GetFlag("DaAntiRag") then BE.DisconnectSafe("DaHood_AntiRag"); return end
                    local h = GetBotHum()
                    if not h then return end
                    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
                    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    h:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   true)
                    -- if currently ragdolled, force get up
                    local st = h:GetState()
                    if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                        h:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end)
            end)
            BE.TrackConnection("DaHood_AntiRag", conn)
            BE.Respond("🔒 Anti-Ragdoll ON — you won't get knocked")
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: datp <player> — instant TP
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "datp",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhtp", "dahood_tp"},
        Description = "Instant TP to player in Da Hood",
        Execute     = function(BE, args, exec, rest)
            if not args[2] then BE.RespondError("Usage: ?bot datp <player>"); return end
            local t = BE.GetSmartTarget(args[2], exec)
            if not t then BE.RespondError("Can't find: " .. args[2]); return end
            local tHRP = BE.GetHRP(t)
            local bHRP = GetBotHRP()
            if not tHRP or not bHRP then BE.RespondError("Character not loaded"); return end
            bHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
            BE.Respond("🌀 TP → " .. t.Name)
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: dakill <player> — fling kill
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "dakill",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhkill", "dahood_kill", "daelim"},
        Description = "Kill (fling) a player in Da Hood",
        Execute     = function(BE, args, exec, rest)
            if not args[2] then BE.RespondError("Usage: ?bot dakill <player>"); return end
            local t = BE.GetSmartTarget(args[2], exec)
            if not t then BE.RespondError("Can't find: " .. args[2]); return end
            task.spawn(function() BE.ExecuteSmartFling(t) end)
            BE.Respond("💥 Fling → " .. t.Name)
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: daesp — toggle ESP highlights on all players
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "daesp",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhesp", "dahood_esp", "dashowplayers"},
        Description = "Toggle ESP (player highlights + name/health) in Da Hood",
        Execute     = function(BE, args, exec, rest)
            if BE.GetFlag("DaESP") then
                BE.SetFlag("DaESP", false)
                BE.DisconnectSafe("DaHood_ESP")
                -- Destroy all highlights we made
                if BE.DaESPObjects then
                    for _, obj in pairs(BE.DaESPObjects) do
                        pcall(function()
                            if obj.hl then obj.hl:Destroy() end
                            if obj.bb then obj.bb:Destroy() end
                        end)
                    end
                    BE.DaESPObjects = {}
                end
                BE.Respond("👁️ ESP OFF")
                return
            end

            BE.SetFlag("DaESP", true)
            BE.DaESPObjects = {}

            local function AddESP(player)
                if player == LocalPlayer then return end
                if BE.DaESPObjects[player] then return end
                BE.DaESPObjects[player] = {}
                pcall(function()
                    local char = player.Character
                    if not char then return end

                    -- Highlight
                    local hl = Instance.new("SelectionBox")
                    hl.Color3 = Color3.fromHSV(math.random(), 1, 1)
                    hl.LineThickness = 0.04
                    hl.Adornee = char
                    hl.Parent  = ws
                    BE.DaESPObjects[player].hl = hl

                    -- Billboard name + health
                    local bb = Instance.new("BillboardGui")
                    bb.Size    = UDim2.new(0, 80, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    bb.Adornee = hrp or char
                    bb.AlwaysOnTop = true
                    bb.Parent = ws
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(1, 1, 1)
                    lbl.TextStrokeTransparency = 0
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextScaled = true
                    lbl.Parent = bb
                    BE.DaESPObjects[player].bb  = bb
                    BE.DaESPObjects[player].lbl = lbl
                end)
            end

            -- Initial ESP on current players
            for _, p in ipairs(Players:GetPlayers()) do pcall(function() AddESP(p) end) end

            -- Update loop: refresh names/health, add new players
            local espConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BE.GetFlag("DaESP") then BE.DisconnectSafe("DaHood_ESP"); return end
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then
                            if not BE.DaESPObjects[p] then AddESP(p) end
                            local obj = BE.DaESPObjects[p]
                            if obj and obj.lbl then
                                pcall(function()
                                    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                                    local hp  = hum and math.floor(hum.Health) or "?"
                                    local mx  = hum and math.floor(hum.MaxHealth) or "?"
                                    obj.lbl.Text = p.Name .. "\n❤️ " .. hp .. "/" .. mx
                                end)
                            end
                        end
                    end
                end)
            end)
            BE.TrackConnection("DaHood_ESP", espConn)
            BE.Respond("👁️ ESP ON — seeing all players")
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: dagrabs — auto-grab dropped guns / tools / cash nearby
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "dagrabs",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhgrabs", "dagrab", "autograbs", "autograb"},
        Description = "Auto-grab nearby dropped guns / tools / cash in Da Hood",
        Execute     = function(BE, args, exec, rest)
            if BE.GetFlag("DaAutoGrab") then
                BE.SetFlag("DaAutoGrab", false)
                BE.DisconnectSafe("DaHood_Grab")
                BE.Respond("🔫 Auto-Grab OFF")
                return
            end
            BE.SetFlag("DaAutoGrab", true)
            local grabTimer = 0
            local GRAB_INT  = 0.25

            local conn = RunService.Heartbeat:Connect(function(dt)
                pcall(function()
                    if not BE.GetFlag("DaAutoGrab") then BE.DisconnectSafe("DaHood_Grab"); return end
                    grabTimer = grabTimer + dt
                    if grabTimer < GRAB_INT then return end
                    grabTimer = 0

                    local bHRP = GetBotHRP()
                    if not bHRP then return end
                    local bPos = bHRP.Position

                    -- Scan workspace for Tools and Parts named "Cash"/"Money"/"Gun"
                    for _, obj in ipairs(ws:GetDescendants()) do
                        pcall(function()
                            local isItem = false
                            if obj:IsA("Tool") then isItem = true end
                            local n = obj.Name:lower()
                            if obj:IsA("Part") and (n:find("cash") or n:find("money") or n:find("drop")) then
                                isItem = true
                            end

                            if isItem and obj.Parent and obj.Parent ~= LocalPlayer.Character and obj.Parent ~= LocalPlayer.Backpack then
                                -- Check proximity
                                local partPos
                                if obj:IsA("Tool") then
                                    local h = obj:FindFirstChildOfClass("Part") or obj:FindFirstChild("Handle")
                                    if h then partPos = h.Position end
                                elseif obj:IsA("BasePart") then
                                    partPos = obj.Position
                                end

                                if partPos and (partPos - bPos).Magnitude < 12 then
                                    -- Try firetouchinterest if available
                                    if type(firetouchinterest) == "function" then
                                        local bParts = LocalPlayer.Character and LocalPlayer.Character:GetDescendants() or {}
                                        for _, bp in ipairs(bParts) do
                                            if bp:IsA("BasePart") then
                                                pcall(function() firetouchinterest(bp, obj, 0) end)
                                                pcall(function() firetouchinterest(bp, obj, 1) end)
                                            end
                                        end
                                    end
                                    -- Also try proximity prompt
                                    for _, pp in ipairs(obj:GetDescendants()) do
                                        if pp:IsA("ProximityPrompt") then
                                            pcall(function()
                                                local fe = game:GetService("ProximityPromptService")
                                                if fe then fe:FirePromptHoldBegin(pp) end
                                            end)
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)
            BE.TrackConnection("DaHood_Grab", conn)
            BE.Respond("🔫 Auto-Grab ON — picking up everything nearby")
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: darich [amount] — client-side cash edit (leaderstats)
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "darich",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhrich", "dacash", "damoney", "givecash"},
        Description = "Client-side cash edit in Da Hood leaderstats",
        Execute     = function(BE, args, exec, rest)
            local amount = tonumber(args[2]) or 999999
            local set = false
            pcall(function()
                local ls = LocalPlayer:FindFirstChild("leaderstats")
                if not ls then return end
                for _, v in ipairs(ls:GetChildren()) do
                    if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                        local name = v.Name:lower()
                        if name:find("cash") or name:find("money") or name:find("coin") or name:find("credit") then
                            v.Value = amount
                            set = true
                        end
                    end
                end
            end)
            if set then
                BE.Respond("💰 Cash → $" .. amount .. " (client-side)")
            else
                BE.RespondError("Couldn't find cash leaderstat — may be server-protected")
            end
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: darun — sprint continuously at max speed
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "darun",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhrun", "dasprint", "infinisprint"},
        Description = "Sprint continuously at max speed in Da Hood",
        Execute     = function(BE, args, exec, rest)
            if BE.GetFlag("DaSprint") then
                BE.SetFlag("DaSprint", false)
                BE.DisconnectSafe("DaHood_Sprint")
                pcall(function() local h = GetBotHum(); if h then h.WalkSpeed = 16 end end)
                BE.Respond("🐌 Sprint OFF")
                return
            end
            BE.SetFlag("DaSprint", true)
            local SPRINT_SPD = 100
            local conn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BE.GetFlag("DaSprint") then BE.DisconnectSafe("DaHood_Sprint"); return end
                    local h = GetBotHum()
                    if h then h.WalkSpeed = SPRINT_SPD end
                end)
            end)
            BE.TrackConnection("DaHood_Sprint", conn)
            BE.Respond("⚡ Sprint ON — speed " .. SPRINT_SPD)
        end,
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- COMMAND: dastop — stop all Da Hood loops
    -- ─────────────────────────────────────────────────────────────────────────
    BotEnv.RegisterCommand({
        Name        = "dastop",
        Category    = "dahood",
        Permission  = 1,
        Aliases     = {"dhstop", "dahood_stop", "daoff"},
        Description = "Stop all Da Hood active loops",
        Execute     = function(BE, args, exec, rest)
            -- Turn off all Da Hood flags + connections
            BE.SetFlag("DaHoodSpeed",  false)
            BE.SetFlag("DaAntiRag",    false)
            BE.SetFlag("DaESP",        false)
            BE.SetFlag("DaAutoGrab",   false)
            BE.SetFlag("DaSprint",     false)
            BE.DisconnectSafe("DaHood_Speed")
            BE.DisconnectSafe("DaHood_AntiRag")
            BE.DisconnectSafe("DaHood_ESP")
            BE.DisconnectSafe("DaHood_Grab")
            BE.DisconnectSafe("DaHood_Sprint")

            -- Cleanup ESP objects
            if BE.DaESPObjects then
                for _, obj in pairs(BE.DaESPObjects) do
                    pcall(function()
                        if obj.hl then obj.hl:Destroy() end
                        if obj.bb then obj.bb:Destroy() end
                    end)
                end
                BE.DaESPObjects = {}
            end

            -- Restore normal walkspeed
            pcall(function() local h = GetBotHum(); if h then h.WalkSpeed = 16 end end)

            BE.Respond("🛑 All Da Hood loops stopped")
        end,
    })

    -- ── Notify if detected in Da Hood ─────────────────────────────────────
    if isDaHood() then
        pcall(function()
            BotEnv.SendNotification(
                "Da Hood Detected 🏙️",
                "Commands: daspeed · dagod · daanti · daesp · dagrabs · dakill · darun",
                8
            )
        end)
    end

    print("[DaHood] Module loaded — " .. (isDaHood() and "IN DA HOOD ✓" or "not in Da Hood (commands still available)"))
end

return DaHood
