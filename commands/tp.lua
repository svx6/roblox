--[[
    Command: tp
    Category: movement
    Permission: 1
    Usage: ?bot tp <player>
    Aliases: teleport, auratp, tpaura, flashtp, warptp
    Description: Teleport to a player with GOJO aura animation:
                 burst ring of void orbs explodes outward from spawn,
                 rainbow streak marks the path, arrival crown lingers.
]]
return {
    Name = "tp",
    Category = "movement",
    Permission = 1,
    Aliases = {"teleport", "auratp", "tpaura", "flashtp", "warptp"},
    Description = "Teleport to a player with Gojo aura FX (burst + streak + arrival crown)",
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("need a target: ?bot tp <player>"); return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("can't find player: " .. args[2]); return end

        local targetHRP = BotEnv.GetHRP(target)
        local botHRP    = BotEnv.GetBotHRP()
        if not targetHRP or not botHRP then BotEnv.RespondError("character not loaded"); return end

        local ws       = game:GetService("Workspace")
        local spawnPos = botHRP.Position
        local destPos  = targetHRP.Position

        -- Gojo palette hues (blue-purple-magenta)
        local function GojoColor(i, total, shift)
            local h = (0.62 + (i / total) * 0.30 + (shift or 0)) % 1
            return Color3.fromHSV(h, 1, 1)
        end

        -- ── 1. Void burst ring at departure ─────────────────────────────────
        task.spawn(function()
            local BURST = 20
            local burstParts = {}
            for i = 1, BURST do
                local p = Instance.new("Part")
                p.Size        = Vector3.new(0.55, 0.55, 0.55)
                p.Shape       = Enum.PartType.Ball
                p.Material    = Enum.Material.Neon
                p.CanCollide  = false
                p.Anchored    = true
                p.CastShadow  = false
                p.Transparency = 0.08
                p.Color        = GojoColor(i, BURST)
                p.Position     = spawnPos
                p.Name         = "GojoVoidBurst"
                p.Parent       = ws
                burstParts[i]  = p
            end
            -- Expand outward in void ring then fade
            task.spawn(function()
                for step = 1, 28 do
                    task.wait(0.025)
                    for i, p in ipairs(burstParts) do
                        if p and p.Parent then
                            local a = (i / BURST) * math.pi * 2
                            local r = step * 0.38
                            p.Position     = spawnPos + Vector3.new(math.cos(a)*r, 0, math.sin(a)*r)
                            p.Transparency = step / 28
                            p.Color        = GojoColor(i, BURST, step * 0.03)
                            local sz = math.max(0.05, 0.55 - step * 0.017)
                            p.Size = Vector3.new(sz, sz, sz)
                        end
                    end
                end
                for _, p in ipairs(burstParts) do pcall(function() p:Destroy() end) end
            end)
        end)

        -- ── 2. Cursed energy streak from origin → destination ────────────────
        task.spawn(function()
            local STREAK = 22
            local streakParts = {}
            for i = 0, STREAK do
                local alpha = i / STREAK
                local sp    = Instance.new("Part")
                sp.Size        = Vector3.new(0.30, 0.30, 0.30)
                sp.Shape       = Enum.PartType.Ball
                sp.Material    = Enum.Material.Neon
                sp.CanCollide  = false
                sp.Anchored    = true
                sp.CastShadow  = false
                sp.Transparency = 0.15
                sp.Color        = GojoColor(i, STREAK)
                sp.Position     = spawnPos:Lerp(destPos, alpha) + Vector3.new(0, 1.2, 0)
                sp.Name         = "GojoStreak"
                sp.Parent       = ws
                streakParts[i + 1] = sp
                task.wait(0.008)
            end
            -- Fade out after 1.8s
            task.delay(1.8, function()
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

        -- ── 3. Actual teleport ───────────────────────────────────────────────
        task.wait(0.04)
        local freshHRP = BotEnv.GetBotHRP()
        if freshHRP then
            freshHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
        end

        -- ── 4. Arrival crown — 8 orbiting void orbs for 4s ──────────────────
        task.spawn(function()
            local CROWN = 8
            local crownOrbs = {}
            for i = 1, CROWN do
                local c = Instance.new("Part")
                c.Size        = Vector3.new(0.50, 0.50, 0.50)
                c.Shape       = Enum.PartType.Ball
                c.Material    = Enum.Material.Neon
                c.CanCollide  = false
                c.Anchored    = true
                c.CastShadow  = false
                c.Transparency = 0.08
                c.Color        = GojoColor(i, CROWN)
                c.Name         = "GojoArrival"
                c.Parent       = ws
                crownOrbs[i]   = c
            end

            local lt        = 0
            local duration  = 4
            local startTick = tick()

            local conn
            conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
                pcall(function()
                    lt = lt + dt
                    local hrp = BotEnv.GetBotHRP()
                    if not hrp then return end
                    for i, c in ipairs(crownOrbs) do
                        if c and c.Parent then
                            local a = lt * 5.5 + (i / CROWN) * math.pi * 2
                            local r = 2.6 + math.sin(lt * 3 + i) * 0.4
                            local y = 2.8 + math.abs(math.sin(lt * 6 + i)) * 0.7
                            c.Position = hrp.Position + Vector3.new(math.cos(a)*r, y, math.sin(a)*r)
                            c.Color    = GojoColor(i, CROWN, lt * 0.15)
                            local elapsed = tick() - startTick
                            if elapsed > duration - 1 then
                                c.Transparency = math.min(1, (elapsed - (duration - 1)))
                            end
                        end
                    end
                    if (tick() - startTick) >= duration then
                        conn:Disconnect()
                        for _, c in ipairs(crownOrbs) do pcall(function() c:Destroy() end) end
                    end
                end)
            end)
        end)

        BotEnv.Respond("✨ Gojo TP → " .. target.Name .. " (Void Burst + Arrival Crown)")
    end,
}
