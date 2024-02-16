-- anti double execute on production
if not debugMode and _G.script_h then return end;_G.script_h = true

local services = setmetatable({}, { __index = function(s, key) return game:GetService(key) end})
local plr = services.Players.LocalPlayer

local apiMain = 'https://api.hermanos-dev.com'

-- debug mode
if debugMode then
    getgenv().Settings = {
        ['key'] = '4cbab678-c0dd-46d0-a9b4-5e12963ebd84',
        ['PC'] = 'DDC-NICEz',

        ['Sword'] = {'Cursed Dual Katana', 'Tushita', 'Yama', 'Dark Dagger', 'Hallow Scythe', 'Saber'},
        ['Fruit'] = {'Kitsune', 'Leopard', 'Dragon',  'Spirit', 'Control', 'Venom', 'Shadow', 'Dough','Mammoth', 'T-Rex'},
    }
end

local dWarn = debugMode and function(...) warn(...) end or function() end
local dPrint = debugMode and function(...) print(...) end or function() end

repeat task.wait() until plr.Team

local Flag = {
    ['Settings'] = getgenv().Settings,
    ['SeasId'] = {2753915549, 4442272183, 7449423635},
    ['formatStyles'] = {
        ['SanguineArt'] = 'SGA',
        ['Godhuman'] = 'GOD',
        ['SharkmanKarate'] = 'SMK',
        ['DragonTalon'] = 'DT',
        ['ElectricClaw'] = 'ELTC',
        ['DeathStep'] = 'DS',
        ['Superhuman'] = 'SPHM',
    },
    ['formatSwords'] = {
        ['Cursed Dual Katana'] = 'CDK',
    },
}

do -- init
    _G.CommF_ = services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

    if not Flag.Settings or typeof(Flag.Settings) ~= 'table' then
        Flag.Settings = {}
    end
    if not Flag.Settings.PC then
        return plr:Kick('PC is null')
    end

    -- valid key
    do
        local k = Flag.Settings.key
        if not k or typeof(k) ~= 'string' or #k ~= 36 then
            return plr:Kick('Key is invalid')
        end
    end
end

local tableFindReturnIndex = function(t, n)
    for i,v in next,t do
        if v == n then
            return n, i 
        end
    end
end

local addCommas = function(n)
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):gsub(",(%-?)$","%1"):reverse()
end

local tableJoin = function(delimiter, list)
    local result = ''
    for i, item in ipairs(list) do
        result = result .. item .. delimiter
    end
    return result:sub(1, -2)
end

local getPlrTool = function(toolName)
    for _,t in next,{plr.Backpack,plr.Character} do
        for _,v in next,t:GetChildren() do
            if v:IsA('Tool') and v.Name == toolName then
                return v
            end
        end
    end
end

