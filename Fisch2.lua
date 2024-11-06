local ui = game:GetService("CoreGui"):FindFirstChild("MacLib")
if ui then 
    ui:Destroy() 
end

repeat wait() until game:IsLoaded()
wait()

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):ClickButton1(Vector2.new(9e9, 9e9))
end)

local player = game:GetService("Players").LocalPlayer
local screenGui = Instance.new("ScreenGui")
local imageButton = Instance.new("ImageButton")

screenGui.Parent = player:WaitForChild("PlayerGui")

imageButton.Parent = screenGui
imageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
imageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
imageButton.BorderSizePixel = 0
imageButton.Position = UDim2.new(0.486806184, 0, 0.126297578, 0)
imageButton.Size = UDim2.new(0, 57, 0, 56)
imageButton.Image = "http://www.roblox.com/asset/?id=5430597512"

local isVisible = false

imageButton.MouseButton1Click:Connect(function()
    local coreGui = game:GetService("CoreGui")
    local macLib = coreGui:FindFirstChild("MacLib")

    if macLib then
        isVisible = not isVisible
        macLib.Enabled = isVisible
    end
end)

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "FISCH (DEMO)",
    Subtitle = "by doit_only.",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})

local globalSettings = {
    UIBlurToggle = Window:GlobalSetting({
        Name = "UI Blur",
        Default = Window:GetAcrylicBlurState(),
        Callback = function(bool)
            Window:SetAcrylicBlurState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
                Lifetime = 5
            })
        end,
    }),
    NotificationToggler = Window:GlobalSetting({
        Name = "Notifications",
        Default = Window:GetNotificationsState(),
        Callback = function(bool)
            Window:SetNotificationsState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " Notifications",
                Lifetime = 5
            })
        end,
    }),
    ShowUserInfo = Window:GlobalSetting({
        Name = "Show User Info",
        Default = Window:GetUserInfoState(),
        Callback = function(bool)
            Window:SetUserInfoState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Showing" or "Redacted") .. " User Info",
                Lifetime = 5
            })
        end,
    })
}

local tabGroups = {
    TabGroup1 = Window:TabGroup()
}

local tabs = {
    Main = tabGroups.TabGroup1:Tab({ Name = "Main", Image = "rbxassetid://9011713759" }),
    Settings = tabGroups.TabGroup1:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

local sections = {
    MainSection1 = tabs.Main:Section({ Side = "Left" }),
    MainSection2 = tabs.Main:Section({ Side = "Right" }),
    MainSection3 = tabs.Main:Section({ Side = "Left" }),
    MainSection4 = tabs.Main:Section({ Side = "Right" }),
}

sections.MainSection1:Header({
    Name = "Autofarm"
})

sections.MainSection2:Header({
    Name = "Misc"
})

sections.MainSection3:Header({
    Name = "Button"
})

sections.MainSection4:Header({
    Name = "Teleport"
})

local _G = _G or {}
_G.config = {
    fpsCap = 999,
    disableChat = true,
    enableBigButton = false,
    bigButtonScaleFactor = 0.3,
    shakeSpeed = 0.05,
    enableAutoCast = false,
    enableAutoShake = false,
    freezeCharacter = false,
    buttonInMiddle = false,
    enableAutoReel = false
}

local players = game:GetService("Players")
local vim = game:GetService("VirtualInputManager")
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")
local localplayer = players.LocalPlayer
local playergui = localplayer:WaitForChild("PlayerGui")

-- Fishing functions
local utility = {blacklisted_attachments = {"bob", "bodyweld"}}
do
    function utility.simulate_click(x, y, mb)
        vim:SendMouseButtonEvent(x, y, (mb - 1), true, game, 1)
        vim:SendMouseButtonEvent(x, y, (mb - 1), false, game, 1)
    end

    function utility.move_fix(bobber)
        for _, value in ipairs(bobber:GetDescendants()) do
            if value:IsA("Attachment") and table.find(utility.blacklisted_attachments, value.Name) then
                value:Destroy()
            end
        end
    end
end

local farm = {reel_tick = nil, cast_tick = nil}
do
    function farm.find_rod()
        local character = localplayer.Character
        if not character then return nil end

        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("rod") or tool.Name:find("Rod")) then
                return tool
            end
        end
        return nil
    end

    function farm.freeze_character(freeze)
        local character = localplayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = freeze and 0 or 16
                humanoid.JumpPower = freeze and 0 or 50
            end
        end
    end

    function farm.cast()
        if not _G.config.enableAutoCast then return end

        local character = localplayer.Character
        if not character then return end

        local rod = farm.find_rod()
        if not rod then return end

        local args = { [1] = 100, [2] = 1 }
        rod.events.cast:FireServer(unpack(args))
        farm.cast_tick = 0
    end

    function farm.shake()
        if not _G.config.enableAutoShake then return end

        local shake_ui = playergui:FindFirstChild("shakeui")
        if shake_ui then
            local safezone = shake_ui:FindFirstChild("safezone")
            local button = safezone and safezone:FindFirstChild("button")

            if button then
                button.Size = UDim2.new(_G.config.bigButtonScaleFactor, 0, _G.config.bigButtonScaleFactor, 0)

                if button.Visible then
                    utility.simulate_click(
                        button.AbsolutePosition.X + button.AbsoluteSize.X / 2,
                        button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2,
                        1
                    )
                end
            end
        end
    end

    function farm.reel()
        if not _G.config.enableAutoReel then return end

        local reel_ui = playergui:FindFirstChild("reel")
        if not reel_ui then return end

        local reel_bar = reel_ui:FindFirstChild("bar")
        if not reel_bar then return end

        local reel_client = reel_bar:FindFirstChild("reel")
        if not reel_client then return end

        if reel_client.Disabled == true then
            reel_client.Disabled = false
        end

        local update_colors = getsenv(reel_client).UpdateColors

        if update_colors then
            setupvalue(update_colors, 1, 100)
            replicated_storage.events.reelfinished:FireServer(getupvalue(update_colors, 1), true)
            replicated_storage.events.reelfinished:FireServer(getupvalue(update_colors, 1), true)
        end
    end
