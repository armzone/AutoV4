local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local requestFunction = http_request or request or HttpPost or syn.request

local savedJobIdUrl = "http://223.205.204.154:5000/" .. _G.Group .. "/savedJobId"
local putUrlBase = "http://223.205.204.154:5000/" .. _G.Group .. "/HostStatus/"
local apiUrl = "http://223.205.204.154:5000/Fullmoon"

local function isHost1(username)
    for _, name in ipairs(_G.Host.Host1) do
        if name == username then
            return true
        end
    end
    return false
end

local function isHost2(username)
    for _, name in ipairs(_G.Host.Host2) do
        if name == username then
            return true
        end
    end
    return false
end

local function saveJobId(jobId)
    print("Host 1 บันทึก jobId: ", jobId)
    local response = requestFunction({
        Url = savedJobIdUrl,
        Method = "PUT",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({ jobid = jobId })
    })

    if response.StatusCode == 200 then
        print("บันทึก JobId สำเร็จ: " .. jobId)
    else
        warn("ไม่สามารถบันทึก JobId ได้: " .. (response.StatusMessage or "Unknown Error"))
    end
end

local function getSavedJobId()
    local response = game:HttpGet(savedJobIdUrl)
    if response then
        local data = HttpService:JSONDecode(response)
        if data and data.jobid then
            print("Host 2 ดึง jobId สำเร็จ: " .. data.jobid)
            return data.jobid
        else
            warn("ข้อมูลที่ได้รับไม่มี jobid หรือเป็นค่าว่าง")
        end
    else
        warn("ไม่สามารถดึงข้อมูล JobId ได้")
    end
    return nil
end

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
        local c = game.Lighting
        local ao = c.ClockTime
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

local function fetchBestServer()
    local response = game:HttpGet(apiUrl)
    if response then
        print("ข้อมูลที่ได้รับจาก API:", response)
        local data = HttpService:JSONDecode(response)
        if data then
            print("ข้อมูลที่ได้รับจาก API:", HttpService:JSONEncode(data))
            local bestServer = nil
            local leastPlayers = math.huge

            for _, serverData in pairs(data) do
                local playerCount = tonumber(serverData.player_count)
                local timeTillFullMoon = tonumber(serverData.time_till_full_moon:match("^[%d%.]+"))

                print("ตรวจสอบเซิร์ฟเวอร์:", serverData.jobid)
                print("playerCount:", playerCount)
                print("timeTillFullMoon:", timeTillFullMoon)

                if playerCount and timeTillFullMoon then
                    if playerCount < leastPlayers and timeTillFullMoon <= 10 then
                        leastPlayers = playerCount
                        bestServer = serverData
                        print("พบเซิร์ฟเวอร์ที่ตรงเงื่อนไข: ", HttpService:JSONEncode(bestServer))
                    end
                end
            end
            return bestServer
        else
            warn("ไม่สามารถแปลงข้อมูล JSON ได้")
        end
    else
        warn("ไม่สามารถเชื่อมต่อกับ API ได้")
    end
    return nil
end

local function updateHostStatus(username, jobId, playerCount, serverStatus, statusForClient)
    local url = putUrlBase .. HttpService:UrlEncode(username)
    local hostData = {
        username = username,
        playercount = playerCount .. "/12",
        serverstatus = serverStatus,
        jobid = jobId,
        status_for_client = statusForClient
    }

    local response = requestFunction({
        Url = url,
        Method = "PUT",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(hostData)
    })

    if response.StatusCode == 200 then
        print(username .. " อัปเดตสถานะสำเร็จ")
    else
        warn("ไม่สามารถอัปเดตสถานะได้: " .. (response.StatusMessage or "Unknown Error"))
    end
end

local function manageServerEntry()
    local username = Players.LocalPlayer.Name
    local currentJobId = game.JobId

    if isHost1(username) then
        -- ตรวจสอบสถานะเซิร์ฟเวอร์ปัจจุบันก่อนเลือกเซิร์ฟเวอร์ใหม่
        local currentServerStatus = CheckMoonAndTimeForSea3()
        print("Host 1: Current Server Status -", currentServerStatus)

        -- เงื่อนไขสำหรับเซิร์ฟเวอร์ที่เหมาะสม
        local willFullMoonIn = tonumber(currentServerStatus:match("Will Full Moon In (%d+)"))
        local willEndMoonIn = tonumber(currentServerStatus:match("Will End Moon In (%d+)"))

        if (willFullMoonIn and willFullMoonIn < 10) or (willEndMoonIn and willEndMoonIn > 2) then
            print("Host 1: เซิร์ฟเวอร์ปัจจุบันเหมาะสมสำหรับ Full Moon หยุดการเลือกเซิร์ฟเวอร์ใหม่")
            updateHostStatus(_G.Host.Host1[1], currentJobId, #Players:GetPlayers(), currentServerStatus, "Connected")
            return
        end

        -- ค้นหาเซิร์ฟเวอร์ใหม่หากไม่ตรงเงื่อนไข
        local bestServer = fetchBestServer()
        if bestServer then
            local jobId = bestServer.jobid
            saveJobId(jobId)
            updateHostStatus(_G.Host.Host1[1], jobId, #Players:GetPlayers(), CheckMoonAndTimeForSea3(), "Connected")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Players.LocalPlayer)
        else
            print("ไม่พบเซิร์ฟเวอร์ที่เหมาะสมสำหรับ Host 1")
        end
    elseif isHost2(username) then
        -- Host 2: รอ jobId ที่ Host 1 บันทึก
        local savedJobId = getSavedJobId()
        if savedJobId and savedJobId ~= "" and savedJobId ~= currentJobId then
            print("Host 2 กำลังย้ายไปยังเซิร์ฟเวอร์ที่ Host 1 เลือกไว้ด้วย jobId: " .. savedJobId)
            updateHostStatus(_G.Host.Host2[1], savedJobId, #Players:GetPlayers(), CheckMoonAndTimeForSea3(), "Connected")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, savedJobId, Players.LocalPlayer)
        else
            print("Host 2 กำลังรอให้ Host 1 บันทึก jobId...")
        end
    end
end


print("รอ 30 วินาทีก่อนเริ่มการทำงาน...")
wait(30)
while true do
    manageServerEntry()
    wait(10)
end
