return {
    Name = "jump", Category = "utility", Permission = 1, Aliases = {"jp", "jumppower", "jmp"},
    Execute = function(BotEnv, args, executor, restArgs)
        local val = tonumber(args[2]) or 100
        pcall(function() local h = BotEnv.GetBotHumanoid(); if h then h.JumpPower = val; h.UseJumpPower = true end end)
        BotEnv.Respond("JumpPower: " .. val)
    end,
}
