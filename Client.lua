local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local requestFunction = http_request or request or HttpPost or syn.request

local savedJobIdUrl = "http://223.206.69.30:5000/" .. _G.Group .. "/savedJobId"
local hostStatusUrl = "http://223.206.69.30:5000/" .. _G.Group .. "/HostStatus/"

-- ฟังก์ชันสำหรับการเรียก HTTP อย่างปลอดภัย
local function safeHttpGet(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        return response
    else
        print("HTTP Error: ", response) -- แสดงข้อความข้อผิดพลาด
        wait(5) -- รอ 5 วินาทีก่อนลองใหม่
        return nil
    end
end

local function getSavedJobId()
    local response = safeHttpGet(savedJobIdUrl)
    if response then
        local data = HttpService:JSONDecode(response)
        if data and data.jobid then
            return data.jobid
        end
    end
    return nil
end

local function CheckAcientOneStatus()
    local v227, v228, v229 = nil, nil, nil
    local success, err = pcall(function()
        v229, v228, v227 = game.ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
    end)
    if not success then
        print("Error invoking server: ", err)
        wait(5) -- รอ 5 วินาทีก่อนลองใหม่
        return nil, "Error"
    end

    local trainingSessions = v228
    local upgradeStatus
    if v229 == 1 or v229 == 3 then
        upgradeStatus = "💪 Required Train More"
    elseif v229 == 2 or v229 == 4 or v229 == 7 then
        upgradeStatus = "⚙️ Can Buy Gear With " .. v227 .. " Fragments"
    elseif v229 == 5 then
        upgradeStatus = "🏆 You Are Done Your Race."
    elseif v229 == 6 then
        upgradeStatus = "⏳ Upgrades completed: " .. (v228 - 2) .. "/3, Need Trains More"
    elseif v229 == 0 then
        upgradeStatus = "✅ Ready For Trial"
    else
        upgradeStatus = "❓ You have yet to achieve greatness"
    end

    return trainingSessions, upgradeStatus
end

local function teleportToHost()
    local hostJobId = getSavedJobId()
    if hostJobId then
        if hostJobId ~= game.JobId then
            print("ย้ายไปยังเซิร์ฟเวอร์ของ Host")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, hostJobId, Players.LocalPlayer)
        else
            print("คุณอยู่ในเซิร์ฟเวอร์เดียวกับ Host แล้ว")
        end
    else
        print("ไม่พบ JobId ของ Host ในเซิร์ฟเวอร์")
    end
end

local function TeleportToThirdServer()
    local PlaceId = game.PlaceId
    local ServerType = "Public"
    local SortOrder = "Asc"
    local ExcludeFullGames = true
    local Limit = 100

    local ApiUrl = string.format("https://games.roblox.com/v1/games/%d/servers/%s?sortOrder=%s&excludeFullGames=%s&limit=%d",
        PlaceId, ServerType, SortOrder, tostring(ExcludeFullGames), Limit)

    local function ListServers(cursor)
        local url = ApiUrl .. ((cursor and "&cursor="..cursor) or "")
        local response = safeHttpGet(url)
        if response then
            return HttpService:JSONDecode(response)
        else
            return nil
        end
    end

    local player = Players.LocalPlayer
    local Servers, Server, Next
    local retryCount = 0
    local maxRetries = 10 -- กำหนดจำนวนครั้งสูงสุด

    repeat
        Servers = ListServers(Next)
        if Servers and Servers.data then
            Server = Servers.data[3] -- เลือกเซิร์ฟเวอร์ที่ 3
            Next = Servers.nextPageCursor
        else
            Server = nil
        end

        retryCount = retryCount + 1
        if not Server and retryCount < maxRetries then
            print("Retrying... Attempt", retryCount)
            wait(5) -- รอ 5 วินาทีก่อนลองใหม่
        end
    until Server or retryCount >= maxRetries

    if Server then
        print("Teleporting to third server...")
        TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, player)
    else
        warn("Unable to find a suitable server. Attempting random server.")
        TeleportService:Teleport(PlaceId) -- ย้ายไปเซิร์ฟเวอร์สุ่ม
    end
end


local function checkAndTeleport()
    wait(30)
    local trainingSessions, upgradeStatus = CheckAcientOneStatus()
    if upgradeStatus == "Error" then
        return -- ข้ามการทำงานหากเกิดข้อผิดพลาด
    end

    local hostJobId = getSavedJobId()
    local currentJobId = game.JobId

    print("Host JobId:", hostJobId)
    print("Current JobId:", currentJobId)

    if currentJobId == hostJobId then
        if upgradeStatus == "✅ Ready For Trial" or (trainingSessions == nil and upgradeStatus == "❓ You have yet to achieve greatness") then
            print("สถานะตรงเงื่อนไข หรือไม่ต้องย้ายเซิร์ฟเวอร์")
        else
            print("สถานะไม่ตรงเงื่อนไขและอยู่ในเซิร์ฟเวอร์เดียวกับ Host, ย้ายไปเซิร์ฟเวอร์ที่ 3...")
            TeleportToThirdServer()
        end
    else
        if upgradeStatus == "✅ Ready For Trial" or (trainingSessions == nil and upgradeStatus == "❓ You have yet to achieve greatness") then
            print("สถานะตรงเงื่อนไข, เตรียมย้ายเซิร์ฟเวอร์ไปหา Host...")
            teleportToHost()
        else
            print("สถานะไม่ตรงเงื่อนไข และไม่ได้อยู่ในเซิร์ฟเวอร์เดียวกับ Host, ไม่ต้องทำอะไร")
        end
    end
end

while true do
    local success, err = pcall(function()
        checkAndTeleport()
    end)
    if not success then
        warn("Error in checkAndTeleport:", err)
        wait(10) -- รอ 10 วินาทีก่อนลองใหม่
    end
    wait(30) -- หน่วงเวลาเพื่อลดการเรียก API บ่อยเกินไป
end
