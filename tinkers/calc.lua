--[[
Name: Tinker's tool calculator
Author: Sparta252
Date: 12.06.2024
Language: Lua - ComputerCraft
]]--

-- To Do
-- NEW TOOLS
-- MINING LEVEL CHECK (SHOW ONLY HIGHEST)
-- CRITERIUM (MINIMAL MINING LEVEL)
-- OPTIMALIZACIA
-- ZLEPSENIE VYPOCTU HAMMERU (20*20*20*83 je moc vela kombinacii)

MAX_COUNT = 25 -- Pocet TOP nastrojov zapisanych do tinkers/results.lua
MAX_SIZE = 30 -- Urcuje tzv. Presnost (Vyssia hodnota, tazsi a dlhsi vypocet)



Material_list = {}
Tool_list = {}
Tool = {} -- Durability, Speed, Mining Level, Attack, Head, Extra, Tool_rod, value
Top_head = {}
Top_extra = {}
Material = {}

local function formula(atribute, input, type_of_tool)
    type_of_tool = type_of_tool or "pickaxe"
    atribute = atribute or "durability"
    if type_of_tool == "pickaxe" or type_of_tool == "shovel" or type_of_tool == "axe" then
        if atribute == "durability" then
            return input.durability
        elseif atribute == "attack" then
            return input.attack
        elseif atribute == "speed" then
            if input.miningSpeed then
                return input.miningSpeed
            else
                return input.speed
            end
        elseif atribute == "mix" then
            if input.miningSpeed then
                return input.durability*input.miningSpeed
            else
                return input.durability*input.speed
            end
        end
        -- Formula: Durability > ((((2x hammer + 1x plate + 1x plate)/4)*tool_modifier)+tool_rod_durab)*2.5
        -- Formula: MiningSpeed > ((2x hammer + 1x plate + 1x plate)/4)*0.4
    elseif type_of_tool == "hammer" then
        if atribute == "durability" then
            return input.durability
        elseif atribute == "attack" then
            return input.attack
        elseif atribute == "speed" then
            if input.miningSpeed then
                -- 0.1 vychadza zo vzorca vypoctu
                return input.miningSpeed*0.1
            else
                return input.speed*0.1
            end
        elseif atribute == "mix" then
            if input.miningSpeed then
                return input.durability*input.miningSpeed*0.1
            else
                return input.durability*input.speed*0.1
            end
        end
    elseif type_of_tool == "sword" then
        if atribute == "durability" then
            return input.durability
        elseif atribute == "attack" then
            return input.attack
        elseif atribute == "speed" then
            if input.miningSpeed then
                return input.miningSpeed
            else
                return input.speed
            end
        elseif atribute == "mix" then
            --print(input.durability*input.attack)
            return input.durability*input.attack
        end
    end
    
end

local function tableContains(table, value)
    for i = 1,#table do
      if (table[i] == value) then
        return true
      end
    end
    return false
end

local function sort_tools_by_hardness(param, type_of_tool)
    for i=1, #Tool_list do
        print(Tool_list[i].head.." SCORE IS: "..formula(param, Tool_list[i], type_of_tool))
        sleep(0.2)
    end
    table.sort(Tool_list, function(a, b) return formula(param, a, type_of_tool) > formula(param, b, type_of_tool) end)
    print("---------")
    for i=1, #Tool_list do
        print(Tool_list[i].head.." SCORE IS: "..formula(param, Tool_list[i], type_of_tool))
        sleep(0.2)
    end
end

-- Vytvorenie novej struktury Material
function Material:new(name, head, tool_rod, extra)
    local instance = {} -- Vytvorenie novej instancie ako prázdna tabulka
    setmetatable(instance, self) -- Nastavenie metatabule pre instanciu
    self.__index = self -- Definovanie dedicstva metod
    instance.name = name
    instance.head = head
    instance.tool_rod = tool_rod 
    instance.extra = extra 
    return instance -- Vrátenie novej instancie
end

-- V programe sa nepouziva
-- Sluzi na pomocne zobrazenie informacii o nastroji
-- (Vypise data v matierals/[material])
function Material:show()
    local head_info = {"durability", "miningLevel", "speed", "attack", "special"}
    local tool_rod_info = {"durability", "modifier", "special"}
    local extra_info = {"durability", "special"}
    print("-------------------")
    print("Material: ".. self.name)
    print("-------")
    print("Head: ")
    for i = 1, #head_info do
        print(" " .. tostring(head_info[i]) .. ": " .. tostring( self.head[head_info[i]]) )
    end
    print("Tool_rod: ")
    for i = 1, #tool_rod_info do
        print("  " .. tool_rod_info[i] .. ": " .. self.tool_rod[tool_rod_info[i]])
    end
    print("Extra: ")
    for i = 1, #extra_info do
        print("  " .. extra_info[i] .. ": " .. self.extra[extra_info[i]])
    end
    print("-------------------")
