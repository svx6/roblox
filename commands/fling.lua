--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║  FLING — SMART UNIFIED COMMAND v2.0                         ║
    ║  One command does it all. AI picks the right method.        ║
    ╚══════════════════════════════════════════════════════════════╝

    USAGE:
      .bot fling <player>    — fling one player (smart method)
      .bot fling all         — fling everyone
      .bot fling others      — fling everyone except the executor
      .bot fling near/closest— fling the nearest player
      .bot fling rand        — fling a random player
      .bot fling me          — fling the executor (if they asked)
      .bot fling enemies     — fling enemy team
      .bot fling team        — fling your teammates
      shortcut aliases: .bot f <target>
]]

return {
    Name       = "fling",
    Category   = "fling",
    Permission = 1,
    Aliases    = { "f", "yeet", "launch" },

    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil

        -- ── require target ────────────────────────────────────────────────
        if not args[2] then
            BotEnv.RespondError("usage: fling <player|all|others|near|rand>", wt)
            return
        end

        local targetInput = args[2]:lower():match("^%s*(.-)%s*$")

        -- ── resolve targets ───────────────────────────────────────────────
        local targets = BotEnv.GetMultipleTargets(targetInput, executor)
        if #targets == 0 then
            BotEnv.RespondError("cant find: " .. args[2], wt)
            return
        end

        -- ── decide which fling method to use ─────────────────────────────
        --
        -- Priority order:
        --   1. If PreferredFlingMethod > 0  → use it as locked choice
        --   2. If PreferredFlingMethod == 0 (auto):
        --        a. If _FlingSmartPick exists and has real data → use it
        --        b. Otherwise fall back to ExecuteSmartFling (engine default)
        --
        local preferredMethod = BotEnv.GetFlag("PreferredFlingMethod") or 0
        local useEngineDefault = false
        local forcedMethodId   = nil

        if preferredMethod > 0 then
            -- user locked a specific method
            forcedMethodId = preferredMethod
        elseif BotEnv._FlingSmartPick then
            -- check if we have enough data to smart-pick
            local S = BotEnv._FlingStats
            local hasData = false
            if S then
                for id = 1, #BotEnv.FlingMethods do
                    if (S.uses[id] or 0) >= 2 then hasData = true; break end
                end
            end
            if hasData then
                forcedMethodId = BotEnv._FlingSmartPick()
            else
                useEngineDefault = true   -- not enough data, let engine cycle
            end
        else
            useEngineDefault = true
        end

        -- ── build the actual fling executor function ──────────────────────
        local function doFling(target)
            if not target or not target.Parent then return false end
            if not BotEnv.IsAlive(target) then return false end

            local killed = false

            if useEngineDefault then
                -- Let engine's own smart-fling handle it (tries all methods)
                local ok, result = pcall(BotEnv.ExecuteSmartFling, target)
                -- Engine may or may not return a value depending on patch status
                killed = (ok and result == true) or not BotEnv.IsAlive(target)
            else
                -- Run the specific method and record stats
                local method = BotEnv.FlingMethods[forcedMethodId]
                if not method then
                    -- fallback if method index doesn't exist
                    local ok2 = pcall(BotEnv.ExecuteSmartFling, target)
                    killed = ok2 and not BotEnv.IsAlive(target)
                else
                    local t0 = tick()
                    local ok, result = pcall(method, target)
                    local elapsed = tick() - t0
                    killed = (ok and result == true) or not BotEnv.IsAlive(target)

                    -- record into stats if the tracker exists
                    if BotEnv._FlingRecordResult then
                        BotEnv._FlingRecordResult(forcedMethodId, killed, elapsed)
                    end

                    -- if method failed and we have other methods, try fallbacks
                    if not killed and useEngineDefault == false then
                        local numMethods = #BotEnv.FlingMethods
                        for fallbackId = 1, numMethods do
                            if fallbackId ~= forcedMethodId and BotEnv.IsAlive(target) then
                                local fm = BotEnv.FlingMethods[fallbackId]
                                if fm then
                                    local t1 = tick()
                                    local ok2, res2 = pcall(fm, target)
                                    local el2 = tick() - t1
                                    local k2 = (ok2 and res2 == true) or not BotEnv.IsAlive(target)
                                    if BotEnv._FlingRecordResult then
                                        BotEnv._FlingRecordResult(fallbackId, k2, el2)
                                    end
                                    if k2 then killed = true; break end
                                end
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end

            -- after-fling: if target survived, nudge them with a velocity punch
            if not killed then
                pcall(function()
                    local tHRP = BotEnv.GetHRP(target)
                    local bHRP = BotEnv.GetBotHRP()
                    if tHRP and bHRP then
                        local power = BotEnv.FlingPower or 9999999
                        tHRP.AssemblyLinearVelocity = Vector3.new(power, power, power)
                    end
                end)
            end

            return killed
        end

        -- ── describe what we're doing ─────────────────────────────────────
        local methodDesc
        if useEngineDefault then
            methodDesc = "auto"
        elseif forcedMethodId then
            methodDesc = "m" .. forcedMethodId
        else
            methodDesc = "auto"
        end

        -- ── single target ─────────────────────────────────────────────────
        if #targets == 1 then
            local target = targets[1]
            BotEnv.Respond("flinging " .. target.Name .. " [" .. methodDesc .. "]", wt)
            task.spawn(function()
                local killed = doFling(target)
                if killed then
                    BotEnv.Respond(target.Name .. " sent flying ✓", wt)
                end
            end)
            return
        end

        -- ── multiple targets ──────────────────────────────────────────────
        local label = targetInput == "all" and "everyone"
                   or targetInput == "others" and "all others"
                   or (#targets .. " players")
        BotEnv.Respond("flinging " .. label .. " [" .. methodDesc .. "]", wt)

        task.spawn(function()
            local killed = 0
            local failed = 0
            for _, target in ipairs(targets) do
                if not target or not target.Parent then failed = failed + 1; goto continue end
                if not BotEnv.IsAlive(target) then failed = failed + 1; goto continue end
                local ok = doFling(target)
                if ok then killed = killed + 1 else failed = failed + 1 end
                task.wait(0.05)
                ::continue::
            end
            BotEnv.Respond(
                "done — killed:" .. killed .. " failed:" .. failed,
                wt
            )
        end)
    end,
}
