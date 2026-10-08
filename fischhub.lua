-- FischHub beta gate. Gameplay is delivered only to Roblox accounts the owner approved.
-- New testers don't need regular FischHub first: the gate shows the same agreement, registers
-- this install, then downloads the beta.
task.spawn(function()
  local players = game:GetService("Players")
  local started = os.clock()
  while (not players.LocalPlayer or game.PlaceId == 0) and os.clock() - started < 120 do task.wait(0.5) end
  local player = players.LocalPlayer
  if not player or (game.PlaceId ~= 16732694052 and game.GameId ~= 5750914919) then
    print("[FischHub beta] join fisch before loading") return
  end
  if type(httpget) ~= "function" or type(httppost) ~= "function" then
    print("[FischHub beta] this executor can't reach the website") return
  end
  local hs = game:GetService("HttpService")
  local origin, terms, file = "https://adorablewhale.world", "2026-10-01.1", "INSUI/cloud/access.json"
  local function readAccess()
    local ok, value = pcall(function() return isfile(file) and hs:JSONDecode(readfile(file)) or nil end)
    return ok and type(value) == "table" and value or {}
  end
  local function saveAccess(value)
    return pcall(function()
      for _, path in ipairs({"INSUI", "INSUI/cloud"}) do if not isfolder(path) then makefolder(path) end end
      writefile(file, hs:JSONEncode(value))
    end)
  end
  local function post(route, body, key)
    local ok, result = pcall(function()
      return hs:JSONDecode(httppost(origin .. route, hs:JSONEncode(body), "application/json", key and { Authorization = "Bearer " .. key } or {}))
    end)
    if not ok or type(result) ~= "table" then return nil, "website offline" end
    if result.ok ~= true then return nil, tostring(result.error or "website refused") end
    return result
  end

  -- 1. the agreement (the same one every script shows), when this install hasn't accepted it yet
  local access = readAccess()
  if access.terms ~= terms or access.cloud ~= true or access.reporting ~= true then
    local ok, lib = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/adorablewhale/insui/main/insui.lua"))() end)
    if not ok or type(lib) ~= "table" or type(lib.RequireTerms) ~= "function" then
      print("[FischHub beta] couldn't show the agreement; try again in a minute") return
    end
    pcall(function() lib:CreateWindow({ title = "fischhub beta", subtitle = "agreement", size = Vector2.new(520, 360), menuKey = "p", checkboxStyle = true }) end)
    local accepted = lib:RequireTerms()
    pcall(function() lib:Destroy() end)
    if not accepted then print("[FischHub beta] you disagreed with the agreement, so the beta didn't load") return end
    access = readAccess()
  end

  -- 2. this install's key (registering it when it has none) and reporting consent on the website
  if type(access.key) ~= "string" or #access.key ~= 64 then
    local result, why = post("/api/v1/register", { termsVersion = terms, cloudConsent = true, reportingConsent = true })
    if not result or type(result.key) ~= "string" then print("[FischHub beta] couldn't register: " .. tostring(why)) return end
    access.key, access.installation = result.key, result.installation
    access.terms, access.cloud, access.reporting, access.reportPending = terms, true, true, true
    if not saveAccess(access) then print("[FischHub beta] couldn't save your key") return end
  end
  if access.reportPending ~= false then
    local result, why = post("/api/v1/consent", { reporting = true, termsVersion = terms }, access.key)
    if not result then print("[FischHub beta] couldn't confirm the agreement: " .. tostring(why)) return end
    access.reportPending = false
    saveAccess(access)
  end

  -- 3. the beta itself: the website checks your Roblox user ID against the owner's list
  local headers = { Authorization = "Bearer " .. access.key, ["x-roblox-user-id"] = string.format("%.0f", player.UserId) }
  local function download(path)
    local success, result = pcall(httpget, origin .. "/api/v1/fischhub-beta" .. path, headers)
    if not success or type(result) ~= "string" then return nil end
    return result
  end
  local source = download("")
  if not source or not source:find("-- FischHubBeta", 1, true) then
    local parsed, message = pcall(function() return hs:JSONDecode(source or "") end)
    print("[FischHub beta] " .. (parsed and type(message) == "table" and message.error or "access unavailable; ask the owner to add your user ID")
      .. " (your user ID: " .. string.format("%.0f", player.UserId) .. ")")
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
