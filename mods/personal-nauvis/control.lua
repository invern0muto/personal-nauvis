local PLAYER_FORCE = "player"
local KIT_FRAME = "personal_nauvis_kit_frame"
local MODE_FRAME = "personal_nauvis_mode_frame"
local PVP_FORCE_PREFIX = "personal-nauvis-pvp-"
local PVP_COLORS = {
  {r = 0.90, g = 0.20, b = 0.20}, {r = 0.65, g = 0.25, b = 0.90},
  {r = 0.95, g = 0.45, b = 0.10}, {r = 0.20, g = 0.55, b = 0.95},
  {r = 0.85, g = 0.10, b = 0.55}, {r = 0.25, g = 0.80, b = 0.75}
}

local STARTER_KITS = {
  essential = {
    {"iron-plate", 800}, {"copper-plate", 400}, {"steel-plate", 200},
    {"electronic-circuit", 300}, {"transport-belt", 400}, {"inserter", 100},
    {"medium-electric-pole", 80}, {"assembling-machine-2", 20},
    {"electric-mining-drill", 20}, {"electric-furnace", 20},
    {"solar-panel", 60}, {"accumulator", 40}, {"roboport", 4},
    {"construction-robot", 25}, {"repair-pack", 100},
    {"submachine-gun", 1}, {"piercing-rounds-magazine", 100}
  },
  advanced = {
    {"iron-plate", 1600}, {"copper-plate", 800}, {"steel-plate", 300},
    {"electronic-circuit", 600}, {"advanced-circuit", 100},
    {"transport-belt", 800}, {"underground-belt", 80}, {"splitter", 40},
    {"inserter", 150}, {"fast-inserter", 50}, {"medium-electric-pole", 120},
    {"assembling-machine-2", 40}, {"electric-mining-drill", 40},
    {"steel-furnace", 40}, {"boiler", 10}, {"steam-engine", 20},
    {"offshore-pump", 2}, {"solar-panel", 60}, {"accumulator", 40},
    {"roboport", 6}, {"construction-robot", 50},
    {"rail", 500}, {"locomotive", 1}, {"cargo-wagon", 4},
    {"repair-pack", 150}, {"submachine-gun", 1},
    {"piercing-rounds-magazine", 200}
  }
}

local function max_players()
  return settings.startup["personal-nauvis-max-players"].value
end

local function surface_name(slot)
  return "personal-nauvis-" .. slot
end

local function ensure_storage()
  storage.personal_nauvis = storage.personal_nauvis or {
    players = {},
    slots = {},
    pending_arrival = {},
    surface_owners = {},
    pvp_ceasefires = {},
    first_player_personal = false
  }
  storage.personal_nauvis.surface_owners = storage.personal_nauvis.surface_owners or {}
  storage.personal_nauvis.pvp_ceasefires = storage.personal_nauvis.pvp_ceasefires or {}
  storage.personal_nauvis.observers = storage.personal_nauvis.observers or {}
  return storage.personal_nauvis
end

local function get_surface(slot)
  local name = surface_name(slot)
  local planet = game.planets and game.planets[name]
  if planet and planet.valid then
    if planet.surface then return planet.surface end
    local ok, created = pcall(function() return planet.create_surface() end)
    if ok then return created end
  end
  return game.surfaces[name]
end

local function player_record(player_index)
  return ensure_storage().players[player_index]
end

local function set_surface_protection(record, protected)
  local surface = record and game.surfaces[record.surface]
  if not surface then return end

  if record.original_peaceful_mode == nil then
    record.original_peaceful_mode = surface.peaceful_mode
  end
  surface.peaceful_mode = protected or record.original_peaceful_mode
  record.protected = protected
end

local function reentry_protection_ticks()
  return settings.global["personal-nauvis-reentry-protection-minutes"].value * 60 * 60
end

local function refresh_surface_protection(record)
  local protected = not record.online
    or (record.reentry_protection_until and game.tick < record.reentry_protection_until)
  set_surface_protection(record, protected)
end

