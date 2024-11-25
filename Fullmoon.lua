local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- URL ของ Firebase ที่เก็บข้อมูลล่าสุดจาก _latest_messages
local serverUrl = "http://223.205.84.47:5000/Fullmoon"

-- ฟังก์ชันสำหรับการดึงข้อมูลจาก Firebase
local function getLatestMessagesFromFirebase(url)
    local response = game:HttpGet(url)
    if response then
        local data = HttpService:JSONDecode(response)
        if data then
            return data -- คืนค่าข้อมูลทั้งหมดที่ดึงมา
        else
            warn("ไม่พบข้อมูลในโหนด _latest_messages")
            return nil
        end
    else
        warn("ไม่สามารถดึงข้อมูลจาก Firebase ได้")
        return nil
    end
end

-- ฟังก์ชันสำหรับเลือกโหนดที่มี player_count น้อยที่สุดก่อน จากนั้นเลือก time_till_full_moon <= 10 นาที
local function selectBestNode(nodes)
    local bestNode = nil
    local leastPlayers = math.huge -- ค่าเริ่มต้นเป็น infinity

    -- เลือกโหนดที่มี player_count น้อยที่สุดก่อน
    for _, node in pairs(nodes) do
        if node.player_count then
            local playersCount = tonumber(node.player_count:match("%d+")) -- ดึงจำนวนผู้เล่นจาก player_count (เช่น "8")
            if playersCount and playersCount < leastPlayers then
                leastPlayers = playersCount
                bestNode = node
            end
        end
    end

    -- ตรวจสอบว่าโหนดที่เลือกมี time_till_full_moon <= 10 นาทีหรือไม่
    if bestNode and bestNode.time_till_full_moon then
        local time = tonumber(bestNode.time_till_full_moon:match("[0-9.]+")) -- ดึงเลขจาก time_till_full_moon
        if time and time <= 10 then
            return bestNode -- หาก time_till_full_moon <= 10 นาที ให้เลือกโหนดนี้
        end
    end

    return nil -- คืนค่า nil หากไม่พบโหนดที่ตรงตามเงื่อนไข
end

-- ฟังก์ชันสำหรับตรวจสอบและเทเลพอร์ต
local function checkForBestNodeAndTeleport()
    -- ดึงข้อมูลจาก Firebase
    local latestMessages = getLatestMessagesFromFirebase(serverUrl)

    -- ตรวจสอบว่ามีข้อมูลที่ดึงมาได้หรือไม่
    if latestMessages then
        -- เลือกโหนดที่ดีที่สุด
        local selectedNode = selectBestNode(latestMessages)

        -- ตรวจสอบว่าได้เลือกโหนดมาเรียบร้อยแล้วหรือไม่
        if selectedNode and selectedNode.jobid then
            local player = Players.LocalPlayer -- ผู้เล่นที่ต้องการเทเลพอร์ต
            TeleportService:TeleportToPlaceInstance(game.PlaceId, selectedNode.jobid, player)
        else
            print("ไม่พบเซิร์ฟเวอร์ที่ตรงตามเงื่อนไข")
        end
    else
        warn("ไม่พบข้อมูลจาก Firebase หรือไม่สามารถดึงข้อมูลได้")
    end
end

-- สร้าง UI สำหรับปุ่ม
local screenGui = Instance.new("ScreenGui")
local teleportButton = Instance.new("TextButton")

screenGui.Name = "TeleportGui"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

teleportButton.Size = UDim2.new(0, 200, 0, 50)
teleportButton.Position = UDim2.new(0, 20, 0, 20) -- วางปุ่มที่มุมซ้ายบนของหน้าจอ
teleportButton.Text = "Go to Best Server"
teleportButton.Font = Enum.Font.SourceSansBold -- ตั้งฟ้อนต์เป็นตัวหนา
teleportButton.TextSize = 20
teleportButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180) -- สีพื้นหลังของปุ่ม
teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- สีของข้อความในปุ่ม
teleportButton.BorderSizePixel = 0
teleportButton.Parent = screenGui

-- ทำให้ปุ่มมีขอบแบบมน
local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0, 12) -- ปรับขนาดความมนของขอบ
uICorner.Parent = teleportButton

-- เพิ่มฟังก์ชันคลิกปุ่ม
teleportButton.MouseButton1Click:Connect(function()
    checkForBestNodeAndTeleport()
end)