end

-- Create UI toggles for fishing features
sections.MainSection1:Toggle({
    Name = "Auto Cast",
    Default = _G.config.enableAutoCast,
    Callback = function(value)
        _G.config.enableAutoCast = value
    end,
}, "AutoCastToggle")

sections.MainSection1:Toggle({
    Name = "Auto Shake",
    Default = _G.config.enableAutoShake,
    Callback = function(value)
        _G.config.enableAutoShake = value
    end,
}, "AutoShakeToggle")

sections.MainSection1:Toggle({
    Name = "Auto Reel",
    Default = _G.config.enableAutoReel,
    Callback = function(value)
        _G.config.enableAutoReel = value
    end,
}, "AutoReelToggle")

local savedCFrame = nil

sections.MainSection2:Button({
    Name = "Save CFrame",
    Callback = function()
        local character = player.Character
        if character and character.PrimaryPart then
            savedCFrame = character.PrimaryPart.CFrame
            Window:Notify({
                Title = Window.Settings.Title,
                Description = "CFrame saved successfully",
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = Window.Settings.Title,
                Description = "Failed to save CFrame. Character not found.",
                Lifetime = 3
            })
        end
    end
}, "SaveCFrameButton")

sections.MainSection2:Toggle({
    Name = "Freeze Character",
    Default = false,
    Callback = function(value)
        _G.config.freezeCharacter = value
        if value then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                _G.config.loopPosition = character.HumanoidRootPart.Position
            end
        end
    end
}, "FreezeCharacterToggle")

task.spawn(function()
    while true do
        if _G.config.freezeCharacter and savedCFrame then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character:SetPrimaryPartCFrame(savedCFrame)
            end
        end
        task.wait(0.1)
    end
end)


