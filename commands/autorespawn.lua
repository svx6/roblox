return {
    Name = "autorespawn", Category = "admin", Permission = 2, Aliases = {"unautorespawn", "ars", "autors"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAutoRespawn")
        if isOn then
            BotEnv.SetFlag("IsAutoRespawn", false); BotEnv.DisconnectSafe("AutoRespawn"); BotEnv.Respond("AutoRespawn OFF")
        else
            BotEnv.SetFlag("IsAutoRespawn", true); BotEnv.DisconnectSafe("AutoRespawn")
            local conn = BotEnv.LocalPlayer.CharacterAdded:Connect(function(c)
                pcall(function()
                    if not BotEnv.GetFlag("IsAutoRespawn") then return end
                    task.wait(0.5)
                    if BotEnv.GetFlag("IsGodMode") then pcall(BotEnv.StartGodMode) end
                    if BotEnv.GetFlag("IsNoClip") then pcall(BotEnv.StartNoClip) end
                end)
            end)
            BotEnv.TrackConnection("AutoRespawn", conn)
            BotEnv.Respond("AutoRespawn ON")
        end
    end,
}
