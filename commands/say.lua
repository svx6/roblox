return {
    Name = "say", Category = "utility", Permission = 2, Aliases = {"chat", "msg"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not restArgs or restArgs == "" then BotEnv.RespondError("Usage: say <message>"); return end
        BotEnv.SendChatMessage(BotEnv.BypassText(restArgs))
        BotEnv.Respond("Said: " .. restArgs)
    end,
}