local function rebuild_surface_owners()
  local state = ensure_storage()
  state.surface_owners = {}
  for player_index, record in pairs(state.players) do
    if record.original_owner then
      record.mode = "coop"
      record.force_name = PLAYER_FORCE
      record.starter_claimed = true
    else
      record.force_name = record.force_name or PLAYER_FORCE
    end
    local player = game.get_player(player_index)
    record.online = player and player.connected or false
    state.surface_owners[record.surface] = player_index
  refresh_surface_protection(record)
  end
end

local function first_free_slot()
  local state = ensure_storage()
  for slot = 1, max_players() do
    if not state.slots[slot] then return slot end
  end
end

local function prepare_surface(slot, player_name)
  local surface = get_surface(slot)
  if not surface then return nil, nil end

  surface.request_to_generate_chunks({0, 0}, 4)
  surface.force_generate_chunk_requests()
  local spawn = surface.find_non_colliding_position("character", {0, 0}, 32, 0.5) or {0, 0}
  pcall(function()
    surface.localised_name = {"personal-nauvis.surface-name", player_name}
  end)
  return surface, spawn
end

local function assign_owner(player)
  local state = ensure_storage()
  local nauvis = game.surfaces.nauvis
  if not nauvis then return nil end

  local spawn = game.forces[PLAYER_FORCE].get_spawn_position(nauvis)
  local record = {
    slot = 0,
    surface = nauvis.name,
    spawn = spawn,
    player_name = player.name,
    original_owner = true,
    mode = "coop",
    force_name = PLAYER_FORCE,
    starter_claimed = true,
    online = player.connected
  }
  state.owner_index = player.index
  state.players[player.index] = record
  state.surface_owners[nauvis.name] = player.index
    refresh_surface_protection(record)
  return record
end

local function ensure_original_owner()
  local state = ensure_storage()
  if state.first_player_personal then return end
  if state.owner_index and state.players[state.owner_index] then return end

  local first_player
  for _, candidate in pairs(game.players) do
    if not first_player or candidate.index < first_player.index then
      first_player = candidate
    end
  end
  if first_player then assign_owner(first_player) end
end

local function unlock_personal_planets(force)
  force = force or game.forces[PLAYER_FORCE]
  if not force then return end
  for slot = 1, max_players() do
    local name = surface_name(slot)
    if game.planets and game.planets[name] then
      pcall(function() force.unlock_space_location(name) end)
    end
  end
end

local function assign_player(player)
  local state = ensure_storage()
  local existing = state.players[player.index]
  if existing then return existing end

  -- In una partita nuova il primo giocatore diventa proprietario della Nauvis
  -- originale. In una partita esistente viene registrato durante on_init.
  if not state.owner_index and not state.first_player_personal then return assign_owner(player) end

  local slot = first_free_slot()
  if not slot then
    player.print({"personal-nauvis.no-free-slot", tostring(max_players())})
    return nil
  end

  local surface, spawn = prepare_surface(slot, player.name)
  if not surface then
    player.print({"personal-nauvis.creation-failed", tostring(slot)})
    return nil
  end

  local record = {
    slot = slot,
    surface = surface.name,
    spawn = spawn,
    player_name = player.name,
    online = player.connected,
    mode = nil,
    force_name = PLAYER_FORCE,
    starter_claimed = false
  }
  state.players[player.index] = record
  state.slots[slot] = player.index
  state.surface_owners[surface.name] = player.index
  state.pending_arrival[player.index] = true
  player.force = game.forces[PLAYER_FORCE]
  unlock_personal_planets(player.force)
  player.print({"personal-nauvis.assigned", tostring(slot)})
  return record
end

local function teleport_home(player)
  local record = player_record(player.index) or assign_player(player)
  if not record then return false end

  local surface = game.surfaces[record.surface]
  if not surface and record.slot > 0 then surface = get_surface(record.slot) end
  if not surface then
    player.print({"personal-nauvis.home-missing"})
    return false
  end

  local position = surface.find_non_colliding_position("character", record.spawn, 32, 0.5)
    or record.spawn
  return player.teleport(position, surface)
end

local function find_player(value)
  if not value or value == "" then return nil end
  local exact = game.get_player(value)
  if exact then return exact end
  local needle = string.lower(value)
  for _, candidate in pairs(game.players) do
    if string.find(string.lower(candidate.name), needle, 1, true) then return candidate end
  end
