-- item_toggle_grid
function ToggleGrid( event )
    local item = event.ability
    local playerID = event.caster:GetPlayerOwnerID()
    item.playerID = playerID
    local playerData = GetPlayerData(playerID)
    local sector = playerData.sector + 1
    local count = 0
    item.enabled = not item.enabled

    Saves:SaveGrid(playerID, item.enabled)

    if item.enabled then
        if COOP_MAP then
            for y,v in pairs(BuildingHelper.Grid) do
                for x,_ in pairs(v) do
                    local pos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0), nil)
                    if pos.z > 380 and pos.z < 400 and IsInsideSector(pos, sector) then
                        if BuildingHelper:CellHasGridType(x, y, 'BUILDABLE') then
                            Timers:CreateTimer(math.abs(x)*0.01, function()
                                item.particles[x][y] = DrawGrid(x, y, Vector(255,255,255), playerID)
                            end)
                        end
                    end
                end
            end

        else

            for y,v in pairs(BuildingHelper.Grid) do
                for x,_ in pairs(v) do
                    local pos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0), nil)
                    if pos.z > 380 and pos.z < 400 and IsInsideSector(pos, sector) then
                        if BuildingHelper:CellHasGridType(x, y, 'BUILDABLE') then
                            item.particles[x][y] = DrawGrid(x, y, Vector(255,255,255), playerID)
                        end
                    end
                end
            end
        end
    else
        ClearGrid(item)
    end
end

function ClearGrid( item )
    for x, yt in pairs(item.particles) do
        for y, particle in pairs(yt) do
            ParticleManager:DestroyParticle(particle, true)
            item.particles[x][y] = nil
        end
    end
end

function DrawGrid(x, y, color, playerID)
    local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
    BuildingHelper:SnapToGrid(1, pos)
    pos = GetGroundPosition(pos, nil)
        
    local particle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/square_overlay.vpcf", PATTACH_CUSTOMORIGIN, nil, PlayerResource:GetPlayer(playerID))
    ParticleManager:SetParticleControl(particle, 0, pos)
    ParticleManager:SetParticleControl(particle, 1, Vector(32,0,0))
    ParticleManager:SetParticleControl(particle, 2, color)
    ParticleManager:SetParticleControl(particle, 3, Vector(90,0,0))

    return particle
end

function ToggleGridForTower(tower, destroy)
    local ownerID = tower:GetPlayerOwnerID()
    local items = {}

    if COOP_MAP then
        ForAllPlayerIDs(function(playerID)
            local playerData = GetPlayerData(ownerID)
            if playerData.toggle_grid_item and playerData.toggle_grid_item.enabled then
                table.insert(items, playerData.toggle_grid_item)
            end
        end)
    else
        local playerData = GetPlayerData(ownerID)
        if playerData.toggle_grid_item and playerData.toggle_grid_item.enabled then
            table.insert(items, playerData.toggle_grid_item)
        else
            return
        end
    end

    local location = tower:GetAbsOrigin()
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local boundX1 = originX + 1
    local boundX2 = originX - 1
    local boundY1 = originY + 1
    local boundY2 = originY - 1

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    upperBoundX = upperBoundX - 1
    upperBoundY = upperBoundY - 1

    local particleList = {}
    for k,v in pairs(items) do
        table.insert(particleList, v)
    end

    if destroy then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                for _,item in pairs(particleList) do
                    local particles = item.particles
                    if particles[x][y] then
                        ParticleManager:DestroyParticle(particles[x][y], true)
                        particles[x][y] = nil
                    end
                end
            end
        end
    else
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                for k,item in pairs(particleList) do
                    local particles = item.particles
                    if not particles[x][y] then
                        particles[x][y] = DrawGrid(x, y, Vector(255,255,255), item.playerID)
                    end
                end
            end
        end
    end
end
