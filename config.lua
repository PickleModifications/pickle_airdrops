Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.ImageDirectory = "nui://ox_inventory/web/images/"
Config.WeaponsAreItems = true -- This enables the use of weapons as items. If set to false, weapons will be treated as items and not as weapons.
Config.RandomDropCommand = "airdrop" -- Command to spawn a random drop. /airdrop <dropTemplate>

Config.GiveKeys = function(vehicle, plate)
    -- Replace this line with your export / event to give keys for your vehicle.
end

Config.Airdrops = {
    planeSpeed = 2.0, -- Speed of the plane.
    dropSpeed = 0.5, -- Speed of the airdrop package.
    skyHeight = 200.0, -- Height of the plane in the sky.
    announceScheduledDrops = true, -- This enables the announcement of scheduled drops.
    defaultUnlockTime = 0, -- Default time in seconds to unlock the airdrop container.
    defaultItemCaptureTime = 5, -- Default time to capture an item from the airdrop.
}

Config.Currency = {
    currency = "USD",
    countryCode = "en-US",
}

Config.CurrencyItems = {
    -- These are the items that will be used for images from your inventory.
    ["money"] = "money",
    ["dirty_money"] = "black_money",
}

Config.RandomDropZones = {
    -- Radius will affect the randomization of the drop zone around the coordinates. Set to 0.0 to set the drop zone to the exact coordinates.
    { coords = vector3(-1666.8334, -899.7947, 7.4796), radius = 50.0 },
    { coords = vector3(-1138.2551, -2.0392, 47.9821), radius = 50.0 },
    { coords = vector3(1369.0424, -649.6426, 72.5967), radius = 50.0 },
}

Config.RadiusBlip = {
    color = 1,
    alpha = 127,
}

Config.AirdropTemplates = {
    ["default"] = {
        image =  "nui://pickle_airdrops/nui/images/crate.png", -- Image of the airdrop shown on the interact.
        label = "Airdrop Container - Basic", -- Label of the airdrop.
        -- cronSchedule = "0 */1 * * *", -- Cron job to spawn the airdrop. This is in the format of "minute hour day month dayOfWeek". Example: "0 0/5 * * * ?" will spawn every 5 minutes.
        item = "airdrop_basic", -- This is the item that will be used by players to spawn the airdrop at their position.
        radius = 50.0, --- The radius of the airdrop drop zone.
        spawnRadiusMultiplier = 0.5, -- 1.0 is to spawn objects to the fullest extent, 0.1 is to spawn objects in a small area in the center.
        dropBlipEnabled = true, -- This enables the drop blip on the map.
        radiusBlipEnabled = true, -- This enables the radius blip on the map.
        dropModel = `sm_prop_smug_crate_01a`, -- Model of the airdrop container.
        minidropModel = `sm_prop_smug_crate_01a`, -- Model of the airdrop containers that appear when the airdrop contains multiple containers.
        items = { 
            -- If an item's capture time is not specified, it will use the default capture time in Config.Airdrops.
            -- If an item's itemType is not specified, it will interpret it as a item. Types: "item", "weapon", "money".
            -- The higher an item's chance, the more likely it is to spawn in the airdrop container. 
            {chance = 2, itemType = "weapon", name = "WEAPON_APPISTOL", range = {1, 1}}, -- Range is the randomization of how much of the item is spawned in the slot.
            {chance = 5, itemType = "weapon", name = "WEAPON_PISTOL", range = {1, 1}, count = 10},
            {chance = 10, itemType = "dirty_money", range = {10000, 100000}, count = 10},
            {chance = 10, itemType = "money", range = {10000, 100000}, count = 10},
            {chance = 15, name = "water", range = {2, 5}, count = 5 },
            {chance = 15, name = "beer", range = {2, 5}, count = 5 },
        },
        itemRange = {2, 3}, -- The range of items that can be spawned in the airdrop container.
    },
    ["vehicle_default"] = {
        image =  "nui://pickle_airdrops/nui/images/crate.png", -- Image of the airdrop shown on the interact.
        label = "Mystery Vehicle - Basic", -- Label of the airdrop.
        -- cronSchedule = "0 */1 * * *", -- Cron job to spawn the airdrop. This is in the format of "minute hour day month dayOfWeek". Example: "0 0/5 * * * ?" will spawn every 5 minutes.
        dropType = "vehicle", -- This is the type of the airdrop. It can be "vehicle" or "container". If set to "vehicle", the airdrop will spawn a vehicle.
        item = "vehicledrop_basic", -- This is the item that will be used by players to spawn the airdrop at their position.
        radius = 50.0, --- The radius of the airdrop drop zone.
        spawnRadiusMultiplier = 0.5, -- 1.0 is to spawn objects to the fullest extent, 0.1 is to spawn objects in a small area in the center.
        dropBlipEnabled = true, -- This enables the drop blip on the map.
        radiusBlipEnabled = true, -- This enables the radius blip on the map.
        vehicles = { 
            -- If an item's capture time is not specified, it will use the default capture time in Config.Airdrops.
            -- The higher an item's chance, the more likely it is to spawn in the airdrop container. 
            {chance = 2, label = "Adder", model = "adder", captureTime = 60, image = "https://docs.fivem.net/vehicles/adder.webp"},
            {chance = 10, label = "Dominator", model = "dominator", image = "https://docs.fivem.net/vehicles/dominator.webp"},
            {chance = 15, label = "Sanchez", model = "sanchez", image = "https://docs.fivem.net/vehicles/sanchez.webp"},
        },
    },
}

Config.RandomDrops = {
    announceScheduledDrops = true, -- This enables the announcement of scheduled drops.
    cronSchedule = "0 */1 * * *", -- Cron job to spawn the airdrop. Set to nil to disable.
    airdropTemplates = {
        {id = "default", chance = 10, containers = 1}, -- This is the default airdrop template. The chance is the chance of the airdrop spawning.
        {id = "vehicle_default", chance = 10}, -- This is the default airdrop template. The chance is the chance of the airdrop spawning.
    }
}

Config.Blips = {
    ["airdrop_plane_blip"] = {
        sprite = 307,
        color = 0,
        scale = 1.0,
        display = 8,
    },
    ["airdrop_container_blip"] = {
        sprite = 478,
        color = 0,
        scale = 1.0,
        display = 8,
    },
}