end

local function require_admin(command)
  local player = game.get_player(command.player_index)
  if not player then return nil end
  if not player.admin then
    player.print({"personal-nauvis.admin-only"})
    return nil
  end
  return player
end

local function stop_observing(player, silent)
  local state = ensure_storage()
  local session = state.observers[player.index]
  if not session then return false end

  local original_force = game.forces[session.force_name]
  if original_force then player.force = original_force end
  local character = session.character
  if character and character.valid then
    player.set_controller{type = defines.controllers.character, character = character}
  elseif player.controller_type ~= defines.controllers.character then
    player.create_character()
  end
  local surface = game.surfaces[session.surface]
  if surface then player.teleport(session.position, surface) end
  state.observers[player.index] = nil
  if not silent then player.print({"personal-nauvis.observe-ended"}) end
  return true
end

local function start_spectating(admin, surface, position, target_index, message)
  stop_observing(admin, true)
  if admin.controller_type ~= defines.controllers.character or not admin.character then
    return false, "controller"
  end
  local state = ensure_storage()
  state.observers[admin.index] = {
    surface = admin.surface.name,
    position = {x = admin.position.x, y = admin.position.y},
    force_name = admin.force.name,
    character = admin.character,
    target_index = target_index
  }
  admin.set_controller{type = defines.controllers.spectator}
  if admin.teleport(position, surface) == false then
    stop_observing(admin, true)
    return false, "surface"
  end
  admin.print(message)
  return true
end

local function start_observing(admin, target)
  if not target.connected then return false, "offline" end
  if admin.index == target.index then return false, "self" end
  return start_spectating(admin, target.surface, target.position, target.index,
    {"personal-nauvis.observe-started", target.name})
end

local function start_inspecting(admin, target)
  local record = target and player_record(target.index)
  if not record then return false, "missing" end
  if record.original_owner or record.slot == 0 then return false, "original" end
  local surface = game.surfaces[record.surface]
  if not surface then return false, "surface" end
  local position = target.connected and target.surface.name == record.surface
    and target.position or record.spawn
  return start_spectating(admin, surface, position, target.index,
    {"personal-nauvis.inspect-started", target.name})
end

local function delete_personal_world(target)
  local state = ensure_storage()
  local record = target and state.players[target.index]
  if not record then return false, "missing" end
  if record.original_owner or record.slot == 0 then return false, "original" end
  if target.connected or record.online then return false, "online" end

  local surface = game.surfaces[record.surface]
  local nauvis = game.surfaces.nauvis
  local player_force = game.forces[PLAYER_FORCE]
  if not nauvis or not player_force then return false, "destination" end

  -- Sposta prima il personaggio offline in un luogo sicuro: il giocatore
  -- conserva inventario e identita, ma al prossimo accesso ricevera un nuovo
  -- mondo libero. Nessuna superficie viene eliminata con un giocatore sopra.
  target.force = player_force
  local spawn = player_force.get_spawn_position(nauvis)
  local safe = nauvis.find_non_colliding_position("character", spawn, 32, 0.5) or spawn
  local move_ok, moved = pcall(function() return target.teleport(safe, nauvis) end)
  if not move_ok or moved == false then return false, "teleport" end

  if surface and surface.valid then
    local ok, deleted = pcall(function() return game.delete_surface(surface) end)
    if not ok or deleted == false then return false, "surface" end
  end

  state.players[target.index] = nil
  state.slots[record.slot] = nil
  state.surface_owners[record.surface] = nil
  state.pending_arrival[target.index] = nil
  for key, ceasefire in pairs(state.pvp_ceasefires) do
    if ceasefire.first == record.force_name or ceasefire.second == record.force_name then
      state.pvp_ceasefires[key] = nil
    end
  end
  return true, record.slot
end

local function pvp_grace_ticks()
  return settings.global["personal-nauvis-pvp-grace-minutes"].value * 60 * 60
end

