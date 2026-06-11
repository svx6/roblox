return {
    Name = "speed", Category = "utility", Permission = 1, Aliases = {"spd", "ws", "walkspeed"},
    Execute = function(BotEnv, args, executor, restArgs)
        local val = tonumber(args[2]) or 50
        pcall(function() local h = BotEnv.GetBotHumanoid(); if h then h.WalkSpeed = val end end)
        BotEnv.Respond("Speed: " .. val)
    end,
}
