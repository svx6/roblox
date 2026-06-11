return {
    Name = "status", Category = "info", Permission = 1, Aliases = {"stat", "info", "botinfo", "botstat"},
    Execute = function(BotEnv, args, executor, restArgs)
        local st = BotEnv.safeTick or tick or os.clock or function() return 0 end
        local uptime = st() - BotEnv.BotStartTime
        local h = math.floor(uptime / 3600)
        local m = math.floor((uptime % 3600) / 60)
        local s = math.floor(uptime % 60)
        local alive = 0; local dead = 0
        for _, d in pairs(BotEnv.ConnectionRegistry) do if d.alive then alive = alive + 1 else dead = dead + 1 end end
        local cmdCount = 0; for _ in pairs(BotEnv.CommandRegistry) do cmdCount = cmdCount + 1 end
        local playerCount = #BotEnv.Players:GetPlayers()
        local ns = BotEnv.GetNetworkStats and BotEnv.GetNetworkStats() or {}
        local flags = {}
        if BotEnv.GetFlag("IsGodMode") then flags[#flags+1] = "God" end
        if BotEnv.GetFlag("IsNoClip") then flags[#flags+1] = "NC" end
        if BotEnv.GetFlag("IsFlying") then flags[#flags+1] = "Fly" end
        if BotEnv.GetFlag("IsInfJump") then flags[#flags+1] = "IJ" end
        if BotEnv.GetFlag("IsAntiAFK") then flags[#flags+1] = "AAFK" end
        if BotEnv.GetFlag("IsSpinning") then flags[#flags+1] = "Spin" end
        if BotEnv.GetFlag("IsAutoJoin") then flags[#flags+1] = "AJ" end
        if BotEnv.GetFlag("SpamActive") then flags[#flags+1] = "Spam" end
        if BotEnv.GetFlag("ReportLoopActive") then flags[#flags+1] = "RepLoop" end
        if BotEnv.GetFlag("IsAntiFling") then flags[#flags+1] = "AFling" end
        if BotEnv.GetFlag("IsAntiSlow") then flags[#flags+1] = "ASlow" end
        local lines = {
            "=== BOT STATUS ===",
            "Uptime: " .. string.format("%02d:%02d:%02d", h, m, s),
            "Mode: " .. BotEnv.BotMode(),
            "Owner: " .. BotEnv.SuperOwner,
            "Commands: " .. cmdCount,
            "Players: " .. playerCount,
            "Connections: " .. alive .. " alive / " .. dead .. " dead",
            "HTTP: " .. (ns.totalRequests or 0) .. " req / " .. (ns.failed or 0) .. " fail",
            "Active: " .. (#flags > 0 and table.concat(flags, ", ") or "None"),
            "Executor: " .. BotEnv.ExecutorInfo.ExecutorName,
        }
        -- Add AutoJoin info if active
        if BotEnv.GetAutoJoinStatus then
            local aj = BotEnv.GetAutoJoinStatus()
            if aj.enabled then
                lines[#lines+1] = "AutoJoin: " .. (aj.target or "?") .. " [" .. (aj.lastResult or "?") .. "] #" .. (aj.attempts or 0)
            end
        end
        BotEnv.Respond(table.concat(lines, "\n"))
    end,
}