end

local function readList(file, list)
    while 1 do
        local readed = file.readLine()
        if not readed or readed == "" then
            break
        end
        if not string.find(readed, ".lua") then
            readed = readed..".lua"
        end
            table.insert(list, readed)
    end
    file.close()
end

-- Nacitanie vsetkych materialov v priecinku na zaklade blacklistu.lua a whitelistu.lua
-- do "aktualnych" programovej pamata
function Material_load(folder)
    folder = folder or "tinkers" -- Ak nie je zadana hodnota, tak sa nastavi "tinkers"
    local control = true -- Zapne kontrolu whitelistu
    local matfolder = folder.."/materials" -- Cesta k foldru s materialmi
    if not fs.exists(folder.."/whitelist.lua") then
        local file = fs.open(folder.."/whitelist.lua", "w")
        file.close()
    end
    if not fs.exists(folder.."/blacklist.lua") then
        local file = fs.open(folder.."/blacklist.lua", "w")
        file.close()
    end
    local whitefile = fs.open(folder.."/whitelist.lua", "r")
    local blackfile = fs.open(folder.."/blacklist.lua", "r")
    local whitelist = {}
    local blacklist = {}
    readList(whitefile, whitelist)
    readList(blackfile, blacklist)
    if not fs.exists(matfolder) then
        fs.makeDir(matfolder)
    end
    local materials = fs.list(matfolder); -- Zoznam materialov v priecinku
    if #whitelist == 0 then
        control = false
    end
    local loading = true
    for i=1, #materials do
        loading = true
        if not (tableContains(blacklist, materials[i])) then -- Kontrola Blacklistu
            if control == true then
                loading = false
                if tableContains(whitelist, materials[i]) then -- Kontrola Whitelistu
                    loading = true
                end
            end
            if loading then
                local mat_info = fs.open(matfolder.."/"..materials[i], "r")
                local func, error = loadstring(mat_info.readAll())
                local material_data = func()
                materials[i] = Material:new (
                    material_data.name,
                    material_data.head,
                    material_data.tool_rod,
                    material_data.extra
                )
                table.insert(Material_list, materials[i]) -- Hodi to tam ako cislo 1
                mat_info.close()
            end
        end
    end
    term.clear()
    term.setCursorPos(1,1)
    print("Nacitanych ".. #Material_list.. " druhy/ov materialov..")
    print("----------")
end

-- Samotne triedenie casti "head" a "extra", pre zefektivnenie
-- samotneho vytvarania kombinacii
-- (miesto 83^3 --> 20^2*83)
-- (zmensenie kombinacii z 571 787 na 33 200)
-- pozn. Handle obsahuje aj prvok Modifier, co je nasobitel predchadzajucich hodnot
-- je problematicke toto do toho zapocitat, preto mnozstvo handlov neskracujem
local function best_parts(size, atribute, type_of_tool)
    print("Spracuvavam ".. #Material_list*#Material_list*#Material_list .. " moznosti")
    print("----------")
    size = size or MAX_SIZE
    atribute = atribute or "durability"
    if #Material_list < size then
        size = #Material_list
    end

    if type_of_tool == "pickaxe" or type_of_tool == "shovel" or type_of_tool == "axe" or type_of_tool == "sword" then
        for i=1, #Material_list do
            if #Top_head < size then
                table.insert(Top_head, Material_list[i])
                table.insert(Top_extra, Material_list[i])
            else
                local min_head_index = 1
                local min_extra_index = 1

                for j=2, #Top_head do
                    if formula(atribute, Top_head[j].head, type_of_tool) < formula(atribute, Top_head[min_head_index].head, type_of_tool) then
                        min_head_index = j
                    end
                    if Top_extra[j].extra.durability < Top_extra[min_extra_index].extra.durability then
                        min_extra_index = j
                    end
                end

                if formula(atribute, Material_list[i].head, type_of_tool) > formula(atribute, Top_head[min_head_index].head, type_of_tool) then
                    Top_head[min_head_index] = Material_list[i]
                end 

                if Material_list[i].extra.durability > Top_extra[min_extra_index].extra.durability then
                    Top_extra[min_extra_index] = Material_list[i]
                end 


            end
        end
        -- Warning 
        -- Pri hammeri je Skladanie hammeru zmenene na 2 rovnake platy k 1 hlavni hammeru a 1 Tough rodu
    elseif type_of_tool == "hammer" then
        for i=1, #Material_list do
            if #Top_head < size then
                table.insert(Top_head, Material_list[i])
                table.insert(Top_extra, Material_list[i])
            else
                local min_head_index = 1

                for j=2, #Top_head do
                    if formula(atribute, Top_head[j].head) < formula(atribute, Top_head[min_head_index].head) then
                        min_head_index = j
                    end
                end

                if formula(atribute, Material_list[i].head) > formula(atribute, Top_head[min_head_index].head) then
                    Top_head[min_head_index] = Material_list[i]
                    Top_extra[min_head_index] = Material_list[i]
                end 
            end
        end 
    end
    print("Zjedodusujem na ".. #Material_list*size*size .." moznosti")
    print("----------")
end


-- Samotny vypocet danej kombinacie
-- Ako zjedodusenie pouziva upravenu databazu z best_parts()
-- vytvara vsetky mozne kombinacie a uklada ich do (najlepsich MAX_COUNT) Tool_list[] 
-- 
local function calculate(size, atribute, type_of_tool)
    atribute = atribute or "durability"
    size = size or MAX_SIZE
    print("Vytvaram vhodne kombinacie")
    print("----------")
    local num_of_tool = 0;
    local max_materials = #Material_list
    local hardness = 0
    for head_combo = 1, size do
        for extra_combo = 1, size do
            for tool_combo = 1, max_materials do
                num_of_tool = num_of_tool + 1

                local head = Top_head[head_combo]
                local extra = Top_extra[extra_combo]
                local tool = Material_list[tool_combo]

                if type_of_tool == "pickaxe" or type_of_tool == "shovel" or type_of_tool == "axe" then
                    hardness = ((head.head.durability + extra.extra.durability) * tool.tool_rod.modifier) + tool.tool_rod.durability
                elseif type_of_tool == "hammer" then
                    hardness = ((((head.head.durability*2 + extra.head.durability*2)/4) * tool.tool_rod.modifier) + tool.tool_rod.durability) * 2.5
                elseif type_of_tool == "sword" then
                    hardness = (((head.head.durability + extra.extra.durability) * tool.tool_rod.modifier) + tool.tool_rod.durability) * 1.1
                end

                if head.head.special == "Cheepskate" then
                    hardness = hardness * 0.8
                elseif extra.head.special == "Cheepskate" and type_of_tool == "hammer" then
                    hardness = hardness * 0.8
                end

                local newTool

                if type_of_tool == "pickaxe" or type_of_tool == "shovel" or type_of_tool == "axe" or type_of_tool == "sword" then
                    local setdamage = head.head.attack
                    local setspeed = head.head.miningSpeed
                    if type_of_tool == "shovel" then
                        setdamage = setdamage*0.9
                    elseif type_of_tool == "axe" then
                        setdamage = (setdamage*1.1)+0.5
                    elseif type_of_tool == "sword" then
                        setdamage = setdamage + 1
                        setspeed = 1.6
                    end
                    setdamage = setdamage+1
                    newTool = {
                        durability = hardness,
                        speed = setspeed,
                        mininglevel = head.head.miningLevel,
                        attack = setdamage,
                        head = head.name,
                        tool_rod = tool.name,
                        extra = extra.name,
                        special = { head.head.special, extra.extra.special, tool.tool_rod.special }
                    }
                elseif type_of_tool == "hammer" then
                    local setspeed = (head.head.miningSpeed*2 + extra.head.miningSpeed*2)*0.1
                    local setdamage = ((head.head.attack*2 + extra.head.attack*2)/4)*1.2+1
                    newTool = {
                        durability = hardness,
                        speed = setspeed,
                        mininglevel = head.head.miningLevel .." & "..extra.head.miningLevel,
                        attack = setdamage,
                        head = head.name,
                        tool_rod = tool.name,
                        extra = extra.name,
                        special = { head.head.special, extra.head.special, tool.tool_rod.special }
                    }
                end
                
                -- ChatGPT feature:
                -- Insert the tool into Tool_list if it's better than the worst tool in the list
                if #Tool_list < MAX_COUNT then
                    table.insert(Tool_list, newTool)
                else
                    -- Find the tool with the minimum durability in the list
                    local min_durability_index = 1
                    for i = 2, #Tool_list do
                        if formula(atribute, Tool_list[i], type_of_tool) < formula(atribute, Tool_list[min_durability_index], type_of_tool) then
                            min_durability_index = i
                        end
                    end

                    -- Replace the tool with minimum durability if the new tool is better
                    if formula(atribute, newTool, type_of_tool) > formula(atribute, Tool_list[min_durability_index], type_of_tool) then
                        Tool_list[min_durability_index] = newTool
                    end
                end
            end
        end
    end
end

local function write_results(folder, type_of_tool)
    folder = folder or "tinkers"
    local location = folder.."/results.lua"
    if fs.exists(location) then
        fs.delete(location)
    end
    print("Zapisujem do "..location)
    print("----------")
    local file = fs.open(location, "w")
    if MAX_COUNT > #Tool_list then
        MAX_COUNT = #Tool_list 
    end
    for i=1, MAX_COUNT do
        file.writeLine(i..". Durability: ".. Tool_list[i].durability .. "   Speed: ".. Tool_list[i].speed.. "   M_level: ".. Tool_list[i].mininglevel)
        file.writeLine("    Attack: ".. Tool_list[i].attack .. "   Special: ".. Tool_list[i].special[1]..", ".. Tool_list[i].special[2]..", ".. Tool_list[i].special[3])
        file.writeLine("    Vyroba: head:      ".. Tool_list[i].head) 
        if type_of_tool == "pickaxe" or type_of_tool == "shovel" or type_of_tool == "axe" then
        file.writeLine("            binding:   " ..Tool_list[i].extra)
        elseif type_of_tool == "hammer" then
        file.writeLine("            2 plates:  " ..Tool_list[i].extra)
        elseif type_of_tool == "sword" then
        file.writeLine("            wideguard: " ..Tool_list[i].extra)
        end
        file.writeLine("            tool_rod:  " ..Tool_list[i].tool_rod)
        file.writeLine("--------------------------------------------------")
    end
    file.close()
    
end


term.clear()
term.setCursorPos(1,1)
print("Zadaj parameter (cislom), podla ktoreho sa ma vykonat vypocet")
print("[1] - Mix (Durability & MiningSpeed/Attack)")
print("[2] - Durability")
print("[3] - Mining Speed")
print("[4] - Attack")
print("-----------------------")
write("-->  ")
local choice = read()
local param = ""
local type_of_tool = ""   
if choice == "1" then
    param = "mix"
elseif choice == "2" then
    param = "durability"
elseif choice == "3" then
    param = "speed"
elseif choice == "4" then
    param = "attack"
else
    print("Chybne zadany argument, program sa ukoncuje..")
    sleep(1.5)
    term.clear()
    return
end
term.clear()
term.setCursorPos(1,1)
print("Zadaj parameter (cislom), ktory nastroj chces vypocitat")
print("[1] - Pickaxe")
print("[2] - Shovel")
print("[3] - Hatchet")
print("[4] - Hammer")
print("[5] - Excavator")
print("[6] - Lumber Axe")
print("[7] - Broadsword")
print("-----------------------")
write("-->  ")
choice = read()
if choice == "1" then
    type_of_tool = "pickaxe"
elseif choice == "2" then
    type_of_tool = "shovel"
elseif choice == "3" then
    type_of_tool = "axe"
elseif choice == "4" then
    type_of_tool = "hammer"
elseif choice == "5" then
    type_of_tool = "excavator"
    print("To do!")
    return
elseif choice == "6" then
    type_of_tool = "lumber"
    print("To do!")
    return
elseif choice == "7" then
    type_of_tool = "sword"
else
    print("Chybne zadany argument, program sa ukoncuje..")
    sleep(1.5)
    term.clear()
    return
end



Material_load();
best_parts(MAX_SIZE, param, type_of_tool)
calculate(MAX_SIZE, param, type_of_tool)
print(type_of_tool)
print(#Tool_list)
print(Tool_list[1].head)
sleep(1)
sort_tools_by_hardness(param, type_of_tool)
print(Tool_list[1].head)
sleep(1)
write_results("tinkers", type_of_tool)
print("Hotovo")




--[[
local wood = Material:new(
    "wood",
    {
        durability = 30,
        miningLevel = 1,
        miningSpeed = 2,
        attack = 1,
        special = "Ecological"
    },
    {
        durability = 20,
        modifier = "1",
        special = "Ecological"
    },
    {
        durability = 10,
        special = "Ecological"
    }
)
]]--
--wood:show()
