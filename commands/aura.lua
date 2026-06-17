--[[
    Command: aura
    Category: fx
    Permission: 1
    Usage: ?bot aura
    Aliases: storm, electric, discharge, shock, staticstorm, voltage
    Description: ELECTRIC STORM — crackling lightning arcs shoot from the bot,
                 shockwave rings pulse outward from the feet, and a blazing
                 energy core throbs at the chest. Zero orbit balls.
]]

return {
    Name = "aura",
    Category = "fx",
    Permission = 1,
    Aliases = {"storm", "electric", "discharge", "shock", "staticstorm", "voltage", "glow"},
    Description = "Electric Storm FX — lightning arcs + shockwave rings + energy core",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraActive")

        -- ─── OFF ──────────────────────────────────────────────────────────────
        if isOn then
            BotEnv.SetFlag("IsAuraActive", false)
            BotEnv.DisconnectSafe("Aura_Core")
            BotEnv.DisconnectSafe("Aura_Rings")
            for _, pt in ipairs(BotEnv.AuraParts) do
                pcall(function() pt:Destroy() end)
            end
            BotEnv.AuraParts = {}
            BotEnv.Respond("⚡ Electric Storm OFF")
            return
        end

        -- ─── ON ───────────────────────────────────────────────────────────────
        BotEnv.SetFlag("IsAuraActive", true)
        BotEnv.AuraParts = {}
        local ws = game:GetService("Workspace")

        -- ── Energy Core: single pulsing sphere at torso ───────────────────────
        local core = Instance.new("Part")
        core.Size        = Vector3.new(1, 1, 1)
        core.Shape       = Enum.PartType.Ball
        core.Material    = Enum.Material.Neon
        core.CanCollide  = false
        core.Anchored    = true
        core.CastShadow  = false
        core.Color       = Color3.new(0.4, 0.9, 1)   -- electric cyan
        core.Transparency = 0.0
        core.Name        = "ElectricCore"
        core.Parent      = ws
        BotEnv.AuraParts[#BotEnv.AuraParts + 1] = core

        -- ── Lightning Arcs: 10 thin bolts pointing to random targets ─────────
        local NUM_ARCS = 10
        local arcs = {}
        for i = 1, NUM_ARCS do
            local a = Instance.new("Part")
            a.Size        = Vector3.new(0.07, 0.07, 1)
            a.Material    = Enum.Material.Neon
            a.CanCollide  = false
            a.Anchored    = true
            a.CastShadow  = false
            a.Color       = Color3.new(1, 1, 1)
            a.Transparency = 0
            a.Name        = "LightningArc" .. i
            a.Parent      = ws
            arcs[i] = a
            BotEnv.AuraParts[#BotEnv.AuraParts + 1] = a
        end

        -- ── Main loop: core pulse + arc flicker ──────────────────────────────
        local t = 0
        local arcTimer = 0
        local ARC_TICK = 0.045  -- update arcs every 45ms → visible flicker

        local coreConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraActive") then
                    BotEnv.DisconnectSafe("Aura_Core")
                    return
                end
                t = t + dt
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end
                local pos = hrp.Position

                -- Core: sit at mid-torso, pulse in size, cycle hue (cyan→white→yellow)
                if core and core.Parent then
                    local pulse = 0.55 + math.abs(math.sin(t * 8)) * 0.70
                    core.Size     = Vector3.new(pulse, pulse, pulse)
                    core.Position = pos + Vector3.new(0, 0.5, 0)
                    local hPulse = (0.54 + math.sin(t * 3) * 0.06) % 1  -- cyan flicker
                    core.Color    = Color3.fromHSV(hPulse, 0.8, 1)
                    core.Transparency = 0.05 + math.abs(math.sin(t * 12)) * 0.25
                end

                -- Arc flicker: every ARC_TICK, repoint all arcs to new random targets
                arcTimer = arcTimer + dt
                if arcTimer >= ARC_TICK then
                    arcTimer = 0
                    for i, arc in ipairs(arcs) do
                        if arc and arc.Parent then
                            -- random endpoint around the character
                            local rx = (math.random() - 0.5) * 11
                            local ry = (math.random() - 0.5) * 7
                            local rz = (math.random() - 0.5) * 11
                            local target = pos + Vector3.new(rx, ry, rz)
                            local origin = pos + Vector3.new(0, 0.5, 0)
                            local dir    = target - origin
                            local len    = dir.Magnitude
                            if len > 0.1 then
                                arc.Size  = Vector3.new(0.055, 0.055, len)
                                arc.CFrame = CFrame.new(origin + dir * 0.5, target)
                            end
                            -- flicker on/off + colour shift
                            local roll = math.random()
                            if roll < 0.35 then
                                arc.Transparency = 1  -- invisible frame (flicker)
                            elseif roll < 0.65 then
                                arc.Color = Color3.new(1, 1, 1); arc.Transparency = 0
                            elseif roll < 0.85 then
                                arc.Color = Color3.fromHSV(0.55, 1, 1); arc.Transparency = 0.1
                            else
                                arc.Color = Color3.fromHSV(0.12, 1, 1); arc.Transparency = 0.2  -- hot yellow
                            end
                        end
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("Aura_Core", coreConn)

        -- ── Shockwave rings: spawn one every 0.45s ────────────────────────────
        local ringTimer  = 0
        local RING_INT   = 0.45
        local ringHue    = 0.55
        local ringConn

        ringConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraActive") then
                    BotEnv.DisconnectSafe("Aura_Rings")
                    return
                end
                ringTimer = ringTimer + dt
                if ringTimer < RING_INT then return end
                ringTimer = 0

                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end
                local spawnPos = hrp.Position - Vector3.new(0, 2.8, 0)  -- at feet

                ringHue = (ringHue + 0.14) % 1

                -- spawn expanding disc in background task
                local capturedHue = ringHue
                task.spawn(function()
                    local ring = Instance.new("Part")
                    ring.Size        = Vector3.new(0.5, 0.08, 0.5)
                    ring.Material    = Enum.Material.Neon
                    ring.CanCollide  = false
                    ring.Anchored    = true
                    ring.CastShadow  = false
                    ring.Transparency = 0.15
                    ring.Color       = Color3.fromHSV(capturedHue, 0.9, 1)
                    ring.CFrame      = CFrame.new(spawnPos)
                    ring.Name        = "ShockwaveRing"
                    ring.Parent      = ws

                    -- 22 steps = ~0.55s to expand and fade
                    for step = 1, 22 do
                        task.wait(0.025)
                        if not (ring and ring.Parent) then break end
                        local s = 0.5 + step * 1.1      -- 0.5 → 24.7
                        ring.Size        = Vector3.new(s, 0.07, s)
                        ring.Transparency = 0.15 + (step / 22) * 0.85
                        ring.Color       = Color3.fromHSV((capturedHue + step * 0.02) % 1, 0.9, 1)
                    end
                    pcall(function() if ring and ring.Parent then ring:Destroy() end end)
                end)
            end)
        end)
        BotEnv.TrackConnection("Aura_Rings", ringConn)

        -- ── Spark burst: fire outward bursts when moving ──────────────────────
        local lastBurstPos = nil

        local burstConn
        burstConn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsAuraActive") then
                    BotEnv.DisconnectSafe("Aura_Burst")
                    return
                end
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end
                if lastBurstPos and (hrp.Position - lastBurstPos).Magnitude < 3 then return end
                lastBurstPos = hrp.Position

                -- fire 5 random sparks
                for _ = 1, 5 do
                    task.spawn(function()
                        local sp = Instance.new("Part")
                        sp.Size        = Vector3.new(0.14, 0.14, 0.14)
                        sp.Shape       = Enum.PartType.Ball
                        sp.Material    = Enum.Material.Neon
                        sp.CanCollide  = false
                        sp.Anchored    = false
                        sp.CastShadow  = false
                        sp.Transparency = 0.1
                        sp.Color       = Color3.fromHSV(math.random() * 0.15 + 0.50, 1, 1)
                        sp.Position    = hrp.Position + Vector3.new(
                            (math.random() - 0.5) * 2,
                            math.random() * 2,
                            (math.random() - 0.5) * 2
                        )
                        sp.Name        = "ElecSpark"
                        sp.Parent      = ws
                        -- give it a random impulse
                        sp.AssemblyLinearVelocity = Vector3.new(
                            (math.random() - 0.5) * 30,
                            math.random(5, 20),
                            (math.random() - 0.5) * 30
                        )
                        -- fade out
                        for i = 1, 8 do
                            task.wait(0.07)
                            if sp and sp.Parent then
                                sp.Transparency = sp.Transparency + 0.12
                            end
                        end
                        pcall(function() if sp and sp.Parent then sp:Destroy() end end)
                    end)
                end
            end)
        end)
        BotEnv.TrackConnection("Aura_Burst", burstConn)

        BotEnv.Respond("⚡ Electric Storm ON — lightning arcs + shockwave rings!")
    end,
}
