local function downloadFile(url, filename)
    local response = http.get(url)
    if response then
        local file = fs.open("tinkers/"..filename, "w")
        file.write(response.readAll())
        file.close()
        response.close()
        print("Soubor ".. filename .." bol uspesne stiahnuty.")
    else
        print("Nepodarilo se stiahnut soubor z danej URL.")
    end
end


local url = "https://raw.githubusercontent.com/Sparta252/tinkers_calculator/main/tinkers/calc.lua"
downloadFile(url, "calc.lua")
url = "https://raw.githubusercontent.com/Sparta252/tinkers_calculator/main/tinkers/data.lua"
downloadFile(url, "data.lua")

shell.run("tinkers/calc.lua")
sleep(1)
term.clear()

print("Stahujem Databazu")
sleep(2.5)
local database = fs.open("tinkers/data.lua", "r")
while 1 do
    local material = database.readLine()
    if not material then
        break
    end
    url = "https://raw.githubusercontent.com/Sparta252/tinkers_calculator/main/tinkers/materials/"..material
    downloadFile(url, "materials/"..material)

end
database.close()

print("hotovo")