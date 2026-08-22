local max_players = settings.startup["personal-nauvis-max-players"].value
local source = data.raw.planet and data.raw.planet.nauvis

if not source then
  error("Personal Nauvis: prototipo del pianeta Nauvis non disponibile")
end

local function personal_name(slot)
  return "personal-nauvis-" .. slot
end

for slot = 1, max_players do
  local planet = table.deepcopy(source)
  planet.name = personal_name(slot)
  planet.localised_name = {"personal-nauvis.planet-name", tostring(slot)}
  planet.order = "z[personal-nauvis]-" .. string.format("%02d", slot)
  planet.map_seed_offset = (slot * 104729 + 7919) % 4294967295

  -- Le copie sono raccolte vicino a Nauvis senza sovrapporsi tra loro.
  planet.orientation = ((source.orientation or 0) + (slot - (max_players + 1) / 2) * 0.006) % 1
  planet.label_orientation = planet.orientation
  planet.distance = (source.distance or 15000) + slot * 800
  data:extend({planet})
end

-- Space Age richiede vere connessioni spaziali affinche una piattaforma possa
-- partire da una Nauvis personale verso gli stessi pianeti raggiungibili dalla
-- Nauvis originale. Non vengono duplicati i pianeti di destinazione.
if mods["space-age"] and data.raw["space-connection"] then
  local nauvis_connections = {}
  for _, connection in pairs(data.raw["space-connection"]) do
    if connection.from == "nauvis" or connection.to == "nauvis" then
      nauvis_connections[#nauvis_connections + 1] = table.deepcopy(connection)
    end
  end

  for slot = 1, max_players do
    for _, template in ipairs(nauvis_connections) do
      local connection = table.deepcopy(template)
      connection.name = "personal-nauvis-connection-" .. slot .. "-" .. template.name
      if connection.from == "nauvis" then connection.from = personal_name(slot) end
      if connection.to == "nauvis" then connection.to = personal_name(slot) end
      connection.localised_name = {"personal-nauvis.connection-name", tostring(slot)}
      data:extend({connection})
    end
  end
end
