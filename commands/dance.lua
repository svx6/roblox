return {
    Name = "dance", Category = "utility", Permission = 1, Aliases = {"undance", "emote"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsDancing")
        if isOn then
            BotEnv.SetFlag("IsDancing", false); BotEnv.DisconnectSafe("Dance"); BotEnv.Respond("Dance OFF")
        else
            BotEnv.SetFlag("IsDancing", true); BotEnv.DisconnectSafe("Dance")
            local t = 0
            local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
                pcall(function()
                    if not BotEnv.GetFlag("IsDancing") then BotEnv.DisconnectSafe("Dance"); return end
                    t = t + dt
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    local x = math.sin(t * 4) * 3
                    local z = math.cos(t * 4) * 3
                    local y = math.abs(math.sin(t * 8)) * 2
                    hrp.CFrame = hrp.CFrame * CFrame.new(x * 0.02, y * 0.02, z * 0.02) * CFrame.Angles(0, math.sin(t * 3) * 0.1, math.sin(t * 5) * 0.05)
                end)
            end)
            BotEnv.TrackConnection("Dance", conn)
            BotEnv.Respond("Dance ON")
        end
    end,
}
