# ![Alecs Logo](./icon.png) ALECS
[![Build Status](https://travis-ci.org/pcornier/Alecs.svg?branch=master)](https://travis-ci.org/pcornier/Alecs)


**A**nother **L**ÖVE **ECS**. It provides a clear separation between logic and data, it reduces code complexity, it breaks dependencies between game objects, allows the serialization of the whole game state and makes dynamic composition possible. It was initially made for LÖVE but as there are no dependencies, you can use it in all your Lua projects.

## Usage with Löve

```lua
Alecs = require 'Alecs'

function love.load()
  alecs = Alecs()
  -- add entities & systems here
end

function love.update(dt)
  alecs:update(dt)
end
```

## Function Reference

### Alecs()
Return a *new* Alecs instance.
```lua
local alecs = Alecs()
```

### alecs:addSystem(system [, group])
Add a system to the world. A system is a Lua table with an optional `filter` key.
```lua
local spriteSystem = { filter = { 'sprite', 'pos' } }
alecs:addSystem(playerSystem, 'logic')
alecs:addSystem(collisionSystem, 'logic')
alecs:addSystem(spriteSystem, 'rendering')
```

### alecs:status(group, status)
Enable/disable a group of systems.
```lua
alecs:status('logic', false)
```

### alecs:addEntity(entity)
Add a new entity to the world. An ID will be automatically generated if no one is provided.
```lua
alecs:addEntity({
  id = "mydog",
  pos = { x = 10, y = 20 }
})
```

### alecs:removeEntity(entity)
Remove the provided entity from the world.
```lua
destroyBulletSystem = { filter = { 'bullet', 'pos' } }
function destroyBulletSystem:process(e, dt)
  if e.pos.x > 640 then self.alecs:removeEntity(e) end
end
```

### alecs:get(id)
Return the corresponding entity.
```lua
local dog = alecs:get('dog')
```

### alecs:filter({key1,key2,...})
Return a list of compatible entities.
```lua
local balls = alecs:filter({ 'pos', 'color' })
```

### alecs:find(key, value)
Return entities that meet the condition key == value.
```lua
local redBalls = alecs:find('color', 'red')
```

### alecs:pick({key1,key2,...})
Return the first compatible entity.
```lua
local player = alecs:pick({ 'controller' })
```

### alecs:getEntities()
Return all world entities.
```lua
local entities = alecs:getEntities()
```

### alecs:getSystems()
Return all world systems.
```lua
local systems = alecs:getSystems()
```

### alecs:register(event, callback)
ALECS provides a mini event/messaging system. This function registers a callback to a custom event.
```lua
alecs:register('newBullet', function(x, y, vx, vy)
  alecs:addEntity({
    pos = { x = x, y = y },
    vx = vx,
    vy = vy
  })
end)
```

### alecs:emit(event, ...)
Generate a new event.
```lua
alecs:emit('newBullet', 10, 10, 1, 2)
```

## Events

### system:added()
Called when the system is added to the world.
```lua
function playerSystem:added()
  -- a good place for the system to initialize
end
```

### system:newEntity(entity)
Called when a new compatible entity is added to the world.
```lua
ballSystem = { filter = { 'ball', 'pos', 'size' } }
function ballSystem:newEntity(ball)
  -- initialize some ball props here
  ball.size = math.random(15)
end
```

### system:update(...)
The frame event, which is triggered by alecs:update(...). A good practice is to send the deltatime to systems.
```lua
function ballSystem:update(dt)
  -- reorder balls for rendering based on vertical positions
  table.sort(self.entities, function(a, b)
    return a.pos.y < b.pos.y
  end)
end
```

### system:process(entity, ...)
This event is called for each compatible entity in the system.
```lua
function ballSystem:process(ball, dt)
  ball.pos.x = ball.pos.x + ball.norm.x * ball.speed
  ball.pos.y = ball.pos.y + ball.norm.y * ball.speed
end
```

## Shortcuts

The Alecs instance and the list of compatible entities are available from any systems using `self.alecs` and `self.entities` respectively.
```lua
function ballSystem:update()
  for _,e in pairs(self.entities) do
    if e.pos.x > 100 then self.alecs:removeEntity(e) end
  end
end
```

## Best practices

- Dedicate each system to only one simple task.
- Avoid communication between systems. If it seems inevitable then rethink your design.
- Avoid the creation of new entities within systems, a possible workaround is to emit an event that is captured by a centralized factory mechanism.
- Prefix all component names to avoid conflicts between systems.
- Group your systems and keep rendering, logic and inputs decoupled to increase portability.
- An entity is not always visible, it can be used as a virtual container.
- Avoid game specific systems, try to only create reusable systems.
- Use a state manager like the one provided below and encapsulate Alecs in a state.
- Have fun!


---

```lua
-- A state manager.

local State = {
  stack = {},
  index = 1
}

function State:switch(state)
  self.stack[self.index] = state
  if state.enter then state:enter()
end

function State:push(state)
  self.index = self.index + 1
  self.stack[self.index] = state
  if state.enter then state:enter()
end

function State:pop()
  local state = self.stack[self.index]
  self.stack[self.index] = nil
  self.index = self.index - 1
  if state.exit then state:exit()
end

function State:update(...)
  self.stack[self.index]:update(...)
end

return State
```
