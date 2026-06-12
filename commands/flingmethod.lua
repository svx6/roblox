return {
    Name = "flingmethod",
    Aliases = {"fm", "fmethod", "setfling"},
    Description = "Manage fling method selection and view stats",
    Permission = 2,

    Execute = function(BotEnv, args, executor, restArgs)
        local sub = (args[2] or ""):lower()

        -- Initialise stats table once, in a stable upvalue
        -- so all closures below always point to the same object
        if not BotEnv._FlingStats then
            BotEnv._FlingStats = {
                uses    = {},   -- methodId -> total attempts
                kills   = {},   -- methodId -> confirmed kills
                lastId  = 0,
                lastKill = false,
            }
        end
        local S = BotEnv._FlingStats

        -- ── helpers ────────────────────────────────────────────────

        -- Record a fling attempt result
        -- Called from fling.lua and flingbypass.lua
        BotEnv._FlingRecordResult = function(methodId, killed)
            methodId = tonumber(methodId) or 0
            S.uses[methodId]  = (S.uses[methodId]  or 0) + 1
            S.kills[methodId] = (S.kills[methodId] or 0) + (killed and 1 or 0)
            S.lastId   = methodId
            S.lastKill = killed
        end

        -- Return the best method id based on kill ratio (needs >=3 uses)
        BotEnv._FlingSmartPick = function()
            local bestId, bestRatio = 0, -1
            for id, uses in pairs(S.uses) do
                if uses >= 3 then
                    local ratio = (S.kills[id] or 0) / uses
                    if ratio > bestRatio then
                        bestRatio = ratio
                        bestId = id
                    end
                end
            end
            return bestId, bestRatio
        end

        -- Returns true if we have enough data to smart-pick
        BotEnv._FlingHasData = function()
            local total = 0
            for _, v in pairs(S.uses) do total = total + v end
            return total >= 5
        end

        -- ── subcommands ────────────────────────────────────────────

        if sub == "set" or sub == "use" then
            local id = tonumber(args[3])
            if not id then
                BotEnv.RespondError("Usage: flingmethod set <1-9>", nil)
                return
            end
            if id < 0 or id > 9 then
                BotEnv.RespondError("Method must be 0-9 (0 = auto)", nil)
                return
            end
            BotEnv.SetFlag("PreferredFlingMethod", id)
            if id == 0 then
                BotEnv.Respond("Fling method: AUTO (smart pick)", nil, true)
            else
                BotEnv.Respond("Fling method set to #" .. id, nil, true)
            end

        elseif sub == "stats" or sub == "info" then
            local lines = {"=== Fling Stats ==="}
            local methodNames = {
                [0]  = "Auto/Unknown",
                [1]  = "BodyVelocity Spam",
                [2]  = "Orbital Offset",
                [3]  = "Burst Teleport",
                [4]  = "CanCollide Pulse",
                [5]  = "Seat Launch",
                [6]  = "MicroPulse",
                [7]  = "MassSlam",
                [8]  = "PartProjectile",
                [9]  = "TouchSpam",
                [10] = "AntiFling Bypass",
            }
            local hasAny = false
            for id = 0, 10 do
                local uses = S.uses[id] or 0
                if uses > 0 then
                    hasAny = true
                    local kills  = S.kills[id] or 0
                    local ratio  = math.floor((kills / uses) * 100)
                    local nm     = methodNames[id] or ("Method " .. id)
                    lines[#lines+1] = string.format("#%d %-18s %d/%d (%d%%)", id, nm, kills, uses, ratio)
                end
            end
            if not hasAny then lines[#lines+1] = "No data yet" end
            local bestId, bestRatio = BotEnv._FlingSmartPick()
            if bestId > 0 then
                lines[#lines+1] = "Best: #" .. bestId .. " (" .. math.floor(bestRatio*100) .. "% kills)"
            end
            local preferred = BotEnv.GetFlag("PreferredFlingMethod") or 0
            lines[#lines+1] = "Current preference: " .. (preferred > 0 and ("#" .. preferred) or "AUTO")
            BotEnv.Respond(table.concat(lines, "\n"), nil, true)

        elseif sub == "reset" or sub == "clear" then
            -- Wipe in-place so all closures keep pointing at the same table object
            for k in pairs(S.uses)  do S.uses[k]  = nil end
            for k in pairs(S.kills) do S.kills[k] = nil end
            S.lastId   = 0
            S.lastKill = false
            BotEnv.SetFlag("PreferredFlingMethod", 0)
            BotEnv.Respond("Fling stats cleared, method reset to AUTO", nil, true)

        elseif sub == "auto" then
            BotEnv.SetFlag("PreferredFlingMethod", 0)
            BotEnv.Respond("Fling method: AUTO", nil, true)

        elseif sub == "best" then
            if not BotEnv._FlingHasData() then
                BotEnv.Respond("Not enough data yet (need 5+ attempts)", nil, true)
                return
            end
            local bestId, bestRatio = BotEnv._FlingSmartPick()
            if bestId > 0 then
                BotEnv.SetFlag("PreferredFlingMethod", bestId)
                BotEnv.Respond("Set to best method #" .. bestId .. " (" .. math.floor(bestRatio*100) .. "% kill rate)", nil, true)
            else
                BotEnv.Respond("No clear winner yet, staying on AUTO", nil, true)
            end

        else
            -- Default: show current setting
            local preferred = BotEnv.GetFlag("PreferredFlingMethod") or 0
            local msg = "Fling method: " .. (preferred > 0 and ("#" .. preferred) or "AUTO")
            msg = msg .. "\nSubs: set <n> | stats | reset | auto | best"
            BotEnv.Respond(msg, nil, true)
        end
    end,
}
