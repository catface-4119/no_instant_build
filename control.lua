-- Initialize the list of entities to ignore
local ignoredEntities = {
  "unit",
  "unit-spawner",
  "explosion",
  "tree",
  "combat-robot",
  "construction-robot",
  "logistic-robot",
  "container",
  "logistic-container",
  "electric-energy-interface",
  "entity-ghost",
  "",
}

-- Add the entity to the list of entities being built
script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity

    -- Ignore entities that are not valid
    if not entity.valid then return end

    -- Start the build process of this entity.
    StartBuilding(entity)
end)

-- Remove the entity from the list of entities being built
script.on_event(defines.events.on_player_mined_entity, function(event)
    RemoveEntityFromBuildList(event.entity)
end)

script.on_event(defines.events.on_entity_died, function(event)
    RemoveEntityFromBuildList(event.entity)
end)

script.on_nth_tick(5, function ()
    local globalAllEntitiesBeingBuilt = global.allEntitiesBeingBuilt

    -- If global.allEntitiesBeingBuilt is nil, initialize it
    if not globalAllEntitiesBeingBuilt then
        global.allEntitiesBeingBuilt = {}
        globalAllEntitiesBeingBuilt = global.allEntitiesBeingBuilt
    end

    -- Check if the list of entities being built is empty
    if #globalAllEntitiesBeingBuilt == 0 then return end

    -- Iterate through all entities being built and call the ProgressBuilding function on them
    for _, entity in pairs(globalAllEntitiesBeingBuilt) do
        ProgressBuilding(entity)
    end
end)

-- "Builds" the given entity by increasing its health value by 1 every tick
function StartBuilding(entity)
    -- Check if the entity is still valid
    if not entity.valid then return end

    -- Ignore entities that are in the list of ignored entities
    if table.contains(ignoredEntities, entity.type) then return end

    -- Check if the entity has a health value, if yes, set it to 1
    if entity.health then
        entity.health = 1
    end

    -- Deactivate the entity
    entity.active = false
    entity.operable = false

    -- Change the force of this entity to the neutral force, so it won't be repaired by robots
    entity.force = game.forces.neutral

    -- Add the entity to the list of entities being built
    table.insert(global.allEntitiesBeingBuilt, entity)
end

-- Progresses a building entity by 1 tick
function ProgressBuilding(entity)
    -- Check if the entity is still valid
    if not entity.valid then return end

    -- Increase the health value of the entity by 1
    entity.health = entity.health + 1

    -- Check if the entity is fully built
    if entity.health >= entity.prototype.max_health then
        -- Remove the entity from the list of entities being built
        RemoveEntityFromBuildList(entity)

        -- Activate the entity
        entity.active = true
        entity.operable = true

        -- Change the force of this entity to the player force, so it can be repaired by robots
        entity.force = game.forces.player
        return
    end
end

-- Removes the entity from the list of entities being built
function RemoveEntityFromBuildList(entity)
    -- Check if entity is nil
    if not entity then return end

    -- Check if the entity is still valid
    if not entity.valid then return end

    local globalAllEntitiesBeingBuilt = global.allEntitiesBeingBuilt

    -- Remove the entity from the list of entities being built.
    if globalAllEntitiesBeingBuilt and #globalAllEntitiesBeingBuilt >= 1 then
        -- Iterate over all entities being built and remove the entity from the list
        for i, e in pairs(globalAllEntitiesBeingBuilt) do
            if e == entity then
                table.remove(global.allEntitiesBeingBuilt, i)
                return
            end
        end
    end
end

-- Returns true if the given value is contained in the table
function table.contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end