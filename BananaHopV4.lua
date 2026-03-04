-- ==============================
-- CONFIG
-- ==============================

_G.host = 1
_G.Group = "One"

local FULLMOON_LIMIT = 15
local END_LIMIT = 3
local INITIAL_DELAY = 25
local CHECK_INTERVAL = 8

-- ==============================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local PlaceId = game.PlaceId

local BASE_URL = "http://223.206.67.125:5000/" .. _G.Group .. "/savedJobId"

-- ==============================
-- UI
-- ==============================

local function CreateUI()
    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FullMoonUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- พื้นหลัง
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 260, 0, 110)
    frame.Position = UDim2.new(0, 16, 0, 16)
    frame.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- มุมโค้ง
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- เส้นขอบสีฟ้าม่วง
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 80, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = frame

    -- ไอคอนดวงจันทร์ + หัวเรื่อง
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -16, 0, 28)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌕  FULL MOON TRACKER"
    titleLabel.TextColor3 = Color3.fromRGB(200, 170, 255)
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    -- divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -24, 0, 1)
    divider.Position = UDim2.new(0, 12, 0, 38)
    divider.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    divider.BackgroundTransparency = 0.6
    divider.BorderSizePixel = 0
    divider.Parent = frame

    -- label สถานะ
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 22)
    statusLabel.Position = UDim2.new(0, 12, 0, 44)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: กำลังตรวจสอบ..."
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 210)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame

    -- label เวลา Full Moon
    local moonLabel = Instance.new("TextLabel")
    moonLabel.Name = "MoonLabel"
    moonLabel.Size = UDim2.new(1, -16, 0, 30)
    moonLabel.Position = UDim2.new(0, 12, 0, 66)
    moonLabel.BackgroundTransparency = 1
    moonLabel.Text = "⏳  --  นาที"
    moonLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
    moonLabel.TextSize = 18
    moonLabel.Font = Enum.Font.GothamBold
    moonLabel.TextXAlignment = Enum.TextXAlignment.Left
    moonLabel.Parent = frame

    return screenGui, statusLabel, moonLabel, frame
end

local screenGui, statusLabel, moonLabel, mainFrame = CreateUI()

-- ฟังก์ชันอัปเดต UI
local function UpdateUI(status, minutes, isFullMoon, isLocked)
    if not statusLabel or not moonLabel then return end

    statusLabel.Text = "Status: " .. status

    if isLocked then
        mainFrame.BackgroundColor3 = Color3.fromRGB(10, 25, 10)
        moonLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
    elseif isFullMoon then
        mainFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 5)
        moonLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
    else
        mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
        moonLabel.TextColor3 = Color3.fromRGB(140, 140, 200)
    end

    if minutes then
        moonLabel.Text = "⏳  " .. tostring(minutes) .. "  นาที"
    else
        moonLabel.Text = "⏳  --  นาที"
    end
end

-- ==============================
-- Full Moon Logic (ไม่แก้)
-- ==============================

local function CheckMoonAndTimeForSea3()
    local function MoonTextureId()
        return game:GetService("Lighting").Sky.MoonTextureId
    end

    local function CheckMoon()
        local moonIds = {
            ["http://www.roblox.com/asset/?id=9709150401"] = "Bad Moon",
            ["http://www.roblox.com/asset/?id=9709150086"] = "Bad Moon",
            ["http://www.roblox.com/asset/?id=9709149680"] = "Bad Moon",
            ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon",
            ["http://www.roblox.com/asset/?id=15493317929"] = "Full Moon",
            ["http://www.roblox.com/asset/?id=9709149052"] = "Next Night",
            ["http://www.roblox.com/asset/?id=9709143733"] = "Bad Moon",
            ["http://www.roblox.com/asset/?id=9709139597"] = "Bad Moon",
            ["http://www.roblox.com/asset/?id=9709135895"] = "Bad Moon",
        }
        local moonreal = MoonTextureId()
        return moonIds[moonreal] or "Unknown Moon"
    end

    local function calculateMoonPhase()
        local ao = Lighting.ClockTime
        local moonStatus = CheckMoon()

        if moonStatus == "Full Moon" and ao <= 5 then
            return "Full Moon (Will End Moon In " .. math.floor(5 - ao) .. " Minutes)"
        elseif moonStatus == "Full Moon" and (ao > 12 and ao < 18) then
            return "Full Moon (Will Full Moon In " .. math.floor(18 - ao) .. " Minutes)"
        elseif moonStatus == "Full Moon" and (ao > 18 and ao <= 24) then
            return "Full Moon (Will End Moon In " .. math.floor(24 + 6 - ao) .. " Minutes)"
        end

        return "Unknown Moon Status"
    end

    return calculateMoonPhase()
