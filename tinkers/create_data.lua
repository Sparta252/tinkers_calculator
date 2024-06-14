local folderPath = "tinkers/materials"  -- Cesta k adresáři materials
local outputFile = "data.lua"  -- Název výstupního souboru

-- Funkce pro zápis dat do souboru
local function writeToFile(filename, content)
    local file = fs.open(filename, "a")  -- Otevření souboru pro přidání na konec
    if file then
        file.writeLine(content)  -- Zápis obsahu na nový řádek
        file.close()  -- Uzavření souboru
        print("Název souboru '" .. content .. "' byl úspěšně zapsán do souboru '" .. filename .. "'.")
    else
        print("Nepodařilo se otevřít soubor '" .. filename .. "' pro zápis.")
    end
end

-- Funkce pro načtení seznamu souborů z adresáře
local function listFilesInFolder(path)
    local files = fs.list(path)  -- Získání seznamu souborů v adresáři
    if files then
        for _, filename in ipairs(files) do
            writeToFile(outputFile, filename)  -- Zápis názvu každého souboru do výstupního souboru
        end
    else
        print("Adresář '" .. path .. "' neexistuje nebo nelze přistupovat k obsahu.")
    end
end

-- Zavolání funkce pro získání a zápis názvů souborů
listFilesInFolder(folderPath)