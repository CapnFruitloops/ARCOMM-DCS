-- ARCOMM Practice Mission
-- Author: Matúš 'matuzalem' Sabol
-- Powered by MOOSE Framework

-- debug
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- arg map keys
kArgKeys = {
    ZONE="zone",
    NAME="name",
    SKILL="skill",
    DB="db",
    STORE_ZONE="store_zone"
}

-- MOOSE Spawn object list
spawn_objects = {}

spawned_ai_aggressors = {}
spawned_ground_groups = {}
spawned_sea_groups    = {}

local function SpawnAITargets(arg_map)
    local zone_name  = arg_map[kArgKeys.ZONE]
    local group_name = arg_map[kArgKeys.NAME]
    local skill_name = arg_map[kArgKeys.SKILL]
    local unit_db    = arg_map[kArgKeys.DB]
    local store_zone = arg_map[kArgKeys.STORE_ZONE]

    local spawn_group = spawn_objects[group_name]

    if skill_name ~= nil
    then
        spawn_group:InitSkill(skill_name)
    end

    local spawn_zone = ZONE:FindByName(zone_name)
    local spawned_group = spawn_group:SpawnInZone(spawn_zone, true)
    if spawned_group == nil
    then
        MESSAGE:New("Failed to spawn " .. group_name .. " in " .. zone_name, 5):ToBlue()
    else
        MESSAGE:New("A group of " .. group_name .. " (" .. skill_name .. ") was spawned in " .. zone_name, 5):ToBlue()
        if unit_db ~= nil
        then
            if store_zone
            then
                if unit_db[zone_name] == nil
                then 
                    unit_db[zone_name] = {}
                end

                table.insert(unit_db[zone_name], spawned_group)
            else
                table.insert(unit_db, spawned_group)
            end
        end
    end
end

local function ClearAIAggressors(arg_map)
    for grp_idx, grp in ipairs(spawned_ai_aggressors)
    do
        grp:Destroy()
    end

    MESSAGE:New("All AI aggressors were cleared", 5):ToAll()
end

local function ClearGroundTargets(arg_map)
    local zone_name = arg_map[kArgKeys.ZONE]

    if spawned_ground_groups[zone_name] == nil
    then
        return
    end

    for grp_idx, grp in ipairs(spawned_ground_groups[zone_name])
    do
        grp:Destroy()
    end

    MESSAGE:New("All ground units in " .. zone_name .. " were cleared", 5):ToAll()
end

local function ClearSeaTargets(arg_map)
    local zone_name = arg_map[kArgKeys.ZONE]

    if spawned_sea_groups[zone_name] == nil
    then
        return
    end

    for grp_idx, grp in ipairs(spawned_sea_groups[zone_name])
    do
        grp:Destroy()
    end

    MESSAGE:New("All sea units in zone " .. zone_name .. " were cleared", 5):ToAll()
end

--==|| SET UP AI AGGRESSOR SPAWNING ||==--
-- spawn zone names
aggressor_spawn_zones_names = {
    "Krymsk Zone", 
    "Krasnodar Zone", 
    "Temryuk Zone", 
    "Sochi Zone",
    "Maykop Zone"
}

-- AI aggressor group names
ai_aggressors_list = {
    "MiG-21 Aggressors", 
    "MiG-23 Aggressors", 
    "MiG-25 Aggressors",
    "MiG-29A Aggressors", 
    "MiG-29S Aggressors", 
    "Su-27 Aggressors"
}
-- AI aggressor difficulty list
ai_aggressor_difficulties = {"Average", "Good", "High", "Excellent", "Random"}

-- create menus to spawn AI aggressor flights
local blue_ai_aggressor_menu = MENU_COALITION:New(coalition.side.BLUE, "Spawn AI REDFOR Aggressors") -- menu root
for zone_idx, zone in ipairs(aggressor_spawn_zones_names) -- create menu item per each zone
do
    local zone_menu = MENU_COALITION:New(coalition.side.BLUE, "in " .. zone, blue_ai_aggressor_menu)
    for name_idx, name in ipairs(ai_aggressors_list) -- create aircraft menu item per each zone
    do
        spawn_objects[name] = SPAWN:New(name)
        local type_menu = MENU_COALITION:New(coalition.side.BLUE, name, zone_menu)
        for diff_idx, diff in ipairs(ai_aggressor_difficulties) -- create skill item per each aircraft
        do
            func_args = {}
            func_args[kArgKeys.ZONE]       = zone
            func_args[kArgKeys.NAME]       = name
            func_args[kArgKeys.SKILL]      = diff
            func_args[kArgKeys.DB]         = spawned_ai_aggressors
            func_args[kArgKeys.STORE_ZONE] = false
            MENU_COALITION_COMMAND:New(coalition.side.BLUE, diff, type_menu, SpawnAITargets, func_args)
        end
    end
