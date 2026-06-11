return {
    Name = "time", Category = "utility", Permission = 1, Aliases = {"settime", "daytime", "night", "day", "noon", "midnight"},
    Execute = function(BotEnv, args, executor, restArgs)
        local cmd = args[1]:lower()
        local presets = {day=14, night=0, noon=12, midnight=0, morning=7, evening=18, sunset=17.5, sunrise=6.5}
        local val = presets[cmd] or tonumber(args[2]) or nil
        if not val then
            local current = 14
            pcall(function() current = game:GetService("Lighting").ClockTime end)
            BotEnv.Respond("Current time: " .. string.format("%.1f", current)); return
        end
        pcall(function() game:GetService("Lighting").ClockTime = val end)
        BotEnv.Respond("Time set to " .. string.format("%.1f", val))
    end,
}
