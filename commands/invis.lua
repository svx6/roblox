return {
    Name = "invis", Category = "utility", Permission = 2, Aliases = {"invisible", "vis", "visible", "uninvis"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local isVis = true
        pcall(function()
            local c = BotEnv.LocalPlayer.Character
            if c then local h = c:FindFirstChild("Head"); if h then isVis = h.Transparency < 0.5 end end
        end)
        if mode == "on" or mode == "1" then
            BotEnv.SetInvisible(true); BotEnv.Respond("Invisible ON")
        elseif mode == "off" or mode == "0" then
            BotEnv.SetInvisible(false); BotEnv.Respond("Visible")
        else
            if isVis then BotEnv.SetInvisible(true); BotEnv.Respond("Invisible ON")
            else BotEnv.SetInvisible(false); BotEnv.Respond("Visible") end
        end
    end,
}
