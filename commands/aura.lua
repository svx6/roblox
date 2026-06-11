return {
    Name = "aura", Category = "utility", Permission = 1, Aliases = {"unaura", "glow", "auraon"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraActive")
        if isOn then
            BotEnv.SetFlag("IsAuraActive", false); BotEnv.DisconnectSafe("Aura")
            for _, pt in ipairs(BotEnv.AuraParts) do pcall(function() pt:Destroy() end) end
            BotEnv.AuraParts = {}; BotEnv.Respond("Aura OFF")
        else
            BotEnv.SetFlag("IsAuraActive", true); BotEnv.DisconnectSafe("Aura")
            local particles = {}
            for i = 1, 8 do
                local p = Instance.new("Part"); p.Size = Vector3.new(0.5, 0.5, 0.5); p.Shape = Enum.PartType.Ball
                p.Material = Enum.Material.Neon; p.CanCollide = false; p.Anchored = true
                p.Transparency = 0.3; p.BrickColor = BrickColor.Random()
                p.Name = "BotAura" .. i; p.Parent = game:GetService("Workspace")
                particles[i] = p; BotEnv.AuraParts[#BotEnv.AuraParts+1] = p
            end
            local t = 0
            local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
                pcall(function()
                    if not BotEnv.GetFlag("IsAuraActive") then BotEnv.DisconnectSafe("Aura"); return end
                    t = t + dt
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    for i, p in ipairs(particles) do
                        if p and p.Parent then
                            local a = t * 3 + (i / #particles) * math.pi * 2
                            local r = 3 + math.sin(t * 2 + i) * 0.5
                            local y = math.sin(t * 4 + i * 0.8) * 2
                            p.Position = hrp.Position + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
                            p.Color = Color3.fromHSV((t * 0.1 + i * 0.1) % 1, 1, 1)
                        end
                    end
                end)
            end)
            BotEnv.TrackConnection("Aura", conn)
            BotEnv.Respond("Aura ON")
        end
    end,
}
