return {
    Name = "antivoid", Category = "admin", Permission = 2, Aliases = {"unantivoid", "av", "novoid"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAntiVoid")
        if isOn then
            BotEnv.SetFlag("IsAntiVoid", false); BotEnv.DisconnectSafe("AntiVoid"); BotEnv.Respond("AntiVoid OFF")
        else
            BotEnv.SetFlag("IsAntiVoid", true); BotEnv.DisconnectSafe("AntiVoid")
            local safePos = nil
            pcall(function() local h = BotEnv.GetBotHRP(); if h then safePos = h.CFrame end end)
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsAntiVoid") then return end
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    if hrp.Position.Y > -50 then safePos = hrp.CFrame
                    else if safePos then hrp.CFrame = safePos end end
                end)
            end)
            BotEnv.TrackConnection("AntiVoid", conn)
            BotEnv.Respond("AntiVoid ON")
        end
    end,
}
