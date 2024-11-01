-- Initialize the list of entitiy-types to ignore
local ignoredEntityTypes = {
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

-- Initialize the list of entitiy-names to ignore
local ignoredEntityNames = {
  "entity-ghost",
  "mining-depot",
  "",
}

-- List of events on which to call the "StartBuilding" function
local eventsToStartBuilding = {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity
}

-- Add the entity to the list of entities being built..
script.on_event(eventsToStartBuilding, function(event)
    local entity = event.created_entity

    -- Ignore entities that are not valid
    if not entity.valid then return end

    -- Start the build process of this entity.
    StartBuilding(entity)
end)

-- List of events on which to call the "RemoveEntityFromBuildList" function
local eventsToRemoveEntityFromBuildList = {
    defines.events.on_player_mined_entity,
    defines.events.on_entity_died,
    defines.events.on_robot_mined_entity
}

-- Remove the entity from the list of entities being built
script.on_event(eventsToRemoveEntityFromBuildList, function(event)
    -- Check if the event is the on_player_mined_entity event
    if event.name == defines.events.on_player_mined_entity then
        -- Get the name of the mined entity and the event inventory
        local entityName = event.entity.name
        local eventInventory = event.buffer

        -- Check if the eventInventory contains the entity
        local eventIntentoryContents = eventInventory.get_contents()

        for itemName, itemCount in pairs(eventIntentoryContents) do
            -- Check if the item is the entity that was mined
            if itemName == entityName then
                -- Yes, we do have to get the stack here, because the get_contents() function returns the count of the items in the inventory, and not the stacks.
                -- We want the stacks so we can set the health.
                -- Find the entity by name in the event inventory
                local entityStack = eventInventory.find_item_stack(entityName)

                -- Check if we got a valid item-stack
                if entityStack then
                    -- Set the health of the stack to 1
                    entityStack.health = 1
                end
            end
        end
    end

    RemoveEntityFromBuildList(event.entity)
end)

-- Progressing buildings on every 5th tick.
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

    -- Ignore entities with types that are in the list of ignored entities
    if table.contains(ignoredEntityTypes, entity.type) then return end

    -- Ignore entities with names that are in the list of ignored entities
    if table.contains(ignoredEntityNames, entity.name) then return end

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
        
        -- Replace the entity
        FinishEntity(entity)
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

-- Replaces the given entity with a new entity with the exact same settings, but the player force.
function FinishEntity(entity)
    -- Check if the entity is still valid
    if not entity.valid then return end

    -- Reactivate the entity and make it operable
    entity.active = true
    entity.operable = true

    -- Change the force of this entity to the player force
    entity.force = game.forces.player

    script.raise_script_built({entity = entity})
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