local function set_force_relationship(first, second, grace)
  if not first or not second or first.name == second.name then return end
  first.set_friend(second, false)
  second.set_friend(first, false)
  first.set_cease_fire(second, grace)
  second.set_cease_fire(first, grace)
end

local function ceasefire_key(first, second)
  if first.name < second.name then return first.name .. "|" .. second.name end
  return second.name .. "|" .. first.name
end

local function add_pvp_ceasefire(first, second, until_tick)
  local state = ensure_storage()
  local key = ceasefire_key(first, second)
  local existing = state.pvp_ceasefires[key]
  if not existing or existing.until_tick < until_tick then
    state.pvp_ceasefires[key] = {
      first = first.name,
      second = second.name,
      until_tick = until_tick
    }
  end
  set_force_relationship(first, second, true)
end

local function choose_coop(player, record)
  player.force = game.forces[PLAYER_FORCE]
  record.mode = "coop"
  record.force_name = PLAYER_FORCE
  record.pvp_grace_until = nil
end

local function choose_pvp(player, record)
  local force_name = PVP_FORCE_PREFIX .. player.index
  local force = game.forces[force_name]
  if not force then
    force = game.create_force(force_name)
    force.copy_from(game.forces[PLAYER_FORCE])
  else
    -- Returning from Co-op must not lose technologies completed by the shared
    -- force while this personal PvP force was dormant.
    for technology_name, technology in pairs(game.forces[PLAYER_FORCE].technologies) do
      if technology.researched and force.technologies[technology_name] then
        force.technologies[technology_name].researched = true
      end
    end
  end

  record.mode = "pvp"
  record.force_name = force.name
  player.force = force
  force.set_spawn_position(record.spawn, game.surfaces[record.surface])
  unlock_personal_planets(force)

  local color = PVP_COLORS[((record.slot - 1) % #PVP_COLORS) + 1]
  player.color = color
  player.chat_color = color

  local grace_ticks = pvp_grace_ticks()
  for _, other_record in pairs(ensure_storage().players) do
    if other_record.force_name and other_record.force_name ~= force.name then
      local other_force = game.forces[other_record.force_name]
      if grace_ticks > 0 then
        add_pvp_ceasefire(force, other_force, game.tick + grace_ticks)
      else
        set_force_relationship(force, other_force, false)
      end
    end
  end
  record.pvp_grace_until = grace_ticks > 0 and game.tick + grace_ticks or nil
end

local function transfer_personal_world_force(record, old_force, new_force)
  local surface = record and game.surfaces[record.surface]
  if not surface or not old_force or not new_force or old_force == new_force then return 0 end
  local transferred = 0
  for _, entity in pairs(surface.find_entities_filtered{force = old_force}) do
    if entity.valid and entity.type ~= "character" then
      local ok = pcall(function() entity.force = new_force end)
      if ok then transferred = transferred + 1 end
    end
  end
  return transferred
end

local function set_player_mode(target, mode)
  local record = target and player_record(target.index)
  if not record then return false, "missing" end
  if record.original_owner or record.slot == 0 then return false, "original" end
  if mode ~= "coop" and mode ~= "pvp" then return false, "mode" end
  if record.mode == mode then return false, "unchanged" end

  local old_force = game.forces[record.force_name] or target.force
  if mode == "coop" then choose_coop(target, record) else choose_pvp(target, record) end
  local new_force = game.forces[record.force_name]
  local transferred = transfer_personal_world_force(record, old_force, new_force)
  return true, transferred
end

local function close_mode_choice(player)
  local frame = player.gui.screen[MODE_FRAME]
  if frame then frame.destroy() end
end

local function show_mode_choice(player)
  local record = player_record(player.index)
  if not record or record.original_owner or record.mode then return end
  if player.gui.screen[MODE_FRAME] then return end

  local frame = player.gui.screen.add{
    type = "frame",
    name = MODE_FRAME,
    direction = "vertical",
    caption = {"personal-nauvis.welcome-title"}
  }
  frame.auto_center = true
  frame.add{type = "label", caption = {"personal-nauvis.welcome-intro"}}
  frame.add{type = "label", caption = {"personal-nauvis.welcome-world"}}
  frame.add{type = "label", caption = {"personal-nauvis.welcome-protection"}}
  frame.add{type = "label", caption = {"personal-nauvis.welcome-spidertron"}}

  local buttons = frame.add{type = "flow", direction = "horizontal"}
  for _, mode in ipairs({"coop", "pvp"}) do
    local button = buttons.add{
      type = "button",
      caption = {"personal-nauvis.mode-" .. mode},
      tooltip = {"personal-nauvis.mode-" .. mode .. "-description"}
    }
    button.tags = {personal_nauvis_mode = mode}
  end
  frame.add{type = "label", caption = {"personal-nauvis.mode-permanent-warning"}}
end

local function close_kit_choice(player)
  local frame = player.gui.screen[KIT_FRAME]
  if frame then frame.destroy() end
end

local function show_kit_choice(player)
  local record = player_record(player.index)
  if not record or record.original_owner or not record.mode or record.starter_claimed then return end
  if player.gui.screen[KIT_FRAME] then return end

  local frame = player.gui.screen.add{
    type = "frame",
    name = KIT_FRAME,
    direction = "vertical",
    caption = {"personal-nauvis.kit-title"}
  }
  frame.auto_center = true
  frame.add{type = "label", caption = {"personal-nauvis.kit-intro"}}
  local buttons = frame.add{type = "flow", direction = "vertical"}
  for _, kit in ipairs({"advanced", "essential", "none"}) do
    local button = buttons.add{
      type = "button",
      caption = {"personal-nauvis.kit-" .. kit},
      tooltip = {"personal-nauvis.kit-" .. kit .. "-description"}
    }
    button.tags = {personal_nauvis_kit = kit}
    button.style.horizontally_stretchable = true
  end
end

local function show_onboarding(player)
  local record = player_record(player.index)
  if not record or record.original_owner then return end
  if not record.mode then show_mode_choice(player) else show_kit_choice(player) end
end

local function place_starter_spidertron(player, kit_name)
  local record = player_record(player.index)
  local items = STARTER_KITS[kit_name] or {}
  if not record or not prototypes.entity.spidertron then return false end
  local surface = game.surfaces[record.surface]
  if not surface then return false end

  local position = surface.find_non_colliding_position("spidertron", record.spawn, 32, 1)
  local spider = position and surface.create_entity{
    name = "spidertron",
    position = position,
    force = player.force,
    raise_built = true
  }
  if not spider then return false end

  local trunk = spider.get_inventory(defines.inventory.spider_trunk)
  local ammo = spider.get_inventory(defines.inventory.spider_ammo)
  if not trunk or not ammo then
    spider.destroy{raise_destroy = true}
    return false
  end

  for _, entry in ipairs(items) do
    if prototypes.item[entry[1]] then
      local inserted = trunk.insert{name = entry[1], count = entry[2]}
      if inserted < entry[2] then
        spider.destroy{raise_destroy = true}
        return false
      end
    end
  end

  if not prototypes.item.rocket or ammo.insert{name = "rocket", count = 100} < 100 then
    spider.destroy{raise_destroy = true}
    return false
  end
  pcall(function() spider.backer_name = player.name .. "'s Starter Spidertron" end)
  record.starter_spidertron = spider.unit_number
  return true
end

script.on_init(function()
  local state = ensure_storage()
  -- Existing saves already contain at least one player when the mod is first
  -- installed and therefore preserve the original Nauvis owner. A genuinely
  -- empty dedicated save has no host/base to preserve, so its first arrival
  -- receives a personal planet and the complete onboarding flow.
  state.first_player_personal = #game.players == 0
  ensure_original_owner()
  rebuild_surface_owners()
  unlock_personal_planets()
end)

script.on_configuration_changed(function()
  ensure_storage()
  ensure_original_owner()
  rebuild_surface_owners()
  unlock_personal_planets()
end)

script.on_event(defines.events.on_player_created, function(event)
  assign_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local record = player_record(player.index) or assign_player(player)
  if record then
    if record.mode and game.forces[record.force_name] then
      player.force = game.forces[record.force_name]
    end
    local was_protected = record.protected or not record.online
    record.online = true
    local grace_ticks = reentry_protection_ticks()
    record.reentry_protection_until = was_protected and grace_ticks > 0
      and game.tick + grace_ticks or nil
    refresh_surface_protection(record)
    if record.reentry_protection_until then
      player.print({"personal-nauvis.reentry-protection", tostring(grace_ticks / 3600)})
    end
    if player.surface.name == record.surface then show_onboarding(player) end
  end
end)

script.on_event(defines.events.on_player_left_game, function(event)
  local player = game.get_player(event.player_index)
  if player then stop_observing(player, true) end
  local record = player_record(event.player_index)
  if record then
    record.online = false
    record.reentry_protection_until = nil
    refresh_surface_protection(record)
  end
end)

-- Su una superficie protetta ripristina esattamente la salute precedente al
-- colpo. L'evento avviene dopo l'applicazione del danno ma prima della morte
-- definitiva dell'entità, compresi i colpi potenzialmente letali.
script.on_event(defines.events.on_entity_damaged, function(event)
  local entity = event.entity
  if not (entity and entity.valid and entity.health) then return end
  if entity.type == "character" then return end

  local state = ensure_storage()
  local owner_index = state.surface_owners[entity.surface.name]
  local record = owner_index and state.players[owner_index]
  if not (record and record.protected) then return end
  if entity.force.name ~= record.force_name then return end

  local restored = event.final_health + event.final_damage_amount
  local maximum = entity.prototype.max_health
  if maximum then restored = math.min(restored, maximum) end
  entity.health = math.max(restored, 1)
end)

-- Lo spawn della forza non viene mai modificato. Factorio completa il respawn
-- normalmente e subito dopo riportiamo il giocatore sulla sua superficie.
script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)
  if player then teleport_home(player) end
end)

