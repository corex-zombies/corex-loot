Config = {}
Config.Debug = false

Config.ItemsPerContainer = { min = 2, max = 5 }

Config.Respawn = {
    minTime = 900,
    maxTime = 1800
}

Config.Reveal = {
    itemRevealDelay = 1800,
    searchAnimDict = 'mini@repair',
    searchAnim = 'fixing_a_ped'
}

Config.ContainerTypes = {
    police = {
        label = 'Police Locker',
        model = 'prop_mil_crate_01',
        searchTime = 4000,
        icon = 'fa-shield-halved',
        interactLabel = '[E] Search Locker',
        interactDistance = 2.0,
        blip = { sprite = 526, color = 29, scale = 0.7, label = 'Police Station' }
    },
    medical = {
        label = 'Medical Supply',
        model = 'prop_mil_crate_02',
        searchTime = 3000,
        icon = 'fa-kit-medical',
        interactLabel = '[E] Search Cabinet',
        interactDistance = 2.0,
        blip = { sprite = 153, color = 1, scale = 0.7, label = 'Medical Supply' }
    },
    military = {
        label = 'Military Crate',
        model = 'prop_box_ammo07a',
        searchTime = 5000,
        icon = 'fa-crosshairs',
        interactLabel = '[E] Open Crate',
        interactDistance = 2.0,
        blip = { sprite = 310, color = 1, scale = 0.8, label = 'Military Zone' }
    },
    house = {
        label = 'Storage Box',
        model = 'prop_cs_cardbox_01',
        searchTime = 2000,
        icon = 'fa-box-open',
        interactLabel = '[E] Search Box',
        interactDistance = 2.0,
        blip = false
    }
}

Config.LootTables = {
    police = {
        { chance = 0.45, items = {
            { name = 'pistol_ammo', min = 5, max = 15 },
            { name = 'bandage', min = 1, max = 2 },
            { name = 'cloth', min = 1, max = 3 }
        }},
        { chance = 0.30, items = {
            { name = 'WEAPON_CERAMICPISTOL', min = 1, max = 1 },
            { name = 'painkillers', min = 1, max = 2 },
            { name = 'scrap_metal', min = 1, max = 2 }
        }},
        { chance = 0.18, items = {
            { name = 'WEAPON_PISTOL_MK2', min = 1, max = 1 },
            { name = 'antibiotics', min = 1, max = 1 },
            { name = 'smg_ammo', min = 10, max = 20 }
        }},
        { chance = 0.07, items = {
            { name = 'WEAPON_COMBATPDW', min = 1, max = 1 },
            { name = 'blueprint_pistol_ammo', min = 1, max = 1 }
        }}
    },
    medical = {
        { chance = 0.45, items = {
            { name = 'bandage', min = 1, max = 3 },
            { name = 'herbs', min = 1, max = 3 },
            { name = 'dirty_water', min = 1, max = 2 }
        }},
        { chance = 0.30, items = {
            { name = 'antibiotics', min = 1, max = 2 },
            { name = 'painkillers', min = 1, max = 3 },
            { name = 'clean_water', min = 1, max = 2 }
        }},
        { chance = 0.18, items = {
            { name = 'medkit', min = 1, max = 1 },
            { name = 'antidote', min = 1, max = 1 },
            { name = 'chemicals', min = 1, max = 2 }
        }},
        { chance = 0.07, items = {
            { name = 'blueprint_antidote', min = 1, max = 1 },
            { name = 'blueprint_medkit', min = 1, max = 1 }
        }}
    },
    military = {
        { chance = 0.40, items = {
            { name = 'pistol_ammo', min = 10, max = 25 },
            { name = 'smg_ammo', min = 10, max = 25 },
            { name = 'scrap_metal', min = 2, max = 4 }
        }},
        { chance = 0.30, items = {
            { name = 'WEAPON_PISTOL_MK2', min = 1, max = 1 },
            { name = 'WEAPON_CERAMICPISTOL', min = 1, max = 1 },
            { name = 'chemicals', min = 1, max = 2 }
        }},
        { chance = 0.20, items = {
            { name = 'WEAPON_COMBATPDW', min = 1, max = 1 },
            { name = 'WEAPON_TECPISTOL', min = 1, max = 1 },
            { name = 'medkit', min = 1, max = 1 }
        }},
        { chance = 0.10, items = {
            { name = 'blueprint_smg_ammo', min = 1, max = 1 },
            { name = 'blueprint_pistol_ammo', min = 1, max = 1 },
            { name = 'antidote', min = 1, max = 2 }
        }}
    },
    house = {
        { chance = 0.50, items = {
            { name = 'cloth', min = 1, max = 3 },
            { name = 'dirty_water', min = 1, max = 2 },
            { name = 'duct_tape', min = 1, max = 1 }
        }},
        { chance = 0.30, items = {
            { name = 'canned_food', min = 1, max = 2 },
            { name = 'clean_water', min = 1, max = 1 },
            { name = 'bandage', min = 1, max = 2 }
        }},
        { chance = 0.15, items = {
            { name = 'herbs', min = 1, max = 2 },
            { name = 'scrap_metal', min = 1, max = 2 },
            { name = 'energy_drink', min = 1, max = 1 }
        }},
        { chance = 0.05, items = {
            { name = 'painkillers', min = 1, max = 1 },
            { name = 'chemicals', min = 1, max = 1 }
        }}
    }
}

Config.Locations = {
    {
        name = 'Sandy Shores Sheriff',
        type = 'police',
        containers = {
            { coords = vector3(1853.5, 3687.5, 33.70), heading = 30.0 }
        }
    },
    {
        name = 'Sandy Shores Medical',
        type = 'medical',
        containers = {
            { coords = vector3(1839.3713, 3672.8123, 34.2768), heading = 210.0886 }
        }
    },
    {
        name = 'Fort Zancudo Armory',
        type = 'military',
        containers = {
            { coords = vector3(-2359.5, 3253.3, 31.81), heading = 85.0 },
            { coords = vector3(-2356.8601, 3246.5652, 31.8107), heading = 328.3917 }
        }
    },
    {
        name = 'Route 68 House',
        type = 'house',
        containers = {
            { coords = vector3(1393.4376, 3603.4702, 33.9809), heading = 197.1876 }
        }
    },
    {
        name = 'Harmony House',
        type = 'house',
        containers = {
            { coords = vector3(547.2, 2670.8, 41.30), heading = 10.0 }
        }
    },
    {
        name = 'Grapeseed Medical',
        type = 'medical',
        containers = {
            { coords = vector3(1662.5, 4767.3, 41.20), heading = 60.0 }
        }
    },
    {
        name = 'Paleto Sheriff',
        type = 'police',
        containers = {
            { coords = vector3(-446.5775, 6014.0400, 31.20), heading = 313.1423 }
        }
    },
    {
        name = 'Paleto Medical',
        type = 'medical',
        containers = {
            { coords = vector3(-247.5, 6331.0, 31.60), heading = 225.0 }
        }
    }
}
