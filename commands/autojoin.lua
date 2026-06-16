return {
    Name = "autojoin",
    Category = "utility",
    Permission = 3,
    Aliases = {"aj", "autofollow", "autojn"},
    Execute = function(BotEnv, args, executor, restArgs)
        local sub = (args[2] or ""):lower()
        if sub == "" then
            if BotEnv.GetFlag("IsAutoJoin") then
                BotEnv.StopAutoJoin()
                BotEnv.Respond("AutoJoin disabled")
            else
                BotEnv.RespondError("Usage: autojoin <player> | off | status | retry")
            end
            return
        end
        if sub == "off" or sub == "stop" or sub == "disable" then
            BotEnv.StopAutoJoin()
            BotEnv.Respond("AutoJoin disabled")
            return
        end
        if sub == "status" or sub == "info" or sub == "stat" or sub == "check" then
            local s = BotEnv.GetAutoJoinStatus()
            if s then
                local lines = {
                    "=== AutoJoin Status ===",
                    "Enabled:  " .. (s.enabled and "YES" or "NO"),
                    "Target:   " .. (s.target or "none"),
                    "Status:   " .. (s.lastResult or "unknown"),
                    "Attempts: " .. tostring(s.attempts or 0),
                    "Found:    " .. (s.targetFound and "YES" or "NO"),
                }
                if s.lastCheck and s.lastCheck > 0 then
                    local ago = math.floor((BotEnv.safeTick or tick)() - s.lastCheck)
                    lines[#lines+1] = "Last check: " .. ago .. "s ago"
                end
                if s.lastFoundServer then
                    lines[#lines+1] = "Server: " .. tostring(s.lastFoundServer):sub(1, 24) .. "..."
                end
                BotEnv.Respond(table.concat(lines, "\n"))
            else
                BotEnv.Respond(BotEnv.GetFlag("IsAutoJoin") and "AutoJoin ON" or "AutoJoin OFF")
            end
            return
        end
        if sub == "retry" or sub == "restart" or sub == "reset" then
            local current = BotEnv.GetFlag("AutoJoinTarget")
            if not current or current == "" then
                pcall(function()
                    current = _G.__BOT_SAVED_SETTINGS and _G.__BOT_SAVED_SETTINGS.AutoJoinTarget
                end)
            end
            if not current or current == "" then
                BotEnv.RespondError("No active target to retry")
                return
            end
            BotEnv.StopAutoJoin()
            task.wait(0.3)
            local ok = BotEnv.StartAutoJoin(current)
            if ok then
                BotEnv.Respond("AutoJoin restarted for: " .. current)
            else
                BotEnv.RespondError("Retry failed - TeleportService unavailable")
            end
            return
        end
        local targetName = args[2]
        local inServer = BotEnv.GetSmartTarget(targetName, executor, true)
        if inServer then
            targetName = inServer.Name
        else
            for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                if p.Name:lower() == targetName:lower() then
                    targetName = p.Name
                    break
                end
            end
        end
        if BotEnv.GetFlag("IsAutoJoin") then
            BotEnv.StopAutoJoin()
            task.wait(0.2)
        end
        local ok = BotEnv.StartAutoJoin(targetName)
        if ok then
            BotEnv.Respond("AutoJoin ON -> " .. targetName .. "\nChecks every ~16s. Faster when target online.\nCommands: autojoin status | off | retry")
        else
            BotEnv.RespondError("Failed to start AutoJoin - TeleportService unavailable")
        end
    end,
}