-- A Personal Nauvis arrival starts on the personal planet, not beside the
-- vanilla crash site. Pending guests leave the intro cutscene immediately;
-- the short retry loop only waits until Factorio has created their character.
script.on_nth_tick(10, function()
  local state = ensure_storage()

  -- Riallinea anche dopo un arresto improvviso del server, durante il quale
  -- l'evento di disconnessione potrebbe non essere stato salvato.
  for player_index, record in pairs(state.players) do
    local player = game.get_player(player_index)
    local online = player and player.connected or false
    if record.online ~= online then
      record.online = online
      if not online then record.reentry_protection_until = nil end
      refresh_surface_protection(record)
    end
    if record.reentry_protection_until and game.tick >= record.reentry_protection_until then
      record.reentry_protection_until = nil
      refresh_surface_protection(record)
      if player and player.connected then
        player.print({"personal-nauvis.reentry-protection-ended"})
      end
    end
    if record.pvp_grace_until and game.tick >= record.pvp_grace_until then
      record.pvp_grace_until = nil
      if player and player.connected then
        player.print({"personal-nauvis.pvp-grace-ended"})
      end
    end
  end

  for key, ceasefire in pairs(state.pvp_ceasefires) do
    if game.tick >= ceasefire.until_tick then
      local first = game.forces[ceasefire.first]
      local second = game.forces[ceasefire.second]
      if first and second then set_force_relationship(first, second, false) end
      state.pvp_ceasefires[key] = nil
    end
  end

  for player_index in pairs(state.pending_arrival) do
    local player = game.get_player(player_index)
    if player and player.valid and player.connected
      and player.controller_type == defines.controllers.cutscene then
      pcall(function() player.exit_cutscene() end)
    end
    if player and player.valid and player.connected
      and player.controller_type == defines.controllers.character then
      state.pending_arrival[player_index] = nil
      teleport_home(player)
      show_onboarding(player)
    end
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid and element.tags) then return end
  local player = game.get_player(event.player_index)
  local record = player and player_record(player.index)
  if not player or not record then return end

  local mode_name = element.tags.personal_nauvis_mode
  if mode_name and not record.mode then
    if mode_name == "coop" then
      choose_coop(player, record)
    elseif mode_name == "pvp" then
      choose_pvp(player, record)
    else
      return
    end
    close_mode_choice(player)
    player.print({"personal-nauvis.mode-selected-" .. mode_name})
    show_kit_choice(player)
    return
  end

  local kit_name = element.tags.personal_nauvis_kit
  if not kit_name or record.starter_claimed then return end

  if place_starter_spidertron(player, kit_name) then
    record.starter_claimed = true
    record.starter_kit = kit_name
    close_kit_choice(player)
    player.print({"personal-nauvis.kit-created"})
  else
    player.print({"personal-nauvis.kit-failed"})
  end
