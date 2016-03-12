--[[
    PlayerResource:Select(playerID, unit_args)
    * Creates a new selection for the player
    * Can recieve an Entity Index, a NPC Handle, or a table of each type.
--]]
function CDOTA_PlayerResource:Select(playerID, unit_args)
    local player = self:GetPlayer(playerID)
    if player then
        local entities = Selection:GetEntIndexListFromTable(unit_args)
        CustomGameEventManager:Send_ServerToPlayer(player, "selection_new", {entities = entities})
    end
end 

--[[
    PlayerResource:AddToSelection(playerID, unit_args)
    * Adds units to the current selection
    * Can recieve an Entity Index, NPC Handle, or a table of each type.
--]]
function CDOTA_PlayerResource:AddToSelection(playerID, unit_args)
    local player = self:GetPlayer(playerID)
    if player then
        local entities = Selection:GetEntIndexListFromTable(unit_args)
        CustomGameEventManager:Send_ServerToPlayer(player, "selection_add", {entities = entities})
    end
end

--[[
    PlayerResource:RemoveFromSelection(playerID, unit_args)
    * Removes units from the player selection
    * Can recieve an Entity Index, NPC Handle, or a table of each type.
    * If the unit isn't currently selected, it will be skipped
--]]
function CDOTA_PlayerResource:RemoveFromSelection(playerID, unit_args)
    local player = self:GetPlayer(playerID)
    if player then
        local entities = Selection:GetEntIndexListFromTable(unit_args)
        CustomGameEventManager:Send_ServerToPlayer(player, "selection_remove", {entities = entities})
    end
end

--[[
    PlayerResource:ResetSelection(playerID)
    * Clears the current selection of the player
    * The game will select the main hero, and this can be redirected to another entity
]]
function CDOTA_PlayerResource:ResetSelection(playerID)
    local player = self:GetPlayer(playerID)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "selection_reset", {})
    end
end

--[[
    PlayerResource:GetSelectedEntities(playerID)
    * Returns the list of units by entity index that are selected by the player
--]]
function CDOTA_PlayerResource:GetSelectedEntities(playerID)
    return Selection.entities[playerID] or {}
end

--[[
    PlayerResource:IsUnitSelectedByPlayerID(playerID)
    * Returns the index of the first selected unit of the player
--]]
function CDOTA_PlayerResource:GetMainSelectedEntity(playerID)
    local selectedEntities = self:GetSelectedEntities(playerID) 
    return selectedEntities and selectedEntities["0"]
end

--[[
    PlayerResource:IsUnitSelectedByPlayerID(playerID, unit_args)
    * Can recieve an Entity Index or NPC Handle
    * Returns bool
--]]
function CDOTA_PlayerResource:IsUnitSelectedByPlayerID(playerID, unit)
    if not unit then return false end
    local entIndex = type(unit)=="number" and unit or IsValidEntity(unit) and unit:GetEntityIndex()
    if not entIndex then return false end
    
    local selectedEntities = self:GetSelectedEntities(playerID)
    for _,v in pairs(selectedEntities) do
        if v==entIndex then
            return true
        end
    end
    return false
end

--[[
    PlayerResource:SetDefaultSelectionEntity(playerID)
    * Redirects the selection of the main hero to another entity of choice
    * Can recieve an Entity Index or NPC Handle
    * Use -1 to reset to default
]]
function CDOTA_PlayerResource:SetDefaultSelectionEntity(playerID, unit)
    if not unit then unit = -1 end
    local entIndex = type(unit)=="number" and unit or unit:GetEntityIndex()
    local hero = self:GetSelectedHeroEntity(playerID)
    if hero then
        hero:SetSelectionOverride(unit)
    end
end

--[[
    npcHandle:SetSelectionOverride(reselect_unit)
    * Redirects the selection of any entity to another entity of choice
    * Can recieve an Entity Index or NPC Handle
    * Use -1 to reset to default
]]
function CDOTA_BaseNPC:SetSelectionOverride(reselect_unit)
    local unit = self
    local reselectIndex = type(reselect_unit)=="number" and reselect_unit or reselect_unit:GetEntityIndex()

    CustomNetTables:SetTableValue("selection", tostring(unit:GetEntityIndex()), {entity = reselectIndex})
end

------------------------------------------------------------------------
-- Internal
------------------------------------------------------------------------

if not Selection then
    Selection = class({})
end

function Selection:Init()
    Selection.entities = {} --Stores the selected entities of each playerID
    Selection.default_entity = {} --Stores a possible selection override for each playerID
    CustomGameEventManager:RegisterListener("selection_update", Dynamic_Wrap(Selection, 'OnUpdate'))
end

function Selection:OnUpdate(event)
    local playerID = event.PlayerID
    Selection.entities[playerID] = event.entities
end

function Selection:Refresh()
    FireGameEvent("dota_player_update_selected_unit", {})
end

-- Internal function to build an entity index list out of various inputs
function Selection:GetEntIndexListFromTable(unit_args)
    local entities = {}
    if type(unit_args)=="number" then
        table.insert(entities, unit_args) -- Entity Index
    -- Check contents of the table
    elseif type(unit_args)=="table" then
        if unit_args.IsCreature then
            table.insert(entities, unit_args:GetEntityIndex()) -- NPC Handle
        else
            for _,arg in pairs(unit_args) do
                -- Table of entity index values
                if type(arg)=="number" then
                    table.insert(entities, arg)
                -- Table of npc handles
                elseif type(arg)=="table" then
                    if arg.IsCreature then
                        table.insert(entities, arg:GetEntityIndex())
                    end
                end
            end
        end
    end
    return entities
end

if not Selection.entities then Selection:Init() end