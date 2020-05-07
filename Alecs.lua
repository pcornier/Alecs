
local Alecs = function()

  local systems = {}
  local entities = {}
  local alecs = {}
  local reg = {}
  local stack = {}
  local statuses = {}
  local index = 1

  local function match(filter, entity)
    for _, component in pairs(filter) do
      if entity[component] == nil then return false end
    end
    return true
  end

  function alecs:addEntity(entity)
    local id = entity.id or #entities+1
    entity.id = id
    entities[id] = entity
    for _, s in pairs(systems) do
      local system = s.system
      if match(system.filter, entity) and system.newEntity then
        system:newEntity(entity)
      end
    end
    return id
  end

  function alecs:addSystem(system, group)
    system.filter = system.filter or {}
    systems[#systems+1] = {
      update = function(entities, ...)
        system.entities = {}
        for _, entity in pairs(entities) do
          if match(system.filter, entity) then
            system.entities[#system.entities+1] = entity
          end
        end
        if system.update then system:update(...) end
        if system.process then
          for _, entity in pairs(system.entities) do
            system:process(entity, ...)
          end
        end
      end,
      system = system,
      enabled = true,
      group = group or ''
    }
    system.alecs = alecs
    if system.added then system:added() end
  end

  function alecs:filter(filter)
    matches = {}
    for _, entity in pairs(entities) do
      if match(filter, entity) then
        matches[#matches+1] = entity
      end
    end
    return matches
  end

  function alecs:find(prop, value)
    matches = {}
    for _, entity in pairs(entities) do
      if entity[prop] and entity[prop] == value then
        matches[#matches+1] = entity
      end
    end
    return matches
  end

  function alecs:pick(filter)
    for _, entity in pairs(entities) do
      if match(filter, entity) then
        return entity
      end
    end
  end

  function alecs:update(...)
    for _, system in pairs(systems) do
      if system.enabled then
        system.update(entities, ...)
      end
    end
  end

  function alecs:removeEntity(entity)
    entities[entity.id] = nil
  end

  function alecs:getEntities()
    return entities
  end

  function alecs:getSystems()
    return systems
  end

  function alecs:status(group, status)
    if statuses[group] == nil or statuses[group] ~= status then
      for _, system in pairs(systems) do
        if system.group == group then
          system.enabled = status
        end
      end
      statuses[group] = status
    end
  end

  function alecs:get(id)
    return entities[id]
  end

  function alecs:emit(event, ...)
    local res = {}
    if reg[event] then
      for _, cb in pairs(reg[event]) do
        local r = cb(...)
        if r ~= nil then table.insert(res, r) end
      end
    end
    return res
  end

  function alecs:register(event, cb)
    reg[event] = reg[event] or {}
    table.insert(reg[event], cb)
  end

  return alecs
end

return Alecs
