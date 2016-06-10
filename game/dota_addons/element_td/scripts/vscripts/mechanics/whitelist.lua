function VerifyRegions()
    local regions = LoadKeyValues("scripts/regions.txt")
    local ips = {}
    local regionsOrder = {}
    for regionName,values in pairs(regions) do
        if values["region"] then
            regionsOrder[values["region"]] = values
        end
    end
    for i,values in pairs(regionsOrder) do
        for k,v in pairs(values) do
            if k == "ip_range" then
                if type(v) == "table" then
                    for _,ip in pairs(v) do
                        -- Handles range between '-'
                        if ip:match("-") then
                            local ipSection,start,finish = ip:match('(%d+%.%d+%.%d+%.)(%d+)%-%d+%.%d+%.%d+%.(%d+)')
                            start = tonumber(start)
                            finish = tonumber(finish)
                            for i=start,finish do
                                table.insert(ips,ipSection..i)
                            end
                        else
                            table.insert(ips,ip)
                        end
                    end
                else table.insert(ips,v) end
            end
        end
    end

    local output = "$_IP_WHITELIST = array("
    for _,ip in pairs(ips) do
        output = output.."\""..ip.."\","
    end
    output = output:sub(1, - 2)
    output = output..")"

    local file = io.open("../../dota_addons/element_td/scripts/IP_WhiteList.txt", 'r')
    local content = file:read("*all")
    file:close()

    if content ~= output then
        file = io.open("../../dota_addons/element_td/scripts/IP_WhiteList.txt", 'w')
        file:write(output)
        file:close()
        print("Regions Updated!")
    end
end

if IsInToolsMode() then
    VerifyRegions()
end