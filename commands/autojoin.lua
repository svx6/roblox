return {
    Name = "autojoin",
    Aliases = {"aj", "autofollow", "autojn"},
    Description = "Auto-join a player across servers. Usage: autojoin <player> | off | status | retry",
    Permission = 3,

    Execute = function(BotEnv, args, executor, restArgs)
        -- ── Reply helpers ──────────────────────────────────────────
        local function Reply(msg) BotEnv.Respond(msg, nil, true) end
        local function Err(msg)   BotEnv.RespondError(msg, nil) end

        local sub = (args[2] or ""):lower()

        -- ── No arg: toggle off if running, else show usage ───────────────
        if sub == "" then
            if BotEnv.GetFlag("IsAutoJoin") then
                BotEnv.StopAutoJoin()
                Reply("AutoJoin disabled")
            else
                Err("Usage: autojoin <player> | off | status | retry")
            end
            return
        end

        -- ── OFF ──────────────────────────────────────────────────────────
        if sub == "off" or sub == "stop" or sub == "disable" then
            BotEnv.StopAutoJoin()
            Reply("AutoJoin disabled")
            return
        end

        -- ── STATUS ───────────────────────────────────────────────────────
        if sub == "status" or sub == "info" or sub == "stat" or sub == "check" then
            local s = BotEnv.GetAutoJoinStatus and BotEnv.GetAutoJoinStatus()
            if s then
                local lines = {
                    "=== AutoJoin Status ===",
                    "Enabled:  " .. (s.enabled and "YES" or "NO"),
                    "Target:   " .. (s.target or "none"),
                    "Status:   " .. (s.lastResult or "unknown"),
                    "Attempts: " .. tostring(s.attempts or 0),
                    "Found:    " .. (s.targetFound and "YES" or "NO"),
                }
                if s.lastCheck and s.lastCheck > 0 then
                    local ago = math.floor((BotEnv.safeTick or tick)() - s.lastCheck)
                    lines[#lines+1] = "Last check: " .. ago .. "s ago"
                end
                if s.lastFoundServer then
                    lines[#lines+1] = "Server: " .. tostring(s.lastFoundServer):sub(1, 24) .. "..."
                end
                Reply(table.concat(lines, "\n"))
            else
                local tgt = _G.__BOT_SAVED_SETTINGS and _G.__BOT_SAVED_SETTINGS.AutoJoinTarget
                Reply(BotEnv.GetFlag("IsAutoJoin")
                    and ("AutoJoin ON for: " .. (tgt or "unknown"))
                    or  "AutoJoin OFF")
            end
            return
        end

        -- ── RETRY: restart loop without changing target ──────────────────
        if sub == "retry" or sub == "restart" or sub == "reset" then
            local current = BotEnv.GetFlag("AutoJoinTarget")
                or (_G.__BOT_SAVED_SETTINGS and _G.__BOT_SAVED_SETTINGS.AutoJoinTarget)
            if not current or current == "" then
                Err("No active target to retry — use: autojoin <player>")
                return
            end
            BotEnv.StopAutoJoin()
            task.wait(0.3)
            local ok = BotEnv.StartAutoJoin(current)
            Reply(ok and ("AutoJoin restarted for: " .. current)
                     or  "Retry failed — TeleportService unavailable")
            return
        end

        -- ── START for a named player ─────────────────────────────────────
        local targetName = args[2]

        -- Snap to exact casing if player is already in our server
        local inServer = BotEnv.GetSmartTarget(targetName, executor, true)
        if inServer then
            targetName = inServer.Name
        else
            for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                if p.Name:lower() == targetName:lower() then
                    targetName = p.Name
                    break
                end
            end
        end

        -- Stop any running session cleanly before starting a new one
        if BotEnv.GetFlag("IsAutoJoin") then
            BotEnv.StopAutoJoin()
            task.wait(0.2)
        end

        -- ── Locals we need ───────────────────────────────────────────────
        local TeleportService = BotEnv.TeleportService
        local HttpService     = BotEnv.HttpService
        local Players         = BotEnv.Players
        local safeTick        = BotEnv.safeTick or tick

        if not TeleportService then
            Err("TeleportService unavailable")
            return
        end

        -- Mark flags so engine tracks this session
        BotEnv.SetFlag("IsAutoJoin",     true)
        BotEnv.SetFlag("AutoJoinTarget", targetName)
        pcall(function()
            _G.__BOT_SAVED_SETTINGS.AutoJoinEnabled = true
            _G.__BOT_SAVED_SETTINGS.AutoJoinTarget  = targetName
        end)
        BotEnv.AutoJoinStatus.attempts    = 0
        BotEnv.AutoJoinStatus.lastResult  = "searching"
        BotEnv.AutoJoinStatus.targetFound = false

        task.spawn(function()
            -- ── Persistent state across loop iterations ──────────────────
            local cachedUid       = nil   -- Roblox userId, cached after first resolve
            local cachedPlaceId   = nil   -- placeId from last successful presence hit
            local consecutiveFail = 0     -- consecutive userId-resolve failures
            local lastJoinAttempt = 0     -- safeTick() of most recent teleport call

            -- ── Helper: pick whichever HTTP function the executor has ─────
            local function getReq()
                if type(request)      == "function" then return request      end
                if type(http_request) == "function" then return http_request end
                return nil
            end

            -- ── Helper: fire a teleport with retry on error ──────────────
            local function doTeleport(placeId, gameId)
                -- Attempt 1: full signature
                local ok = pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, gameId, Players.LocalPlayer)
                end)
                if ok then return true end
                -- Attempt 2: no player arg (some executors block it)
                ok = pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, gameId)
                end)
                return ok
            end

            -- ── userId resolution — 3 independent methods ────────────────
            local function resolveUserId()
                if cachedUid then return true end
                local target = BotEnv.GetFlag("AutoJoinTarget")
                if not target then return false end

                -- Method A: POST to users API (most reliable)
                pcall(function()
                    local doReq = getReq()
                    if not doReq or not HttpService then return end
                    local body = HttpService:JSONEncode({
                        usernames = {target}, excludeBannedUsers = false,
                    })
                    local r = doReq({
                        Url     = "https://users.roblox.com/v1/usernames/users",
                        Method  = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body    = body,
                    })
                    if r and r.Body then
                        local ok, d = pcall(function() return HttpService:JSONDecode(r.Body) end)
                        if ok and d and d.data and d.data[1] then
                            cachedUid = d.data[1].id
                        end
                    end
                end)
                if cachedUid then return true end

                -- Method B: GetUserIdFromNameAsync (no HTTP needed, works everywhere)
                pcall(function()
                    local id = Players:GetUserIdFromNameAsync(target)
                    if id and id > 0 then cachedUid = id end
                end)
                if cachedUid then return true end

                -- Method C: Scrape profile page as last resort
                pcall(function()
                    local doReq = getReq()
                    if not doReq then return end
                    local r = doReq({
                        Url    = "https://www.roblox.com/users/profile?username=" .. target,
                        Method = "GET",
                    })
                    if r and r.Body then
                        local uid = r.Body:match('"UserId":(%d+)')
                                 or r.Body:match("Roblox%.UserId%s*=%s*(%d+)")
                        if uid then cachedUid = tonumber(uid) end
                    end
                end)

                return cachedUid ~= nil
            end

            -- ── Presence join — primary join path ────────────────────────
            -- Returns true if a teleport was actually fired
            local function tryPresenceJoin()
                if not cachedUid then return false end
                local doReq = getReq()
                if not doReq or not HttpService then return false end
                local target = BotEnv.GetFlag("AutoJoinTarget")
                local fired  = false

                pcall(function()
                    local body = HttpService:JSONEncode({userIds = {cachedUid}})
                    local r = doReq({
                        Url     = "https://presence.roblox.com/v1/presence/users",
                        Method  = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body    = body,
                    })
                    if not r or not r.Body then return end
                    local ok, d = pcall(function() return HttpService:JSONDecode(r.Body) end)
                    if not ok or not d or not d.userPresences or #d.userPresences == 0 then return end

                    local pr = d.userPresences[1]
                    local ptype = pr.userPresenceType

                    if ptype == 2 and pr.placeId and pr.gameId and pr.gameId ~= "" then
                        -- Target is in-game
                        cachedPlaceId = pr.placeId
                        pcall(function()
                            _G.__BOT_SAVED_SETTINGS.AutoJoinPlaceId = pr.placeId
                        end)

                        -- Throttle: don't fire teleport more than once per 8s
                        local now = safeTick()
                        if (now - lastJoinAttempt) < 8 then
                            BotEnv.AutoJoinStatus.lastResult = "in game (throttle)"
                            return
                        end
                        lastJoinAttempt = now

                        BotEnv.AutoJoinStatus.lastResult      = "joining"
                        BotEnv.AutoJoinStatus.lastFoundServer = pr.gameId
                        BotEnv.AutoJoinStatus.targetFound     = true

                        BotEnv.SendNotification(
                            "AutoJoin",
                            "Found " .. (target or "?") ..
                            "! Joining... (#" .. BotEnv.AutoJoinStatus.attempts .. ")",
                            6
                        )

                        fired = doTeleport(pr.placeId, pr.gameId)

                    elseif ptype == 0 then
                        BotEnv.AutoJoinStatus.lastResult  = "offline"
                        BotEnv.AutoJoinStatus.targetFound = false
                    elseif ptype == 1 then
                        BotEnv.AutoJoinStatus.lastResult = "on website"
                    elseif ptype == 3 then
                        BotEnv.AutoJoinStatus.lastResult = "in studio"
                    else
                        BotEnv.AutoJoinStatus.lastResult = "presence unknown (" .. tostring(ptype) .. ")"
                    end
                end)

                return fired
            end

            -- ── Server-list join — retry cached server directly ──────────
            -- Used when presence returns in-game but placeId/gameId didn't work
            local function tryServerListJoin()
                local placeId = cachedPlaceId
                    or (_G.__BOT_SAVED_SETTINGS and _G.__BOT_SAVED_SETTINGS.AutoJoinPlaceId)
                local gameId  = BotEnv.AutoJoinStatus.lastFoundServer
                if not placeId or not gameId then return false end

                local now = safeTick()
                if (now - lastJoinAttempt) < 8 then return false end
                lastJoinAttempt = now

                local fired = doTeleport(placeId, gameId)
                if fired then
                    BotEnv.AutoJoinStatus.lastResult = "retrying last server"
                end
                return fired
            end

            -- ── Main loop ────────────────────────────────────────────────
            while BotEnv.GetFlag("IsAutoJoin") do
                local target = BotEnv.GetFlag("AutoJoinTarget")
                if not target then break end

                BotEnv.AutoJoinStatus.lastCheck = safeTick()
                BotEnv.AutoJoinStatus.attempts  = BotEnv.AutoJoinStatus.attempts + 1

                -- Fast path: check if target already landed in our server
                local alreadyHere = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower() == target:lower() then
                        alreadyHere = true
                        BotEnv.AutoJoinStatus.lastResult  = "target is here!"
                        BotEnv.AutoJoinStatus.targetFound = true
                        break
                    end
                end

                if not alreadyHere then
                    BotEnv.AutoJoinStatus.targetFound = false

                    -- Resolve userId (cached after first success, re-tries all methods if nil)
                    if not resolveUserId() then
                        consecutiveFail = consecutiveFail + 1
                        BotEnv.AutoJoinStatus.lastResult = "cant resolve userId (x" .. consecutiveFail .. ")"
                        -- Bust cache after 5 straight failures (in case username changed)
                        if consecutiveFail >= 5 then
                            cachedUid       = nil
                            consecutiveFail = 0
                        end
                    else
                        consecutiveFail = 0

                        -- Primary: presence API → join
                        local joined = tryPresenceJoin()

                        -- Secondary: if we have a cached server and presence failed,
                        -- retry the last known gameId directly
                        if not joined
                            and BotEnv.AutoJoinStatus.lastResult ~= "offline"
                            and BotEnv.AutoJoinStatus.lastResult ~= "on website"
                            and BotEnv.AutoJoinStatus.lastResult ~= "in studio"
                        then
                            tryServerListJoin()
                        end
                    end
                end

                -- ── Adaptive delay ────────────────────────────────────────
                local result = BotEnv.AutoJoinStatus.lastResult
                local delay
                if     result == "target is here!" then delay = 25
                elseif result == "joining"          then delay = 12
                elseif result == "retrying last server" then delay = 12
                elseif result == "in game (throttle)"   then delay = 10
                elseif result == "offline"          then delay = 40
                elseif result == "on website"       then delay = 18
                elseif result == "in studio"        then delay = 60
                elseif result:find("cant resolve")  then delay = 45
                else                                     delay = 16
                end

                task.wait(math.max(10, math.min(delay, 90)))
            end
        end)

        Reply(
            "AutoJoin ON → " .. targetName ..
            "\nChecks every ~16s. Faster when target online." ..
            "\nCommands: autojoin status | off | retry"
        )
    end,
}
