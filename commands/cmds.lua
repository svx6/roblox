return {
    Name = "cmds", Category = "info", Permission = 1, Aliases = {"commands", "help", "h", "cmdlist"},
    Execute = function(BotEnv, args, executor, restArgs)
        local cats = {}
        for name, mod in pairs(BotEnv.CommandRegistry) do
            local cat = mod.Category or "other"
            if not cats[cat] then cats[cat] = {} end
            cats[cat][#cats[cat]+1] = name
        end
        local lines = {"=== BOT COMMANDS ==="}
        local order = {"combat","movement","utility","admin","info","mm2","other"}
        for _, cat in ipairs(order) do
            if cats[cat] and #cats[cat] > 0 then
                table.sort(cats[cat])
                lines[#lines+1] = "[" .. cat:upper() .. "] " .. table.concat(cats[cat], ", ")
                cats[cat] = nil
            end
        end
        for cat, cmds in pairs(cats) do
            table.sort(cmds)
            lines[#lines+1] = "[" .. cat:upper() .. "] " .. table.concat(cmds, ", ")
        end
        lines[#lines+1] = "Total: " .. tostring(BotEnv.GetLoadedCommandCount and BotEnv.GetLoadedCommandCount() or "?") .. " commands"
        lines[#lines+1] = "Prefixes: ?bot .bot ,bot /bot"
        BotEnv.Respond(table.concat(lines, "\n"))
    end,
}
