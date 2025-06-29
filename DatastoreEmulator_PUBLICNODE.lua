--THIS IS ONLY TO BE USED IF YOU WANT TO CONNECT TO THE PUBLIC NODE.
--IF YOU WANT TO USE YOUR OWN NODE, SEE DatastoreEmulator.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreService = {}
DatastoreService.__index = DatastoreService
local BACKEND_URL = "https://datastore.tocat.xyz"
local ACCESSKEY = "" -- Don't have an access key or don't wanna get one? Set this to 'public'.
--  				 Note: This is very insecure and will likely lead to your datastores being leaked. Don't use it for important stuff, as ANYONE can read/set data.
--           DM tocatwastaken on discord to request an access key for your own personal seperated datastore node.
local RATE_LIMIT = 30
local RETRY_DELAY = 1
local MAX_RETRIES = 3
local lastRequestTime = 0
local requestCount = 0
local requestQueue = {}
local DataStore = {}
DataStore.__index = DataStore

if ACCESSKEY == "" or ACCESSKEY == nil then
	warn("Access key not provided, using public.")
	warn("[DataStoreEmulator]: Note: This is very insecure and will likely lead to your datastores being leaked. Don't use it for important stuff, as ANYONE can read/set data.")
	ACCESSKEY = "public"
end
print("[DataStoreEmulator]: Checking backend url...")
local res = HttpService:GetAsync(BACKEND_URL .. "/ping")
if res == "OK" then
	print("[DataStoreEmulator]: Backend URL Returned OK")
else
	print("[DataStoreEmulator]: Backend URL didn't return OK, halting.")
	error("BackendURLNotOKResponse")
end

local function throttleRequest()
    if tick() - lastRequestTime >= 1 then
        lastRequestTime = tick()
        requestCount = 0
    end
    if requestCount < RATE_LIMIT then
        requestCount = requestCount + 1
        return true
    end
    table.insert(requestQueue, tick())
    return false
end

local function processQueue()
    for i = #requestQueue, 1, -1 do
        if tick() - requestQueue[i] >= 1 then
            table.remove(requestQueue, i)
        end
    end
end

local function retryRequest(func)
    local retries = 0
    local success, result
    repeat
        success, result = pcall(func)
        if not success then
            retries = retries + 1
            wait(RETRY_DELAY)
        end
    until success or retries >= MAX_RETRIES
    return success, result
end
function DatastoreService:GetDataStore(name)
    local success, result = retryRequest(function()
        if not throttleRequest() then return false end
        local payload = { name = name }
        local json = HttpService:JSONEncode(payload)
        return HttpService:PostAsync(BACKEND_URL .. "/createdatastore?accesskey=" .. ACCESSKEY, json, Enum.HttpContentType.ApplicationJson)
    end)
    processQueue()

    if success then
        print("[DataStoreEmulator]: Backend created datastore: " .. name)
    else
        warn("[DataStoreEmulator]: Failed to create datastore: " .. name .. "\Error:" .. result)
    end

    local self = setmetatable({}, DataStore)
    self.StoreName = name
    return self
end


function DataStore:GetAsync(key)
    local success, result = retryRequest(function()
        if not throttleRequest() then return nil end
        local url = BACKEND_URL .. "/getdata?key=" .. HttpService:UrlEncode(self.StoreName .. "_" .. key) .. "&accesskey=" .. ACCESSKEY
        return HttpService:GetAsync(url)
    end)
    processQueue()
    if success then
        --local decoded = HttpService:JSONDecode(result)
        return result or nil
    else
        print("[DataStoreEmulator]: [DatastoreService:GetAsync] Failed to retrieve data for key: " .. key .. "\n" .. result)
        return nil
    end
end

function DataStore:SetAsync(key, value)
    local success, result = retryRequest(function()
        if not throttleRequest() then return false end
        local payload = { key = self.StoreName .. "_" .. key, value = value }
        local json = HttpService:JSONEncode(payload)
		print("[DBG] " .. BACKEND_URL .. "/setdata?accesskey=" .. ACCESSKEY)
        return HttpService:PostAsync(BACKEND_URL .. "/setdata?accesskey=" .. ACCESSKEY, json, Enum.HttpContentType.ApplicationJson)
    end)
    processQueue()
    if success then
        return true
    else
        print("[DataStoreEmulator]: [DatastoreService:SetAsync] Failed to save data for key: " .. key .. "\n" .. result)
        return false
    end
end

function DataStore:UpdateAsync(key, callback)
    local success, currentData = retryRequest(function()
        if not throttleRequest() then return nil end
        local data = self:GetAsync(key)
        return data
    end)
    processQueue()
    if success then
        local updatedData = callback(currentData)
        local successSet = self:SetAsync(key, updatedData)
        if successSet then
            return updatedData
        else
            print("[DataStoreEmulator]: [DatastoreService:UpdateAsync] Failed to update data for key: " .. key)
            return nil
        end
    else
        print("[DataStoreEmulator]: [DatastoreService:UpdateAsync] Failed to retrieve current data for key: " .. key)
        return nil
    end
end

function DataStore:IncrementAsync(key, delta)
    delta = delta or 1
    return self:UpdateAsync(key, function(currentData)
        currentData = currentData or 0
        return currentData + delta
    end)
end

function DataStore:RemoveAsync(key)
    local success, result = retryRequest(function()
        if not throttleRequest() then return false end
        local url = BACKEND_URL .. "/removedata?key=" .. HttpService:UrlEncode(self.StoreName .. "_" .. key) .. "&accesskey=" .. ACCESSKEY
        return HttpService:GetAsync(url)
    end)
    processQueue()
    if success then
        return true
    else
        print("[DataStoreEmulator]: [DatastoreService:RemoveAsync] Failed to remove data for key: " .. key)
        return false
    end
end

function DataStore:GetSortedAsync(minValue, maxValue)
    local success, result = retryRequest(function()
        if not throttleRequest() then return nil end
        local url = BACKEND_URL .. "/getsorteddata?store=" .. HttpService:UrlEncode(self.StoreName) ..
                    "&minValue=" .. HttpService:UrlEncode(tostring(minValue)) ..
                    "&maxValue=" .. HttpService:UrlEncode(tostring(maxValue))
        return HttpService:GetAsync(url)
    end)
    processQueue()
    if success then
        return HttpService:JSONDecode(result) or {}
    else
        print("[DataStoreEmulator]: [DatastoreService:GetSortedAsync] Failed to retrieve ordered data.")
        return {}
    end
end

function DatastoreService:GetGlobalDataStore(name)
    return self:GetDataStore(name)
end

print("[DataStoreEmulator]: CATBLOX DatastoreEmulator initialized!")
return DatastoreService