end

local function GetMoonMinutes()
    local status = CheckMoonAndTimeForSea3()
    local willFull = tonumber(status:match("Will Full Moon In (%d+)"))
    local willEnd  = tonumber(status:match("Will End Moon In (%d+)"))
    return willFull, willEnd
end

-- ==============================
-- API
-- ==============================

local function saveJobId(jobId)
    pcall(function()
        request({
            Url = BASE_URL,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({ jobid = jobId })
        })
    end)
end

local function getJobId()
    local success, response = pcall(function()
        return request({
            Url = BASE_URL,
            Method = "GET"
        })
    end)
    if success and response and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        return data.jobid
    end
    return nil
end

-- ==============================
-- SERVER LIST
-- ==============================

local function GetServers()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100",
        PlaceId
    )
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not success then return nil end
    return HttpService:JSONDecode(result)
end

-- ==============================
-- HOP คนน้อยที่สุด
-- ==============================

local function HopLowestPlayerServer()
    local data = GetServers()
    if not data or not data.data then return false end

    local servers = {}
    for _, server in ipairs(data.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            table.insert(servers, server)
        end
    end

    if #servers == 0 then return false end

    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)

    local chosen = servers[1]
    print("HOP ไปเซิร์ฟที่มีคน:", chosen.playing)

    TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, player)
    return true
end

-- ==============================
-- HOST 1
-- ==============================

local function RunHost1()
    print("HOST 1 เริ่มทำงาน")
    UpdateUI("รอ " .. INITIAL_DELAY .. " วินาที...", nil, false, false)
    task.wait(INITIAL_DELAY)

    local lockedServer = false

    while true do
        local willFull, willEnd = GetMoonMinutes()

        if not lockedServer then
            if (willFull and willFull <= FULLMOON_LIMIT)
            or (willEnd and willEnd <= FULLMOON_LIMIT) then

                print("เจอ Fullmoon ≤ 15 นาที → บันทึก JobId")
                saveJobId(game.JobId)
                lockedServer = true

                local mins = willEnd or willFull
                UpdateUI("🔒 ล็อกเซิร์ฟแล้ว! Full Moon กำลังมา", mins, true, true)

            else
                local mins = willFull or willEnd
                print("ยังไม่ถึงเงื่อนไข → Hop")
                UpdateUI("กำลัง HOP หาเซิร์ฟ...", mins, false, false)
                HopLowestPlayerServer()
            end
        else
            if willEnd and willEnd <= END_LIMIT then
                print("Will End Moon In ≤ 3 นาที → Reset แล้ว HOP ใหม่")
                UpdateUI("Moon จบแล้ว กำลัง HOP ใหม่...", willEnd, false, false)
                lockedServer = false
                saveJobId("")
                HopLowestPlayerServer()
            else
                local mins = willEnd or willFull
                print("รอให้ End ≤ 3 นาที ตอนนี้:", mins)
                UpdateUI("🌕 Full Moon กำลังดำเนิน!", mins, true, true)
            end
        end

        task.wait(CHECK_INTERVAL)
    end
end

-- ==============================
-- HOST 2
-- ==============================

local function RunHost2()
    print("HOST 2 เริ่มตรวจสอบ")
    UpdateUI("Host 2: รอ JobId จาก Host 1...", nil, false, false)

    while true do
        local jobIdFromHost1 = getJobId()

        if jobIdFromHost1 and jobIdFromHost1 ~= "" then
            if game.JobId ~= jobIdFromHost1 then
                print("JobId ไม่ตรง → วาร์ปไปหา Host1")
                UpdateUI("กำลัง Warp ไปหา Host 1...", nil, false, false)
                TeleportService:TeleportToPlaceInstance(PlaceId, jobIdFromHost1, player)
            else
                local willFull, willEnd = GetMoonMinutes()
                local mins = willEnd or willFull
                UpdateUI("✅ อยู่เซิร์ฟเดียวกับ Host 1 แล้ว", mins, willEnd ~= nil, true)
            end
        else
            print("ยังไม่มี JobId จาก Host1")
            UpdateUI("Host 2: รอ JobId จาก Host 1...", nil, false, false)
        end

        task.wait(5)
    end
end

-- ==============================
-- START
-- ==============================

if _G.host == 1 then
    RunHost1()
elseif _G.host == 2 then
    RunHost2()
else
    warn("กรุณาตั้ง _G.host = 1 หรือ 2")
end
