return {
    Name = "noclip", Category = "utility", Permission = 1, Aliases = {"nc", "clip", "unclip"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local isOn = BotEnv.GetFlag("IsNoClip")
        if mode == "on" or mode == "1" then
            if not isOn then pcall(BotEnv.StartNoClip) end; BotEnv.Respond("NoClip ON")
        elseif mode == "off" or mode == "0" then
            pcall(BotEnv.StopNoClip); BotEnv.Respond("NoClip OFF")
        else
            if isOn then pcall(BotEnv.StopNoClip); BotEnv.Respond("NoClip OFF")
            else pcall(BotEnv.StartNoClip); BotEnv.Respond("NoClip ON") end
        end
    end,
}
