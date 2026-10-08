-- FischHub beta gate. Gameplay is delivered only to approved installation keys.
task.spawn(function()
  local players = game:GetService("Players")
  local started = os.clock()
  while (not players.LocalPlayer or game.PlaceId == 0) and os.clock() - started < 120 do task.wait(0.5) end
  local player = players.LocalPlayer
  if not player or (game.PlaceId ~= 16732694052 and game.GameId ~= 5750914919) then
    print("[FischHub beta] join fisch before loading") return
  end
  local hs = game:GetService("HttpService")
  local ok, access = pcall(function() return hs:JSONDecode(readfile("INSUI/cloud/access.json")) end)
  if not ok or type(access) ~= "table" or type(access.key) ~= "string" or #access.key ~= 64 or type(httpget) ~= "function" then
    print("[FischHub beta] run regular fischhub once, then ask the owner to approve your beta access") return
  end
  local headers = { Authorization = "Bearer " .. access.key, ["x-roblox-user-id"] = string.format("%.0f", player.UserId) }
  local function download(path)
    local success, result = pcall(httpget, "https://adorablewhale.world/api/v1/fischhub-beta" .. path, headers)
    if not success or type(result) ~= "string" then return nil end
    return result
  end
  local source = download("")
  if not source or not source:find("-- FischHubBeta", 1, true) then
    local parsed, message = pcall(function() return hs:JSONDecode(source or "") end)
    print("[FischHub beta] " .. (parsed and type(message) == "table" and message.error or "access unavailable; ask the owner to save your beta access"))
    return
  end
  local library = download("/insui")
  if not library or not library:find("function InsUi:SyntheticMouse", 1, true) then
    print("[FischHub beta] beta ui unavailable; try again later") return
  end
  local saved, reason = pcall(function()
    for _, path in ipairs({"INSUI", "INSUI/FischHubBeta"}) do if not isfolder(path) then makefolder(path) end end
    writefile("INSUI/FischHubBeta/insui.lua", library)
  end)
  if not saved then print("[FischHub beta] could not save beta ui: " .. tostring(reason)) return end
  local fn, err = loadstring(source)
  if not fn then print("[FischHub beta] release did not compile: " .. tostring(err)) return end
  -- Manual beta loading replaces the regular script without overwriting its settings.
  if _G.FischHub and type(_G.FischHub.Unload) == "function" then pcall(_G.FischHub.Unload) end
  fn()
end)
