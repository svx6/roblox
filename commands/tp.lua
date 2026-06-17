--[[
    Command: tp
    Category: movement
    Permission: 1
    Usage: ?bot tp <player>          → teleport + start shadowing
           ?bot tp                   → stop shadowing
    Aliases: teleport, tpfollow, shadow, follow, stalk, tpme, ghostfollow
    Description: Ghost Follow TP — teleports to a player with a cinematic
                 void burst + streak then LOCKS the bot 2.5 studs behind
                 them continuously. Type ?bot tp (no player) to stop.
]]
return {
    Name        = "tp",
    Category    = "movement",
    Permission  = 1,
    Aliases     = {"teleport", "tpfollow", "ghostfollow", "stalk"},
    Description = "Ghost Follow TP — teleport + continuous shadow follow (stop with ?bot tp alone)",
    Execute = function(BotEnv, args, executor, restArgs)
        local ws = game:GetService("Workspace")

        -- ── Toggle OFF if already following ───────────────────────────────────
        if BotEnv.GetFlag("IsTpFollow") then
            BotEnv.SetFlag("IsTpFollow", false)
            BotEnv.SetFlag("TpFollowTarget", nil)
            BotEnv.DisconnectSafe("TpFollow_Ghost")
            BotEnv.Respond("👤 Ghost Follow OFF")
            return
        end

        -- ── Need a target ─────────────────────────────────────────────────────
        if not args[2] then
            BotEnv.RespondError("Usage: ?bot tp <player>  |  ?bot tp (no args) to stop")
            return
        end

        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then
            BotEnv.RespondError("Can't find player: " .. args[2])
            return
        end

        local targetHRP = BotEnv.GetHRP(target)
        local botHRP    = BotEnv.GetBotHRP()
        if not targetHRP or not botHRP then
            BotEnv.RespondError("Character not loaded")
            return
        end

        local spawnPos = botHRP.Position
        local destPos  = targetHRP.Position

        -- Gojo palette helper
        local function GC(i, n, shift)
            return Color3.fromHSV((0.62 + (i / n) * 0.30 + (shift or 0)) % 1, 1, 1)
        end

        -- ── Cinematic: Void burst ring at departure ────────────────────────────
        task.spawn(function()
            pcall(function()
                local BURST = 20
                local parts = {}
                for i = 1, BURST do
                    local p = Instance.new("Part")
                    p.Size        = Vector3.new(0.5, 0.5, 0.5)
                    p.Shape       = Enum.PartType.Ball
                    p.Material    = Enum.Material.Neon
                    p.CanCollide  = false
                    p.Anchored    = true
                    p.CastShadow  = false
                    p.Transparency = 0.0
                    p.Color        = GC(i, BURST)
                    p.Position     = spawnPos
                    p.Name         = "TpBurst"
                    p.Parent       = ws
                    parts[i] = p
                end
                for step = 1, 25 do
                    task.wait(0.025)
                    for i, p in ipairs(parts) do
                        if p and p.Parent then
                            local a = (i / BURST) * math.pi * 2
                            local r = step * 0.42
                            p.Position    = spawnPos + Vector3.new(math.cos(a)*r, 0, math.sin(a)*r)
                            p.Transparency = step / 25
                            p.Color        = GC(i, BURST, step * 0.025)
                            local sz = math.max(0.04, 0.5 - step * 0.018)
                            p.Size = Vector3.new(sz, sz, sz)
                        end
                    end
                end
                for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
            end)
        end)

        -- ── Cinematic: Cursed energy streak origin → destination ──────────────
        task.spawn(function()
            pcall(function()
                local STREAK = 24
                local streakParts = {}
                for i = 0, STREAK do
                    local alpha = i / STREAK
                    local sp    = Instance.new("Part")
                    sp.Size        = Vector3.new(0.28, 0.28, 0.28)
                    sp.Shape       = Enum.PartType.Ball
                    sp.Material    = Enum.Material.Neon
                    sp.CanCollide  = false
                    sp.Anchored    = true
                    sp.CastShadow  = false
                    sp.Transparency = 0.1
                    sp.Color        = GC(i, STREAK)
                    sp.Position     = spawnPos:Lerp(destPos, alpha) + Vector3.new(0, 1.3, 0)
                    sp.Name         = "TpStreak"
                    sp.Parent       = ws
                    streakParts[i + 1] = sp
                    task.wait(0.007)
                end
                task.delay(1.6, function()
                    for _, sp in ipairs(streakParts) do
                        task.spawn(function()
                            for step = 1, 10 do
                                task.wait(0.1)
                                if sp and sp.Parent then sp.Transparency = sp.Transparency + 0.09 end
                            end
                            pcall(function() if sp and sp.Parent then sp:Destroy() end end)
                        end)
                    end
                end)
            end)
        end)

        -- ── Actual teleport: 2.5 studs behind target ──────────────────────────
        task.wait(0.03)
        local freshHRP = BotEnv.GetBotHRP()
        if freshHRP then
            freshHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2.5)
        end

        -- ── Arrival crown: 8 void orbs orbit for 4 seconds then fade ─────────
        task.spawn(function()
            pcall(function()
                local CROWN = 8
                local crownOrbs = {}
                for i = 1, CROWN do
                    local c = Instance.new("Part")
                    c.Size        = Vector3.new(0.45, 0.45, 0.45)
                    c.Shape       = Enum.PartType.Ball
                    c.Material    = Enum.Material.Neon
                    c.CanCollide  = false
                    c.Anchored    = true
                    c.CastShadow  = false
                    c.Transparency = 0.05
                    c.Color        = GC(i, CROWN)
                    c.Name         = "TpArrival"
                    c.Parent       = ws
                    crownOrbs[i] = c
                end
                local lt = 0
                local dur = 4
                local st  = tick()
                local conn
                conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
                    pcall(function()
                        lt = lt + dt
                        local hrp = BotEnv.GetBotHRP()
                        if not hrp then return end
                        for i, c in ipairs(crownOrbs) do
                            if c and c.Parent then
                                local a = lt * 5.5 + (i / CROWN) * math.pi * 2
                                local r = 2.5 + math.sin(lt * 3 + i) * 0.4
                                local y = 2.8 + math.abs(math.sin(lt * 6 + i)) * 0.7
                                c.Position  = hrp.Position + Vector3.new(math.cos(a)*r, y, math.sin(a)*r)
                                c.Color     = GC(i, CROWN, lt * 0.12)
                                local elapsed = tick() - st
                                if elapsed > dur - 1 then
                                    c.Transparency = math.min(1, elapsed - (dur - 1))
                                end
                            end
                        end
                        if (tick() - st) >= dur then
                            conn:Disconnect()
                            for _, c in ipairs(crownOrbs) do pcall(function() c:Destroy() end) end
                        end
                    end)
                end)
            end)
        end)

        -- ── Ghost Follow: lock bot 2.5 studs behind target every heartbeat ────
        BotEnv.SetFlag("IsTpFollow", true)
        BotEnv.SetFlag("TpFollowTarget", target)

        local followConn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsTpFollow") then
                    BotEnv.DisconnectSafe("TpFollow_Ghost"); return
                end
                local t = BotEnv.GetFlag("TpFollowTarget")
                if not t or not t.Parent then
                    BotEnv.SetFlag("IsTpFollow", false)
                    BotEnv.DisconnectSafe("TpFollow_Ghost"); return
                end
                local tHRP = BotEnv.GetHRP(t)
                local bHRP = BotEnv.GetBotHRP()
                if not tHRP or not bHRP then return end
                -- Stand 2.5 studs behind target, matching their look direction
                bHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2.5)
            end)
        end)
        BotEnv.TrackConnection("TpFollow_Ghost", followConn)

        BotEnv.Respond("👤 Ghost Follow ON → " .. target.Name .. " | ?bot tp to stop")
    end,
}
