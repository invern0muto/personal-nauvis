-- Getaggte Constant Combinators (Beschreibung beginnt mit "FDASH:").
--
-- Damit lassen sich beliebige Schaltkreis-Signale ins Dashboard heben, ohne
-- dass der Mod etwas ueber ihre Bedeutung wissen muss.

local sweep = require("scripts.sweep")

local job = { name = "circuits", per_surface = true, interval = 300 }

local TYPES = { "constant-combinator" }
local PREFIX = "FDASH:"

-- Liest bei einem markierten Kombinator nicht nur dessen konfigurierte Werte,
-- sondern auch die tatsächlich auf Rot und Grün anliegenden Netze. Damit ist
-- ein FDASH:-Kombinator ein passiver Messpunkt: er muss keine Signale selbst
-- erzeugen und verändert die Schaltung nicht.
local function network_signals(entity, connector_id)
  local ok, network = pcall(function()
    return entity.get_circuit_network(connector_id)
  end)
  if not ok or not network or not network.valid then return nil end

  local signals = {}
  local ok_signals, raw = pcall(function() return network.signals end)
  if ok_signals and raw then
    for _, entry in pairs(raw) do
      local signal = entry.signal
      if signal and signal.name and (entry.count or 0) ~= 0 then
        local key = signal.name
        if signal.quality and signal.quality ~= "normal" then
          key = key .. "@" .. signal.quality
        end
        signals[key] = (signals[key] or 0) + entry.count
      end
    end
  end
  return { id = network.network_id, signals = signals }
end

function job.run(st, si, budget)
  if not st.tags then
    st.ti, st.slot = 1, 1
    st.tags = {}
  end
  st.extra = 0

  local tags = st.tags
  local surface_name = (game.surfaces[si] and game.surfaces[si].name) or tostring(si)

  local spent, done = sweep.registry(st, si, TYPES, budget, function(e)
    local desc = e.combinator_description
    if not desc or string.sub(desc, 1, 6) ~= PREFIX then return end

    -- Nur die getaggten Combinators kosten wirklich etwas — der Rest ist ein
    -- Stringvergleich.
    st.extra = st.extra + 3
    local configured = {}
    local cb = e.get_control_behavior()
    if cb and cb.sections then
      for _, sec in pairs(cb.sections) do
        for _, filt in pairs(sec.filters or {}) do
          if filt and filt.value then configured[filt.value.name] = filt.min end
        end
      end
    end
    local red = network_signals(e, defines.wire_connector_id.circuit_red)
    local green = network_signals(e, defines.wire_connector_id.circuit_green)
    local signals = {}
    for name, count in pairs(configured) do signals[name] = count end
    for _, source in pairs({ red, green }) do
      for name, count in pairs((source and source.signals) or {}) do
        signals[name] = (signals[name] or 0) + count
      end
    end
    tags[#tags + 1] = {
      label = string.sub(desc, 7),
      surface = surface_name,
      position = { x = e.position.x, y = e.position.y },
      signals = signals,
      configured_signals = configured,
      networks = { red = red, green = green }
    }
  end)

  local cost = spent + st.extra
  if not done then return cost, nil end

  st.tags = nil
  return cost, { surface = surface_name, tags = tags }
end

return job