end)

commands.add_command("pn-home", {"personal-nauvis.command-home-help"}, function(command)
  local player = game.get_player(command.player_index)
  if player and not stop_observing(player, false) then teleport_home(player) end
end)

commands.add_command("pn-observe", {"personal-nauvis.command-observe-help"}, function(command)
  local admin = require_admin(command)
  if not admin then return end
  local target = find_player(command.parameter)
  if not target then admin.print({"personal-nauvis.player-not-found"}); return end
  local ok, reason = start_observing(admin, target)
  if not ok then admin.print({"personal-nauvis.observe-failed-" .. reason, target.name}) end
end)

commands.add_command("pn-observe-exit", {"personal-nauvis.command-observe-exit-help"}, function(command)
  local admin = require_admin(command)
  if admin and not stop_observing(admin, false) then admin.print({"personal-nauvis.observe-not-active"}) end
end)

commands.add_command("pn-inspect", {"personal-nauvis.command-inspect-help"}, function(command)
  local admin = require_admin(command)
  if not admin then return end
  local target = find_player(command.parameter)
  if not target then admin.print({"personal-nauvis.player-not-found"}); return end
  local ok, reason = start_inspecting(admin, target)
  if not ok then admin.print({"personal-nauvis.inspect-failed-" .. reason, target.name}) end
end)

