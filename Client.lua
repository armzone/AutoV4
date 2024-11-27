local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local requestFunction = http_request or request or HttpPost or syn.request

local savedJobIdUrl = "http://223.206.146.78:5000/" .. _G.Group .. "/savedJobId"
local hostStatusUrl = "http://223.206.146.78:5000/" .. _G.Group .. "/HostStatus/"

local function getSavedJobId()
    local response = game:HttpGet(savedJobIdUrl)
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
    v229, v228, v227 = game.ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")

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
        print("ย้ายไปยังเซิร์ฟเวอร์ของ Host")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, hostJobId, Players.LocalPlayer)
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
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end

    local player = Players.LocalPlayer
    local Servers, Server, Next

    repeat
        Servers = ListServers(Next)
        Server = Servers.data[3]  -- เลือกเซิร์ฟเวอร์ที่ 3
        Next = Servers.nextPageCursor
    until Server

    if Server then
        wait(5) -- รอ 5 วินาทีก่อนเทเลพอร์ต
        TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, player)
    else
        warn("Server not found.")
    end
end

local function checkAndTeleport()
    wait(30)
    local trainingSessions, upgradeStatus = CheckAcientOneStatus()
    local hostJobId = getSavedJobId()
    local currentJobId = game.JobId

    print("Host JobId:", hostJobId)
    print("Current JobId:", currentJobId)

    if currentJobId == hostJobId then
        -- หากเงื่อนไขนี้เป็นจริง ผู้เล่นจะไม่ถูกย้ายไปเซิร์ฟเวอร์ที่ 3
        if upgradeStatus == "✅ Ready For Trial" or (trainingSessions == nil and upgradeStatus == "❓ You have yet to achieve greatness") then
            print("สถานะตรงเงื่อนไข หรือไม่ต้องย้ายเซิร์ฟเวอร์")
        else
            -- เงื่อนไขนี้จะทำงานหากไม่ตรงกับสถานะข้างต้น
            print("สถานะไม่ตรงเงื่อนไขและอยู่ในเซิร์ฟเวอร์เดียวกับ Host, ย้ายไปเซิร์ฟเวอร์ที่ 3...")
            TeleportToThirdServer()
        end
    else
        -- การตรวจสอบในกรณีที่ไม่อยู่ในเซิร์ฟเวอร์เดียวกับ Host
        if upgradeStatus == "✅ Ready For Trial" or (trainingSessions == nil and upgradeStatus == "❓ You have yet to achieve greatness") then
            print("สถานะตรงเงื่อนไข, เตรียมย้ายเซิร์ฟเวอร์ไปหา Host...")
            teleportToHost()
        else
            print("สถานะไม่ตรงเงื่อนไข และไม่ได้อยู่ในเซิร์ฟเวอร์เดียวกับ Host, ไม่ต้องทำอะไร")
        end
    end
end

while true do
    checkAndTeleport()
    wait(10)
end
