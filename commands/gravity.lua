return {
    Name = "gravity", Category = "utility", Permission = 2, Aliases = {"grav", "setgrav"},
    Execute = function(BotEnv, args, executor, restArgs)
        local val = tonumber(args[2])
        if not val then
            pcall(function() game:GetService("Workspace").Gravity = BotEnv.OriginalGravity end)
            BotEnv.Respond("Gravity reset to " .. BotEnv.OriginalGravity)
        else
            pcall(function() game:GetService("Workspace").Gravity = val end)
            BotEnv.Respond("Gravity: " .. val)
        end
    end,
}
