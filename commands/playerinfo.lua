return {
    Name = "playerinfo", Category = "info", Permission = 1, Aliases = {"pinfo", "whois", "lookup", "age"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: playerinfo <player>"); return end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        local ageD = math.floor(t.AccountAge)
        local ageY = string.format("%.1f", ageD / 365)
        local hrp = BotEnv.GetHRP(t)
        local bhrp = BotEnv.GetBotHRP()
        local dist = (hrp and bhrp) and math.floor((hrp.Position - bhrp.Position).Magnitude) or "?"
        local hum = BotEnv.GetHumanoid(t)
        local hp = hum and math.floor(hum.Health) or "?"
        local maxhp = hum and math.floor(hum.MaxHealth) or "?"
        local ws = hum and math.floor(hum.WalkSpeed) or "?"
        local jp = hum and math.floor(hum.JumpPower) or "?"
        local team = t.Team and t.Team.Name or "None"
        local perm = BotEnv.GetPermLevel(t)
        local lines = {
            "=== " .. t.Name .. " ===",
            "Display: " .. t.DisplayName,
            "ID: " .. t.UserId,
            "Age: " .. ageD .. " days (" .. ageY .. " yrs)",
            "Team: " .. team,
            "HP: " .. hp .. "/" .. maxhp,
            "Speed: " .. ws .. " | Jump: " .. jp,
            "Distance: " .. dist .. " studs",
            "Perm Level: " .. perm,
        }
        BotEnv.Respond(table.concat(lines, "\n"))
    end,
}
