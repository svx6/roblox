--[[
    Command: auramode
    Category: aura
    Permission: 1
    Usage: ?bot auramode
    Aliases: modeaura, botaura, glowmode, auraall
    Description: Toggle FULL AURA bot mode — ALL effects simultaneously:
                 rainbow particles, spinning orbit ring, floating crown orbs,
                 and aura glow trail all active at once. Gojo Satoru vibes.
]]

return {
    Name = "auramode",
    Category = "aura",
    Permission = 1,
    Aliases = {"modeaura", "botaura", "glowmode", "auraall", "auraon"},
    Description = "Toggle FULL Gojo aura mode (orbit ring + crown orbs + sparkle trail — all at once)",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraModeOn")

        -- ─── OFF ────────────────────────────────────────────────────────────────
        if isOn then
            BotEnv.SetFlag("IsAuraModeOn", false)
            BotEnv.DisconnectSafe("AuraMode_Orbit")
            BotEnv.DisconnectSafe("AuraMode_Crown")
            BotEnv.DisconnectSafe("AuraMode_Rain")
            BotEnv.DisconnectSafe("AuraMode_Trail")

            -- destroy every aura part we spawned
            if BotEnv.AuraModeParts then
                for _, p in ipairs(BotEnv.AuraModeParts) do
                    pcall(function() p:Destroy() end)
                end
                BotEnv.AuraModeParts = {}
            end

            BotEnv.Respond("🌑 Aura Mode OFF")
            return
        end

        -- ─── ON ─────────────────────────────────────────────────────────────────
        BotEnv.SetFlag("IsAuraModeOn", true)
        BotEnv.AuraModeParts = BotEnv.AuraModeParts or {}

        local ws   = game:GetService("Workspace")
        local t    = 0
        local ORBS = 12   -- orbit ring orbs
        local CROWN = 6   -- crown orbs above head

        -- helper: make a neon ball
        local function MakeBall(size, name)
            local p = Instance.new("Part")
            p.Size        = Vector3.new(size, size, size)
            p.Shape       = Enum.PartType.Ball
            p.Material    = Enum.Material.Neon
            p.CanCollide  = false
            p.Anchored    = true
            p.CastShadow  = false
            p.Transparency = 0.15
            p.Name        = name or "AuraModeOrb"
            p.Parent      = ws
            BotEnv.AuraModeParts[#BotEnv.AuraModeParts + 1] = p
            return p
        end

        -- ── Layer 1: outer orbit ring (12 large orbs) ────────────────────────
        local orbitOrbs = {}
        for i = 1, ORBS do
            orbitOrbs[i] = MakeBall(0.7, "AuraOrbit" .. i)
        end

        -- ── Layer 2: inner crown (6 small orbs above head) ──────────────────
        local crownOrbs = {}
        for i = 1, CROWN do
            crownOrbs[i] = MakeBall(0.4, "AuraCrown" .. i)
        end

        -- ── Layer 3: rain sparkle trail parts ───────────────────────────────
        local rainParts = {}
        local MAX_RAIN = 60
        local lastRainPos = nil

        -- ── Orbit + crown loop ───────────────────────────────────────────────
        local orbitConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraModeOn") then
                    BotEnv.DisconnectSafe("AuraMode_Orbit")
                    return
                end
                t = t + dt
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end
                local pos = hrp.Position

                -- outer orbit (slow spiral in XZ, gentle Y bob)
                for i, orb in ipairs(orbitOrbs) do
                    if orb and orb.Parent then
                        local a   = t * 2.2 + (i / ORBS) * math.pi * 2
                        local r   = 4.5 + math.sin(t * 1.1 + i * 0.6) * 0.8
                        local y   = math.sin(t * 3   + i * 0.9) * 1.8
                        orb.Position = pos + Vector3.new(
                            math.cos(a) * r,
                            y,
                            math.sin(a) * r
                        )
                        -- rainbow colour per orb, cycling over time
                        orb.Color = Color3.fromHSV(((t * 0.12 + i / ORBS)) % 1, 1, 1)
                        orb.Size  = Vector3.new(
                            0.7 + math.sin(t * 4 + i) * 0.15,
                            0.7 + math.sin(t * 4 + i) * 0.15,
                            0.7 + math.sin(t * 4 + i) * 0.15
                        )
                    end
                end

                -- crown orbs (faster spin, above head)
                for i, orb in ipairs(crownOrbs) do
                    if orb and orb.Parent then
                        local a   = t * 4.5 + (i / CROWN) * math.pi * 2
                        local r   = 1.8 + math.sin(t * 5 + i) * 0.3
                        local yOff = 3.2 + math.abs(math.sin(t * 6 + i * 1.1)) * 0.5
                        orb.Position = pos + Vector3.new(
                            math.cos(a) * r,
                            yOff,
                            math.sin(a) * r
                        )
                        orb.Color = Color3.fromHSV(((t * 0.25 + i / CROWN + 0.5)) % 1, 1, 1)
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("AuraMode_Orbit", orbitConn)

        -- ── Rain/trail loop ──────────────────────────────────────────────────
        local trailConn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsAuraModeOn") then
                    BotEnv.DisconnectSafe("AuraMode_Trail")
                    return
                end
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end

                -- spawn sparkle if moved
                if not lastRainPos or (hrp.Position - lastRainPos).Magnitude > 2 then
                    lastRainPos = hrp.Position

                    -- tiny sparkle at feet
                    local spark = Instance.new("Part")
                    spark.Size        = Vector3.new(0.2, 0.2, 0.2)
                    spark.Shape       = Enum.PartType.Ball
                    spark.Material    = Enum.Material.Neon
                    spark.CanCollide  = false
                    spark.Anchored    = true
                    spark.CastShadow  = false
                    spark.Transparency = 0.25
                    spark.Color        = Color3.fromHSV(math.random(), 1, 1)
                    spark.Position     = hrp.Position - Vector3.new(0, 2.8, 0)
                    spark.Name         = "AuraRain"
                    spark.Parent       = ws
                    rainParts[#rainParts + 1] = spark
                    BotEnv.AuraModeParts[#BotEnv.AuraModeParts + 1] = spark

                    -- fade and destroy after 3s
                    task.delay(3, function()
                        pcall(function()
                            for step = 1, 15 do
                                task.wait(0.2)
                                if spark and spark.Parent then
                                    spark.Transparency = spark.Transparency + 0.05
                                end
                            end
                            if spark and spark.Parent then spark:Destroy() end
                        end)
                    end)

                    -- keep rain list capped
                    if #rainParts > MAX_RAIN then
                        pcall(function()
                            if rainParts[1] and rainParts[1].Parent then
                                rainParts[1]:Destroy()
                            end
                        end)
                        table.remove(rainParts, 1)
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("AuraMode_Trail", trailConn)

        BotEnv.Respond("✨ Aura Mode ON — orbit ring + crown + sparkle trail active!")
    end,
}
