return {
    Name = "god", Category = "utility", Permission = 2, Aliases = {"godmode", "ungod", "nogod", "ugod"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local isOn = BotEnv.GetFlag("IsGodMode")
        if mode == "on" or mode == "1" then
            if not isOn then pcall(BotEnv.StartGodMode) end
            BotEnv.Respond("God ON")
        elseif mode == "off" or mode == "0" then
            pcall(BotEnv.StopGodMode)
            BotEnv.Respond("God OFF")
        else
            if isOn then pcall(BotEnv.StopGodMode); BotEnv.Respond("God OFF")
            else pcall(BotEnv.StartGodMode); BotEnv.Respond("God ON") end
        end
    end,
}