sections.MainSection2:Button({
    Name = "FPS Boost",
    Callback = function()
        _G.Ignore = {}
        _G.Settings = {
            Players = {
                ["Ignore Me"] = true,
                ["Ignore Others"] = true,
                ["Ignore Tools"] = true
            },
            Meshes = {
                NoMesh = false,
                NoTexture = false,
                Destroy = false
            },
            Images = {
                Invisible = true,
                Destroy = false
            },
            Explosions = {
                Smaller = true,
                Invisible = false, -- Not for PVP games
                Destroy = false -- Not for PVP games
            },
            Particles = {
                Invisible = true,
                Destroy = false
            },
            TextLabels = {
                LowerQuality = true,
                Invisible = false,
                Destroy = false
            },
            MeshParts = {
                LowerQuality = true,
                Invisible = false,
                NoTexture = false,
                NoMesh = false,
                Destroy = false
            },
            Other = {
                ["No Camera Effects"] = true,
                ["No Clothes"] = true,
                ["Low Water Graphics"] = true,
                ["No Shadows"] = true,
                ["Low Rendering"] = true,
                ["Low Quality Parts"] = true,
                ["Low Quality Models"] = true,
                ["Reset Materials"] = true,
            }
        }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()
    end
}, "RunFPSBoosterButton")


sections.MainSection3:Toggle({
    Name = "Middle Button",
    Default = false,
    Callback = function(value)
        _G.config.buttonInMiddle = value 
        local shake_ui = playergui:FindFirstChild("shakeui")
        if shake_ui then
            local safezone = shake_ui:FindFirstChild("safezone")
            local button = safezone and safezone:FindFirstChild("button")
            if button then
                if value then
                    button.Position = UDim2.new(0.5, -button.Size.X.Offset / 2, 0.5, -button.Size.Y.Offset / 2)
                else
                    button.Position = UDim2.new(0, 0, 0, 0) 
                end
            end
        end
    end
}, "ButtonInMiddleToggle")

spawn(function()
    while task.wait(0.1) do
        if _G.config.buttonInMiddle then
            local shake_ui = playergui:FindFirstChild("shakeui")
            if shake_ui then
                local safezone = shake_ui:FindFirstChild("safezone")
                local button = safezone and safezone:FindFirstChild("button")
                if button then
                    button.AnchorPoint = Vector2.new(0.5, 0.5)
                    button.Position = UDim2.new(0.5, 0, 0.5, 0)
                    button.Size = UDim2.new(0.20, 0, 0.20, 0)
                end
            end
        end
    end
end)

player.PlayerGui.DescendantAdded:Connect(function(descendant)
    if _G.config.buttonInMiddle then
        if descendant.Name == 'button' and descendant.Parent.Name == 'safezone' then
            descendant.AnchorPoint = Vector2.new(0.5, 0.5)
            descendant.Position = UDim2.new(0.5, 0, 0.5, 0)
            descendant.Size = UDim2.new(0.20, 0, 0.20, 0)
        end
    end
end)


sections.MainSection3:Toggle({
    Name = "Big Button",
    Default = _G.config.enableBigButton,
    Callback = function(value)
        _G.config.enableBigButton = value
    end,
}, "EnableBigButtonToggle")

sections.MainSection3:Slider({
    Name = "Big Button Scale",
    Default = _G.config.bigButtonScaleFactor,
    Minimum = 0.30,
    Maximum = 1,
    DisplayMethod = "Number",
    Precision = 2,
    Callback = function(value)
        _G.config.bigButtonScaleFactor = value
    end
}, "Slider")

sections.MainSection2:Input({
	Name = "FPS Cap",
	Placeholder = tostring(_G.config.fpsCap),
	AcceptedCharacters = "0123456789",
	Callback = function(input)
		local fpsValue = tonumber(input)
		if fpsValue then
			_G.config.fpsCap = fpsValue
			setfpscap(_G.config.fpsCap)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = "FPS cap successfully set to " .. fpsValue
			})
		else
			Window:Notify({
				Title = Window.Settings.Title,
				Description = "Invalid input. Please enter a numeric value."
			})
		end
	end,
}, "FPSCapInput")

sections.MainSection4:Label({
	Text = "Coming Soon..."
})


spawn(function()
    while task.wait(_G.config.shakeSpeed) do
        local rod = farm.find_rod()
        if rod then
            farm.cast()
            farm.shake()
            farm.reel()
            farm.reel()
        end
    end
end)

MacLib:SetFolder("Maclib")
tabs.Settings:InsertConfigSection("Left")

Window.onUnloaded(function()
    print("Unloaded!")
end)

tabs.Main:Select()
MacLib:LoadAutoLoadConfig()
