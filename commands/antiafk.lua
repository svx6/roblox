return {
    Name = "antiafk", Category = "admin", Permission = 2, Aliases = {"aafk", "noafk"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local isOn = BotEnv.GetFlag("IsAntiAFK")
        if mode == "on" or mode == "1" then BotEnv.ToggleAntiAFK(true); BotEnv.Respond("AntiAFK ON")
        elseif mode == "off" or mode == "0" then BotEnv.ToggleAntiAFK(false); BotEnv.Respond("AntiAFK OFF")
        else if isOn then BotEnv.ToggleAntiAFK(false); BotEnv.Respond("AntiAFK OFF") else BotEnv.ToggleAntiAFK(true); BotEnv.Respond("AntiAFK ON") end end
    end,
}
