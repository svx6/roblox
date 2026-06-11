return {
    Name = "autojoin",
    Category = "utility",
    Permission = 3,
    Aliases = {"aj", "autofollow", "autojn"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then
            if BotEnv.GetFlag("IsAutoJoin") then
                BotEnv.StopAutoJoin()
                BotEnv.Respond("AutoJoin disabled")
            else
                BotEnv.RespondError("usage: ?bot autojoin <player> | off | status")
            end
            return
        end

        local subCmd = args[2]:lower()

        if subCmd == "off" or subCmd == "stop" or subCmd == "disable" then
            BotEnv.StopAutoJoin()
            BotEnv.Respond("AutoJoin disabled")
            return
        end

        if subCmd == "status" or subCmd == "info" or subCmd == "stat" then
            if BotEnv.GetAutoJoinStatus then
                local s = BotEnv.GetAutoJoinStatus()
                local lines = {"=== AutoJoin Status ==="}
                lines[#lines+1] = "Enabled: " .. (s.enabled and "YES" or "NO")
                lines[#lines+1] = "Target: " .. (s.target or "none")
                lines[#lines+1] = "Status: " .. (s.lastResult or "unknown")
                lines[#lines+1] = "Attempts: " .. (s.attempts or 0)
                lines[#lines+1] = "Target Found: " .. (s.targetFound and "YES" or "NO")
                if s.lastCheck and s.lastCheck > 0 then
                    local ago = math.floor((BotEnv.safeTick or tick)() - s.lastCheck)
                    lines[#lines+1] = "Last Check: " .. ago .. "s ago"
                end
                if s.lastFoundServer then
                    lines[#lines+1] = "Last Server: " .. tostring(s.lastFoundServer):sub(1, 20) .. "..."
                end
                BotEnv.Respond(table.concat(lines, "\n"))
            else
                -- Fallback for older engine
                if BotEnv.GetFlag("IsAutoJoin") then
                    local target = _G.__BOT_SAVED_SETTINGS and _G.__BOT_SAVED_SETTINGS.AutoJoinTarget or "unknown"
                    BotEnv.Respond("AutoJoin is ON for: " .. target)
                else
                    BotEnv.Respond("AutoJoin is OFF")
                end
            end
            return
        end

        -- Start autojoin for target player
        local targetName = args[2]
        local target = BotEnv.GetSmartTarget(targetName, executor, true)
        if target then
            targetName = target.Name
        end

        local success = BotEnv.StartAutoJoin(targetName)
        if success then
            BotEnv.Respond("AutoJoin enabled for " .. targetName .. " (saved, will follow across servers)")
        else
            BotEnv.RespondError("Failed to start AutoJoin (TeleportService unavailable)")
        end
    end,
}
