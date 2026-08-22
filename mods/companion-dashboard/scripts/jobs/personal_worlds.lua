local job = { name = "personal_worlds", per_surface = false, interval = 600 }

function job.run(_st, _si, _budget)
  if not (remote.interfaces.personal_nauvis and remote.interfaces.personal_nauvis.get_status) then
    return 1, { available = false, worlds = {}, online = 0, total = 0 }
  end
  local ok, worlds = pcall(remote.call, "personal_nauvis", "get_status")
  if not ok or type(worlds) ~= "table" then
    return 1, { available = true, error = tostring(worlds), worlds = {}, online = 0, total = 0 }
  end
  table.sort(worlds, function(a, b) return (a.slot or math.huge) < (b.slot or math.huge) end)
  local online = 0
  local modes = { coop = 0, pvp = 0, pending = 0 }
  for _, world in ipairs(worlds) do
    if world.online then online = online + 1 end
    local mode = world.mode or "pending"
    modes[mode] = (modes[mode] or 0) + 1
  end
  return 1, { available = true, worlds = worlds, online = online, total = #worlds, modes = modes }
end

return job
