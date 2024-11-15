local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local requestFunction = http_request or request or HttpPost or syn.request

local savedJobIdUrl = "http://223.206.145.158:5000/" .. _G.Group .. "/savedJobId"
local putUrlBase = "http://223.206.145.158:5000/" .. _G.Group .. "/HostStatus/"
local apiUrl = "http://223.206.145.158:5000/Fullmoon"

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
    local response = requestFunction({
        Url = savedJobIdUrl,
        Method = "PUT", -- เปลี่ยนจาก POST เป็น PUT
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
        if data and data.jobId then
            print("ดึง JobId สำเร็จ: " .. data.jobId)
            return data.jobId
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
        local data = HttpService:JSONDecode(response)
        if data then
            local bestServer = nil
            local leastPlayers = math.huge

            for _, serverData in pairs(data) do
                print("ตรวจสอบเซิร์ฟเวอร์:", HttpService:JSONEncode(serverData))  -- เพิ่มการพิมพ์ข้อมูลที่ได้รับ
                local playerCount = tonumber(serverData.player_count)
                local timeTillFullMoon = tonumber(serverData.time_till_full_moon)  -- แปลงเป็นตัวเลข

                if playerCount and timeTillFullMoon and playerCount < leastPlayers then
                    if timeTillFullMoon <= 10 then
                        leastPlayers = playerCount
                        bestServer = serverData
                    end
                end
            end
            return bestServer
        end
    else
        warn("ไม่สามารถดึงข้อมูลจาก API ได้")
    end
    return nil
end



local function updateHostStatus(username, jobId, playerCount, serverStatus, statusForClient)
    local url = putUrlBase .. HttpService:UrlEncode(username)
    local hostData = {
        Username = username,
        Playercount = playerCount .. "/12",
        Serverstatus = serverStatus,
        Jobid = jobId,
        StatusforClient = statusForClient
    }

    local response = requestFunction({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(hostData)
    })

    if response.StatusCode == 200 then
        print(username .. " อัปเดตสถานะสำเร็จ")
    else
        warn("ไม่สามารถอัปเดตสถานะได้: " .. (response.StatusMessage or "Unknown Error"))
    end
end

local function teleportToBestServer()
    local playerName = Players.LocalPlayer.Name
    local bestServer = fetchBestServer()

    local currentServerStatus = CheckMoonAndTimeForSea3()

    print("Current Moon Status: ", currentServerStatus)

    if (currentServerStatus:find("Will Full Moon In") and currentServerStatus:find("%d+") and tonumber(currentServerStatus:match("%d+")) < 10) or
       (currentServerStatus:find("Will End Moon In") and currentServerStatus:find("%d+") and tonumber(currentServerStatus:match("%d+")) > 2) then
        print("เซิร์ฟเวอร์ปัจจุบันมีเวลาที่เหมาะสมสำหรับ Full Moon, หยุดการหาเซิร์ฟเวอร์ใหม่...")
        updateHostStatus(playerName, game.JobId, #Players:GetPlayers(), currentServerStatus, "Connected")
        return
    else
        print("ไม่ตรงกับเงื่อนไข Full Moon")
    end

    if bestServer then
        local jobId = bestServer.jobid
        local playerCount = bestServer.player_count
        local serverStatus = bestServer.serverStatus or "Unknown"
        local statusForClient = "Connected"

        updateHostStatus(playerName, jobId, playerCount, serverStatus, statusForClient)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Players.LocalPlayer)
    else
        print("ไม่พบเซิร์ฟเวอร์ที่เหมาะสม")
    end
end

local function manageServerEntry()
    local username = Players.LocalPlayer.Name
    local currentJobId = game.JobId

    if isHost1(username) then
        local bestServer = fetchBestServer()
        if bestServer then
            local jobId = bestServer.jobid
            saveJobId(jobId)
            teleportToBestServer()
        else
            print("ไม่พบเซิร์ฟเวอร์ที่เหมาะสมสำหรับ Host 1")
        end
    elseif isHost2(username) then
        local savedJobId = getSavedJobId()
        if savedJobId and savedJobId ~= currentJobId then
            print("ย้ายไปยังเซิร์ฟเวอร์ที่ Host1 ได้เลือกไว้แล้ว")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, savedJobId, Players.LocalPlayer)
        else
            print("ไม่มี JobId ที่บันทึกไว้ หรือ Host 2 อยู่ในเซิร์ฟเวอร์เดียวกันแล้ว")
        end
    end
end

local function checkHost2Status()
    local savedJobId = getSavedJobId()
    local currentJobId = game.JobId

    if isHost2(Players.LocalPlayer.Name) then
        if savedJobId and savedJobId ~= currentJobId then
            print("Host 2 กำลังย้ายไปยังเซิร์ฟเวอร์ที่ Host 1 เลือก...")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, savedJobId, Players.LocalPlayer)
        else
            print("Host 2 อยู่ในเซิร์ฟเวอร์เดียวกับ Host 1 แล้ว")
        end
    end
end

manageServerEntry()

while true do
    manageServerEntry()
    checkHost2Status()
    wait(10)
end
