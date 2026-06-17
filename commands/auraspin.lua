--[[
    Command: auraspin
    Category: aura
    Permission: 1
    Usage: ?bot auraspin [speed]
    Aliases: spinglow, glowspin, auravortex
    Description: Spins the bot with a full aura vortex:
                 - BodyAngularVelocity rotates the bot
                 - 3 rings of neon orbs spinning at different speeds form a gyroscope
                 - Each ring is a different hue band shifting over time
]]

return {
    Name = "auraspin",
    Category = "aura",
    Permission = 1,
    Aliases = {"spinglow", "glowspin", "auravortex"},
    Description = "Spins the bot with a 3-ring gyroscope aura vortex",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraSpin")

        if isOn then
            BotEnv.SetFlag("IsAuraSpin", false)
            BotEnv.DisconnectSafe("AuraSpin_Orbs")
            -- remove spin motor
            pcall(function()
                local hrp = BotEnv.GetBotHRP()
                if hrp then
                    local bav = hrp:FindFirstChild("AuraSpinBAV")
                    if bav then bav:Destroy() end
                end
            end)
            if BotEnv.AuraSpinParts then
                for _, p in ipairs(BotEnv.AuraSpinParts) do pcall(function() p:Destroy() end) end
                BotEnv.AuraSpinParts = {}
            end
            BotEnv.Respond("🌑 Aura Spin OFF")
            return
        end

        local speed = tonumber(args[2]) or 25
        BotEnv.SetFlag("IsAuraSpin", true)
        BotEnv.AuraSpinParts = {}
        local ws = game:GetService("Workspace")

        -- attach BodyAngularVelocity
        local hrp = BotEnv.GetBotHRP()
        if hrp then
            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(0, speed, 0)
            bav.MaxTorque       = Vector3.new(0, math.huge, 0)
            bav.P               = 9999
            bav.Name            = "AuraSpinBAV"
            bav.Parent          = hrp
        end

        -- ring definitions: {count, radius, yOffset, spinMult}
        local RINGS = {
            {count=10, radius=4.0, yOff=0.0,  spinMult=1.0},
            {count=8,  radius=3.0, yOff=1.5,  spinMult=-1.3},
            {count=6,  radius=2.0, yOff=3.0,  spinMult=2.1},
        }

        local orbs = {}
        local hueOffsets = {0, 0.33, 0.66}

        for ri, ring in ipairs(RINGS) do
            orbs[ri] = {}
            for i = 1, ring.count do
                local p = Instance.new("Part")
                p.Size        = Vector3.new(0.55, 0.55, 0.55)
                p.Shape       = Enum.PartType.Ball
                p.Material    = Enum.Material.Neon
                p.CanCollide  = false
                p.Anchored    = true
                p.CastShadow  = false
                p.Transparency = 0.12
                p.Name         = "AuraSpinOrb_R" .. ri .. "_" .. i
                p.Parent       = ws
                orbs[ri][i]    = p
                BotEnv.AuraSpinParts[#BotEnv.AuraSpinParts + 1] = p
            end
        end

        local t = 0
        local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraSpin") then BotEnv.DisconnectSafe("AuraSpin_Orbs"); return end
                t = t + dt
                local h = BotEnv.GetBotHRP(); if not h then return end
                local pos = h.Position

                for ri, ring in ipairs(RINGS) do
                    for i, orb in ipairs(orbs[ri]) do
                        if orb and orb.Parent then
                            local a = t * ring.spinMult * 2.5 + (i / ring.count) * math.pi * 2
                            local r = ring.radius + math.sin(t * 3 + i * 0.8) * 0.4
                            local yOff = ring.yOff + math.sin(t * 4 + i * 1.1) * 0.3
                            orb.Position = pos + Vector3.new(math.cos(a)*r, yOff, math.sin(a)*r)
                            orb.Color    = Color3.fromHSV((hueOffsets[ri] + t * 0.1 + i / ring.count) % 1, 1, 1)
                            local s = 0.55 + math.abs(math.sin(t * 6 + i)) * 0.2
                            orb.Size = Vector3.new(s, s, s)
                        end
                    end
                end
            end)
        end)
        BotEnv.TrackConnection("AuraSpin_Orbs", conn)
        BotEnv.Respond("🌀 Aura Spin ON (speed:" .. speed .. ") — gyroscope rings active!")
    end,
}
