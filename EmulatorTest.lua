local HttpService = game:GetService("HttpService")
local DatastoreService = require(game:GetService("ReplicatedStorage"):WaitForChild("DatastoreService")) --wherever tf you store your module at, put it there
local passed = 0
local failed = 0
local ds = DatastoreService:GetDataStore("Test2012Store")
local testKey = "Player_1"
local testValue = {
    Coins = 100,
    Level = 5
}
local function tableToString(tbl)
    local str = "{ "
    for k, v in pairs(tbl) do
        str = str .. tostring(k) .. " = " .. tostring(v) .. ", "
    end
    return str .. "}"
end
print("[TEST] Setting data...")
local success = ds:SetAsync(testKey, testValue)
if success then
	passed = passed + 1
    print("[SET] Success: Set data to", tableToString(testValue))
else
	failed = failed + 1
    print("[SET] Failed to set data.")
end
wait(2)
print("[TEST] Getting data...")
local data = ds:GetAsync(testKey)
if data then
	passed = passed + 1
    print("[GET] Success: Retrieved", tableToString(data))
else
	failed = failed + 1
    print("[GET] Failed to retrieve data or data is nil.")
end
wait(2)
print("[TEST] Updating data...")
local updated = ds:UpdateAsync(testKey, function(old)
    old = old or {Coins = 0, Level = 1}
    old.Coins = old.Coins + 50
    old.Level = old.Level + 1
    return old
end)
if updated then
	passed = passed + 1
    print("[UPDATE] Success: Updated to", tableToString(updated))
else
	failed = failed + 1
    print("[UPDATE] Failed to update data.")
end
wait(2)
print("[TEST] Removing data...")
local removed = ds:RemoveAsync(testKey)
if removed then
	passed = passed + 1
    print("[REMOVE] Success: Data removed.")
else
	failed = failed + 1
    print("[REMOVE] Failed to remove data.")
end
wait(2)
print("[TEST] Verifying data removal...")
local afterRemoval = ds:GetAsync(testKey)
if afterRemoval == nil then
	passed = passed + 1
    print("[VERIFY] Data confirmed removed.")
else
	failed = failed + 1
    print("[VERIFY] Data still exists:", tableToString(afterRemoval))
end
local successpercentage = 100 * passed / (passed + failed)
print("Test complete. " .. successpercentage .. "% compliant with DatastoreService syntax.")
print(passed .. " passed, " .. failed .. " failed")
