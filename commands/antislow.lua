return {
    Name = "antislow", Category = "admin", Permission = 2, Aliases = {"unantislow", "as", "noslow"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAntiSlow")
        if isOn then
            BotEnv.SetFlag("IsAntiSlow", false); BotEnv.DisconnectSafe("AntiSlow"); BotEnv.Respond("AntiSlow OFF")
        else
            BotEnv.SetFlag("IsAntiSlow", true); BotEnv.DisconnectSafe("AntiSlow")
            local minSpeed = tonumber(args[2]) or 16
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsAntiSlow") then return end
                    local hum = BotEnv.GetBotHumanoid(); if not hum then return end
                    if hum.WalkSpeed < minSpeed then hum.WalkSpeed = minSpeed end
                    if hum.JumpPower < 50 then hum.JumpPower = 50 end
                end)
            end)
            BotEnv.TrackConnection("AntiSlow", conn)
            BotEnv.Respond("AntiSlow ON (min:" .. minSpeed .. ")")
        end
    end,
}
