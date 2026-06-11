return {
    Name = "strobe", Category = "utility", Permission = 2, Aliases = {"unstrobe", "flash", "disco"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsStrobing")
        if isOn then
            BotEnv.SetFlag("IsStrobing", false); BotEnv.DisconnectSafe("Strobe")
            pcall(function()
                local L = game:GetService("Lighting")
                L.Ambient = BotEnv.OriginalLighting.Ambient; L.Brightness = BotEnv.OriginalLighting.Brightness
                L.FogEnd = BotEnv.OriginalLighting.FogEnd; L.ClockTime = BotEnv.OriginalLighting.ClockTime
            end)
            BotEnv.Respond("Strobe OFF")
        else
            BotEnv.SetFlag("IsStrobing", true)
            local tick_count = 0
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsStrobing") then return end
                    tick_count = tick_count + 1
                    local L = game:GetService("Lighting")
                    if tick_count % 6 < 3 then
                        L.Ambient = Color3.fromRGB(255, 255, 255); L.Brightness = 10; L.ClockTime = 14
                    else
                        L.Ambient = Color3.fromRGB(0, 0, 0); L.Brightness = 0; L.ClockTime = 0
                    end
                end)
            end)
            BotEnv.TrackConnection("Strobe", conn)
            BotEnv.Respond("Strobe ON")
        end
    end,
}
