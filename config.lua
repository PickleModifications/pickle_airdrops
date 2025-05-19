Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.ImageDirectory = "nui://ox_inventory/web/images/"

Config.Airdrops = {
    defaultItemCaptureTime = 1, -- Default time to capture an item from the airdrop.
}

Config.CurrencyItems = {
    -- These are the items that will be used for images from your inventory.
    ["money"] = "money",
    ["dirty_money"] = "black_money",
}

Config.RandomDropCommand = "airdrop" -- Command to spawn a random drop. /airdrop <dropTemplate>

Config.RandomDropZones = {
    -- Radius will affect the randomization of the drop zone around the coordinates. Set to 0.0 to set the drop zone to the exact coordinates.
    { coords = vector3(-1666.8334, -899.7947, 7.4796), radius = 50.0 },
}

Config.AirdropTemplates = {
    ["default"] = {
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
        radius = {
            size = 50.0,
            color = 1,
        },
    },
}