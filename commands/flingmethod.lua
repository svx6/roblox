--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║  FLING METHOD SELECTOR — FINAL ULTRA v3.1                       ║
    ║  Compatible with bot_engine.lua v9.0                            ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║  COMMANDS:                                                       ║
    ║   flingmethod <0-11>           set by number                    ║
    ║   flingmethod <name>           set by name (slam, nuclear…)     ║
    ║   flingmethod auto             AI picks best every fling        ║
    ║   flingmethod best             lock to highest-scored method    ║
    ║   flingmethod bench <target>   test all methods on player       ║
    ║   flingmethod bench others     benchmark on every other player  ║
    ║   flingmethod bench all        benchmark on everyone            ║
    ║   flingmethod cycle            rotate to next method            ║
    ║   flingmethod info             full method list with live stats ║
    ║   flingmethod stats            performance table                ║
    ║   flingmethod reset            wipe all recorded stats          ║
    ║   flingmethod help             show this list                   ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

return {
    Name       = "flingmethod",
    Category   = "fling",
    Permission = 1,
    Aliases    = { "fm", "flingmode", "setfling", "fmethod" },

    Execute = function(BotEnv, args, executor, restArgs)

        -- ════════════════════════════════════════════════════════════
        -- SECTION 1: METHOD REGISTRY
        -- ════════════════════════════════════════════════════════════
        local MethodInfo = {
            [0]  = { name = "auto",       short = "AI picks best method every fling using live kill-rate + speed + streak score.", tags = { "adaptive", "safe" } },
            [1]  = { name = "slam",       short = "CFrame-slams bot onto target with full-axis BodyVelocity + BodyAngularVelocity.", tags = { "fast", "reliable", "direct" } },
            [2]  = { name = "multiangle", short = "Cycles 9 positional offsets while slamming — bypasses many anti-fling shields.", tags = { "bypass", "varied", "angle" } },
            [3]  = { name = "burst",      short = "Randomised linear velocity burst each frame — chaotic, hard to predict or block.", tags = { "chaotic", "random", "anti-predict" } },
            [4]  = { name = "collision",  short = "Toggles CanCollide rapidly while oscillating around target with sine-wave offsets.", tags = { "collision", "physics", "oscillate" } },
            [5]  = { name = "seat",       short = "Spawns invisible seat on target + applies velocity to both simultaneously.", tags = { "seat", "indirect", "dual-force" } },
            [6]  = { name = "nuclear",    short = "All-axis max-force slam with simultaneous BodyVelocity + angular. Most raw power.", tags = { "nuclear", "max", "extreme" } },
            [7]  = { name = "jointbreak", short = "Breaks Motor6D joints to ragdoll target before applying fling velocity.", tags = { "ragdoll", "joints", "destructive" } },
            [8]  = { name = "spinlaunch", short = "Spins bot at high angular velocity into target then releases trajectory burst.", tags = { "spin", "trajectory", "momentum" } },
            [9]  = { name = "velocity6",  short = "Six independent velocity vectors fired simultaneously for maximum spread force.", tags = { "multi-vector", "spread" } },
            [10] = { name = "gravity",    short = "Briefly overrides workspace gravity during fling window to amplify upward force.", tags = { "gravity", "env", "world" } },
            [11] = { name = "rootswap",   short = "Swaps HRP CFrame with target then fires bot velocity — exploits physics sync.", tags = { "swap", "trick", "exploit" } },
        }

        -- ════════════════════════════════════════════════════════════
        -- SECTION 2: STATS — initialise once on BotEnv, persist between calls
        --
        -- CRITICAL FIX: We never replace BotEnv._FlingStats with a new table.
        -- On reset we wipe the contents in-place so all function closures
        -- below that read BotEnv._FlingStats keep pointing at the same object.
        -- ════════════════════════════════════════════════════════════
        if not BotEnv._FlingStats then
            BotEnv._FlingStats = {
                uses        = {},
                kills       = {},
                times       = {},
                streak      = {},
                bestEver    = {},
                lastWin     = 0,
                totalFlings = 0,
            }
        end

        local numMethods = #BotEnv.FlingMethods

        -- Ensure every method slot exists (safe to call repeatedly)
        local function ensureSlots()
            local S   = BotEnv._FlingStats
            local max = math.max(numMethods, 11)
            for id = 1, max do
                S.uses[id]     = S.uses[id]     or 0
                S.kills[id]    = S.kills[id]    or 0
                S.times[id]    = S.times[id]    or 0
                S.streak[id]   = S.streak[id]   or 0
                S.bestEver[id] = S.bestEver[id] or math.huge
            end
        end
        ensureSlots()

        -- ════════════════════════════════════════════════════════════
        -- SECTION 3: STAT HELPER FUNCTIONS
        -- All read BotEnv._FlingStats directly (not a captured local S)
        -- so they stay correct after an in-place reset.
        -- ════════════════════════════════════════════════════════════
        local function mName(id)
            return (MethodInfo[id] and MethodInfo[id].name) or ("m" .. tostring(id))
        end

        local function mLabel(id)
            return tostring(id) .. " (" .. mName(id) .. ")"
        end

        local function killRate(id)
            local u = BotEnv._FlingStats.uses[id] or 0
            if u == 0 then return "n/a" end
            return tostring(math.floor(((BotEnv._FlingStats.kills[id] or 0) / u) * 100)) .. "%"
        end

        local function avgTime(id)
            local u = BotEnv._FlingStats.uses[id] or 0
            if u == 0 then return "n/a" end
            return string.format("%.2fs", (BotEnv._FlingStats.times[id] or 0) / u)
        end

        local function bestTime(id)
            local b = BotEnv._FlingStats.bestEver[id] or math.huge
            if b == math.huge then return "n/a" end
            return string.format("%.2fs", b)
        end

        -- Score formula: kill_rate 60% · speed 25% · streak 15%
        -- Methods with <2 uses get 0.5 so they still get tried
        local function methodScore(id)
            local S = BotEnv._FlingStats
            local u = S.uses[id] or 0
            if u < 2 then return 0.5 end
            local kr     = (S.kills[id] or 0) / u
            local avgT   = (S.times[id] or 0) / u
            local speedB = math.max(0, 1 - (avgT / 5))
            local strkB  = math.min((S.streak[id] or 0) * 0.05, 0.30)
            return (kr * 0.60) + (speedB * 0.25) + (strkB * 0.15)
        end

        local function smartPickMethod()
            local bestId, bestSc = 1, -1
            for id = 1, numMethods do
                local sc = methodScore(id)
                if sc > bestSc then bestSc = sc; bestId = id end
            end
            return bestId
        end

        -- Record one fling result. Always writes into BotEnv._FlingStats.
        local function recordResult(id, killed, elapsed)
            if not id or id < 1 or id > math.max(numMethods, 11) then return end
            local S = BotEnv._FlingStats
            -- ensure slot exists in case reset happened just before this call
            S.uses[id]     = S.uses[id]     or 0
            S.kills[id]    = S.kills[id]    or 0
            S.times[id]    = S.times[id]    or 0
            S.streak[id]   = S.streak[id]   or 0
            S.bestEver[id] = S.bestEver[id] or math.huge

            S.uses[id]    = S.uses[id]    + 1
            S.times[id]   = S.times[id]   + (elapsed or 0)
            S.totalFlings = (S.totalFlings or 0) + 1

            if killed then
                S.kills[id]  = S.kills[id]  + 1
                S.streak[id] = S.streak[id] + 1
                S.lastWin    = id
                if (elapsed or 0) < S.bestEver[id] then
                    S.bestEver[id] = elapsed
                end
            else
                S.streak[id] = 0
            end
        end

        local function hasEnoughData(minUses)
            minUses = minUses or 2
            local S = BotEnv._FlingStats
            for id = 1, numMethods do
                if (S.uses[id] or 0) >= minUses then return true end
            end
            return false
        end

        -- ════════════════════════════════════════════════════════════
        -- SECTION 4: PUBLISH HOOKS FOR fling.lua
        -- Stored on BotEnv so fling.lua can use the same stat system.
        -- Re-published every Execute call so they always point to the
        -- current (possibly reset) closures.
        -- ════════════════════════════════════════════════════════════
        BotEnv._FlingRecordResult = recordResult
        BotEnv._FlingSmartPick   = smartPickMethod
        BotEnv._FlingHasData     = hasEnoughData
        BotEnv._FlingMethodScore = methodScore

        -- ════════════════════════════════════════════════════════════
        -- SECTION 5: PARSE SUBCOMMAND / INPUT
        -- ════════════════════════════════════════════════════════════
        local sub = (args[2] or ""):lower():match("^%s*(.-)%s*$")

        -- Convert method name or tag → its number string
        if sub ~= "" and tonumber(sub) == nil then
            local reserved = {
                info=true, list=true, stats=true, reset=true, best=true,
                bench=true, cycle=true, auto=true, help=true,
                others=true, all=true,
            }
            if not reserved[sub] then
                -- try exact name match
                for id = 0, 11 do
                    local info = MethodInfo[id]
                    if info and info.name == sub then
                        sub = tostring(id)
                        break
                    end
                end
                -- try tag match
                if tonumber(sub) == nil then
                    for id = 0, 11 do
                        local info = MethodInfo[id]
                        if info and info.tags then
                            for _, tag in ipairs(info.tags) do
                                if tag == sub then
                                    sub = tostring(id)
                                    break
                                end
                            end
                        end
                        if tonumber(sub) then break end
                    end
                end
            end
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: info / list
        -- ════════════════════════════════════════════════════════════
        if sub == "info" or sub == "list" then
            local S       = BotEnv._FlingStats
            local current = BotEnv.GetFlag("PreferredFlingMethod") or 0
            local lines   = {
                "── fling methods ── " .. numMethods .. " loaded | total flings: " .. tostring(S.totalFlings or 0),
                "current mode: " .. mLabel(current),
            }
            for id = 0, math.max(numMethods, 5) do
                local info   = MethodInfo[id] or { name = "method"..id, short = "No description.", tags = {} }
                local active = (id == current) and " ◄ ACTIVE" or ""
                local loaded = (id == 0 or id <= numMethods) and "" or " [not loaded]"
                local statsStr = ""
                if id > 0 then
                    statsStr = string.format("  kill:%s avg:%s best:%s streak:%d",
                        killRate(id), avgTime(id), bestTime(id), S.streak[id] or 0)
                end
                table.insert(lines, string.format(" %2d: %-12s%s%s%s", id, info.name, active, loaded, statsStr))
                if info.short and info.short ~= "" then
                    table.insert(lines, "      " .. info.short)
                end
                if info.tags and #info.tags > 0 then
                    table.insert(lines, "      [" .. table.concat(info.tags, ", ") .. "]")
                end
            end
            BotEnv.Respond(table.concat(lines, "\n"), nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: stats
        -- ════════════════════════════════════════════════════════════
        if sub == "stats" then
            local S       = BotEnv._FlingStats
            local current = BotEnv.GetFlag("PreferredFlingMethod") or 0
            local ranked  = {}
            for id = 1, numMethods do
                table.insert(ranked, { id = id, sc = methodScore(id) })
            end
            table.sort(ranked, function(a, b) return a.sc > b.sc end)
            local sep   = string.rep("─", 56)
            local lines = {
                "── fling stats ──",
                string.format("mode: %s | total flings: %d | last win: %s",
                    mLabel(current),
                    S.totalFlings or 0,
                    (S.lastWin or 0) > 0 and mLabel(S.lastWin) or "none"
                ),
                "ranked best → worst:", sep,
                string.format(" %-3s %-12s %5s %5s %7s %6s %6s %6s",
                    "#", "Name", "Uses", "Kills", "KRate", "Avg", "Best", "Score"),
                sep,
            }
            for rank, entry in ipairs(ranked) do
                local id     = entry.id
                local info   = MethodInfo[id] or { name = "method"..id }
                local marker = (id == current) and "◄" or " "
                table.insert(lines, string.format("%s%-3d %-12s %5d %5d %7s %6s %6s %6s",
                    marker, rank, info.name,
                    S.uses[id] or 0, S.kills[id] or 0,
                    killRate(id), avgTime(id), bestTime(id),
                    string.format("%.3f", methodScore(id))
                ))
            end
            table.insert(lines, sep)
            if hasEnoughData(3) then
                local bestId = smartPickMethod()
                table.insert(lines, "▶ recommended: " .. mLabel(bestId) ..
                    " (score: " .. string.format("%.3f", methodScore(bestId)) .. ")")
            else
                table.insert(lines, "▶ not enough data — run 'bench <player>' to calibrate")
            end
            BotEnv.Respond(table.concat(lines, "\n"), nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: reset
        -- Wipe in-place — never replace the table object itself
        -- ════════════════════════════════════════════════════════════
        if sub == "reset" then
            local S = BotEnv._FlingStats
            for k in pairs(S.uses)     do S.uses[k]     = nil end
            for k in pairs(S.kills)    do S.kills[k]    = nil end
            for k in pairs(S.times)    do S.times[k]    = nil end
            for k in pairs(S.streak)   do S.streak[k]   = nil end
            for k in pairs(S.bestEver) do S.bestEver[k] = nil end
            S.lastWin     = 0
            S.totalFlings = 0
            ensureSlots()
            BotEnv.Respond("fling stats wiped — all methods start fresh", nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: best
        -- ════════════════════════════════════════════════════════════
        if sub == "best" then
            if not hasEnoughData(2) then
                BotEnv.Respond(
                    "not enough data yet\n" ..
                    "tip: run 'flingmethod bench <player>' to calibrate all methods quickly",
                    nil
                )
                return
            end
            local bestId = smartPickMethod()
            BotEnv.SetFlag("PreferredFlingMethod", bestId)
            BotEnv.Respond(
                "locked best method: " .. mLabel(bestId) ..
                "\n  score: "     .. string.format("%.3f", methodScore(bestId)) ..
                "  kill rate: "   .. killRate(bestId) ..
                "  avg time: "    .. avgTime(bestId) ..
                "  best time: "   .. bestTime(bestId),
                nil
            )
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: auto
        -- ════════════════════════════════════════════════════════════
        if sub == "auto" then
            BotEnv.SetFlag("PreferredFlingMethod", 0)
            local tip = hasEnoughData(2)
                and "smart-pick active (has data)"
                or  "smart-pick warming up (run bench to calibrate)"
            BotEnv.Respond("fling method → 0 (auto)\n" .. tip, nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: bench
        -- ════════════════════════════════════════════════════════════
        if sub == "bench" then
            local targetArg = (args[3] or ""):lower():match("^%s*(.-)%s*$")
            if targetArg == "" then
                BotEnv.RespondError(
                    "usage:\n  flingmethod bench <player>\n  flingmethod bench others\n  flingmethod bench all",
                    nil
                )
                return
            end

            local targets = {}
            if targetArg == "others" then
                for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                    if p ~= BotEnv.LocalPlayer and p ~= executor and BotEnv.IsAlive(p) then
                        table.insert(targets, p)
                    end
                end
            elseif targetArg == "all" then
                for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                    if p ~= BotEnv.LocalPlayer and BotEnv.IsAlive(p) then
                        table.insert(targets, p)
                    end
                end
            else
                local t = BotEnv.GetSmartTarget(targetArg, executor)
                if t then table.insert(targets, t) end
            end

            if #targets == 0 then
                BotEnv.RespondError("no valid targets found for bench", nil)
                return
            end

            local targetNames = {}
            for _, t in ipairs(targets) do table.insert(targetNames, t.Name) end
            BotEnv.Respond(
                "benchmarking " .. numMethods .. " methods on " ..
                #targets .. " target(s): " .. table.concat(targetNames, ", "),
                nil
            )

            task.spawn(function()
                local results    = {}
                local totalKills = 0
                local totalFails = 0

                for id = 1, numMethods do
                    local method = BotEnv.FlingMethods[id]

                    if not method then
                        table.insert(results, string.format(" %2d:%-12s → [NOT LOADED]", id, mName(id)))
                    else
                        local methodKills = 0
                        local methodFails = 0
                        local methodTime  = 0

                        for _, target in ipairs(targets) do
                            -- wait for target to respawn if needed
                            if not BotEnv.IsAlive(target) then
                                local waited = 0
                                repeat
                                    task.wait(0.4)
                                    waited = waited + 0.4
                                until BotEnv.IsAlive(target) or waited >= 8
                            end

                            if not BotEnv.IsAlive(target) or not target.Parent then
                                methodFails = methodFails + 1
                            else
                                local t0        = tick()
                                local ok, kres  = pcall(method, target)
                                local elapsed   = tick() - t0
                                local wasKilled = (ok and kres == true) or not BotEnv.IsAlive(target)

                                recordResult(id, wasKilled, elapsed)
                                methodTime = methodTime + elapsed

                                if wasKilled then
                                    methodKills = methodKills + 1
                                    totalKills  = totalKills  + 1
                                else
                                    methodFails = methodFails + 1
                                    totalFails  = totalFails  + 1
                                end
                                task.wait(0.3)
                            end
                        end

                        local kr  = (#targets > 0) and math.floor((methodKills / #targets) * 100) or 0
                        local avg = (#targets > 0) and string.format("%.2fs", methodTime / #targets) or "n/a"
                        local tag = (methodKills == #targets) and "✓ PERFECT"
                                 or (methodKills > 0)          and "~ partial"
                                 or                               "✗ failed"

                        table.insert(results, string.format(
                            " %2d:%-12s → %s  %d/%d killed  kr:%d%%  avg:%s",
                            id, mName(id), tag, methodKills, #targets, kr, avg
                        ))
                    end

                    task.wait(0.5)
                end

                local bestId = smartPickMethod()
                BotEnv.SetFlag("PreferredFlingMethod", bestId)

                table.insert(results, "")
                table.insert(results, string.rep("─", 48))
                table.insert(results, string.format(
                    "bench complete — killed:%d  failed:%d  best→ %s (score:%.3f)",
                    totalKills, totalFails,
                    mLabel(bestId), methodScore(bestId)
                ))
                BotEnv.Respond(table.concat(results, "\n"), nil)
            end)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: cycle
        -- ════════════════════════════════════════════════════════════
        if sub == "cycle" then
            local current = BotEnv.GetFlag("PreferredFlingMethod") or 0
            local nextId  = (current % numMethods) + 1   -- wraps 1..numMethods
            BotEnv.SetFlag("PreferredFlingMethod", nextId)
            local info = MethodInfo[nextId] or { name = "method"..nextId, short = "" }
            BotEnv.Respond("cycled → " .. mLabel(nextId) .. "\n" .. (info.short or ""), nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SUBCOMMAND: help (or unrecognised text)
        -- ════════════════════════════════════════════════════════════
        if sub == "help" or (sub ~= "" and tonumber(sub) == nil) then
            BotEnv.Respond(table.concat({
                "── flingmethod commands ──",
                "  <0-" .. numMethods .. ">              set method by number",
                "  <name>                 set by name (slam, burst, nuclear…)",
                "  auto                   AI picks every fling",
                "  best                   lock to highest-scored method",
                "  bench <player>         benchmark all methods on one player",
                "  bench others           benchmark on all others",
                "  bench all              benchmark on everyone",
                "  cycle                  rotate to next method",
                "  info                   full method list + live stats",
                "  stats                  ranked performance table",
                "  reset                  wipe all recorded stats",
                "  help                   show this",
                "",
                "aliases: fm, flingmode, setfling, fmethod",
            }, "\n"), nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- SET METHOD BY NUMBER
        -- ════════════════════════════════════════════════════════════
        local method = tonumber(sub)
        if not method then
            BotEnv.RespondError("unknown input — type 'flingmethod help' for options", nil)
            return
        end

        if method < 0 or method > numMethods then
            BotEnv.RespondError(
                "invalid — choose 0 to " .. numMethods ..
                "  (0=auto, 1-" .. numMethods .. "=specific)",
                nil
            )
            return
        end

        BotEnv.SetFlag("PreferredFlingMethod", method)

        local info  = MethodInfo[method] or { name = "method"..method, short = "", tags = {} }
        local label
        if method == 0 then
            label = "auto" .. (hasEnoughData(2) and " (smart-pick ready)" or " (warming up)")
        else
            label = info.name
        end

        BotEnv.Respond(
            "fling method → " .. method .. " (" .. label .. ")\n" ..
            (info.short or "") ..
            (info.tags and #info.tags > 0 and ("\ntags: " .. table.concat(info.tags, ", ")) or "") ..
            (method > 0 and (
                "\nstats: kill " .. killRate(method) ..
                " | avg "  .. avgTime(method) ..
                " | best " .. bestTime(method) ..
                " | score " .. string.format("%.3f", methodScore(method))
            ) or ""),
            nil
        )
    end,
}
