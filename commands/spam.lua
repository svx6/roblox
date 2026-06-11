return {
    Name = "spam", Category = "combat", Permission = 2, Aliases = {"chatspam", "unspam", "stopspam"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil

        -- Handle stop commands
        if mode == "off" or mode == "stop" or mode == "0" then
            BotEnv.SetFlag("SpamActive", false)
            BotEnv.DisconnectSafe("Spam")
            BotEnv.Respond("Spam OFF")
            return
        end

        -- Toggle off if already running
        if BotEnv.GetFlag("SpamActive") then
            BotEnv.SetFlag("SpamActive", false)
            BotEnv.DisconnectSafe("Spam")
            BotEnv.Respond("Spam OFF")
            return
        end

        -- Get spam text (skip "on" as text)
        local text
        if mode == "on" or mode == "1" then
            -- "on" is a mode switch, use restArgs minus "on"
            local rest2 = restArgs and restArgs:match("^%S+%s+(.+)$")
            text = (rest2 and rest2 ~= "") and rest2 or "get rekt"
        else
            text = (restArgs and restArgs ~= "") and restArgs or "get rekt"
        end

        -- Start spam with proper flag tracking
        BotEnv.SetFlag("SpamActive", true)
        BotEnv.DisconnectSafe("Spam")

        -- Spawn the spam loop — checks flag on every iteration
        task.spawn(function()
            while BotEnv.GetFlag("SpamActive") do
                pcall(function() BotEnv.SendChatMessage(BotEnv.BypassText(text)) end)
                task.wait(1.2)
            end
        end)

        -- Track a real connection so DisconnectSafe can kill it
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            if not BotEnv.GetFlag("SpamActive") then
                BotEnv.DisconnectSafe("Spam")
            end
        end)
        BotEnv.TrackConnection("Spam", conn)
        BotEnv.Respond("Spam ON: " .. text)
    end,
}