end

--==|| SET UP TARGET DRONE SPAWNING ||==--
target_drone_spawn_zones_names = {
    "Krymsk Zone", 
    "Krasnodar Zone", 
    "Temryuk Zone", 
    "Sochi Zone",
    "Maykop Zone"
}

-- AI aggressor group names
target_drone_list = {
    "Small Target Drone", 
    "Large Target Drone"
}

-- create menus to spawn AI aggressor flights
local blue_target_drone_menu = MENU_COALITION:New(coalition.side.BLUE, "Spawn Target Drones") -- menu root
for zone_idx, zone in ipairs(target_drone_spawn_zones_names) -- create menu item per each zone
do
    local zone_menu = MENU_COALITION:New(coalition.side.BLUE, "in " .. zone, blue_target_drone_menu)
    for name_idx, name in ipairs(target_drone_list) -- create aircraft menu item per each zone
    do
        spawn_objects[name] = SPAWN:New(name)
        func_args = {}
        func_args[kArgKeys.ZONE]       = zone
        func_args[kArgKeys.NAME]       = name
        func_args[kArgKeys.SKILL]      = ai_aggressor_difficulties[1]
        func_args[kArgKeys.DB]         = spawned_ai_aggressors
        func_args[kArgKeys.STORE_ZONE] = false
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, name, zone_menu, SpawnAITargets, func_args)
    end
end

--==|| SET UP AA TARGET SPAWNING ||==--
-- spawn zone names
aa_spawn_zones_names = {
    "Krymsk Zone", 
    "Krasnodar Zone", 
    "Temryuk Zone", 
    "Sochi Zone",
    "Maykop Zone"
}

-- ground target groups names
aa_targets_list = {
    "SA-2 (long range) AA Group",
    "SA-3 (long range) AA Group",
    "SA-6 (medium range) AA Group",
    "SA-10 (long range) AA Group",
    "SA-11 (medium range) AA Group",
    "Mixed (vintage, short range) AA Group",
    "Mixed (modern, short range) AA Group"
}

-- create menus to spawn ground targets
local blue_aa_target_menu = MENU_COALITION:New(coalition.side.BLUE, "Spawn REDFOR AA Targets") -- menu root
for zone_idx, zone in ipairs(aa_spawn_zones_names) -- create menu item per each zone
do
    local zone_menu = MENU_COALITION:New(coalition.side.BLUE, "in " .. zone, blue_aa_target_menu)
    for name_idx, name in ipairs(aa_targets_list) -- create ground target menu item per each zone
    do
        spawn_objects[name] = SPAWN:New(name)
        local type_menu = MENU_COALITION:New(coalition.side.BLUE, name, zone_menu)
        for diff_idx, diff in ipairs(ai_aggressor_difficulties) -- create skill item per each aircraft
        do
            func_args = {}
            func_args[kArgKeys.ZONE]       = zone
            func_args[kArgKeys.NAME]       = name
            func_args[kArgKeys.SKILL]      = diff
            func_args[kArgKeys.DB]         = spawned_ground_groups
            func_args[kArgKeys.STORE_ZONE] = true
            MENU_COALITION_COMMAND:New(coalition.side.BLUE, diff, type_menu, SpawnAITargets, func_args)
        end
    end
end

--==|| SET UP GROUND TARGET SPAWNING ||==--
-- spawn zone names
gnd_spawn_zones_names = {
    "Gostagaevskaya Zone",
    "Krymsk Zone", 
    "Krasnodar Zone", 
    "Temryuk Zone", 
    "Sochi Zone",
    "Maykop Zone"
}

