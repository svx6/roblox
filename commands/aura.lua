--[[
    Command: aura
    Category: aura
    Permission: 1
    Usage: ?bot aura
    Aliases: unaura, glow, gojoaura, sixeyes, limitless, infinity
    Description: Toggle the GOJO Six Eyes / Limitless aura —
                 void-blue & purple lightning orbs, infinity ring,
                 domain expansion particle burst, and cursed energy trail.
]]

return {
    Name = "aura",
    Category = "aura",
    Permission = 1,
    Aliases = {"unaura", "glow", "gojoaura", "sixeyes", "limitless", "infinity"},
    Description = "Toggle GOJO Six Eyes aura (void rings + lightning orbs + cursed energy trail)",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraActive")

        -- ─── OFF ────────────────────────────────────────────────────────────────
        if isOn then
            BotEnv.SetFlag("IsAuraActive", false)
            BotEnv.DisconnectSafe("Aura_Orbs")
            BotEnv.DisconnectSafe("Aura_Trail")
            for _, pt in ipairs(BotEnv.AuraParts) do
                pcall(function() pt:Destroy() end)
            end
            BotEnv.AuraParts = {}
            BotEnv.Respond("🌑 Six Eyes OFF")
            return
        end

        -- ─── ON ─────────────────────────────────────────────────────────────────
        BotEnv.SetFlag("IsAuraActive", true)
        BotEnv.AuraParts = BotEnv.AuraParts or {}
        local ws = game:GetService("Workspace")
        local t = 0

        -- Gojo colour palette: deep-blue (#0ff / #7f00ff / #ff00ff) neon
        local GojoHues = {0.62, 0.75, 0.82, 0.55, 0.90} -- blue→purple→magenta band

        local function MakeOrb(size, name)
            local p = Instance.new("Part")
            p.Size        = Vector3.new(size, size, size)
            p.Shape       = Enum.PartType.Ball
            p.Material    = Enum.Material.Neon
            p.CanCollide  = false
            p.Anchored    = true
            p.CastShadow  = false
            p.Transparency = 0.10
            p.Name        = name or "GojoPart"
            p.Parent      = ws
            BotEnv.AuraParts[#BotEnv.AuraParts + 1] = p
            return p
        end

        -- ── Layer 1: Outer void ring — 14 large orbs ──────────────────────────
        local OUTER = 14
        local outerOrbs = {}
        for i = 1, OUTER do
            outerOrbs[i] = MakeOrb(0.75, "GojoOuter" .. i)
        end

        -- ── Layer 2: Inner infinity ring — 8 medium orbs (counter-spin) ───────
        local INNER = 8
        local innerOrbs = {}
        for i = 1, INNER do
            innerOrbs[i] = MakeOrb(0.45, "GojoInner" .. i)
        end

        -- ── Layer 3: Crown — 6 small orbs above head ──────────────────────────
        local CROWN = 6
        local crownOrbs = {}
        for i = 1, CROWN do
            crownOrbs[i] = MakeOrb(0.30, "GojoCrown" .. i)
        end

        -- ── Main orbit loop ───────────────────────────────────────────────────
        local orbConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraActive") then
                    BotEnv.DisconnectSafe("Aura_Orbs"); return
                end
                t = t + dt
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end
                local pos = hrp.Position

                -- Outer void ring — slow, large radius, Y-bob
                for i, orb in ipairs(outerOrbs) do
                    if orb and orb.Parent then
                        local a   = t * 1.8 + (i / OUTER) * math.pi * 2
                        local r   = 5.0 + math.sin(t * 0.9 + i * 0.5) * 0.9
                        local y   = math.sin(t * 2.5 + i * 0.7) * 2.2
                        orb.Position = pos + Vector3.new(math.cos(a)*r, y, math.sin(a)*r)
                        -- Gojo blue-purple-magenta colour wave
                        local hue = (GojoHues[(i % #GojoHues) + 1] + t * 0.05) % 1
                        orb.Color = Color3.fromHSV(hue, 1, 1)
                        local sz  = 0.75 + math.sin(t * 5 + i) * 0.18
                        orb.Size  = Vector3.new(sz, sz, sz)
                    end
                end

                -- Inner infinity ring — faster counter-spin
                for i, orb in ipairs(innerOrbs) do
                    if orb and orb.Parent then
                        local a   = -(t * 3.2) + (i / INNER) * math.pi * 2
                        local r   = 2.8 + math.sin(t * 2 + i * 0.8) * 0.5
                        local y   = math.cos(t * 4 + i * 1.2) * 1.5
                        orb.Position = pos + Vector3.new(math.cos(a)*r, y, math.sin(a)*r)
                        local hue = (0.62 + t * 0.12 + i / INNER * 0.3) % 1
                        orb.Color = Color3.fromHSV(hue, 1, 1)
                    end
                end

                -- Crown — fast spin above head
                for i, orb in ipairs(crownOrbs) do
                    if orb and orb.Parent then
                        local a    = t * 6.0 + (i / CROWN) * math.pi * 2
                        local r    = 1.6 + math.sin(t * 7 + i) * 0.25
                        local yOff = 3.5 + math.abs(math.sin(t * 8 + i * 1.3)) * 0.6
                        orb.Position = pos + Vector3.new(math.cos(a)*r, yOff, math.sin(a)*r)
                        orb.Color    = Color3.fromHSV((0.75 + t * 0.2 + i / CROWN) % 1, 1, 1)
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("Aura_Orbs", orbConn)

        -- ── Cursed energy trail (sparks when moving) ──────────────────────────
        local trailParts = {}
        local MAX_TRAIL  = 50
        local lastPos    = nil
        local trailHue   = 0.62

        local trailConn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsAuraActive") then
                    BotEnv.DisconnectSafe("Aura_Trail"); return
                end
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end

                if not lastPos or (hrp.Position - lastPos).Magnitude > 1.5 then
                    lastPos  = hrp.Position
                    trailHue = (trailHue + 0.035) % 1

                    local spark = Instance.new("Part")
                    spark.Size        = Vector3.new(0.18, 0.18, 0.18)
                    spark.Shape       = Enum.PartType.Ball
                    spark.Material    = Enum.Material.Neon
                    spark.CanCollide  = false
                    spark.Anchored    = true
                    spark.CastShadow  = false
                    spark.Transparency = 0.20
                    spark.Color        = Color3.fromHSV(trailHue, 1, 1)
                    spark.Position     = hrp.Position - Vector3.new(0, 2.5, 0)
                    spark.Name         = "GojoTrail"
                    spark.Parent       = ws
                    trailParts[#trailParts + 1] = spark
                    BotEnv.AuraParts[#BotEnv.AuraParts + 1] = spark

                    -- fade out over 2.5s
                    task.delay(2.5, function()
                        pcall(function()
                            for step = 1, 12 do
                                task.wait(0.18)
                                if spark and spark.Parent then
                                    spark.Transparency = spark.Transparency + 0.065
                                end
                            end
                            if spark and spark.Parent then spark:Destroy() end
                        end)
                    end)

                    if #trailParts > MAX_TRAIL then
                        pcall(function()
                            if trailParts[1] and trailParts[1].Parent then
                                trailParts[1]:Destroy()
                            end
                        end)
                        table.remove(trailParts, 1)
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("Aura_Trail", trailConn)

        BotEnv.Respond("👁️ Six Eyes ON — Infinity / Limitless / Domain active!")
    end,
}
