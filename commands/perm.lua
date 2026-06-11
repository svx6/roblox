return {
    Name = "perm",
    Category = "admin",
    Permission = 3,
    Aliases = {"perms", "permit", "permission"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil

        if not BotEnv.IsSuperOwner(executor) and BotEnv.GetPermLevel(executor) < 3 then
            BotEnv.RespondError("only level 3+ or superowner can use perm", wt)
            return
        end

        if not args[2] then
            BotEnv.RespondError("usage: ?bot perm <player/list> [level/save/unsave/remove]", wt)
            return
        end

        local subCmd = args[2]:lower()

        if subCmd == "list" then
            local lines = {"Permitted Users:"}
            for name, level in pairs(BotEnv.PermittedUsers) do
                local savedTag = ""
                if _G.__BOT_SAVED_PERMS and _G.__BOT_SAVED_PERMS[name] then
                    savedTag = " [SAVED]"
                end
                table.insert(lines, "  " .. name .. " = Level " .. tostring(level) .. savedTag)
            end
            BotEnv.Respond(table.concat(lines, "\n"), wt)
            return
        end

        local target = BotEnv.GetSmartTarget(args[2], executor, true)
        if not target then
            BotEnv.RespondError("cant find player: " .. args[2], wt)
            return
        end

        if BotEnv.IsSuperOwner(target) and not BotEnv.IsSuperOwner(executor) then
            BotEnv.RespondError("cannot modify superowner permissions", wt)
            return
        end

        local action = args[3] and args[3]:lower() or nil

        if not action then
            BotEnv.SetPermission(target.Name, 1, false)
            BotEnv.Respond(target.Name .. " granted perm level 1", wt)
            return
        end

        if action == "save" then
            local currentLevel = BotEnv.GetPermLevel(target)
            if currentLevel < 1 then currentLevel = 1 end
            BotEnv.SetPermission(target.Name, currentLevel, true)
            BotEnv.Respond(target.Name .. " perm level " .. currentLevel .. " SAVED (persists across restarts)", wt)
            return
        end

        if action == "unsave" then
            BotEnv.RemovePermission(target.Name, true)
            BotEnv.Respond(target.Name .. " perm UNSAVED and removed", wt)
            return
        end

        if action == "remove" or action == "revoke" or action == "delete" then
            BotEnv.RemovePermission(target.Name, true)
            BotEnv.Respond(target.Name .. " perm removed completely", wt)
            return
        end

        local level = tonumber(action)
        if level then
            if level < 0 or level > 3 then
                BotEnv.RespondError("level must be 0-3 (4 is superowner only)", wt)
                return
            end
            if not BotEnv.IsSuperOwner(executor) and level >= BotEnv.GetPermLevel(executor) then
                BotEnv.RespondError("cant give equal or higher level than yours", wt)
                return
            end
            local shouldSave = args[4] and args[4]:lower() == "save"
            BotEnv.SetPermission(target.Name, level, shouldSave)
            local saveMsg = shouldSave and " [SAVED]" or ""
            BotEnv.Respond(target.Name .. " set to perm level " .. level .. saveMsg, wt)
            return
        end

        BotEnv.RespondError("unknown action: " .. action .. " | use: save, unsave, remove, or a number 0-3", wt)
    end,
}
