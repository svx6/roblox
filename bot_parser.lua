local Parser = {}

local TypoCorrections = {
    flig="fling",flimg="fling",filng="fling",flng="fling",flnig="fling",flingg="fling",flign="fling",fliing="fling",flibg="fling",flong="fling",fllung="fling",fking="fling",flng="fling",flinh="fling",flinf="fling",flint="fling",flinb="fling",
    yeeet="yeet",yet="yeet",yeet1="yeet",yeett="yeet",yeat="yeet",yett="yeet",
    kil="kill",killl="kill",kll="kill",kiil="kill",krill="kill",kell="kill",
    tp2m="tp2me",tp2mee="tp2me",tpme="tp2me",tp2em="tp2me",tpto="tp",teleport="tp",tele="tp",telep="tp",
    tpcoord="tpcoords",tpxyz="tpcoords",coords="tpcoords",tpbhind="tpbehind",tpbhnd="tpbehind",
    shoo="shoot",sho="shoot",schoot="shoot",schut="shoot",schot="shoot",shooot="shoot",shott="shoot",
    murdr="murd",murder="murd",murde="murd",murdrer="murd",killer="murd",mureder="murd",mrdr="murd",murdere="murd",
    folw="follow",follw="follow",folow="follow",fllw="follow",follwo="follow",fallow="follow",
    orbt="orbit",orbitt="orbit",orbti="orbit",orbut="orbit",
    sezure="seizure",seizur="seizure",seezure="seizure",siezure="seizure",
    torndo="tornado",tornad="tornado",tornndo="tornado",torndao="tornado",tonado="tornado",
    blckhole="blackhole",blkhole="blackhole",blckhl="blackhole",blackhol="blackhole",blachole="blackhole",
    scater="scatter",scattr="scatter",scattre="scatter",scater="scatter",
    cag="cage",caeg="cage",trp="trap",trpa="trap",spm="spam",spma="spam",spamm="spam",
    strb="strobe",strbe="strobe",stobe="strobe",
    gient="giant",gint="giant",giiant="giant",gaint="giant",
    tny="tiny",tny1="tiny",tini="tiny",
    creap="creep",crep="creep",creeep="creep",
    mimik="mimic",mimck="mimic",mimac="mimic",
    stck="stack",stak="stack",stakc="stack",
    flngall="flingall",flingal="flingall",flinagl="flingall",flingalll="flingall",flnigall="flingall",
    resp="respawn",rspwn="respawn",rspawn="respawn",respwn="respawn",respon="respawn",respwan="respawn",
    refr="refresh",refrsh="refresh",refreh="refresh",refesh="refresh",refrish="refresh",
    freze="freeze",freez="freeze",frez="freeze",feeze="freeze",freee="freeze",
    unfreze="unfreeze",unfreez="unfreeze",unfrez="unfreeze",unfeeze="unfreeze",
    invs="invis",invisble="invisible",inviz="invis",invisb="invis",invsi="invis",
    visibl="visible",visble="visible",visibe="visible",
    nclip="noclip",noclp="noclip",nocilp="noclip",noclipp="noclip",
    hlp="help",hep="help",hlep="help",hepl="help",
    cmd="cmds",comands="commands",comds="cmds",cmdss="cmds",commads="cmds",comandz="cmds",comnds="cmds",
    gd="god",ugod="ungod",godd="god",goood="god",
    spd="speed",sped="speed",spped="speed",speeed="speed",speeed="speed",
    jmp="jump",jmup="jump",jmpp="jump",jujmp="jump",jumpp="jump",
    hl="highlight",hilight="highlight",highligh="highlight",highligt="highlight",hlight="highlight",
    vew="view",spectat="spectate",spectae="spectate",veiw="view",veew="view",
    rprt="report",reprt="report",rport="report",reprot="report",
    magnt="magnet",magent="magnet",magnt="magnet",mangnet="magnet",
    roket="rocket",rcket="rocket",rockt="rocket",rocet="rocket",
    pul="pull",pll="pull",puull="pull",
    crsh="crash",crass="crash",chrash="crash",crahs="crash",
    ragdol="ragdoll",ragdl="ragdoll",ragdll="ragdoll",ragoll="ragdoll",
    wallbng="wallbang",wlbang="wallbang",wallbamg="wallbang",
    antiflng="antifling",antiflingg="antifling",antiflig="antifling",
    antislw="antislow",antislo="antislow",antislwo="antislow",
    autoshoot="shoot",autoshot="shoot",
    automurd="murd",automurder="murd",
    infojump="infjump",infjmp="infjump",infjup="infjump",
    loopteleport="looptp",looptpp="looptp",loptp="looptp",
    gt="goto",gto="goto",gotoo="goto",gooto="goto",
    bak="back",bck="back",bakk="back",bback="back",
    brng="bring",bringg="bring",brign="bring",brig="bring",briing="bring",
    sftp="safetp",saftp="safetp",safetelep="safetp",safetpp="safetp",
    atach="attach",attch="attach",atatch="attach",attatch="attach",atacch="attach",
    anoy="annoy",anny="annoy",anooy="annoy",anoyy="annoy",annooy="annoy",
    loopflng="loopfling",loopflingg="loopfling",lopfling="loopfling",loofling="loopfling",
    loopkl="loopkill",loopkll="loopkill",lopkill="loopkill",
    loopflngall="loopflingall",lopflingall="loopflingall",
    unlooptpp="unlooptp",unloptp="unlooptp",
    prm="perm",perms="perm",permm="perm",prmit="perm",permit="perm",permission="perm",premission="perm",
    addcommand="addcmd",addcom="addcmd",adcmd="addcmd",
    relod="reload",reloard="reload",rlod="reload",relaod="reload",relad="reload",
    autojin="autojoin",autjoin="autojoin",autojn="autojoin",autojon="autojoin",autojoun="autojoin",autjon="autojoin",
    netstats="netstat",netst="netstat",nstat="netstat",
    autogun="mm2autogun",autogrb="mm2autogun",autograb="mm2autogun",
    mm2god="mm2god",mm2gd="mm2god",murdgod="mm2god",
    sherif="sheriff",sher="sheriff",sherf="sheriff",sherrif="sheriff",sherff="sheriff",
    flingmrd="flingmurd",flingmurdr="flingmurd",flngmurd="flingmurd",flingkiler="flingmurd",
    flingsherf="flingsheriff",flingshrf="flingsheriff",flngsheriff="flingsheriff",
    mm2rol="mm2role",murd2role="mm2role",
    mm2stat="mm2status",mm2inf="mm2status",
    stpo="stop",stp="stop",stopp="stop",
    clen="clean",clena="clean",clearn="clean",
    rstop="reset",reste="reset",resett="reset",rset="reset",
    unfl="unfling",unflig="unfling",
    unlop="unloop",unlopp="unloop",
    infnit="infinite",infint="infinite",
    destro="destroy",desroy="destroy",dstroy="destroy",
    dancee="dance",danc="dance",dnce="dance",
    traill="trail",tral="trail",treil="trail",
    aurea="aura",aurra="aura",auura="aura",aurraa="aura",
    auratp2="auratp",aurtp="auratp",auratp1="auratp",
    tpme2="tp",tpmee="tp",tpme="tp",
    gojoo="gojo",goho="gojo",goho1="gojo",goji="gojo",
    shadoww="shadow",shadw="shadow",shaodw="shadow",
    domian="domain",doamin="domain",domainn="domain",
    dahood1="dh",dahod="dh",dahoood="dh",dhhood="dh",
    daespd="daesp",daespp="daesp",dhespp="daesp",
    dkill="dakill",dhkill="dakill",dakll="dakill",
    dspeed="daspeed",dhspeed="daspeed",daspd="daspeed",
    espp="esp",eesp="esp",
    hidd="hide",hidee="hide",
    clne="clone",cloen="clone",
    chatspam="spam",chatspm="spam",
    tpall="tpall",teleportall="tpall",
    rprt="report",reprt="report",rport="report",reprot="report",
    autoreport="report",massreport="report",masrep="report",massrep="report",
    reportall="report",loopreport="report",autoban="report",
    ajstatus="autojoin",ajstat="autojoin",autojnstatus="autojoin",
    -- bounce
    bouncd="bounce",bounse="bounce",bonce="bounce",bounce1="bounce",bounc="bounce",lnch="bounce",launche="bounce",lauch="bounce",lanch="bounce",
    -- shake
    shke="shake",shak="shake",shakee="shake",shaek="shake",jitr="jitter",jiter="jitter",jittr="jitter",
    -- dizzy
    dzy="dizzy",dizz="dizzy",dizy="dizzy",dizi="dizzy",dizyes="dizzy",whril="whirl",wirl="whirl",wirl1="whirl",
    -- push
    psh="push",pussh="push",puhs="push",puh="push",shov="shove",shvoe="shove",shovee="shove",shvee="shove",
    -- haunt
    hant="haunt",haun="haunt",hauntt="haunt",hanut="haunt",gohst="ghost",ghst="ghost",ghoost="ghost",stlk="stalk",stalck="stalk",stalke="stalk",
}

