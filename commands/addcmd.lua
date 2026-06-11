return {
    Name = "addcmd",
    Category = "admin",
    Permission = 4,
    Aliases = {"addcommand", "loadcmd", "installcmd"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil

        if not BotEnv.IsSuperOwner(executor) then
            BotEnv.RespondError("only superowner can add commands", wt)
            return
        end

        if not args[2] then
            BotEnv.RespondError("usage: ?bot addcmd <raw_url>", wt)
            return
        end

        local url = args[2]
        if not url:match("^https?://") then
            url = BotEnv.GITHUB_RAW_BASE .. url
            if not url:match("%.lua$") then
                url = url .. ".lua"
            end
        end

        BotEnv.Respond("downloading command from: " .. url, wt)

        task.spawn(function()
            local success, cmdName = BotEnv.AddCommandFromUrl(url)
            if success then
                BotEnv.Respond("command '" .. cmdName .. "' added successfully", wt)
            else
                BotEnv.RespondError("failed to add command from url", wt)
            end
        end)
    end,
}
