--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║  FLING — SMART UNIFIED COMMAND v2.1                         ║
    ║  Compatible with bot_engine.lua v9.0                        ║
    ╚══════════════════════════════════════════════════════════════╝

    USAGE:
      .bot fling <player>     — fling one player
      .bot fling all          — fling everyone
      .bot fling others       — fling everyone except executor
      .bot fling near/closest — fling nearest player
      .bot fling rand         — fling a random player
      .bot fling me           — fling the executor
      .bot fling enemies      — fling enemy team
      .bot fling team         — fling your teammates
      aliases: f, yeet, launch
]]

return {
    Name       = "fling",
    Category   = "fling",
    Permission = 1,
    Aliases    = { "f", "yeet", "launch" },

    Execute = function(BotEnv, args, executor, restArgs)

        -- ── require target ────────────────────────────────────────────
        if not args[2] then
            BotEnv.RespondError("usage: fling <player|all|others|near|rand>", nil)
            return
        end

        local targetInput = args[2]:lower():match("^%s*(.-)%s*$")

        -- ── resolve targets ───────────────────────────────────────────
        local targets = BotEnv.GetMultipleTargets(targetInput, executor)
        if #targets == 0 then
            BotEnv.RespondError("cant find: " .. args[2], nil)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- DECIDE WHICH METHOD TO USE
        --
        -- The flingmethod command stores optional helpers on BotEnv:
        --   BotEnv._FlingStats           – stats table
        --   BotEnv._FlingSmartPick()     – returns best method id
        --   BotEnv._FlingRecordResult()  – records a result
        --
        -- These are OPTIONAL.  If flingmethod was never run they won't
        -- exist and we fall back to the engine's ExecuteSmartFling.
        --
        -- Priority:
        --   1. PreferredFlingMethod > 0  → locked specific method
        --   2. _FlingSmartPick exists + has data → smart-pick id
        --   3. Otherwise → engine's ExecuteSmartFling (safe default)
        -- ════════════════════════════════════════════════════════════
        local preferredMethod  = BotEnv.GetFlag("PreferredFlingMethod") or 0
        local forcedMethodId   = nil   -- nil  = use engine default
        local useEngineDefault = true

        if preferredMethod > 0 and BotEnv.FlingMethods[preferredMethod] then
            -- user explicitly locked a method
            forcedMethodId   = preferredMethod
            useEngineDefault = false

        elseif type(BotEnv._FlingSmartPick) == "function" then
            -- flingmethod module is loaded — check if it has real data
            local S       = BotEnv._FlingStats
            local hasData = false
            if S and S.uses then
                for id = 1, #BotEnv.FlingMethods do
                    if (S.uses[id] or 0) >= 2 then
                        hasData = true
                        break
                    end
                end
            end
            if hasData then
                local picked = BotEnv._FlingSmartPick()
                if picked and BotEnv.FlingMethods[picked] then
                    forcedMethodId   = picked
                    useEngineDefault = false
                end
            end
            -- if no data yet: useEngineDefault stays true
        end

        -- ════════════════════════════════════════════════════════════
        -- doFling(target) — execute one fling on a single player
        -- Returns true if target was killed / sent flying
        -- ════════════════════════════════════════════════════════════
        local function doFling(target)
            if not target or not target.Parent then return false end
            if not BotEnv.IsAlive(target) then return false end

            local killed = false

            if useEngineDefault then
                -- ── safe path: engine handles everything ──────────────
                pcall(BotEnv.ExecuteSmartFling, target)
                killed = not BotEnv.IsAlive(target)

            else
                -- ── run chosen method ─────────────────────────────────
                local method = BotEnv.FlingMethods[forcedMethodId]

                if not method then
                    -- guard: method slot missing, fall back silently
                    pcall(BotEnv.ExecuteSmartFling, target)
                    killed = not BotEnv.IsAlive(target)
                else
                    local t0             = tick()
                    local ok, killResult = pcall(method, target)
                    local elapsed        = tick() - t0
                    killed = (ok and killResult == true) or not BotEnv.IsAlive(target)

                    -- record into stats tracker if available
                    if type(BotEnv._FlingRecordResult) == "function" then
                        pcall(BotEnv._FlingRecordResult, forcedMethodId, killed, elapsed)
                    end

                    -- ── fallback: try other methods if primary failed ──
                    if not killed then
                        local numMethods = #BotEnv.FlingMethods
                        for fallbackId = 1, numMethods do
                            if fallbackId ~= forcedMethodId then
                                if not BotEnv.IsAlive(target) then break end
                                local fm = BotEnv.FlingMethods[fallbackId]
                                if fm then
                                    local t1        = tick()
                                    local ok2, res2 = pcall(fm, target)
                                    local el2       = tick() - t1
                                    local k2 = (ok2 and res2 == true) or not BotEnv.IsAlive(target)
                                    if type(BotEnv._FlingRecordResult) == "function" then
                                        pcall(BotEnv._FlingRecordResult, fallbackId, k2, el2)
                                    end
                                    if k2 then killed = true; break end
                                end
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end

            -- ── last-resort velocity punch if still alive ─────────────
            if not killed then
                pcall(function()
                    local tHRP = BotEnv.GetHRP(target)
                    if tHRP then
                        local power = BotEnv.FlingPower or 9999999
                        tHRP.AssemblyLinearVelocity = Vector3.new(power, power, power)
                    end
                end)
            end

            return killed
        end

        -- ── method label for messages ─────────────────────────────────
        local methodDesc = useEngineDefault and "auto"
            or ("m" .. tostring(forcedMethodId))

        -- ════════════════════════════════════════════════════════════
        -- SINGLE TARGET
        -- ════════════════════════════════════════════════════════════
        if #targets == 1 then
            local target = targets[1]
            BotEnv.Respond("flinging " .. target.Name .. " [" .. methodDesc .. "]", nil)
            task.spawn(function()
                local killed = doFling(target)
                if killed then
                    BotEnv.Respond(target.Name .. " sent flying ✓", nil)
                end
            end)
            return
        end

        -- ════════════════════════════════════════════════════════════
        -- MULTIPLE TARGETS
        -- NOTE: Luau does not support `goto`, so we use if/else guards
        -- ════════════════════════════════════════════════════════════
        local label = targetInput == "all"    and "everyone"
                   or targetInput == "others" and "all others"
                   or (#targets .. " players")
        BotEnv.Respond("flinging " .. label .. " [" .. methodDesc .. "]", nil)

        task.spawn(function()
            local killed = 0
            local failed = 0
            for _, target in ipairs(targets) do
                if target and target.Parent and BotEnv.IsAlive(target) then
                    local ok = doFling(target)
                    if ok then
                        killed = killed + 1
                    else
                        failed = failed + 1
                    end
                    task.wait(0.05)
                else
                    failed = failed + 1
                end
            end
            BotEnv.Respond("done — killed:" .. killed .. " failed:" .. failed, nil)
        end)
    end,
}
