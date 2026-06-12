return {
    Name = "fling",
    Aliases = {"fl", "yeet", "launch"},
    Description = "Fling a player using smart method selection",
    Permission = 2,

    Execute = function(args, executor, isWhisper, BotEnv)
        local targetName = args[1]
        if not targetName or targetName == "" then
            BotEnv.RespondError("Usage: fling <player>", isWhisper and executor or nil)
            return
        end

        local targets = BotEnv.GetMultipleTargets(targetName, executor)
        if not targets or #targets == 0 then
            BotEnv.RespondError("Player not found: " .. targetName, isWhisper and executor or nil)
            return
        end

        -- Read preferred method flag safely
        local preferredMethod = BotEnv.GetFlag("PreferredFlingMethod") or 0
        preferredMethod = tonumber(preferredMethod) or 0

        for _, target in ipairs(targets) do
            if not BotEnv.IsAlive(target) then
                BotEnv.RespondError(target.Name .. " is not alive", isWhisper and executor or nil)
            else
                task.spawn(function()
                    local killed = false

                    -- If preferred method is set, try it first
                    if preferredMethod > 0 and BotEnv.FlingMethods and BotEnv.FlingMethods[preferredMethod] then
                        local ok, result = pcall(BotEnv.FlingMethods[preferredMethod], target, 20)
                        if ok and result then
                            killed = true
                        end
                    end

                    -- Fallback to smart fling if preferred didn't work or wasn't set
                    if not killed then
                        if not target or not target.Parent or not BotEnv.IsAlive(target) then
                            killed = true
                        else
                            pcall(BotEnv.ExecuteSmartFling, target)
                            killed = not BotEnv.IsAlive(target)
                        end
                    end

                    -- Record result into stats system if flingmethod module loaded it
                    if type(BotEnv._FlingRecordResult) == "function" then
                        local methodUsed = preferredMethod > 0 and preferredMethod or 0
                        pcall(BotEnv._FlingRecordResult, methodUsed, killed)
                    end
                end)
            end
        end
    end,
}
