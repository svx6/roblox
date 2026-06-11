return {
    Name = "whisper", Category = "utility", Permission = 2, Aliases = {"w", "dm", "pm"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] or not args[3] then BotEnv.RespondError("Usage: whisper <player> <message>"); return end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        local msg = ""
        for i = 3, #args do msg = msg .. (i > 3 and " " or "") .. args[i] end
        BotEnv.SendWhisperMessage(t, BotEnv.BypassText(msg))
        BotEnv.Respond("Whispered to " .. t.Name)
    end,
}