-- ground target groups names
gnd_targets_list = {
    "Soft Unarmed Line Group",
    "Soft Unarmed Cross Group",
    "Hard Unarmed Line Group",
    "Hard Unarmed Cross Group",
    "Soft Armed Line Group",
    "Soft Armed Cross Group",
    "Hard Armed Line Group",
    "Hard Armed Cross Group"
}

-- create menus to spawn ground targets
local blue_gnd_target_menu = MENU_COALITION:New(coalition.side.BLUE, "Spawn REDFOR Ground Targets") -- menu root
for zone_idx, zone in ipairs(gnd_spawn_zones_names) -- create menu item per each zone
do
    local zone_menu = MENU_COALITION:New(coalition.side.BLUE, "in " .. zone, blue_gnd_target_menu)
    for name_idx, name in ipairs(gnd_targets_list) -- create ground target menu item per each zone
    do
        spawn_objects[name] = SPAWN:New(name)
        func_args = {}
        func_args[kArgKeys.ZONE]       = zone
        func_args[kArgKeys.NAME]       = name
        func_args[kArgKeys.SKILL]      = ai_aggressor_difficulties[1]
        func_args[kArgKeys.DB]         = spawned_ground_groups
        func_args[kArgKeys.STORE_ZONE] = true
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, name, zone_menu, SpawnAITargets, func_args)
    end
end

--==|| SET UP SEA TARGET SPAWNING ||==--
-- spawn zone names
sea_spawn_zones_names = {
    "Near Sea Range Zone",
    "Far Sea Range Zone"
}

-- sea target groups names
sea_targets_list = {
    "Small Cargo Ship Fleet",
    "Large Cargo Ship Fleet",
    "Corvette Pair Fleet",
    "Frigate Pair Fleet",
    "Slava-class Cruiser",
    "Kirov-class Battlecruiser",
    "Admiral Kuznetsov",
    "Carrier Strike Group"
}

-- create menus to spawn ground targets
local blue_sea_target_menu = MENU_COALITION:New(coalition.side.BLUE, "Spawn REDFOR Sea Targets") -- menu root
for zone_idx, zone in ipairs(sea_spawn_zones_names) -- create menu item per each zone
do
    local zone_menu = MENU_COALITION:New(coalition.side.BLUE, "in " .. zone, blue_sea_target_menu)
    for name_idx, name in ipairs(sea_targets_list) -- create sea target menu item per each zone
    do
        spawn_objects[name] = SPAWN:New(name)
        func_args = {}
        func_args[kArgKeys.ZONE]       = zone
        func_args[kArgKeys.NAME]       = name
        func_args[kArgKeys.SKILL]      = ai_aggressor_difficulties[1]
        func_args[kArgKeys.DB]         = spawned_sea_groups
        func_args[kArgKeys.STORE_ZONE] = true
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, name, zone_menu, SpawnAITargets, func_args)
    end
end

--==|| MISC SETUP ||==--

-- create menus for clearing air targets
local blue_clear_ai_aggressors_menu = MENU_COALITION:New(coalition.side.BLUE, "Clear AI Aggressors") -- menu root
MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Clear All AI Aggressors", blue_clear_ai_aggressors_menu, ClearAIAggressors, {})

-- create menus for clearing ground targets in zones
local blue_clear_zone_menu = MENU_COALITION:New(coalition.side.BLUE, "Clear Ground Targets in Zone") -- menu root
for zone_idx, zone in ipairs(gnd_spawn_zones_names) -- create menu item per each zone
do
    func_args = {}
    func_args[kArgKeys.ZONE] = zone
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, zone, blue_clear_zone_menu, ClearGroundTargets, func_args)
end

-- create menus for clearing sea targets
local blue_clear_sea_menu = MENU_COALITION:New(coalition.side.BLUE, "Clear Sea Targets in Zone") -- menu root
for zone_idx, zone in ipairs(sea_spawn_zones_names) -- create menu item per each zone
do
    func_args = {}
    func_args[kArgKeys.ZONE] = zone
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, zone, blue_clear_sea_menu, ClearSeaTargets, func_args)
end

--==|| INIT DONE ||==--
MESSAGE:New("Mission initialization finished. Good luck, have fun...", 5):ToAll()