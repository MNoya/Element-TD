if not Tooltips then
    Tooltips = class({})
end

function Tooltips:Validate()
    Tooltips.mainLanguage = "english"
    Tooltips.resourceTooltips = LoadKeyValues("resource/addon_"..Tooltips.mainLanguage..".txt").Tokens
    Tooltips.panoramaTooltips = LoadKeyValues("panorama/localization/addon_"..Tooltips.mainLanguage..".txt").Tokens
    Tooltips.file = io.open("../../dota_addons/element_td/scripts/Tooltips.txt", 'w')

    local languages = {"schinese"}
        
    for _,language in pairs(languages) do
        Tooltips:Check(Tooltips.resourceTooltips, "resource/addon_"..language..".txt")
        Tooltips:Check(Tooltips.panoramaTooltips, "panorama/localization/addon_"..language..".txt")
    end

    Tooltips.file:close()
end

function Tooltips:Check(mainFile, fileName)
    Tooltips:write("Checking "..fileName)
    local file = LoadKeyValues(fileName).Tokens
    local separator = ("------------------------------------------")

    local missing = {}
    local diffValues = {}
    local missValues = {}
    for key,mainValue in pairs(mainFile) do
        if not file[key] then
            table.insert(missing, key)
        else
            local originalNumbers = {}
            local translationNumbers = {}
            mainValue:gsub( "%d+", function(i) table.insert(originalNumbers, i) end)
            file[key]:gsub( "%d+", function(i) table.insert(translationNumbers, i) end)

            for k,v in pairs(originalNumbers) do
                if originalNumbers[k] ~= translationNumbers[k] then
                    if translationNumbers[k] then
                        table.insert(diffValues, {key=string.gsub(key, "DOTA_Tooltip_ability_", ""), translation=translationNumbers[k], original=originalNumbers[k]})
                    else
                        table.insert(missValues, {key=string.gsub(key, "DOTA_Tooltip_ability_", ""), original=originalNumbers[k]})
                    end
                end
            end
        end
    end

    if #missing > 0 then
        Tooltips:write("Missing Keys:")
        table.sort(missing, function(a,b) return a < b end)

        local max = 0
        for k,v in pairs(missing) do
            max = string.len(v) > max and string.len(v) or max
        end

        for k,v in pairs(missing) do
            local spaces = max + 4 - string.len(v)
            Tooltips:write(string.rep(" ", 8).."\""..v.."\""..string.rep(" ", spaces).."\"\"")
        end
    else
        Tooltips:write("OK - 0 Missing keys on "..fileName.."!")
    end

    local maxValueLen = 0
    Tooltips:write(separator)
    if #diffValues > 0 then
        Tooltips:write("Different Number Values:")
        table.sort(diffValues, function(a,b) return a.key < b.key end)

        for k,v in pairs(diffValues) do
            maxValueLen = string.len(v.key) > maxValueLen and string.len(v.key) or maxValueLen
        end

        for k,v in pairs(diffValues) do
            local spaces = maxValueLen + 4 - string.len(v.key)
            Tooltips:write(v.key..string.rep(" ", spaces)..v.translation.."->"..v.original)
        end
    else
        Tooltips:write("OK - 0 Different Number Values on "..fileName.."!")
    end

    Tooltips:write(separator)
    if #missValues > 0 then
        Tooltips:write("Missing Number Values:")
        table.sort(diffValues, function(a,b) return a.key < b.key end)

        for k,v in pairs(missValues) do
            local spaces = maxValueLen + 4 - string.len(v.key)
            Tooltips:write(v.key..string.rep(" ", spaces)..v.original)
        end
    else
        Tooltips:write("OK - 0 Missing Number Values on "..fileName.."!")
    end

    Tooltips:write(separator)
end

function Tooltips:write(...)
    Tooltips.file:write(... .."\n")
end