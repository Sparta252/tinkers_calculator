--[[
Name: Tinker's tool calculator
Author: Sparta252
Date: 12.06.2024
Language: Lua - ComputerCraft
]]--

MAX_COUNT = 25 -- Pocet TOP nastrojov zapisanych do tinkers/results.lua
MAX_SIZE = 30 -- Urcuje tzv. Presnost (Vyssia hodnota, tazsi a dlhsi vypocet)



Material_list = {}
Tool_list = {}
Tool = {} -- Durability, Speed, Mining Level, Attack, Head, Extra, Tool_rod
Top_head = {}
Top_extra = {}
Material = {}

local function tableContains(table, value)
    for i = 1,#table do
      if (table[i] == value) then
        return true
      end
    end
    return false
end

function sort_tools_by_hardness()
    table.sort(Tool_list, function(a, b) return a.durability > b.durability end)
end

function Material:new(name, head, tool_rod, extra)
    local instance = {} -- Vytvorenie novej in?tancie ako prázdna tabu?ka
    setmetatable(instance, self) -- Nastavenie metatabule pre in?tanciu
    self.__index = self -- Definovanie dedi?stva metód
    instance.name = name
    instance.head = head
    instance.tool_rod = tool_rod 
    instance.extra = extra 
    return instance -- Vrátenie novej in?tancie
end

function Material:show()
    local head_info = {"durability", "miningLevel", "miningSpeed", "attack", "special"}
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
    -- local whitelist = whitefile.readAll()
    -- local blacklist = blackfile.readAll()
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
local function best_parts(size, atribute)
    print("Spracuvavam ".. #Material_list*#Material_list*#Material_list .. " moznosti")
    print("----------")
    size = size or MAX_SIZE
    atribute = atribute or "durability"
    if #Material_list < size then
        size = #Material_list
    end
    
    for i=1, #Material_list do
        if #Top_head < size then
            table.insert(Top_head, Material_list[i])
            table.insert(Top_extra, Material_list[i])
        else
            local min_head_index = 1
            local min_extra_index = 1

            for j=2, #Top_head do
                if Top_head[j].head.durability < Top_head[min_head_index].head.durability then
                    min_head_index = j
                end
                if Top_extra[j].extra.durability < Top_extra[min_extra_index].extra.durability then
                    min_extra_index = j
                end
            end

            if Material_list[i].head.durability > Top_head[min_head_index].head.durability then
                Top_head[min_head_index] = Material_list[i]
            end 

            if Material_list[i].extra.durability > Top_extra[min_extra_index].extra.durability then
                Top_extra[min_extra_index] = Material_list[i]
            end 


        end
    end
    print("Zjedodusujem na ".. #Material_list*size*size .." moznosti")
    print("----------")
end

local function calculate(size, atribute)
    atribute = atribute or "durability"
    size = size or MAX_SIZE
    print("Vytvaram vhodne kombinacie")
    print("----------")
    local num_of_tool = 0;

    if atribute == "durability" then
        local max_materials = #Material_list
        for head_combo = 1, size do
            for extra_combo = 1, size do
                for tool_combo = 1, max_materials do
                    num_of_tool = num_of_tool + 1

                    local head = Top_head[head_combo]
                    local extra = Top_extra[extra_combo]
                    local tool = Material_list[tool_combo]

                    local hardness = ((head.head.durability + extra.extra.durability) * tool.tool_rod.modifier) + tool.tool_rod.durability

                    if head.head.special == "Cheepskate" then
                        hardness = hardness * 0.8
                    end

                    local newTool = {
                        durability = hardness,
                        speed = head.head.miningSpeed,
                        mininglevel = head.head.miningLevel,
                        attack = head.head.attack,
                        head = head.name,
                        tool_rod = tool.name,
                        extra = extra.name,
                        special = { head.head.special, extra.extra.special, tool.tool_rod.special }
                    }
                    
                    -- ChatGPT feature:
                    -- Insert the tool into Tool_list if it's better than the worst tool in the list
                    if #Tool_list < MAX_COUNT then
                        table.insert(Tool_list, newTool)
                    else
                        -- Find the tool with the minimum durability in the list
                        local min_durability_index = 1
                        for i = 2, #Tool_list do
                            if Tool_list[i].durability < Tool_list[min_durability_index].durability then
                                min_durability_index = i
                            end
                        end

                        -- Replace the tool with minimum durability if the new tool is better
                        if newTool.durability > Tool_list[min_durability_index].durability then
                            Tool_list[min_durability_index] = newTool
                        end
                    end
                end
            end
        end
    end
end

function write_results(folder)
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
        file.writeLine("    Vyroba: head:     ".. Tool_list[i].head) 
        file.writeLine("            extra:    " ..Tool_list[i].extra)
        file.writeLine("            tool_rod: " ..Tool_list[i].tool_rod)
        file.writeLine("--------------------------------------------------")
    end
    file.close()
    
end

Material_load();
best_parts()
calculate();
sort_tools_by_hardness()
write_results()
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
