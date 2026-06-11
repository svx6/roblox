return {
    Name = "netstat", Category = "info", Permission = 1, Aliases = {"nstat", "network", "httpstats"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not BotEnv.GetNetworkStats then BotEnv.RespondError("Network stats unavailable"); return end
        local s = BotEnv.GetNetworkStats()
        local lines = {
            "=== NETWORK ===",
            "Loaded: " .. (s.loaded or 0),
            "Failed: " .. (s.failed or 0),
            "Cache Hits: " .. (s.cacheHits or 0),
            "Total Requests: " .. (s.totalRequests or 0),
            "Active Downloads: " .. (s.activeDownloads or 0),
        }
        if s.failedList and #s.failedList > 0 then
            lines[#lines+1] = "Failed: " .. table.concat(s.failedList, ", ")
        end
        BotEnv.Respond(table.concat(lines, "\n"))
    end,
}