do
    local cleanCursedDualKatana = function(t)
        if not table.find(t, 'CDK') then return t end

        local r = {}
        for i,v in next,t do
            if not table.find({'Yama', 'Tushita'}, v) then
                r[#r + 1] = v
            end
        end
        return r
    end

    function getSwords()
        if not Flag.Settings.Sword or typeof(Flag.Settings.Sword) ~= 'table' then
            return 'No Config.'
        end
    
        local data = {}
        local targetWeapon = Flag.Settings.Sword
        local inventory = checkItems(nil, { Get = true })
    
        for i,v in next,inventory do
            if v.Type == 'Sword' then
                local tName, tIndex = tableFindReturnIndex(targetWeapon, v.Name)
                if not tName then continue end
    
                table.insert(data, {
                    Name = (Flag.formatSwords[v.Name] or v.Name),
                    Sort = tIndex
                })
            end
        end
    
        table.sort(data, function(a,b)
            return a.Sort < b.Sort
        end)
    
        data = (function()
            local r = {}
            for _,v in next,data do
                r[#r + 1] = v.Name
            end
            return r
        end)()
        if #data <= 0 then return '-' end
    
        data = cleanCursedDualKatana(data)
        return tableJoin(',', data)
    end
end


do
    local stylesName = {'SanguineArt', 'Godhuman', 'DragonTalon', 'ElectricClaw', 'SharkmanKarate', 'DeathStep', 'Superhuman'} 
    local caches = {
        text = '',
        oldData = {},
        data = {'','','','','',''}
    }

    function getStyles()
        for i,v in next,stylesName do
            if table.find(caches.oldData, v) then continue end
            local check = _G.CommF_:InvokeServer('Buy' .. v ,true)
            if check == 1 then
                table.insert(caches.oldData, v)
                caches.data[i] = Flag.formatStyles[v] or v 
            end
        end

        local dataWithoutNull = (function()
            local r = {}
            for _,v in next,caches.data do
                if v == '' then continue end
                r[#r + 1] = v
            end
            return r
        end)()

        if #dataWithoutNull <= 0 then return '-' end

        return string.format('%s[%d]', dataWithoutNull[1], #dataWithoutNull)
    end
end

do
    local caches = {
        data = nil,
        time = -1
    }

    local g = function()
        local d = _G.CommF_:InvokeServer('getInventory')
        caches.time = tick() + 30
        caches.data = d
        return d
    end
    
    function checkItems(n, opts)
        local opts = opts or {}
        local data = tick() > caches.time and g() or caches.data

        if opts.Get then return data end
        
        for _,v in next,data do
            if v.Name == n then
                if v.Type == 'Material' then return v end
                return v.Name
            end
        end

        if opts['Spoof'] then
            return {
                ['Name'] = n,
                ['Count'] = 0,
            }
        end
    end
end

function getSea()
    for i,v in next,{2753915549, 4442272183, 7449423635} do
        if v == game.PlaceId then
            return tostring(i)
        end
    end
    return ''
end

do
    local c = {false, false}
    function getMirror()
        if c[1] then return true end
        local isGot = checkItems('Mirror Fractal')
        if isGot then c[1] = true end
        return isGot and true or false
    end
    
    function getValkyrie()
        if c[2] then return true end
        local isGot = checkItems('Valkyrie Helm')
        if isGot then c[2] = true end
        return isGot and true or false
    end
end

local getFruitInventory = function()
    if not Flag.Settings.Fruit or typeof(Flag.Settings.Fruit) ~= 'table' then
        return 'No Config.'
    end
    
    local plrInventory = checkItems(nil, { Get = true })
    local getFruits = {}
    local result = ''
    local targetFruits = Flag.Settings.Fruit

    for _,v in next,plrInventory do
        if v.Type == 'Blox Fruit' and v.Value >= 1000000 then
            local name = v.Name:split('-')[1]
            if v.Name == 'T-Rex-T-Rex' then
                name = 'T-Rex'
            end
            if not table.find(targetFruits, name) then continue end

            table.insert(getFruits, {
                Name = name,
                Price = v.Value
            })
        end
    end
    if #getFruits == 0 then return '-' end
    
    table.sort(getFruits, function(a,b)
        return a.Price > b.Price
    end)
    
    for i,v in next,getFruits do
        result = result .. v.Name .. (i < #getFruits and ',' or '')
    end
    return result
end

local shortNumber = function(n)
    local suffixes = {'', 'K', 'M', 'B', 'T'}

    local formattedNumber = n
    local suffixIndex = 1

    while formattedNumber >= 1000 and suffixIndex < #suffixes do
        formattedNumber = math.floor(formattedNumber / 1000)
        suffixIndex = suffixIndex + 1
    end

    return formattedNumber .. suffixes[suffixIndex]
end

do
    local oldRace = nil
    local oldRaceLevel = nil

    local racesSkillName = {'Last Resort', 'Agility', 'Water Body', 'Heavenly Blood', 'Heightened Senses', 'Energy Core'}

    local checkRaceV4 = function()
        return plr.PlayerGui.Main.RaceEnergy.Visible
    end

    local checkRaceV3 = function()
        for i,v in next,racesSkillName do
            if plr.Backpack:FindFirstChild(v) then return true end
            if plr.Character:FindFirstChild(v) then return true end
        end
    end

    local raceIsOld = function(currentRace)
        return oldRace == currentRace
    end

    function getRace()
        local plrRace = plr.Data.Race.Value
        
        local raceVersion = (function()
            if raceIsOld() and oldRaceLevel == 'V4' then return oldRaceLevel end

            local s, isV4 = pcall(checkRaceV4)
            if s and isV4 then
                oldRaceLevel = 'V4'
                return 'V4' 
            end

            if raceIsOld() and oldRaceLevel == 'V3' then return oldRaceLevel end

            local s, isV3 = pcall(checkRaceV3)
            if s and isV3 then
                oldRaceLevel = 'V3'
                return 'V3'
            end
            
            if raceIsOld() and oldRaceLevel == 'V2' then return oldRaceLevel end

            local isV2 = _G.CommF_:InvokeServer('Alchemist', '1')
            if isV2 == -2 then
                oldRaceLevel = 'V2'
                return 'V2'
            end
            
            return 'V1'
        end)()
        
        oldRace = plrRace

        return string.format('%s %s', plrRace, '['.. raceVersion ..']')
    end
end

do
    local cache = nil
    function isUnlockLever()
        if cache then return true end
        if not _G.CommF_:InvokeServer('CheckTempleDoor') then
            return false
        end
        cache = true
        return true
    end
end

function getCountDarkFragment()
    local d = checkItems('Dark Fragment', { Spoof = true })
    return d.Count
end

function getPlrDevilFruit()
    local plrDevilFruit = plr.Data.DevilFruit.Value
    if plrDevilFruit == '' then return '-' end
    local r = plrDevilFruit:split('-')[1]
    if plrDevilFruit == 'T-Rex-T-Rex' then r = 'T-Rex' end

    local mastery = (function()
        local tool = getPlrTool(plrDevilFruit) 
        if not tool then return '-' end

        local level = tool:FindFirstChild('Level')
        if not level then return '-' end

        return tostring(level.Value)
    end)()

    local awakenedSkill = (function()
        local t = _G.CommF_:InvokeServer('getAwakenedAbilities')
        if typeof(t) ~= 'table' then return '' end

        local sLength = 0
        local r = {}
        for s,v in next,t do
            sLength = sLength + 1
            if v.Awakened then
                r[#r + 1] = s
            end
        end
        if #r <= 0 or #r < sLength then return '' end

        return '[FULL AWAKED]'
    end)()

    return string.format('%s [%s] %s', r, mastery, awakenedSkill)
end

do
    local sendWebhookValidationError = function(payload)
        xpcall(function()
            request({
                Url = 'https://discord.com/api/webhooks/1203338650755014696/-gSE7JVNjxvmdNUXf4MPREmMt8POe5MjyQwH53KzPI7dGvj_j88DfJx6Pwa4zTzQHIKf',
                Body = services.HttpService:JSONEncode({
                    embeds = {
                        {
                            title = ":peach: Validation Error",
                            color = 16745728,
                            description = payload
                        }
                    },
                }),
                Method = "POST",
                Headers = {
                    ["content-type"] = "application/json"
                }
            })
        end,function(err)
            dWarn(err)
        end)
    end

    function sendData()
        local payload = services.HttpService:JSONEncode({
            ['data'] = {
                ['key'] = Flag.Settings.key,
                ['data'] = {
                    ['pc'] = Flag.Settings.PC,
                    ['username'] = plr.Name,

                    ['level'] = addCommas(plr.Data.Level.Value),
                    ['money'] = shortNumber(plr.Data.Beli.Value),
                    ['fragment'] = shortNumber(plr.Data.Fragments.Value),
                    ['devilFruit'] = getPlrDevilFruit(),
                    ['world'] = getSea(),

                    ['race'] = getRace(),

                    ['melee'] = getStyles(),
                    ['sword'] = getSwords(),
                    ['fruitInventory'] = getFruitInventory(),

                    ['mirror'] = getMirror(),
                    ['valkyrie'] = getValkyrie(),
                    ['lever'] = isUnlockLever(),
                    ['darkFragment'] = getCountDarkFragment(),
                },
            }
        })
        local res = game:HttpGet( apiMain .. '/account-data/bloxfruit/update?abdullah=chickenmasala&hoppa=123&data=' .. payload)

        local success, data = pcall(function()
            return services.HttpService:JSONDecode(res)
        end)
        if not success then
            return dWarn('Parse Json Data Faile', data)
        end

        if data.error == 'Validation Error' then
            -- sendWebhookValidationError(payload)
            dWarn('Validation Fail')
            return task.wait(2)
        end

        if data.message ~= 'Success' then
            plr:Kick(string.format('Hermanos: %s', data.message))
            task.wait(999999999)
            return error('Kick')
        end

        dPrint('Response:', data.message)
    end
end

local main = function() 
    while true do task.wait()
        local s, _ = pcall(sendData)
        if not s then task.wait(10);continue end

        task.wait(10)
    end
end

do -- thread
    task.spawn(main)
end

dPrint('Running')