local function CorrectTypo(cmd) return TypoCorrections[cmd] or cmd end

local LevenBuf0 = {}
local LevenBuf1 = {}
for i = 0, 256 do LevenBuf0[i] = 0; LevenBuf1[i] = 0 end

local function LevenshteinFast(s1, s2)
    if not s1 or not s2 then return 999 end
    local l1, l2 = #s1, #s2
    if l1 == 0 then return l2 end
    if l2 == 0 then return l1 end
    if s1 == s2 then return 0 end
    if l1 > 40 or l2 > 40 then return 999 end
    local absDiff = l1 > l2 and l1 - l2 or l2 - l1
    if absDiff > 5 then return 999 end
    local prev, curr = LevenBuf0, LevenBuf1
    for j = 0, l2 do prev[j] = j end
    for i = 1, l1 do
        curr[0] = i
        local s1b = s1:byte(i)
        local bestInRow = i
        for j = 1, l2 do
            local cost = s1b == s2:byte(j) and 0 or 1
            local del = prev[j] + 1
            local ins = curr[j-1] + 1
            local sub = prev[j-1] + cost
            local mn
            if del < ins then mn = del < sub and del or sub
            else mn = ins < sub and ins or sub end
            curr[j] = mn
            if mn < bestInRow then bestInRow = mn end
        end
        if bestInRow > 5 then return 999 end
        prev, curr = curr, prev
    end
    return prev[l2]
