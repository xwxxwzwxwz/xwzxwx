-- @vacbt

local VIM = game:GetService("VirtualInputManager")
local RS = game:GetService("RunService")
local plr = game.Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Funky Friday",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local MainTab = Window:AddTab({ Title = "Main" })

MainTab:AddToggle("AutoPlay", {
    Title = "Auto Player",
    Default = false
})

getgenv().auto = false
Fluent.Options.AutoPlay:OnChanged(function()
    getgenv().auto = Fluent.Options.AutoPlay.Value
end)

local keys = {}
local side = "Left"
local hitZone = 0.4

local function getNotes()
    local notes = {}
    local success = pcall(function()
        local gui = plr.PlayerGui.Window.Game.Fields[side].Inner
        for i = 1, 9 do
            local lane = gui:FindFirstChild("Lane"..i)
            if lane then notes[i] = lane.Notes end
        end
    end)
    return notes
end

local function updateKeys()
    pcall(function()
        local gui = plr.PlayerGui.Window.Game.Fields[side].Inner
        for i = 1, 9 do
            local lane = gui:FindFirstChild("Lane"..i)
            if lane then
                local txt = lane.Labels.Label.Text.Text
                keys[i] = Enum.KeyCode[txt]
            end
        end
    end)
end

local function detectSide()
    pcall(function()
        local char = plr.Character
        if not char then return end
        local root = char.HumanoidRootPart
        if not root then return end
        
        local leftDist = math.huge
        local rightDist = math.huge
        
        for _, stage in pairs(workspace.Map.Stages:GetChildren()) do
            local teams = stage:FindFirstChild("Teams")
            if teams then
                local left = teams:FindFirstChild("Left")
                local right = teams:FindFirstChild("Right")
                
                if left then
                    local d = (root.Position - left.Position).Magnitude
                    if d <= 5 then leftDist = math.min(leftDist, d) end
                end
                
                if right then
                    local d = (root.Position - right.Position).Magnitude
                    if d <= 5 then rightDist = math.min(rightDist, d) end
                end
            end
        end
        
        if leftDist < rightDist then
            side = "Left"
        elseif rightDist < leftDist then
            side = "Right"
        end
    end)
end

local function handleNote(note, col)
    local key = keys[col]
    if not key then return end
    
    VIM:SendKeyEvent(true, key, false, game)
    
    local isLongNote = #note:GetChildren() == 2
    
    if isLongNote then
        task.spawn(function()
            while note.Parent and note.Position.Y.Scale > hitZone and getgenv().auto do
                RS.Heartbeat:Wait()
            end
            VIM:SendKeyEvent(false, key, false, game)
        end)
    else
        task.spawn(function()
            task.wait(0.05)
            VIM:SendKeyEvent(false, key, false, game)
        end)
    end
end

local function autoPlayer()
    local noteData = {}
    
    for i = 1, 9 do
        noteData[i] = {}
    end
    
    while getgenv().auto do
        local lanes = getNotes()
        
        for col, lane in pairs(lanes) do
            for _, note in pairs(lane:GetChildren()) do
                if note:IsA("GuiObject") then
                    local pos = note.Position.Y.Scale
                    
                    if pos > hitZone and not noteData[col][note] then
                        noteData[col][note] = true
                        handleNote(note, col)
                    elseif pos <= hitZone and noteData[col][note] then
                        noteData[col][note] = nil
                    end
                    
                    if not note.Parent then
                        noteData[col][note] = nil
                    end
                end
            end
        end
        
        RS.Heartbeat:Wait()
    end
end

task.spawn(function()
    while true do
        if getgenv().auto then
            autoPlayer()
        end
        task.wait(0.3)
    end
end)

while true do
    pcall(function()
        local gui = plr.PlayerGui:FindFirstChild("GameGui")
        if gui and gui:FindFirstChild("Windows") then
            local selector = gui.Windows:FindFirstChild("SongSelector")
            if selector and selector.Visible then
                detectSide()
            end
        end
    end)
    
    updateKeys()
    task.wait()
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Funky Friday")
SaveManager:SetFolder("Funky Friday")
SaveManager:BuildConfigSection(MainTab)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
