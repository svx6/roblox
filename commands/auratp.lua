--[[
    Command: auratp
    Category: aura
    Permission: 1
    Usage: ?bot auratp <player>
    Aliases: tpaura, flashtp, warptp
    Description: Teleport to a player with a spectacular AURA animation:
                 - Burst ring of neon orbs explodes outward from bot spawn
                 - Streak of rainbow sparkles marks the travel path
                 - Crown of orbiting orbs lingers at destination
]]

return {
    Name = "auratp",
    Category = "aura",
    Permission = 1,
    Aliases = {"tpaura", "flashtp", "warptp"},
    Description = "Teleport to a player with aura FX (burst + streak + arrival crown)",
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("need a target: ?bot auratp <player>"); return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("can't find player: " .. args[2]); return end

        local targetHRP = BotEnv.GetHRP(target)
        local botHRP    = BotEnv.GetBotHRP()
        if not targetHRP or not botHRP then BotEnv.RespondError("character not loaded"); return end

        local ws          = game:GetService("Workspace")
        local spawnPos    = botHRP.Position
        local destPos     = targetHRP.Position

        -- ── 1. Burst ring at departure ───────────────────────────────────────
        task.spawn(function()
            local BURST = 16
            local burstParts = {}
            for i = 1, BURST do
                local p = Instance.new("Part")
                p.Size        = Vector3.new(0.5, 0.5, 0.5)
                p.Shape       = Enum.PartType.Ball
                p.Material    = Enum.Material.Neon
                p.CanCollide  = false
                p.Anchored    = true
                p.CastShadow  = false
                p.Transparency = 0.1
                p.Color        = Color3.fromHSV((i / BURST), 1, 1)
                p.Position     = spawnPos
                p.Name         = "AuraBurst"
                p.Parent       = ws
                burstParts[i]  = p
            end

            -- expand outward in a ring then fade
            task.spawn(function()
                for step = 1, 25 do
                    task.wait(0.03)
                    for i, p in ipairs(burstParts) do
                        if p and p.Parent then
                            local a = (i / BURST) * math.pi * 2
                            local r = step * 0.4
                            p.Position     = spawnPos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
                            p.Transparency = step / 25
                            p.Color        = Color3.fromHSV(((i / BURST) + step * 0.04) % 1, 1, 1)
                            p.Size         = Vector3.new(
                                math.max(0.05, 0.5 - step * 0.018),
                                math.max(0.05, 0.5 - step * 0.018),
                                math.max(0.05, 0.5 - step * 0.018)
                            )
                        end
                    end
                end
                for _, p in ipairs(burstParts) do pcall(function() p:Destroy() end) end
            end)
        end)

        -- ── 2. Streak of sparkles from origin to destination ────────────────
        task.spawn(function()
            local STREAK = 18
            local streakParts = {}
            for i = 0, STREAK do
                local alpha = i / STREAK
                local sp    = Instance.new("Part")
                sp.Size        = Vector3.new(0.35, 0.35, 0.35)
                sp.Shape       = Enum.PartType.Ball
                sp.Material    = Enum.Material.Neon
                sp.CanCollide  = false
                sp.Anchored    = true
                sp.CastShadow  = false
                sp.Transparency = 0.2
                sp.Color        = Color3.fromHSV(alpha, 1, 1)
                sp.Position     = spawnPos:Lerp(destPos, alpha) + Vector3.new(0, 1, 0)
                sp.Name         = "AuraStreak"
                sp.Parent       = ws
                streakParts[i + 1] = sp
                task.wait(0.01)
            end
            -- fade out after 2 s
            task.delay(2, function()
                for _, sp in ipairs(streakParts) do
                    task.spawn(function()
                        for step = 1, 10 do
                            task.wait(0.1)
                            if sp and sp.Parent then sp.Transparency = sp.Transparency + 0.08 end
                        end
                        pcall(function() if sp and sp.Parent then sp:Destroy() end end)
                    end)
                end
            end)
        end)

        -- ── 3. Actual teleport ───────────────────────────────────────────────
        task.wait(0.05)
        local freshHRP = BotEnv.GetBotHRP()
        if freshHRP then
            freshHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
        end

        -- ── 4. Arrival crown (orbiting orbs that linger 4 s) ────────────────
        task.spawn(function()
            local CROWN = 8
            local crownOrbs = {}
            for i = 1, CROWN do
                local c = Instance.new("Part")
                c.Size        = Vector3.new(0.5, 0.5, 0.5)
                c.Shape       = Enum.PartType.Ball
                c.Material    = Enum.Material.Neon
                c.CanCollide  = false
                c.Anchored    = true
                c.CastShadow  = false
                c.Transparency = 0.1
                c.Color        = Color3.fromHSV((i / CROWN), 1, 1)
                c.Name         = "AuraArrival"
                c.Parent       = ws
                crownOrbs[i]   = c
            end

            local lt = 0
            local duration = 4
            local startTick = tick()

            local conn
            conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
                pcall(function()
                    lt = lt + dt
                    local hrp = BotEnv.GetBotHRP()
                    if not hrp then return end
                    for i, c in ipairs(crownOrbs) do
                        if c and c.Parent then
                            local a = lt * 5 + (i / CROWN) * math.pi * 2
                            local r = 2.5 + math.sin(lt * 3 + i) * 0.4
                            local y = 2.5 + math.abs(math.sin(lt * 6 + i)) * 0.8
                            c.Position = hrp.Position + Vector3.new(math.cos(a)*r, y, math.sin(a)*r)
                            c.Color    = Color3.fromHSV(((lt * 0.2 + i/CROWN)) % 1, 1, 1)
                            -- fade in last second
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

        BotEnv.Respond("✨ Aura TP → " .. target.Name)
    end,
}