commands.add_command("pn-set-mode", {"personal-nauvis.command-set-mode-help"}, function(command)
  local admin = command.player_index and require_admin(command) or nil
  if command.player_index and not admin then return end
  local target_name, mode = string.match(command.parameter or "", "^%s*(.-)%s+([%a]+)%s*$")
  mode = mode and string.lower(mode) or nil
  if not target_name or target_name == "" or (mode ~= "coop" and mode ~= "pvp") then
    if admin then admin.print({"personal-nauvis.set-mode-usage"}) else log("[Personal Nauvis] usage: /pn-set-mode <player> <coop|pvp>") end
    return
  end
  local target = find_player(target_name)
  if not target then
    if admin then admin.print({"personal-nauvis.player-not-found"}) else log("[Personal Nauvis] player not found") end
    return
  end
  local ok, result = set_player_mode(target, mode)
  if not ok then
    if admin then
      admin.print({"personal-nauvis.set-mode-failed-" .. result, target.name, {"personal-nauvis.mode-" .. mode}})
    else
      log("[Personal Nauvis] mode change failed for " .. target.name .. ": " .. tostring(result))
    end
    return
  end
  if admin then
    admin.print({"personal-nauvis.set-mode-complete", target.name,
      {"personal-nauvis.mode-" .. mode}, tostring(result)})
  else
    log("[Personal Nauvis] changed " .. target.name .. " to " .. mode
      .. "; transferred entities: " .. tostring(result))
  end
  if target.connected then
    target.print({"personal-nauvis.set-mode-player", {"personal-nauvis.mode-" .. mode}})
  end
end)

commands.add_command("pn-visit", {"personal-nauvis.command-visit-help"}, function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  local target = find_player(command.parameter)
  local record = target and player_record(target.index)
  if not record then
    player.print({"personal-nauvis.player-not-found"})
    return
  end
  if player.force.name ~= record.force_name then
    player.print({"personal-nauvis.enemy-visit-blocked"})
    return
  end
  local surface = game.surfaces[record.surface]
  if not surface then
    player.print({"personal-nauvis.home-missing"})
    return
  end
  local position = surface.find_non_colliding_position("character", record.spawn, 32, 0.5)
    or record.spawn
  player.teleport(position, surface)
  player.print({"personal-nauvis.visiting", target.name})
end)

