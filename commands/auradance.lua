--[[
    Command: auradance
    Category: aura
    Permission: 1
    Usage: ?bot auradance
    Aliases: danceglow, glowdance, auramove
    Description: Makes the bot dance with a full rainbow aura around it:
                 - Bot body sways and bounces
                 - 12 neon orbs orbit in a pulsing torus shape
                 - Hue shifts with the beat
]]

return {
    Name = "auradance",
    Category = "aura",
    Permission = 1,
    Aliases = {"danceglow", "glowdance", "auramove"},
    Description = "Bot dances with a full rainbow aura torus of neon orbs",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraDancing")

        -- ─── OFF ────────────────────────────────────────────────────────────
        if isOn then
            BotEnv.SetFlag("IsAuraDancing", false)
            BotEnv.DisconnectSafe("AuraDance_Body")
            BotEnv.DisconnectSafe("AuraDance_Orbs")
            if BotEnv.AuraDanceParts then
                for _, p in ipairs(BotEnv.AuraDanceParts) do pcall(function() p:Destroy() end) end
                BotEnv.AuraDanceParts = {}
            end
            BotEnv.Respond("🌑 Aura Dance OFF")
            return
        end

        -- ─── ON ─────────────────────────────────────────────────────────────
        BotEnv.SetFlag("IsAuraDancing", true)
        BotEnv.AuraDanceParts = {}
        local ws = game:GetService("Workspace")

        -- spawn orbs
        local ORB_COUNT = 14
        local orbs = {}
        for i = 1, ORB_COUNT do
            local p = Instance.new("Part")
            p.Size        = Vector3.new(0.6, 0.6, 0.6)
            p.Shape       = Enum.PartType.Ball
            p.Material    = Enum.Material.Neon
            p.CanCollide  = false
            p.Anchored    = true
            p.CastShadow  = false
            p.Transparency = 0.15
            p.Name         = "AuraDanceOrb" .. i
            p.Parent       = ws
            orbs[i]        = p
            BotEnv.AuraDanceParts[#BotEnv.AuraDanceParts + 1] = p
        end

        local t = 0

        -- body dance
        local bodyConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraDancing") then BotEnv.DisconnectSafe("AuraDance_Body"); return end
                t = t + dt
                local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                -- sway left-right + bounce up
                local swayX = math.sin(t * 5)   * 0.035
                local swayY = math.abs(math.sin(t * 8)) * 0.025
                local tiltZ = math.sin(t * 4)   * 0.08
                hrp.CFrame = hrp.CFrame
                    * CFrame.new(swayX, swayY, 0)
                    * CFrame.Angles(0, math.sin(t * 3) * 0.05, tiltZ)
            end)
        end)
        BotEnv.TrackConnection("AuraDance_Body", bodyConn)

        -- orb torus
        local orbConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraDancing") then BotEnv.DisconnectSafe("AuraDance_Orbs"); return end
                local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                local pos = hrp.Position

                -- two layers: ring (equator) and top-ring
                local half = math.floor(ORB_COUNT / 2)
                for i = 1, ORB_COUNT do
                    if orbs[i] and orbs[i].Parent then
                        local a, r, yOff
                        if i <= half then
                            -- equator ring
                            a    = t * 3.0 + (i / half) * math.pi * 2
                            r    = 3.5 + math.sin(t * 5 + i * 0.7) * 0.6
                            yOff = math.sin(t * 6 + i * 1.2) * 0.8
                        else
                            -- upper ring
                            local j = i - half
                            a    = -(t * 3.5) + (j / half) * math.pi * 2
                            r    = 2.2 + math.sin(t * 4 + j * 0.9) * 0.4
                            yOff = 2.8 + math.sin(t * 7 + j * 1.1) * 0.6
                        end
                        orbs[i].Position = pos + Vector3.new(math.cos(a)*r, yOff, math.sin(a)*r)
                        orbs[i].Color    = Color3.fromHSV(((t * 0.15 + i / ORB_COUNT)) % 1, 1, 1)
                        -- pulse size with beat
                        local pulse = 0.6 + math.abs(math.sin(t * 8 + i * 0.5)) * 0.35
                        orbs[i].Size = Vector3.new(pulse, pulse, pulse)
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("AuraDance_Orbs", orbConn)

        BotEnv.Respond("💃 Aura Dance ON — rainbow torus active!")
    end,
}
