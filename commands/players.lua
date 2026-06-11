return {
    Name = "players", Category = "info", Permission = 1, Aliases = {"list", "who", "playerlist", "online"},
    Execute = function(BotEnv, args, executor, restArgs)
        local pl = BotEnv.Players:GetPlayers()
        local lines = {"=== PLAYERS (" .. #pl .. ") ==="}
        local bhrp = BotEnv.GetBotHRP()
        for _, p in ipairs(pl) do
            local dist = "?"
            pcall(function()
                local h = BotEnv.GetHRP(p)
                if h and bhrp then dist = tostring(math.floor((h.Position - bhrp.Position).Magnitude)) end
            end)
            local perm = BotEnv.GetPermLevel(p)
            local hp = "?"
            pcall(function() local h = BotEnv.GetHumanoid(p); if h then hp = tostring(math.floor(h.Health)) end end)
            local marker = ""
            if p == BotEnv.LocalPlayer then marker = " [BOT]"
            elseif BotEnv.IsSuperOwner(p) then marker = " [OWNER]"
            elseif perm >= 2 then marker = " [P" .. perm .. "]" end
            lines[#lines+1] = p.Name .. marker .. " | HP:" .. hp .. " | " .. dist .. "m"
        end
        BotEnv.Respond(table.concat(lines, "\n"))
    end,
}
