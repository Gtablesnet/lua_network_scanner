-- Function to get GPS coordinates using gpspipe with a timeout
function get_gps_coordinates(timeout)
    local handle = io.popen("timeout " .. timeout .. " gpspipe -w")
    local gps_data = handle:read("*a")
    handle:close()

    if not gps_data or gps_data == "" then
        return {error = "No GPS data received."}
    end

    local lat, lon = gps_data:match('"lat":%s*([%-?%d%.]+),%s*"lon":%s*([%-?%d%.]+)')
    if lat and lon then
        return {
            latitude = tonumber(lat),
            longitude = tonumber(lon)
        }
    else
        return {error = "Failed to parse GPS data."}
    end
end

-- Function to execute a shell command
local function executeCommand(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Function to split a line into words
local function splitLine(line)
    local words = {}
    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

-- Function to clean symbols from words
local function cleanSymbols(word)
    local symbolsToRemove = {"▂▄▆█", "▂▄▆_", "▂▄__", "▂___"}
    for _, symbol in ipairs(symbolsToRemove) do
        word = word:gsub(symbol, "")
    end
    return word
end

-- Function to concatenate speed info like "Mbit/s" to the speed number
local function concatSpeed(words)
    local i = 1
    while i <= #words do
        if words[i]:match("^%d+$") and words[i + 1] == "Mbit/s" then
            words[i] = words[i] .. words[i + 1]
            table.remove(words, i + 1)
        else
            i = i + 1
        end
    end
    return words
end

-- Function to parse the output of nmcli and clean data
local function parseWifiList(output)
    local lines = {}
    for line in output:gmatch("(.-)\n") do
        table.insert(lines, line)
    end

    local wifiList = {}
    for i = 2, #lines do
        if lines[i] and lines[i]:match("%S") then
            local splitRow = splitLine(lines[i])
            if splitRow[1] == "*" then
                table.remove(splitRow, 1)
            end

            for j, word in ipairs(splitRow) do
                splitRow[j] = cleanSymbols(word)
            end

            splitRow = concatSpeed(splitRow)

            local signal_value = nil
            for idx, word in ipairs(splitRow) do
                if word:match("Mbit/s$") then
                    signal_value = idx + 1
                    break
                end
            end

            if signal_value and tonumber(splitRow[signal_value]) and tonumber(splitRow[signal_value]) > 92 then
                table.insert(wifiList, splitRow)
            end
        end
    end

    return wifiList
end

-- Function to load existing data from the file
local function loadExistingData(filename)
    local file = io.open(filename, "r")
    if not file then 
        print("Error: Could not open file " .. filename)
        return {} 
    end

    local data = file:read("*a")
    file:close()

    -- Try to load the data as a Lua table
    local loadedData = load("return " .. data)
    if loadedData then
        return loadedData()
    else
        print("Error: Failed to parse file data.")
        return {}
    end
end

-- Function to save data to the file
local function saveDataToFile(filename, data)
    local file = io.open(filename, "w")
    if not file then
        print("Error: Could not open file " .. filename .. " for writing.")
        return
    end

    file:write("return " .. table.tostring(data))
    file:close()
end

-- Convert a Lua table to a string
function table.tostring(tbl)
    local result = "{\n"
    for _, v in ipairs(tbl) do
        result = result .. "  {"
        for _, val in ipairs(v) do
            result = result .. '"' .. val .. '", '
        end
        result = result:sub(1, -3) .. "},\n"
    end
    result = result .. "}"
    return result
end

-- Main function to execute the logic
local function main()
    local filename = "wifi_coords.txt"
    local existingData = loadExistingData(filename)
    local commandOutput = executeCommand("nmcli dev wifi list ifname wlan0")
    local filteredArray = parseWifiList(commandOutput)

    -- Check if filteredArray is valid and has elements
    if not filteredArray or #filteredArray == 0 then
        print("No WiFi networks found with signal.")
        return
    end

    print("WiFi Networks with signal:")
    for _, row in ipairs(filteredArray) do
        local ssid = row[1]
        local alreadyExists = false

        -- Check if the SSID already exists in the existing data
        for _, existingRow in ipairs(existingData) do
            if existingRow[1] == ssid then
                alreadyExists = true
                break
            end
        end

        -- If SSID is new, get GPS coordinates and add it to existing data
        if not alreadyExists then
            local gps_coords = get_gps_coordinates(5)
            if gps_coords.error then
                table.insert(row, "Error: " .. gps_coords.error)
            else
                table.insert(row, "Latitude: " .. gps_coords.latitude)
                table.insert(row, "Longitude: " .. gps_coords.longitude)
            end

            table.insert(existingData, row)
        end
    end

    -- Save the updated data to file
    saveDataToFile(filename, existingData)
    print("Data written to " .. filename)
end

while true do
    main()
    --os.execute("sleep 2")
end-- Function to get GPS coordinates using gpspipe with a timeout
function get_gps_coordinates(timeout)
    local handle = io.popen("timeout " .. timeout .. " gpspipe -w")
    local gps_data = handle:read("*a")
    handle:close()

    if not gps_data or gps_data == "" then
        return {error = "No GPS data received."}
    end

    local lat, lon = gps_data:match('"lat":%s*([%-?%d%.]+),%s*"lon":%s*([%-?%d%.]+)')
    if lat and lon then
        return {
            latitude = tonumber(lat),
            longitude = tonumber(lon)
        }
    else
        return {error = "Failed to parse GPS data."}
    end
end

-- Function to execute a shell command
local function executeCommand(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Function to split a line into words
local function splitLine(line)
    local words = {}
    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

-- Function to clean symbols from words
local function cleanSymbols(word)
    local symbolsToRemove = {"▂▄▆█", "▂▄▆_", "▂▄__", "▂___"}
    for _, symbol in ipairs(symbolsToRemove) do
        word = word:gsub(symbol, "")
    end
    return word
end

-- Function to concatenate speed info like "Mbit/s" to the speed number
local function concatSpeed(words)
    local i = 1
    while i <= #words do
        if words[i]:match("^%d+$") and words[i + 1] == "Mbit/s" then
            words[i] = words[i] .. words[i + 1]
            table.remove(words, i + 1)
        else
            i = i + 1
        end
    end
    return words
end

-- Function to parse the output of nmcli and clean data
local function parseWifiList(output)
    local lines = {}
    for line in output:gmatch("(.-)\n") do
        table.insert(lines, line)
    end

    local wifiList = {}
    for i = 2, #lines do
        if lines[i] and lines[i]:match("%S") then
            local splitRow = splitLine(lines[i])
            if splitRow[1] == "*" then
                table.remove(splitRow, 1)
            end

            for j, word in ipairs(splitRow) do
                splitRow[j] = cleanSymbols(word)
            end

            splitRow = concatSpeed(splitRow)

            local signal_value = nil
            for idx, word in ipairs(splitRow) do
                if word:match("Mbit/s$") then
                    signal_value = idx + 1
                    break
                end
            end
            --you can change the signal strength value here
            if signal_value and tonumber(splitRow[signal_value]) and tonumber(splitRow[signal_value]) > 100 then
                table.insert(wifiList, splitRow)
            end
        end
    end

    return wifiList
end

-- Function to load existing data from the file
local function loadExistingData(filename)
    local file = io.open(filename, "r")
    if not file then 
        print("Error: Could not open file " .. filename)
        return {} 
    end

    local data = file:read("*a")
    file:close()

    -- Try to load the data as a Lua table
    local loadedData = load("return " .. data)
    if loadedData then
        return loadedData()
    else
        print("Error: Failed to parse file data.")
        return {}
    end
end

-- Function to save data to the file
local function saveDataToFile(filename, data)
    local file = io.open(filename, "w")
    if not file then
        print("Error: Could not open file " .. filename .. " for writing.")
        return
    end

    file:write("return " .. table.tostring(data))
    file:close()
end

-- Convert a Lua table to a string
function table.tostring(tbl)
    local result = "{\n"
    for _, v in ipairs(tbl) do
        result = result .. "  {"
        for _, val in ipairs(v) do
            result = result .. '"' .. val .. '", '
        end
        result = result:sub(1, -3) .. "},\n"
    end
    result = result .. "}"
    return result
end

-- Main function to execute the logic
local function main()
    local filename = "distance_cal.txt"
    local existingData = loadExistingData(filename)
    local commandOutput = executeCommand("nmcli dev wifi list")
    local filteredArray = parseWifiList(commandOutput)

    -- Check if filteredArray is valid and has elements
    if not filteredArray or #filteredArray == 0 then
        print("No WiFi networks found with signal.")
        return
    end

    print("WiFi Networks with signal: ")
    for _, row in ipairs(filteredArray) do
        local ssid = row[1]
        local alreadyExists = false

        -- Check if the SSID already exists in the existing data
        for _, existingRow in ipairs(existingData) do
            if existingRow[1] == ssid then
                alreadyExists = true
                break
            end
        end

        -- If SSID is new, get GPS coordinates and add it to existing data
        if not alreadyExists then
            local gps_coords = get_gps_coordinates(1)
            if gps_coords.error then
                table.insert(row, "Error: " .. gps_coords.error)
            else
                table.insert(row, "Latitude: " .. gps_coords.latitude)
                table.insert(row, "Longitude: " .. gps_coords.longitude)
            end

            table.insert(existingData, row)
        end
    end

    -- Save the updated data to file
    saveDataToFile(filename, existingData)
    print("Data written to " .. filename)
end

while true do
    main()
    os.execute("sleep 1")
end
