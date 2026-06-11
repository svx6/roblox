return {
    Name = "infjump", Category = "utility", Permission = 1, Aliases = {"infinitejump", "ijump", "infjmp"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local isOn = BotEnv.GetFlag("IsInfJump")
        local function startIJ()
            BotEnv.SetFlag("IsInfJump", true); BotEnv.DisconnectSafe("InfJump")
            local conn = BotEnv.UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsInfJump") then return end
                    local h = BotEnv.GetBotHumanoid(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end)
            BotEnv.TrackConnection("InfJump", conn)
            BotEnv.Respond("InfJump ON")
        end
        local function stopIJ() BotEnv.SetFlag("IsInfJump", false); BotEnv.DisconnectSafe("InfJump"); BotEnv.Respond("InfJump OFF") end
        if mode == "on" or mode == "1" then startIJ()
        elseif mode == "off" or mode == "0" then stopIJ()
        else if isOn then stopIJ() else startIJ() end end
    end,
}