end

local function ConsonantSkeleton(s)
    if not s then return "" end
    local r = ""
    local vowels = {a=1,e=1,i=1,o=1,u=1}
    local prev = 0
    for i = 1, #s do
        local b = s:byte(i)
        if b >= 97 and b <= 122 and not vowels[s:sub(i,i)] then
            if b ~= prev then r = r .. s:sub(i,i); prev = b end
        end
    end
    return r
end

local function NormalizeInput(s)
    if not s then return "" end
    local r = {}
    for i = 1, #s do
        local b = s:byte(i)
        if (b >= 32 and b <= 126) then r[#r+1] = string.char(b) end
    end
    local out = table.concat(r)
    out = out:gsub("#+", "")
    out = out:gsub("%s+", " ")
    out = out:match("^%s*(.-)%s*$") or out
    return out
end

local function PrefixMatch(cmd, BotEnv)
    if #cmd < 2 then return nil end
    local best, bestLen = nil, 999
    for name, _ in pairs(BotEnv.CommandRegistry) do
        if name:sub(1, #cmd) == cmd and #name < bestLen then
            best = name; bestLen = #name
        end
    end
    if best then return best end
    for alias, target in pairs(BotEnv.AliasMap) do
        if alias:sub(1, #cmd) == cmd and #alias < bestLen then
            best = target; bestLen = #alias
        end
    end
    return best
end

local function PhoneticMatch(cmd, BotEnv)
    if #cmd < 3 then return nil end
    local cmdSkel = ConsonantSkeleton(cmd)
    if #cmdSkel < 2 then return nil end
    local best, bestDist = nil, 999
    for name, _ in pairs(BotEnv.CommandRegistry) do
        local nameSkel = ConsonantSkeleton(name)
        if cmdSkel == nameSkel then return name end
        local d = LevenshteinFast(cmdSkel, nameSkel)
        if d < bestDist and d <= 2 then bestDist = d; best = name end
    end
    for alias, target in pairs(BotEnv.AliasMap) do
        local aliasSkel = ConsonantSkeleton(alias)
        if cmdSkel == aliasSkel then return target end
        local d = LevenshteinFast(cmdSkel, aliasSkel)
        if d < bestDist and d <= 1 then bestDist = d; best = target end
    end
    return best
end

local function FindClosestCommand(cmd, BotEnv)
    local bm, bd = nil, 999
    local mx = math.max(3, math.floor(#cmd * 0.5))
    for n, _ in pairs(BotEnv.CommandRegistry) do
        local d = LevenshteinFast(cmd, n); if d < bd then bd = d; bm = n end
    end
    for a, t in pairs(BotEnv.AliasMap) do
        local d = LevenshteinFast(cmd, a); if d < bd then bd = d; bm = t end
    end
    for ty, co in pairs(TypoCorrections) do
        local d = LevenshteinFast(cmd, ty); if d < bd then bd = d; bm = co end
    end
    if bd <= mx then return bm, bd end
    local pm = PrefixMatch(cmd, BotEnv)
    if pm then return pm, 1 end
    local phon = PhoneticMatch(cmd, BotEnv)
    if phon then return phon, 2 end
    return nil, bd
end

local function ResolveCommand(rawCmd, BotEnv)
    local cmd = CorrectTypo(rawCmd)
    if BotEnv.AliasMap[cmd] then cmd = BotEnv.AliasMap[cmd] end
    if BotEnv.CommandRegistry[cmd] then return cmd end
    if BotEnv.AliasMap[rawCmd] then return BotEnv.AliasMap[rawCmd] end
    if BotEnv.CommandRegistry[rawCmd] then return rawCmd end
    local pm = PrefixMatch(cmd, BotEnv)
    if pm and BotEnv.CommandRegistry[pm] then return pm end
    local phon = PhoneticMatch(cmd, BotEnv)
    if phon and BotEnv.CommandRegistry[phon] then return phon end
    local closest = FindClosestCommand(rawCmd, BotEnv)
    if closest and BotEnv.CommandRegistry[closest] then
        local d = LevenshteinFast(rawCmd, closest)
        if d <= 2 then return closest end
    end
    return nil
end

local function SmartSplitArgs(input)
    if not input or input == "" then return {} end
    local args, cur, iq, qc = {}, {}, false, nil
    for i = 1, #input do
        local ch = input:sub(i, i)
        if not iq then
            if ch == '"' or ch == "'" then iq = true; qc = ch
            elseif ch == " " or ch == "\t" then
                if #cur > 0 then args[#args+1] = table.concat(cur); cur = {} end
            else cur[#cur+1] = ch end
        else
            if ch == qc then iq = false; qc = nil; if #cur > 0 then args[#args+1] = table.concat(cur); cur = {} end
            else cur[#cur+1] = ch end
        end
    end
    if #cur > 0 then args[#args+1] = table.concat(cur) end
    return args
end

local function StripChatTags(msg)
    if not msg then return "" end
    local s = msg
    s = s:gsub("^%s*%[.-%]%s*", "")
    s = s:gsub("^%s*%{.-%}%s*", "")
    s = s:gsub("^%s*%(.-%)%s*", "")
    s = s:gsub("^%s*%<.-%>%s*", "")
    s = s:match("^%s*(.-)%s*$") or s
    return s
end

local function FindPrefix(msg, Prefixes)
    local cl = NormalizeInput(StripChatTags(msg))
    local lo = cl:lower()
    for _, p in ipairs(Prefixes) do
        local pl = p:lower()
        if lo:sub(1, #pl) == pl then return p, cl end
    end
    return nil, nil
end

local DedupRing = {}
local DedupSize = 256
local DedupHead = 0
local DedupMap = {}

local safeTick = tick or os.clock or function() return 0 end

local function IsDuplicate(key, window)
    local now = safeTick()
    local entry = DedupMap[key]
    if entry and (now - entry) < window then return true end
    DedupMap[key] = now
    DedupHead = (DedupHead % DedupSize) + 1
    local old = DedupRing[DedupHead]
    if old then DedupMap[old] = nil end
    DedupRing[DedupHead] = key
    return false
end

local function ProcessSingleCommand(cleanString, executorPlayer, isWhisper, BotEnv, permLevel)
    local args = SmartSplitArgs(cleanString)
    if not args[1] or args[1] == "" then return end
    local rawCmd = args[1]:lower()
    local cmd = ResolveCommand(rawCmd, BotEnv)
    local wt = isWhisper and executorPlayer or nil
    if cmd then
        if not BotEnv.HasPermission(executorPlayer, cmd) then
            BotEnv.RespondError("Denied '" .. cmd .. "' Lv:" .. permLevel .. " need:" .. (BotEnv.CommandPermissions[cmd] or 1), wt)
            return
        end
        local restArgs = ""
        if #args > 1 then local p = {}; for i = 2, #args do p[#p+1] = args[i] end; restArgs = table.concat(p, " ") end
        local module = BotEnv.CommandRegistry[cmd]
        if not module and BotEnv.LazyLoadCommand then module = BotEnv.LazyLoadCommand(cmd) end
        if module and module.Execute then
            local eOk, eErr = pcall(function() module.Execute(BotEnv, args, executorPlayer, restArgs) end)
            if not eOk then BotEnv.RespondError("'" .. cmd .. "' error: " .. tostring(eErr):sub(1, 80), wt) end
        else
            BotEnv.RespondError("'" .. cmd .. "' registered but missing Execute", wt)
        end
    else
        local corrected = CorrectTypo(rawCmd)
        if BotEnv.AliasMap[corrected] then corrected = BotEnv.AliasMap[corrected] end
        if BotEnv.CommandRegistry[corrected] then
            if not BotEnv.HasPermission(executorPlayer, corrected) then
                BotEnv.RespondError("Denied '" .. corrected .. "'", wt)
                return
            end
            local restArgs = ""
            if #args > 1 then local p = {}; for i = 2, #args do p[#p+1] = args[i] end; restArgs = table.concat(p, " ") end
            local module = BotEnv.CommandRegistry[corrected]
            if module and module.Execute then
                local eOk, eErr = pcall(function() module.Execute(BotEnv, args, executorPlayer, restArgs) end)
                if not eOk then BotEnv.RespondError("'" .. corrected .. "' error: " .. tostring(eErr):sub(1, 80), wt) end
            end
            return
        end
        local sug, dist = FindClosestCommand(rawCmd, BotEnv)
        local msg = "Unknown: '" .. rawCmd .. "'."
        if sug then msg = msg .. " Try '" .. sug .. "'?" end
        msg = msg .. " ?bot cmds"
        BotEnv.RespondError(msg, wt)
    end
end

local function HandleBotCommand(message, executorPlayer, isWhisper, BotEnv)
    if not message or not executorPlayer or type(message) ~= "string" then return end
    if #message < 4 then return end
    local normalizedMsg = NormalizeInput(message)
    if #normalizedMsg < 4 then return end
    local matchedPrefix, cleanedMessage = FindPrefix(normalizedMsg, BotEnv.Prefixes)
    if not matchedPrefix then return end
    local dedupKey = executorPlayer.UserId .. ":" .. normalizedMsg
    if IsDuplicate(dedupKey, BotEnv.DEDUP_WINDOW) then return end
    if not BotEnv.CanUseBot(executorPlayer) then return end
    local permLevel = BotEnv.GetPermLevel(executorPlayer)
    if permLevel < 1 then return end
    if BotEnv.IsOnCooldown(executorPlayer) then return end
    local cleanString = cleanedMessage:sub(#matchedPrefix + 1)
    if not cleanString or cleanString == "" then return end
    cleanString = cleanString:match("^%s*(.-)%s*$") or cleanString
    if cleanString:find("|") then
        local chains = {}
        local start = 1
        while true do
            local pipePos = cleanString:find("|", start, true)
            if not pipePos then
                local part = cleanString:sub(start):match("^%s*(.-)%s*$")
                if part and part ~= "" then chains[#chains+1] = part end
                break
            end
            local part = cleanString:sub(start, pipePos - 1):match("^%s*(.-)%s*$")
            if part and part ~= "" then chains[#chains+1] = part end
            start = pipePos + 1
        end
        for _, chainCmd in ipairs(chains) do
            pcall(function() ProcessSingleCommand(chainCmd, executorPlayer, isWhisper, BotEnv, permLevel) end)
            task.wait(0.05)
        end
    else
        ProcessSingleCommand(cleanString, executorPlayer, isWhisper, BotEnv, permLevel)
    end
end

function Parser.Setup(BotEnv)
    local Players = BotEnv.Players
    local LocalPlayer = BotEnv.LocalPlayer
    local SuperOwner = BotEnv.SuperOwner
    local ReplicatedStorage = BotEnv.ReplicatedStorage
    local TextChatService = BotEnv.TextChatService
    local ChatHooks = {}
    local HookedChannels = {}

    local function HookPlayerChat(player)
        if ChatHooks[player] then return end
        ChatHooks[player] = true
        pcall(function()
            local conn = player.Chatted:Connect(function(msg) pcall(function() HandleBotCommand(msg, player, false, BotEnv) end) end)
            BotEnv.TrackConnection("Chat_" .. player.Name, conn)
        end)
    end

    local function HookTextChannel(channel)
        if not channel:IsA("TextChannel") then return end
        if HookedChannels[channel] then return end
        HookedChannels[channel] = true
        pcall(function()
            local conn = channel.MessageReceived:Connect(function(im)
                pcall(function()
                    local ts = im.TextSource
                    if ts then
                        local ap = Players:GetPlayerByUserId(ts.UserId)
                        if ap then HandleBotCommand(im.Text, ap, channel.Name:find("RBXWhisper") ~= nil, BotEnv) end
                    end
                end)
            end)
            BotEnv.TrackConnection("TCS_" .. channel.Name, conn)
        end)
    end

    pcall(function() for _, p in ipairs(Players:GetPlayers()) do HookPlayerChat(p) end end)

    pcall(function()
        local conn = Players.PlayerAdded:Connect(function(player)
            pcall(function()
                HookPlayerChat(player)
                if player.Name:lower() == SuperOwner:lower() then
                    BotEnv.PermittedUsers[player.Name:lower()] = 4
                    BotEnv.SendNotification("Boss", SuperOwner .. " joined!", 5)
                end
                if _G.__BOT_SAVED_PERMS and _G.__BOT_SAVED_PERMS[player.Name:lower()] then
                    BotEnv.PermittedUsers[player.Name:lower()] = _G.__BOT_SAVED_PERMS[player.Name:lower()]
                end
            end)
        end)
        BotEnv.TrackConnection("PlayerAdded", conn)
    end)

    pcall(function()
        local conn = Players.PlayerRemoving:Connect(function(player)
            pcall(function()
                ChatHooks[player] = nil
                BotEnv.DisconnectSafe("Chat_" .. player.Name)
                if BotEnv.ESPObjects[player] then
                    pcall(function() if BotEnv.ESPObjects[player].highlight then BotEnv.ESPObjects[player].highlight:Destroy() end; if BotEnv.ESPObjects[player].billboard then BotEnv.ESPObjects[player].billboard:Destroy() end end)
                    BotEnv.ESPObjects[player] = nil
                end
                if BotEnv.FreezeCages[player] then for _, pt in ipairs(BotEnv.FreezeCages[player]) do pcall(function() pt:Destroy() end) end; BotEnv.FreezeCages[player] = nil end
            end)
        end)
        BotEnv.TrackConnection("PlayerRemoving", conn)
    end)

    pcall(function()
        if TextChatService then
            for _, d in ipairs(TextChatService:GetDescendants()) do if d:IsA("TextChannel") then HookTextChannel(d) end end
            local conn = TextChatService.DescendantAdded:Connect(function(d) if d:IsA("TextChannel") then task.wait(0.05); HookTextChannel(d) end end)
            BotEnv.TrackConnection("TCS_DescAdded", conn)
        end
    end)

    pcall(function()
        local ce = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if ce then
            local om = ce:FindFirstChild("OnMessageDoneFiltering")
            if om then
                local conn = om.OnClientEvent:Connect(function(md)
                    pcall(function()
                        if md and md.FromSpeaker and md.Message then
                            local iw = md.MessageType == "Whisper" or (md.ExtraData and md.ExtraData.ChatColor == Color3.new(1,1,1))
                            local sn = Players:FindFirstChild(md.FromSpeaker)
                            if sn then HandleBotCommand(md.Message, sn, iw, BotEnv) end
                        end
                    end)
                end)
                BotEnv.TrackConnection("LegacyChat", conn)
            end
        end
    end)

    pcall(function()
        if TextChatService then
            local function hgr() for _, c in ipairs(TextChatService:GetDescendants()) do if c:IsA("TextChannel") then HookTextChannel(c) end end end
            hgr(); task.delay(3, hgr); task.delay(10, hgr); task.delay(30, hgr); task.delay(60, hgr)
        end
    end)

    pcall(function()
        local conn = LocalPlayer.CharacterAdded:Connect(function()
            pcall(function()
                task.wait(0.3)
                if BotEnv.GetFlag("IsNoClip") then pcall(BotEnv.StartNoClip) end
                if BotEnv.GetFlag("IsGodMode") then task.wait(0.2); pcall(BotEnv.StartGodMode) end
                BotEnv.PurgeDeadConnections()
            end)
        end)
        BotEnv.TrackConnection("CharAdded", conn)
    end)

    pcall(function() for _, p in ipairs(Players:GetPlayers()) do if p.Name:lower() == SuperOwner:lower() then BotEnv.PermittedUsers[p.Name:lower()] = 4 end end end)

    -- Self-healing watchdog: re-hook dead chat connections every 30 seconds
    task.spawn(function()
        while true do
            task.wait(30)
            pcall(function()
                -- Re-hook any players that lost their chat connections
                for _, p in ipairs(Players:GetPlayers()) do
                    pcall(function()
                        local connName = "Chat_" .. p.Name
                        local connData = BotEnv.ConnectionRegistry[connName]
                        local isAlive = false
                        if connData and connData.conn then
                            local ok, connected = pcall(function() return connData.conn.Connected end)
                            isAlive = ok and connected
                        end
                        if not isAlive then
                            ChatHooks[p] = nil
                            HookPlayerChat(p)
                        end
                    end)
                end
                -- Re-scan and hook any new or dead TextChannels
                if TextChatService then
                    pcall(function()
                        -- Clean dead channel references
                        for channel, _ in pairs(HookedChannels) do
                            pcall(function()
                                if not channel or not channel.Parent then
                                    HookedChannels[channel] = nil
                                end
                            end)
                        end
                        -- Check existing hooks are alive, re-hook if dead
                        for _, d in ipairs(TextChatService:GetDescendants()) do
                            if d:IsA("TextChannel") then
                                local connName = "TCS_" .. d.Name
                                local connData = BotEnv.ConnectionRegistry[connName]
                                local isAlive = false
                                if connData and connData.conn then
                                    local ok, connected = pcall(function() return connData.conn.Connected end)
                                    isAlive = ok and connected
                                end
                                if not isAlive then
                                    HookedChannels[d] = nil
                                    HookTextChannel(d)
                                end
                            end
                        end
                    end)
                end
                -- Re-hook legacy chat if connection died
                pcall(function()
                    local connData = BotEnv.ConnectionRegistry["LegacyChat"]
                    local isAlive = false
                    if connData and connData.conn then
                        local ok, connected = pcall(function() return connData.conn.Connected end)
                        isAlive = ok and connected
                    end
                    if not isAlive then
                        local ce = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                        if ce then
                            local om = ce:FindFirstChild("OnMessageDoneFiltering")
                            if om then
                                local conn = om.OnClientEvent:Connect(function(md)
                                    pcall(function()
                                        if md and md.FromSpeaker and md.Message then
                                            local iw = md.MessageType == "Whisper" or (md.ExtraData and md.ExtraData.ChatColor == Color3.new(1,1,1))
                                            local sn = Players:FindFirstChild(md.FromSpeaker)
                                            if sn then HandleBotCommand(md.Message, sn, iw, BotEnv) end
                                        end
                                    end)
                                end)
                                BotEnv.TrackConnection("LegacyChat", conn)
                            end
                        end
                    end
                end)
                -- Purge dead connections from registry
                BotEnv.PurgeDeadConnections()
            end)
        end
    end)

    BotEnv.HandleBotCommand = function(m, p, w) HandleBotCommand(m, p, w, BotEnv) end
    BotEnv.CorrectTypo = CorrectTypo
    BotEnv.ResolveCommand = function(c) return ResolveCommand(c, BotEnv) end
    BotEnv.FindClosestCommand = function(c) return FindClosestCommand(c, BotEnv) end
    BotEnv.SmartSplitArgs = SmartSplitArgs
    BotEnv.StripChatTags = StripChatTags
    BotEnv.NormalizeInput = NormalizeInput
    BotEnv.FindPrefix = function(m) return FindPrefix(m, BotEnv.Prefixes) end
    BotEnv.PrefixMatch = function(c) return PrefixMatch(c, BotEnv) end
    BotEnv.PhoneticMatch = function(c) return PhoneticMatch(c, BotEnv) end
end

return Parser
