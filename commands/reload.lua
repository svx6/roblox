return {
    Name = "reload", Category = "admin", Permission = 3, Aliases = {"rl", "reloadcmds"},
    Execute = function(BotEnv, args, executor, restArgs)
        if BotEnv.ReloadAllCommands then
            BotEnv.Respond("Reloading commands...")
            task.spawn(function()
                local loaded, failed = BotEnv.ReloadAllCommands()
                BotEnv.Respond("Reloaded: " .. loaded .. " commands, " .. failed .. " failed")
            end)
        else BotEnv.RespondError("Reload not available") end
    end,
}