commands.add_command("pn-list", {"personal-nauvis.command-list-help"}, function(command)
  local player = game.get_player(command.player_index)
  if not player then return end
  player.print({"personal-nauvis.list-title"})
  local state = ensure_storage()
  local owner = state.owner_index and game.get_player(state.owner_index)
  if owner then
    local owner_record = state.players[owner.index]
    local status = owner_record.online and {"personal-nauvis.online"}
      or {"personal-nauvis.offline-protected"}
    player.print({"personal-nauvis.list-owner", owner.name, status, {"personal-nauvis.mode-coop"}})
  end
  for slot = 1, max_players() do
    local owner_index = state.slots[slot]
    local owner = owner_index and game.get_player(owner_index)
    local record = owner_index and state.players[owner_index]
    local status = record and record.online and {"personal-nauvis.online"}
      or {"personal-nauvis.offline-protected"}
    local mode = record and record.mode and {"personal-nauvis.mode-" .. record.mode}
      or {"personal-nauvis.mode-not-selected"}
    player.print(owner and {"personal-nauvis.list-row", tostring(slot), owner.name, status, mode}
      or {"personal-nauvis.list-empty", tostring(slot)})
  end
end)

commands.add_command("pn-send-home", {"personal-nauvis.command-send-home-help"}, function(command)
  local admin = require_admin(command)
  if not admin then return end
  local target = find_player(command.parameter)
  if not target then
    admin.print({"personal-nauvis.player-not-found"})
    return
  end
  if teleport_home(target) then
    admin.print({"personal-nauvis.sent-home", target.name})
  end
end)

commands.add_command("pn-delete-world", {"personal-nauvis.command-delete-world-help"}, function(command)
  local admin = command.player_index and require_admin(command) or nil
  if command.player_index and not admin then return end
  local target = find_player(command.parameter)
  if not target then
    if admin then admin.print({"personal-nauvis.player-not-found"}) else log("[Personal Nauvis] player not found") end
    return
  end
  local ok, result = delete_personal_world(target)
  local message = ok and {"personal-nauvis.world-deleted", target.name, tostring(result)}
    or {"personal-nauvis.world-delete-failed-" .. result, target.name}
  if admin then admin.print(message) else game.print(message) end
end)

-- Interfaccia di sola lettura per fdash-exporter e altri pannelli.
remote.add_interface("personal_nauvis", {
  informatron_menu = function()
    return {
      personal_nauvis_modes = 1,
      personal_nauvis_worlds = 1,
      personal_nauvis_starter = 1,
      personal_nauvis_commands = 1,
      personal_nauvis_server = 1
    }
  end,
  informatron_page_content = function(data)
    local texts = {
      personal_nauvis = "page_personal_nauvis_text",
      personal_nauvis_modes = "page_personal_nauvis_modes_text",
      personal_nauvis_worlds = "page_personal_nauvis_worlds_text",
      personal_nauvis_starter = "page_personal_nauvis_starter_text",
      personal_nauvis_commands = "page_personal_nauvis_commands_text",
      personal_nauvis_server = "page_personal_nauvis_server_text"
    }
    local key = texts[data.page_name]
    if not key or not data.element or not data.element.valid then return end
    local label = data.element.add{
      type = "label",
      caption = {"personal_nauvis." .. key}
    }
    label.style.single_line = false
    label.style.maximal_width = 850
  end,
  delete_world = function(player_name)
    local target = find_player(player_name)
    if not target then return {ok = false, reason = "missing"} end
    local ok, result = delete_personal_world(target)
    return ok and {ok = true, player_name = target.name, freed_slot = result}
      or {ok = false, player_name = target.name, reason = result}
  end,
  get_status = function()
    local result = {}
    local state = ensure_storage()
    for player_index, record in pairs(state.players) do
      result[#result + 1] = {
        player_index = player_index,
        player_name = record.player_name,
        slot = record.slot,
        surface = record.surface,
        original_owner = record.original_owner or false,
        online = record.online or false,
        protected = record.protected or false,
        mode = record.mode,
        force_name = record.force_name,
        pvp_grace_until = record.pvp_grace_until,
        reentry_protection_until = record.reentry_protection_until
      }
    end
    return result
  end
})
