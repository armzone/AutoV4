local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- URL ของ Firebase ที่เก็บข้อมูลล่าสุดจาก _latest_messages
local serverUrl = "http://223.205.211.207:5000/Fullmoon"

-- ฟังก์ชันสำหรับการดึงข้อมูลจาก Firebase
local function getLatestMessagesFromFirebase(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        if data then
            return data -- คืนค่าข้อมูลทั้งหมดที่ดึงมา
        else
            warn("ไม่พบข้อมูลในโหนด _latest_messages")
            return nil
        end
    else
        warn("ไม่สามารถดึงข้อมูลจาก Firebase ได้: " .. tostring(response))
        return nil
    end
end

-- ฟังก์ชันสำหรับเลือกโหนดที่มี player_count น้อยที่สุดก่อน จากนั้นเลือก time_till_full_moon <= 10 นาที
local function selectBestNode(nodes)
    local bestNode = nil
    local leastPlayers = math.huge -- ค่าเริ่มต้นเป็น infinity

    for _, node in pairs(nodes) do
        if node.player_count and node.time_till_full_moon then
            local playersCount = tonumber(node.player_count:match("%d+")) or math.huge
            local timeTillFullMoon = tonumber(node.time_till_full_moon:match("[0-9.]+")) or math.huge

            -- เลือกโหนดที่มีผู้เล่นน้อยที่สุดและ time_till_full_moon <= 10 นาที
            if playersCount < leastPlayers and timeTillFullMoon <= 10 then
                leastPlayers = playersCount
                bestNode = node
            end
        end
    end

    return bestNode -- คืนโหนดที่ดีที่สุด หรือ nil ถ้าไม่พบโหนดที่เหมาะสม
end

-- ฟังก์ชันสำหรับตรวจสอบและเทเลพอร์ต
local function checkForBestNodeAndTeleport()
    local latestMessages = getLatestMessagesFromFirebase(serverUrl)

    if latestMessages then
        local selectedNode = selectBestNode(latestMessages)

        if selectedNode and selectedNode.jobid then
            local player = Players.LocalPlayer
            TeleportService:TeleportToPlaceInstance(game.PlaceId, selectedNode.jobid, player)
        else
            warn("ไม่พบเซิร์ฟเวอร์ที่ตรงตามเงื่อนไข")
        end
    else
        warn("ไม่พบข้อมูลจาก Firebase หรือไม่สามารถดึงข้อมูลได้")
    end
end

-- สร้าง UI สำหรับปุ่ม
local screenGui = Instance.new("ScreenGui")
local teleportButton = Instance.new("TextButton")

screenGui.Name = "TeleportGui"
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

teleportButton.Size = UDim2.new(0, 200, 0, 50)
teleportButton.Position = UDim2.new(0, 20, 0, 20)
teleportButton.Text = "Go to Best Server"
teleportButton.Font = Enum.Font.SourceSansBold
teleportButton.TextSize = 20
teleportButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportButton.BorderSizePixel = 0
teleportButton.Parent = screenGui

local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0, 12)
uICorner.Parent = teleportButton

-- เพิ่มฟังก์ชันคลิกปุ่ม
teleportButton.MouseButton1Click:Connect(function()
    checkForBestNodeAndTeleport()
end)
