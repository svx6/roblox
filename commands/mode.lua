return {
    Name = "mode", Category = "admin", Permission = 3, Aliases = {"botmode", "public", "private"},
    Execute = function(BotEnv, args, executor, restArgs)
        local cmd = args[1]:lower()
        local mode = args[2] and args[2]:lower() or nil
        if cmd == "public" then mode = "public"
        elseif cmd == "private" then mode = "private" end
        if mode == "public" then BotEnv.SetBotMode("public"); BotEnv.Respond("Mode: PUBLIC (everyone can use)")
        elseif mode == "private" then BotEnv.SetBotMode("private"); BotEnv.Respond("Mode: PRIVATE (perm only)")
        else
            if BotEnv.BotMode() == "public" then BotEnv.SetBotMode("private"); BotEnv.Respond("Mode: PRIVATE")
            else BotEnv.SetBotMode("public"); BotEnv.Respond("Mode: PUBLIC") end
        end
    end,
}
